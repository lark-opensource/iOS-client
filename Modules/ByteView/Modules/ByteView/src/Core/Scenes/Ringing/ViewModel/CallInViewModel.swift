//
//  CallInViewModel.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/6/15.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import ByteViewCommon
import ByteViewNetwork
import ByteViewMeeting
import ByteViewTracker
import AVFoundation
import LarkMedia
import ByteViewSetting

// 用于悬浮窗样式
extension CallInViewModel {
    var floatVM: FloatingPreMeetVM {
        FloatingPreMeetVM(session: meeting,
                          service: service,
                          avatarInfo: self.avatarInfo,
                          topic: self.name,
                          meetingStatus: self.floatDescription)
    }
}

enum CallInType: Equatable {
    case vc
    case ipPhone(String)
    case ipPhoneBindLark
    case enterprisePhone(String)
    case recruitmentPhone(String)

    var isPhoneCall: Bool {
        return self != .vc
    }

    var isPhoneCallWithoutBinding: Bool {
        return self == .ipPhone("") || self == .enterprisePhone("") || self == .recruitmentPhone("")
    }

    static func == (lhs: CallInType, rhs: CallInType) -> Bool {
        return lhs.type == rhs.type
    }

    var type: String? {
        return String(describing: self).components(separatedBy: "(").first
    }
}

class CallInViewModel: MeetingBasicServiceProvider {
    private let disposeBag = DisposeBag()

    // MARK: - Input
    let isVoiceCall: Bool
    let isBusyRinging: Bool
    let isButtonEnabled = BehaviorSubject<Bool>(value: true)
    private let callInDescriptionSubject: BehaviorSubject<String>
    var callInViewStyle: CallInViewStyle

    // MARK: - Output
    let avatarInfo: Driver<AvatarInfo>
    let name: Driver<String>
    var callInDescription: Driver<String> = .empty()
    var meetInDescription: Driver<String> = .empty()
    let floatDescription: Driver<String> = .just(I18n.View_G_Ringing)
    let meeting: MeetingSession
    let callInType: CallInType
    let meetInTopic: Driver<String>  // 会中邀请使用
    var hasShownFloating = false
    var callName: String = ""

    var isWebinar: Bool
    var precheckBuilder: PrecheckBuilder?

    var is1v1: Bool { meeting.meetType == .call }

    // MARK: - private method
    var isCallKitEnabled: Bool {
        meeting.isCallKit
    }

    let service: MeetingBasicService

    // MARK: - Init
    init?(meeting: MeetingSession, isBusyRinging: Bool, viewType: CallInViewStyle) {
        guard let startInfo = meeting.videoChatInfo, let service = meeting.service else {
            Logger.meeting.error("create CallInViewModel failed: videoChatInfo is nil")
            return nil
        }
        Logger.ring.info("callinvm init")

        self.meeting = meeting
        self.service = service
        self.isBusyRinging = isBusyRinging
        self.callInViewStyle = viewType

        self.callInType = meeting.callInType
        self.isWebinar = meeting.setting?.meetingSubType == .webinar

        self.isVoiceCall = callInType == .ipPhone("") ? true : startInfo.isVoiceCall

        let value = service.setting.topic
        self.meetInTopic = Observable<String>.just(value).asDriver(onErrorJustReturn: "")

        let initialDescription = Self.getDescriptionText(callInType, isVoiceCall: isVoiceCall)
        self.callInDescriptionSubject = BehaviorSubject<String>(value: initialDescription)
        self.callInDescription = callInDescriptionSubject.asDriver(onErrorRecover: { _ in return .empty() })

        let avatarSubject = ReplaySubject<AvatarInfo>.create(bufferSize: 1)
        let nameSubject = ReplaySubject<String>.create(bufferSize: 1)
        self.avatarInfo = avatarSubject.asDriver(onErrorRecover: { _ in return .empty() })
        self.name = nameSubject.asDriver(onErrorJustReturn: "")
        let callerName: String
        switch callInType {
        case .ipPhone(let name):
            callerName = name
        case .enterprisePhone(let name), .recruitmentPhone(let name):
            callerName = PhoneNumberUtil.format(name) ?? name
        default:
            callerName = ""
        }
        let currentUserId = meeting.userId
        var pid: ParticipantId?
        switch meeting.meetType {
        case .meet:
            pid = startInfo.inviterPid
        case .call:
            pid = startInfo.participants.first(where: { $0.user.id != currentUserId })?.participantId
        default:
            pid = nil
        }
        if let pid = pid {
            meeting.httpClient.participantService.participantInfo(pid: pid, meetingId: startInfo.id) { [weak self] ap in
                avatarSubject.onNext(ap.avatarInfo)
                let name = callerName.isEmpty ? ap.name : callerName
                self?.callName = name
                nameSubject.onNext(name)
            }
        }

        let nameInvitationObservable = name.map { [weak self] name in
            (self?.isWebinar ?? false) ? I18n.View_G_NameInviteYouToWebinar(name) : I18n.View_M_WantsYouToJoinNameBraces(name)
        }
        self.meetInDescription = nameInvitationObservable.asDriver(onErrorJustReturn: "")
    }

