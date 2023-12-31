//
//  InMeetAudioModeManager.swift
//  ByteView
//
//  Created by lutingting on 2023/4/3.
//

import Foundation
import ByteViewMeeting
import ByteViewSetting
import ByteViewNetwork

protocol InMeetAudioModeListener: AnyObject {
    func beginPstnCalling()
    func closePstnCalling()
    func didChangeMicState(_ state: MicViewState)
}

extension InMeetAudioModeListener {
    func beginPstnCalling() {}
    func closePstnCalling() {}
    func didChangeMicState(_ state: MicViewState) {}
}

/// 优先级：callme = 会议室音频 = 无音频 = 系统音频(禁用音频>系统来电>无麦克风权限>有麦克风权限)
enum MicViewState: Equatable {
    case on
    case off
    case denied
    case sysCalling
    case forbidden
    case disconnect
    case room(BizState)
    case callMe(BizState, Bool)

    enum BizState {
        case on
        case off
        case denied

        var toMicIconState: MicIconState {
            switch self {
            case .denied:
                return .denied
            case .off:
                return .off()
            case .on:
                return .on()
            }
        }

        var roomState: MicIconState {
            switch self {
            case .denied: return .denied
            case .on: return .on(.room(.normal))
            case .off: return .off(.room(.normal))
            }
        }

        var roomTintColor: UIColor {
            switch self {
            case .on: return .ud.N700
            case .off: return .ud.functionDangerContentDefault
            case .denied: return .ud.iconDisabled
            }
        }
    }

    var isSystemAudio: Bool {
        switch self {
        case .disconnect, .room, .callMe:
            return false
        default:
            return true
        }
    }

    var isCallMeRinging: Bool {
        switch self {
        case .callMe(_, true):
            return true
        default:
            return false
        }
    }

    var isHiddenMicAlertIcon: Bool {
        !(self == .denied || self == .callMe(.denied, false) || self == .room(.denied))
    }

    var showVolume: Bool {
        switch self {
        case .on: return true
        case .room(let bindState): return bindState == .on
        case .callMe(let state, let b): return state == .on && !b
        default: return false
        }
    }
}

extension Participant {
    fileprivate var bizAudioMode: BizAudioMode {
        if let binder = binder, binder.type == .room {
            return .room
        }
        if settings.targetToJoinTogether?.type == .room {
            return .room
        }
        switch settings.audioMode {
        case .internet: return .internet
        case .noConnect: return .noConnect
        case .pstn: return .pstn
        case .unknown: return .unknown
        }
    }

    var bindRtcUid: RtcUID? {
        var uId: RtcUID? = rtcUid
        switch bizAudioMode {
        case .unknown, .internet, .noConnect: break
        case .pstn:
            if callMeInfo.status == .onTheCall {
                uId = callMeInfo.rtcUID
            }
        case .room:
            uId = binder?.rtcUid
            if uId == nil {
                Logger.participant.warn("cant find room binder")
            }
        }
        return uId
    }
}

enum BizAudioMode: Int, Hashable {
    case unknown
    case internet
    case pstn
    case room
    case noConnect

    var audioMode: ParticipantSettings.AudioMode {
        switch self {
        case.unknown:
            return .unknown
        case .internet:
            return .internet
        case .pstn:
            return .pstn
        case .room, .noConnect:
            return .noConnect
        }
    }

    var canShowMic: Bool {
        switch self {
        case .internet, .pstn, .room: return true
        default: return false
        }
    }
}

final class InMeetAudioModeManager {
    private let logger = Logger.audioMode

    private let session: MeetingSession
    private let microphone: InMeetMicrophoneManager

    private let listeners = Listeners<InMeetAudioModeListener>()

    var currentMicState: MicViewState?

    private(set) var isPadMicSpeakerDisabled: Bool {
        didSet {
            microphone.isPadMicSpeakerDisabled = isPadMicSpeakerDisabled
        }
    }

    private var isMuted: Bool { microphone.isMuted }

    private(set) var bizMode: BizAudioMode
    var isInCallMe: Bool { bizMode == .pstn }
    @RwAtomic
    private(set) var isPstnCalling: Bool = false
    @RwAtomic
    private(set) var isJoinPstnCalling: Bool = false

    private let service: MeetingBasicService
    private var httpClient: HttpClient { service.httpClient }
    private var setting: MeetingSettingManager { service.setting }
    private let participant: InMeetParticipantManager

