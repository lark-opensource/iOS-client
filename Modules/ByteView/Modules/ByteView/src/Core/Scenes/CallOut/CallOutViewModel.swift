//
//  CallOutViewModel.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/6/14.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import AVFoundation
import LarkMedia
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import ByteViewMeeting
import ByteViewSetting

// 用于悬浮窗样式
extension CallOutViewModel {
    var floatVM: FloatingPreMeetVM {
        FloatingPreMeetVM(session: self.session,
                          service: self.service,
                          avatarInfo: self.avatarInfo,
                          topic: self.name,
                          meetingStatus: self.floatDescription)

    }
}

final class CallOutViewModel {
    // MARK: - public property
    let avatarInfo: Driver<AvatarInfo>
    let name: Driver<String>
    let descriptionRelay = BehaviorRelay<String>(value: "")
    lazy var description: Driver<String> = {
        descriptionRelay.asDriver(onErrorJustReturn: "").map { [weak self] in
            guard let self = self else { return "" }
            return $0 + (self.shouldShowSecureAlert ? "\n" + I18n.View_G_NoteForSecurechat : "")
        }
    }()
    let floatDescription: Driver<String> = .just(I18n.View_G_Calling)

    let isCameraOn: Bool

    let timeoutOfDialing: Driver<Void>
    let noResponseOfDialing: Driver<Void>

    let isVoiceCall: Bool
    var meetSetting: MicCameraSetting
    var hasShownFloating = false

    // MARK: - private property
    private static let logger = Logger.callOut
    private static let dialingTimeoutSeconds = 70
    private static let noResponseSeconds = 15

    var shouldShowAudioToast = false
    private let disposeBag = DisposeBag()

    private let invitationReceived: Observable<Bool>

    private let dialingSubject: ReplaySubject<Bool>
    private let dialingState: Observable<Bool>
    private var callingTime: CFTimeInterval?
    private var cancelTime: CFTimeInterval?
    private var invitationReceivedTime: CFTimeInterval?

    private var isCallKitAudioSessionReady = false
    private var isSoundPlaying = false
    private let isFromSecretChat: Bool
    private let isE2EeMeeting: Bool
    private var player: RtcAudioPlayer?
    private let startCallInfo: StartCallParams
    let session: MeetingSession
    let service: MeetingBasicService
    private let audioSessionFixer = LarkAudioSession.shared.fixAudioSession([.activeOnAlarmEnd])

    private var shouldShowSecureAlert: Bool {
        return self.isFromSecretChat && !self.isE2EeMeeting
    }

    // MARK: - Init
    init?(session: MeetingSession, isFromSecretChat: Bool, isE2EeMeeting: Bool) {
        guard let startCallInfo = session.startCallParams, let service = session.service else {
            Logger.meeting.error("create CallOutViewModel failed: startCallInfo is nil")
            return nil
        }

        self.session = session
        self.service = service
        self.startCallInfo = startCallInfo
        self.isFromSecretChat = isFromSecretChat
        self.isE2EeMeeting = isE2EeMeeting
        self.player = RtcAudioPlayer(session: session)
        if startCallInfo.idType == .userId {
            let avatarSubject = ReplaySubject<AvatarInfo>.create(bufferSize: 1)
            let nameSubject = ReplaySubject<String>.create(bufferSize: 1)
            session.httpClient.participantService.participantInfo(pid: .init(id: startCallInfo.id, type: .larkUser), meetingId: session.meetingId) { ap in
                avatarSubject.onNext(ap.avatarInfo)
                nameSubject.onNext(ap.name)
            }
            self.avatarInfo = avatarSubject.asDriver(onErrorRecover: { _ in return .empty() })
            self.name = nameSubject.asDriver(onErrorJustReturn: "")
        } else {
            let calledId = startCallInfo.id
            let pstnSipUserInfo = Observable<ReservationPstnSipUserInfo?>.deferred { [weak service] in
                let subject = PublishSubject<ReservationPstnSipUserInfo?>()
                service?.httpClient.getResponse(GetReservationRequest(id: calledId)) { result in
                    switch result {
                    case .success(let r):
                        subject.onNext(r.pstnSipUserInfo)
                        subject.onCompleted()
                    case .failure(let error):
                        subject.onError(error)
                    }
                }
                return subject.asObservable()
            }
            self.avatarInfo = pstnSipUserInfo.map { userInfo -> AvatarInfo in
                if let user = userInfo {
                    return .remote(key: user.avatarKey, entityId: calledId)
                } else {
                    return .asset(AvatarResources.sip)
                }
            }.asDriver(onErrorRecover: { _ in return .empty() })
            self.name = pstnSipUserInfo.map { $0?.nickname ?? "" }
                .asDriver(onErrorJustReturn: "")
        }
        var meetSetting: MicCameraSetting = startCallInfo.isVoiceCall ? .onlyAudio : .default
        if !CameraSncWrapper.getCheckResult(by: .callOut) {
            meetSetting.isCameraEnabled = false
        }
        self.isVoiceCall = startCallInfo.isVoiceCall
        self.meetSetting = meetSetting
        self.session.localSetting = meetSetting
        self.isCameraOn = meetSetting.isCameraEnabled

        let dialingSubject = ReplaySubject<Bool>.create(bufferSize: 1)
        let dialingState = dialingSubject.asObservable()
        self.dialingSubject = dialingSubject
        self.dialingState = dialingState
        self.invitationReceived = dialingState
            .filter({ $0 })
            .take(1).share(replay: 1, scope: .forever)
        self.timeoutOfDialing = dialingState.take(1)
            .delay(.seconds(Self.dialingTimeoutSeconds), scheduler: MainScheduler.instance)
            .map({ _ in () }).asDriver(onErrorJustReturn: Void())
        self.noResponseOfDialing = invitationReceived
            .delay(.seconds(Self.noResponseSeconds), scheduler: MainScheduler.instance)
            .map({ _ in () }).asDriver(onErrorJustReturn: Void())
        session.addListener(self)
        session.push?.extraInfo.addObserver(self)
        if self.isVoiceCall {
            self.descriptionRelay.accept(I18n.View_A_VoiceCallStarting)
        } else {
            self.descriptionRelay.accept(I18n.View_V_DialingEllipsis)
        }
        invitationReceived.map({ _ in I18n.View_VM_AwaitingResponse })
            .bind(to: self.descriptionRelay).disposed(by: disposeBag)

        setupAudioOutput()
    }