    deinit {
        Logger.ring.info("callinVM deinit")
    }

    func onAccept() {
        isButtonEnabled.onNext(false)
        callInDescriptionSubject.onNext(I18n.View_G_Connecting)
    }

    func decline() {
        notifyUserDeclined()
        if callInType == .vc && !isWebinar { //拒绝回复，办公电话和webinar不支持
            showDeclinedRefuse()
        }
        trackPressAction(click: "refuse", target: .none)
    }

    func accept() {
        OnthecallReciableTracker.startEnterOnthecall()
        meeting.slaTracker.startEnterOnthecall()
        if isVoiceCall {
            acceptVoiceOnly()
            return
        }

        let context = MeetingPrecheckContext(service: service)
        precheckBuilder = PrecheckBuilder()
        precheckBuilder?.checkMediaResourceOccupancy(isJoinMeeting: true)
            .checkMediaResourcePermission(isNeedAlert: false, isNeedCamera: true)
        precheckBuilder?.execute(context) { [weak self] result in
            guard case .success = result else { return }
            Util.runInMainThread {
                guard let self = self else { return }
                self.onAccept()
                var meetingSettings = MicCameraSetting.none
                if Privacy.audioAuthorized {
                    meetingSettings.isMicrophoneEnabled = true
                }
                if Privacy.videoAuthorized {
                    meetingSettings.isCameraEnabled = true
                }
                self.notifyUserAccepted(meetingSettings)
            }
        }
        trackPressAction(click: "accept", target: callInType == .vc ? TrackEventName.vc_meeting_onthecall_view : TrackEventName.vc_office_phone_calling_view)
    }

    func acceptVoiceOnly() {
        meeting.slaTracker.startEnterOnthecall()
        let context = MeetingPrecheckContext(service: service)
        precheckBuilder = PrecheckBuilder()
        precheckBuilder?.checkMediaResourceOccupancy(isJoinMeeting: true)
            .checkMediaResourcePermission(isNeedAlert: false, isNeedCamera: false)
        precheckBuilder?.execute(context) { [weak self] result in
            guard case .success = result else { return }
            Util.runInMainThread {
                guard let self = self else { return }
                self.onAccept()
                let isAuthorized = Privacy.audioAuthorized
                self.notifyUserAccepted(result.isSuccess && isAuthorized ? .onlyAudio : .none)
            }
        }
        trackPressAction(click: "audio_only", target: TrackEventName.vc_meeting_onthecall_view)
    }

    func notifyUserDeclined() {
        OnthecallReciableTracker.cancelStartOnthecall()
        meeting.slaTracker.endEnterOnthecall(success: true)
        meeting.declineRinging()
    }

    func notifyUserAccepted(_ meetSetting: MicCameraSetting) {
        meeting.acceptRinging(setting: meetSetting)
    }