    init(session: MeetingSession, service: MeetingBasicService, microphone: InMeetMicrophoneManager, myself: Participant, participant: InMeetParticipantManager) {
        self.session = session
        self.service = service
        self.microphone = microphone
        self.bizMode = participant.myself?.bizAudioMode ?? .unknown
        self.isPadMicSpeakerDisabled = service.setting.isMicSpeakerDisabled && bizMode == .internet
        self.participant = participant

        let joinAudioMode = session.joinMeetingParams?.audioMode
        isJoinPstnCalling = (joinAudioMode == .pstn)  // pstn入会样式异化
        isPstnCalling = isJoinPstnCalling
        logger.info("InMeetAudioModeManager joinmode:\(joinAudioMode), isJoinPstnCalling:\(isJoinPstnCalling)")
        currentMicState = getMicCurrentState()
        session.addMyselfListener(self, fireImmediately: false)
        microphone.addListener(self)
        SystemCallingManager.shared.addListener(self)
        setting.addListener(self, for: .isMicSpeakerDisabled)
        if let audioOutput = session.audioDevice?.output {
            addListener(audioOutput)
        }
        microphone.isPadMicSpeakerDisabled = isPadMicSpeakerDisabled
        participant.addListener(self, fireImmediately: false)
    }

    func addListener(_ listener: InMeetAudioModeListener) {
        listeners.addListener(listener)

        if let state = currentMicState {
            Util.runInMainThread {
                listener.didChangeMicState(state)
            }
        }
    }

    func removeListener(_ listener: InMeetAudioModeListener) {
        listeners.removeListener(listener)
    }

    private func handleBizMode(_ myself: Participant, oldMode: BizAudioMode) {
        guard bizMode != .unknown, bizMode != oldMode, !UltrawaveManager.shared.isRecvingUltrawave else {
            return
        }

        session.audioDevice?.output.setNoConnect(bizMode != .internet, shouldRecorverSpeakerOn: bizMode != .pstn)
        switch bizMode {
        case .internet:
            Toast.show(I18n.View_MV_UsingDeviceAudioNow)
            microphone.startAudioCapture(scene: .changeToSystemAudio)
        case .pstn:
            Toast.show(I18n.View_MV_UsinPhoneAudio)
            microphone.stopAudioCapture()
        case .noConnect:
            // rtc 会提示：“音频已断开”    按钮变为「连接音频」按钮,去掉麦克风和扬声器    视频流处mic变为不连接音频的图标
            if !isJoinPstnCalling {
                // 入会toast不在这里，直接弹View_MV_AudioDisconnected_Note
                Toast.show(I18n.View_MV_AudioDisconnected_Note)
            }
            microphone.stopAudioCapture()
        case .room:
            microphone.stopAudioCapture()
        default:
            break
        }
        updateStateIfNeeded()
    }

    func changeBizAudioMode(bizMode: BizAudioMode, isCancelPstn: Bool = false) {
        let audioMode = bizMode.audioMode
        logger.info("changemode request begin \(audioMode), isCancelPstn \(isCancelPstn)")
        var request = ParticipantChangeSettingsRequest(session: session)
        request.participantSettings.audioMode = audioMode
        request.changeAudioReason = isCancelPstn ? .cancelCallMe : .changeAudio
        httpClient.send(request) { result in
            switch result {
            case .success:
                Logger.callme.info("changemode request success")
            case .failure(let error):
                Logger.callme.info("changemode request error \(error)")
            }
        }
    }

    // MARK: - callMe
    private func handleCallMe(callMeInfo: Participant.CallMeInfo, oldMode: BizAudioMode) {
        // pstn拨打失败(为什么要判断isPstnCalling，因为切换过程中，如果不是切换到pstn，callme状态不会刷新，也就是没有拨打电话，之前拨打电话的错误信息也会带过来)
        if callMeInfo.status == .idle, oldMode != .pstn, isPstnCalling || isJoinPstnCalling {
            closePstnCalling()
            if let reason = callMeInfo.callmeIdleReason.reasonString {
                Toast.show(reason)
            }
        } else if oldMode != bizMode, bizMode == .pstn {
            // rtc toolbar样式 rtc 取消tips  Toast提示“正在使用电话音频” Mute按钮文案变为“电话” 取消toolbar扬声器
            closePstnCalling()
        }
    }

    func beginPstnCalling() {
        isPstnCalling = true
        listeners.forEach { $0.beginPstnCalling() }
        changeBizAudioMode(bizMode: .pstn)
    }

    func cancelPstnCall() {
        changeBizAudioMode(bizMode: bizMode, isCancelPstn: true)
    }