    deinit {
        player?.stop(.dialing(ringtone: session.setting?.customRingtone))
    }

    private func firePlayingSound() {
        Logger.audio.info("firePlayingSound: isCallKitAudioSessionReady = \(isCallKitAudioSessionReady), isSoundPlaying = \(isSoundPlaying)")
        if isCallKitAudioSessionReady && !isSoundPlaying {
            isSoundPlaying = true
            player?.play(.dialing(ringtone: session.setting?.customRingtone), playCount: -1)
        }
    }

    private func setupAudioOutput() {
        session.callCoordinator.waitAudioSessionActivated { [weak self] result in
            if let self = self, result.isSuccess {
                self.isCallKitAudioSessionReady = true
                self.firePlayingSound()
            }
        }
    }

    // MARK: - public method
    func onCancelDialing() {
        shouldShowAudioToast = false
    }

    // MARK: - private method
    var isCallKitEnabled: Bool {
        session.isCallKit
    }

    func cancelCalling() {
        let cancelTime = CACurrentMediaTime()
        self.cancelTime = cancelTime
        self.session.leave()

        let isVoiceCall = self.startCallInfo.isVoiceCall
        VCTracker.post(name: .vc_call_cancel, params: ["only_voice": isVoiceCall ? 1 : nil])
        if let invitationReceivedTime = self.invitationReceivedTime {
            let interval = Int64((cancelTime - invitationReceivedTime) * 1000)
            VCTracker.post(name: .vc_call_cancelduration, params: ["call_duration": interval, "only_voice": isVoiceCall ? 1 : nil])
        }
    }

    func callingTimeout() {
        session.reportCallingTimeout()
    }

    private var isRingingReceivedDataProcessed: Bool = false
    private var extraInfo: VideoChatExtraInfo.RingingReceivedData?
    private var info: VideoChatInfo?
}

extension CallOutViewModel: MeetingSessionListener, VideoChatExtraInfoPushObserver {
    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        if state == .calling, let info = event.videoChatInfo {
            self.callingTime = CACurrentMediaTime()
            self.info = info
            handleRingingReceivedData()
            var request = ParticipantChangeSettingsRequest(session: session)
            request.participantSettings.isMicrophoneMuted = !meetSetting.isMicrophoneEnabled
            request.participantSettings.isCameraMuted = !meetSetting.isCameraEnabled
            session.httpClient.send(request)
        }
    }

    func didReceiveExtraInfo(_ extraInfo: VideoChatExtraInfo) {
        if extraInfo.type == .ringingReceived, let data = extraInfo.ringingReceivedData {
            self.extraInfo = data
            handleRingingReceivedData()
        }
    }

    private func handleRingingReceivedData() {
        guard !isRingingReceivedDataProcessed, let info = info, let extra = extraInfo else {
            return
        }

        Logger.meeting.info("[\(info.id)]: handleRingingReceivedData, extra = \(extra)")
        self.isRingingReceivedDataProcessed = true
        let isInvitationReceived = extra.meetingID == info.id && extra.participant.user.id != info.host.id
        if isInvitationReceived {
            let receiveTime = CACurrentMediaTime()
            self.invitationReceivedTime = receiveTime
            if let callingTime = self.callingTime {
                /// 拨号成功
                VCTracker.post(name: .vc_call_dialingduration, params: ["call_duration": Int64((receiveTime - callingTime) * 1000)])
            }
        }
        dialingSubject.onNext(isInvitationReceived)
    }
}

extension CallOutViewModel: PreviewCameraDelegate {
    func didFailedToStartVideoCapture(error: Error) {
        self.meetSetting.isCameraEnabled = false
    }
}