    func showDeclinedRefuse() {
        if let inviterId = meeting.videoChatInfo?.inviterId {
            Logger.ringRefuse.info("decline \(meeting.meetingId) \(meeting.meetType) \(inviterId)")
            let body: RingRefuseBody = RingRefuseBody(meetingId: meeting.meetingId, isSingleMeeting: meeting.meetType == .call, inviterUserId: inviterId, inviterName: callName)
            RingingRefuseManager.shared.openRingRefuse(with: body, httpClient: service.httpClient)
        }
    }
}

extension CallInViewModel {
    private static func getDescriptionText(_ callInType: CallInType, isVoiceCall: Bool) -> String {
        let text: String
        switch callInType {
        case .ipPhone, .ipPhoneBindLark:
            text = I18n.View_G_CallFromPhone
        case .enterprisePhone:
            text = I18n.View_G_OfficePhoneCallback
        case .recruitmentPhone:
            text = I18n.View_G_CallFromCandidate
        default:
            text = isVoiceCall ? I18n.View_A_IncomingVoiceCall : I18n.View_V_IncomingVideoCall
        }
        return text
    }
}

// MARK: - Track
extension CallInViewModel {
    func doPageTrack() {
        var params: TrackParams = [
            "is_mic_open": false,
            "is_in_duration": false,
            "is_cam_open": false,
            "is_voip": meeting.isCallKitFromVoIP ? 1 : 0,
            "is_ios_new_feat": 0, // 新特性上线后有效
            "is_bluetooth_on": LarkAudioSession.shared.isBluetoothActive,
            "is_full_card": self.callInViewStyle == .fullScreen,
            "is_callkit": false,
            "ring_match_id": meeting.sessionId
        ]
        if meeting.meetType == .call {
            params.updateParams(getCallParamsTrack())
        }
        VCTracker.post(name: .vc_meeting_callee_view, params: params)
    }

    func getCallParamsTrack() -> [String: Any] {
        switch callInType {
        case .ipPhone, .ipPhoneBindLark:
            return ["call_source": "ip_phone"]
        case .enterprisePhone:
            return ["call_source": "office_call"]
        case .recruitmentPhone:
            return ["call_source": "recruit_phone"]
        default:
            return isVoiceCall ? ["call_source": "voice_call"] : ["call_source": "video_call"]
        }
    }

    func getCallNameTrack(route: AudioOutput) -> String {
        switch route {
        case .speaker:
            return "speaker"
        case .receiver:
            return "receiver"
        case .headphones:
            return "earphone"
        case .bluetooth:
            return "bluetooth"
        default:
            return ""
        }
    }

    func getCallType() -> String {
        var callType: String = "unknown"
        switch self.meeting.meetType {
        case .call:
            callType = "call"
        case .meet:
            callType = "meeting"
        default:
            callType = "unknown"
        }
        return callType
    }

    func trackPressAction(click: String, target: TrackEventName) {
        var params: TrackParams = [
            .click: click,
            .target: target,
            "is_in_duration": isBusyRinging ? true : false,
            "call_type": getCallType(),
            "is_full_view": callInViewStyle == .fullScreen,
            "is_voip": meeting.isCallKitFromVoIP ? 1 : 0,
            "is_ios_new_feat": 0,
            "is_callkit": false
        ]
        if meeting.meetType == .call {
            params.updateParams(getCallParamsTrack())
        }
        VCTracker.post(name: .vc_meeting_callee_click, params: params)
    }

    func trackRouteChange(_ output: AudioOutput) {
        var params: TrackParams = [
            .click: output.i18nText,
            .location: "callee_page",
            "is_in_duration": false,
            "is_bluetooth_on": output == .bluetooth,
            "is_full_card": true,
            "is_callkit": false
        ]
        if self.meeting.meetType == .call {
            params.updateParams(getCallParamsTrack())
        }
        VCTracker.post(name: .vc_meeting_callee_click, params: params)
    }
}