    private func closePstnCalling() {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if self.isJoinPstnCalling {
                self.isJoinPstnCalling = false
                self.updateStateIfNeeded()
            }
            self.isPstnCalling = false
            self.listeners.forEach { $0.closePstnCalling() }
        }
    }


    // MARK: - micViewState
    private func updateStateIfNeeded() {
        let state = getMicCurrentState()
        logger.info("InMeetAudioModeManager updateStateIfNeeded to:\(state) from: \(currentMicState)")
        isPadMicSpeakerDisabled = state == .forbidden
        if let state = state, currentMicState != state {
            self.currentMicState = state
            Util.runInMainThread { [weak self] in
                self?.listeners.forEach { $0.didChangeMicState(state) }
            }
        }
    }

    /// 统一处理麦克风点击事件拦截
    /// return true 表示处理过了，false表示无需处理
    func shouldHandleMicClickEvent() -> Bool {
        if currentMicState == .forbidden {
            return true
        } else if currentMicState == .sysCalling {
            Toast.showOnVCScene(I18n.View_MV_AnswerCallNoMic)
            return true
        } else if currentMicState == .off && !MicrophoneSncWrapper.isCheckSuccess {
            Toast.show(I18n.View_VM_MicNotWorking)
            return true
        }

        return false
    }

    private func getMicCurrentState() -> MicViewState? {
        var state: MicViewState?
        switch bizMode {
        case .internet:
            if setting.isMicSpeakerDisabled {
                state = .forbidden
            } else if setting.isSystemPhoneCalling {
                state = .sysCalling
            } else if Privacy.audioDenied {
                state = .denied
            } else {
                state = isMuted ? .off : .on
            }
        case .noConnect:
            if isJoinPstnCalling {
                state = .callMe(Privacy.audioDenied ? .denied : isMuted ? .off : .on, true)
            } else {
                state = .disconnect
            }
        case .pstn:
            state = .callMe(Privacy.audioDenied ? .denied : isMuted ? .off : .on, false)
        case .room:
            state = .room(.denied)
            if let binder = participant.myself?.binder, !binder.settings.microphoneStatus.isUnavailable {
                let type: MicViewState.BizState = binder.settings.isMicrophoneMuted ? .off : .on
                state = .room(type)
            }
        default:
            break
        }
        return state
    }
}

extension InMeetAudioModeManager: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        let oldMode = bizMode
        bizMode = myself.bizAudioMode
        handleBizMode(myself, oldMode: oldMode)
        handleCallMe(callMeInfo: myself.callMeInfo, oldMode: oldMode)
    }
}

extension InMeetAudioModeManager: InMeetParticipantListener {
    func didChangeMyselfBinder(_ participant: Participant?, oldValue: Participant?) {
        updateStateIfNeeded()
    }
}

extension InMeetAudioModeManager: InMeetMicrophoneListener {
    func didChangeMicrophoneMuted(_ microphone: InMeetMicrophoneManager) {
        updateStateIfNeeded()
    }
}

extension InMeetAudioModeManager: SystemCallingDelegate {
    func systemCallingDidChange(state: MicIconState, sessionID: String) {
        guard sessionID == session.sessionId else { return }
        updateStateIfNeeded()
    }
}

extension InMeetAudioModeManager: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isMicSpeakerDisabled {
            updateStateIfNeeded()
        }
    }
}

extension MeetingSession {

    var audioMode: ParticipantSettings.AudioMode {
        var mode: ParticipantSettings.AudioMode = .internet
        if state == .prelobby {
            mode = lobbyInfo?.preLobbyParticipant?.participantSettings.audioMode ?? .internet
        } else if state == .lobby {
            mode = lobbyInfo?.lobbyParticipant?.participantSettings.audioMode ?? .internet
        } else if state == .onTheCall {
            mode = myself?.settings.audioMode ?? .internet
        }
        return mode
    }
}


private extension Participant.CallMeIdleReason {
    var reasonString: String? {
        switch self {
        case .kickout, .leave, .switchaudio, .cancel, .unknown:
            return nil
        case .ringTimeout:
            return I18n.View_MV_NoAnswerTheMoment
        case .refuse, .busy:
            return I18n.View_MV_UserBusy
        case .callException:
            return I18n.View_MV_NoAnswerTheMoment  //I18n.View_MV_NumberDialedUnavailable 服务端区分不出来
        case .phoneUnbind:
            return I18n.View_MV_CallFail_PopUp
        case .quotaUsedUp:
            return I18n.View_MV_PhoneTimeReachedLimit
        case .adminQuotaUsedUp:
            return I18n.View_MV_NotEnoughBalanceContact_PopExplain
        case .disableOutgoing:
            return I18n.View_G_NoCallMeMethod
        default:
            return I18n.View_MV_CallFail_PopUp
        }
    }
}
