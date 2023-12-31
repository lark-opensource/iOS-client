//
//  InMeetMicrophoneManager.swift
//  ByteView
//
//  Created by kiri on 2022/8/17.
//

import Foundation
import RxSwift
import ByteViewTracker
import ByteViewMeeting
import ByteViewNetwork
import AVFoundation
import ByteViewUI
import ByteViewSetting
import ByteViewRtcBridge
import LarkMedia

protocol InMeetMicrophoneListener: AnyObject {
    func didChangeMicrophoneMuted(_ microphone: InMeetMicrophoneManager)
}

/// 只管理麦克风的mute/unmute
final class InMeetMicrophoneManager {
    private let logger = Logger.audio
    private let rtc: RtcAudio
    private let service: MeetingBasicService
    private var setting: MeetingSettingManager { service.setting }
    private let audioDevice: AudioDeviceManager
    private let meetingId: String
    private let participant: InMeetParticipantManager

    /// 会中静音提示
    private var hasShownMuteAlert = false

    /// 麦克风是否mute，取自ParticipantSettings
    @RwAtomic
    private var isUserMuted: Bool
    @RwAtomic
    private var isAvailable: Bool
    var isMuted: Bool { isUserMuted || !isAvailable }

    @RwAtomic
    private var isReleased: Bool = false

    var isPadMicSpeakerDisabled: Bool = false {
        didSet {
            guard isPadMicSpeakerDisabled != oldValue else { return }
            Util.runInMainThread {
                self.setPadMicSpeakeDisabled(self.isPadMicSpeakerDisabled)
            }
        }
    }

    private let listeners = Listeners<InMeetMicrophoneListener>()
    private let bag = DisposeBag()

    private let isCallKit: Bool

    init(session: ByteViewMeeting.MeetingSession, isMuted: Bool, isAvailable: Bool, service: MeetingBasicService, audioDevice: AudioDeviceManager, participant: InMeetParticipantManager) {
        self.meetingId = session.meetingId
        self.isCallKit = session.isCallKit
        self.service = service
        self.audioDevice = audioDevice
        self.participant = participant
        self.rtc = RtcAudio(engine: service.rtc)
        self.isUserMuted = isMuted
        self.isAvailable = isAvailable
        /// 初始化配置，上次断线时可能记录了一个不正确的设置（rejoin请求无settings选项）
//        self.updateMicrophoneStatus(isInterrupted: false)
        Privacy.micAccess
            .map { $0.isAuthorized }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.updateMicrophoneStatus(isInterrupted: false)
                self.listeners.forEach { $0.didChangeMicrophoneMuted(self) }
                self.service.postMeetingChanges { $0.isMicrophoneMuted = self.isMuted }
            }).disposed(by: bag)
        setting.updateSettings {
            $0.isInMeetMicrophoneMuted = self.isMuted
        }
        if !isCallKit {
            // 非 CallKit 下走 AVAudioApplication 监听
            // CallKit 下走 CXSetMutedCall 监听
            logger.info("will add microphone mute observer")
            audioDevice.addMicrophoneObserver(self)
        }
        service.postMeetingChanges { $0.isMicrophoneMuted = self.isMuted }
    }

    func release() {
        isReleased = true
        dismissHostAskingUnmuteAlert()
        self.handsUpAlert?.dismiss()
    }

    func addListener(_ listener: InMeetMicrophoneListener) {
        self.listeners.addListener(listener)
    }

    func removeLisenter(_ listener: InMeetMicrophoneListener) {
        self.listeners.removeListener(listener)
    }

    func onJoinChannel(shouldCapture: Bool, shouldMute: Bool) {
        logger.info("onJoinChannel(mic): setMicMuted \(shouldMute), isCapturing: \(shouldCapture), isAudioDenied: \(Privacy.audioDenied)")
        // 入会时先设置麦克风状态再开启采集
        // 1.隐私安全性更能保障
        // 2.iOS 17硬件静音会有系统提示，在采集前调用硬件静音API不会有提示
        setMutedInternal(shouldMute)
        rtc.muteInput(shouldMute)
        let isDenied = Privacy.audioDenied
        if !isDenied && shouldCapture {
            startAudioCapture(scene: .joinChannel)
        } else {
            stopAudioCapture()
        }
    }

    func startAudioCapture(scene: RtcAudioScene) {
        rtc.startAudioCapture(scene: scene) { [weak self] result in
            if !result.isSuccess {
                self?.muteMyself(true, source: .token_check_failure, completion: nil)
            }
        }
    }

    func stopAudioCapture() {
        rtc.stopAudioCapture()
    }

    func setAudioUnitMuted(_ isMuted: Bool) {
        rtc.setAudioUnitMuted(isMuted)
    }

    /// 从Rust同步
    /// - returns: isRtcChanged
    private func updateRustMuted(_ settings: ParticipantSettings) -> Bool {
        if isReleased { return false }
        let isMuted = settings.isMicrophoneMuted
        let isAvailable = !settings.microphoneStatus.isUnavailable
        logger.info("updateRustMuted: isMuted = \(isMuted), isAvailable = \(isAvailable)")
        self.setMutedInternal(isMuted)
        self.setAvailable(isAvailable)
        if rtc.isInputMuted != isMuted {
            // 本地与服务器不同步的情况存在两种：1. 更新麦克风请求失败 2. 主持人关闭参会者麦克风
            // 无论哪种情况，直接使用服务端的值(以前是直接关闭，举手发言需求时改为尊重服务端)
            rtc.muteInput(isMuted)
            UserActionTracks.trackMicrophonePush(isOn: !isMuted)
            logger.info("updateParticipantSettings: isMicrophoneMuted = \(isMuted)")
            return true
        }
        return false
    }

    func fetchRtcAudioMuted(completion: @escaping (Bool) -> Void) {
        if isReleased { return }
        rtc.fetchLocalAudioMuted(completion: completion)
    }

    /// 静音或取消静音麦克风
    /// 由于取消静音是个异步的网络请求，因此接口的成功与否由回调 closure 来给出
    /// 同时对每一个网络请求创建一个唯一的标识 requestID
    /// 该方法会在需要发起网络请求前和请求失败时使用 requestID 来作关键链路埋点
    /// 如果没有发起网络请求，则该方法不创建 requestID，埋点里不包含 requestID 参数
    func muteMyself(_ isMuted: Bool, source: MicrophoneActionSource, requestByHost: Bool = false, showToastOnSuccess: Bool = true, audioMode: ParticipantSettings.AudioMode? = nil,
                    file: String = #fileID, function: String = #function, line: Int = #line,
                    completion: ((Result<Void, Error>) -> Void)?) {
        guard !isReleased else {
            completion?(.success(Void()))
            return
        }

        if source.mayHaveAudioBinder, let binder = participant.myself?.binder, binder.type == .room {
            let binderMuted = binder.settings.isMicrophoneMutedOrUnavailable
            if !ReachabilityUtil.isConnected {
                Toast.show(binderMuted ? I18n.View_G_MicCantOn_Toast : I18n.View_G_MicCantOff_Toast)
                logger.error("sync room failed, show disconnected toast")
                completion?(.failure(VCError.badNetwork))
                return
            }
            setting.syncRoomManage(roomId: binder.user.id, mute: !binderMuted, completion: completion)
            return
        }

        if isPadMicSpeakerDisabled, !isMuted {
            Toast.show(I18n.View_G_NoMicCantStart)
            completion?(.failure(MicrophoneActionError.padMicDisabled))
            return
        }

        // 系统电话仅在系统音频且pad中没有开启禁用麦克风选项时不可解除麦克风，其他情况均可解除麦克风。
        if source != .phone_call_status && !isMuted && setting.isSystemPhoneCalling && setting.audioMode == .internet && !isPadMicSpeakerDisabled {
            Toast.showOnVCScene(I18n.View_MV_AnswerCallNoMic)
            completion?(.failure(MicrophoneActionError.systemPhoneCalling))
            return
        }

        if !MicrophoneSncWrapper.isCheckSuccess, !isMuted {
            Toast.show(I18n.View_VM_MicNotWorking)
            completion?(.failure(MicrophoneActionError.micSncToken))
            return
        }

        if !isMuted, setting.isWebinarAttendee,
           source != .webinar_attendee_unmute {
            Logger.webinarRole.error("unexpect unmute action from \(source)")
            assertionFailure()
            completion?(.failure(MicrophoneActionError.webinarAttendeeNoPermission))
            return
        }

        logger.info("Change microphone status, muted: \(isMuted), source: \(source), rtcMode: \(setting.rtcMode), showToastOnSuccess: \(showToastOnSuccess), allowsUnmute: \(setting.allowPartiUnmute), file: \(URL(fileURLWithPath: file).lastPathComponent), func: \(function), line: \(line)")

        Privacy.requestMicrophoneAccessAlert(completion: { [weak self] result in
            guard result.isSuccess else {
                self?.logger.info("No microphone permission")
                completion?(.failure(VCError.unknown))
                return
            }
            self?.changeMyself(to: isMuted,
                               source: source,
                               requestByHost: requestByHost,
                               showToastOnSuccess: showToastOnSuccess,
                               audioMode: audioMode,
                               completion: completion)
        })
    }

    private func changeMyself(to mute: Bool,
                              source: MicrophoneActionSource,
                              requestByHost: Bool,
                              showToastOnSuccess: Bool,
                              audioMode: ParticipantSettings.AudioMode? = nil,
                              completion: ((Result<Void, Error>) -> Void)?) {
        guard !isReleased else {
            completion?(.success(Void()))
            return
        }

        let allowUnmute = setting.hasCohostAuthority || setting.allowPartiUnmute
        let isHandsUp = setting.micHandsStatus == .putUp
        let rtcMode = setting.rtcMode
        if !requestByHost && !mute && (!allowUnmute || isHandsUp) {
            // 如果不能直接操作麦克风且当前麦克风是关闭的，则需要走举手流程
            // 当前已在举手中，走手放下流程，否则走举手流程
            UserActionTracks.trackChangeMicAction(isOn: !mute, source: source, requestID: nil, result: .hands_up)
            ParticipantTracks.trackPopup("unable_to_unmute_pls_raise_hand", params: ["audience_mode": rtcMode == .audience ? 1 : 0])
            ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .requestUnmute)
            changeHandsStatus(isHandsUp ? .putDown : .putUp)
            completion?(.failure(MicrophoneActionError.handsUp))
        } else {
            // 如果在回声提示的过程中再次调用这个方法尝试解除静音，就自动关闭回声提示的弹框
            // 这种情况在正常路径中不会存在，用户必须先操作回声弹框才能再操作麦克风
            // 但是引入长按空格取消静音需求后，用户可以在弹框期间再按空格取消静音，此时我们通过代码直接关闭该 alert
            ByteViewDialogManager.shared.dismiss(ids: [.unmuteAlert])
            if !mute, audioDevice.output.isMuted, !self.hasShownMuteAlert, !requestByHost {
                UserActionTracks.trackChangeMicAction(isOn: !mute, source: source, requestID: nil, result: .echo_detected)
                self.hasShownMuteAlert = true
                showEchoDetectionAlert(requestByHost: requestByHost)
                completion?(.failure(MicrophoneActionError.echoDetected))
            } else {
                // 暂时只对 unmute 请求记录 requestID，因为 mute 是本地直接改状态，属于确定事件，无需对后续请求结果追踪
                let requestID: String? = mute ? nil : UUID().uuidString
                muteOrUnmteMircrophone(mute, requestByHost: requestByHost, showToastOnSuccess: showToastOnSuccess, audioMode: audioMode) { result in
                    switch result {
                    case .success:
                        completion?(.success(()))
                    case .failure(let error):
                        completion?(.failure(error))
                        UserActionTracks.trackUnmuteMicRequestFailure(requestID: requestID, error: error)
                    }
                }
                UserActionTracks.trackChangeMicAction(isOn: !mute, source: source, requestID: requestID, result: .request_sent)
            }
        }
    }

    func muteAll(_ mute: Bool) {
        if isReleased { return }
        let isMeetingSupport = setting.forceMuteMicrophone
        // 取消全员静音，或者会中不支持强制静音时，不弹窗直接调请求
        if !mute || !isMeetingSupport {
            requestMuteAll(mute, allowPartiUnmute: false)
        } else {
            showMuteAllAlert(mute, allowPartiUnmute: setting.allowPartiUnmute)
        }
    }

    // 点击手放下
    func putDownHands() {
        guard !isReleased else { return }
        let allowParticipantsUnmute = setting.allowPartiUnmute
        let handsUpState = setting.micHandsStatus
        logger.info("allowPartiUnmute is \(allowParticipantsUnmute), self handsup state is \(handsUpState) when click hands put down")
        if !allowParticipantsUnmute && handsUpState == .putUp {
            setting.updateParticipantSettings {
                $0.earlyPush = false
                $0.participantSettings.micHandsStatus = .putDown
            }
        }
    }

    func muteByHost() {
        dismissHostAskingUnmuteAlert()
        if setting.audioMode != .noConnect, !isPadMicSpeakerDisabled {
            Toast.showOnVCScene(I18n.View_M_HostMutedYourMic)
        }
    }

    func unmuteByHost() {
        assertMain()
        if isUserMuted {
            showHostAskingUnmuteAlert()
        } else {
            logger.warn("Receiving UNMUTE_MICROPHONE_CONFIRMED, while microphone is on!")
        }
    }

    func handleHostMuteAll(_ isMuted: Bool, operationUser: ByteviewUser) {
        assertMain()
        logger.info("Unmute all by host, isMuted value: \(isMuted), operationUser: \(operationUser), self id: \(service.account)")
        if isMuted {
            if operationUser != service.account {
                Toast.showOnVCScene(I18n.View_M_HostMutedAll)
            }
            dismissHostAskingUnmuteAlert()
        } else if operationUser != service.account, self.isUserMuted {
            showHostAskingUnmuteAlert()
        }
    }

    func handleAllowPartiUnmute(_ allowPartiUnmute: Bool) {
        // 非主持人、非联席主持人和非观众模式用户收到强制静音设置更改后 对于举手中的用户需要弹toast
        // 因为此时服务端实际给其他用户推送了该举手用户的put_down事件，所以还需要触发rust更新一下当前用户的信息
        guard !isReleased, allowPartiUnmute, !setting.hasCohostAuthority, setting.micHandsStatus == .putUp else {
            logger.debug("your hands status is not put up when allow participant unmute setting is ture")
            return
        }
        if setting.rtcMode != .audience {
            logger.debug("your hannds status is put up when allow participant unmute setting is ture")
            Toast.showOnVCScene(I18n.View_M_YouCanNowUnmuteYourself)
            // 触发信息的更新
            service.httpClient.send(TriggerSelfInfoRequest()) { [weak self] result in
                switch result {
                case .success:
                    self?.logger.debug("triggle push self info success")
                case .failure(let error):
                    self?.logger.debug("triggle push self info error:\(error)")
                }
            }
        }

        if !allowPartiUnmute {
            // 之前会议设置是允许自行打开麦克风，变成不允许后弹框消失
            dismissHostAskingUnmuteAlert()
        }
    }

    private weak var hostAskingUnmuteAlert: ByteViewDialog?
    private let alertNotificationId = UUID().uuidString
    private func showHostAskingUnmuteAlert() {
        guard !isReleased, hostAskingUnmuteAlert == nil else {
            logger.warn("showHostAskingUnmuteAlert ignored, alert exists = \(hostAskingUnmuteAlert != nil)")
            return
        }

        // 主持人请求开启你的麦克风
        let clientMode = setting.rtcMode
        let isAudioOutputMuted = audioDevice.output.isMuted
        let audioMode = setting.audioMode
        let alertTitle = audioMode == .noConnect ? I18n.View_M_HostMicRequestStandard : isAudioOutputMuted ? I18n.View_MV_HostAskTurnOnEcho : I18n.View_M_HostMicRequestStandard
        let message: String? = audioMode == .noConnect ? I18n.View_G_MicOnMayEcho : nil
        let colorTheme: ByteViewDialogConfig.ColorTheme? = audioMode == .noConnect ? .defaultTheme : isAudioOutputMuted ? .redLight : nil
        if setting.targetToJoinTogether != nil {
            ByteViewDialog.Builder()
                .title(I18n.View_M_HostMicRequestStandard)
                .message(I18n.View_G_RoomAudioCanSpeak)
                .rightTitle(I18n.View_G_OkButton)
                .show()
        } else {
            ByteViewDialog.Builder()
                .id(.hostRequestMicrophone)
                .colorTheme(colorTheme)
                .title(alertTitle)
                .message(message)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ [weak self] _ in
                    guard self != nil else { return }
                    HandsUpTracksV2.trackRejectInvite(isAudience: clientMode == .audience, isMicrophone: true)
                    VCTracker.post(name: .vc_meeting_lark_hint,
                                   params: [.action_name: "cancel",
                                            .from_source: "invite_open_mic",
                                            "audience_mode": clientMode == .audience ? 1 : 0])
                    if isAudioOutputMuted {
                        ThemeAlertTrackerV2.trackClickPopupAlert(content: .hostAskUnmute, action: "cancel")
                    }
                })
                .rightTitle(I18n.View_G_ConfirmButton)
                .rightHandler({ [weak self] _ in
                    guard let self = self else { return }
                    VCTracker.post(name: .vc_meeting_lark_hint,
                                   params: [.action_name: "confirm",
                                            .from_source: "invite_open_mic",
                                            "audience_mode": clientMode == .audience ? 1 : 0])
                    if isAudioOutputMuted {
                        ThemeAlertTrackerV2.trackClickPopupAlert(content: .hostAskUnmute, action: "confirm")
                    }
                    self.muteMyself(false, source: .host_request, requestByHost: true, audioMode: audioMode == .noConnect ? .internet : nil, completion: nil)
                    ByteViewDialogManager.shared.dismiss(ids: [.micHandsUp, .micHandsDown])
                })
                .show { [weak self] alert in
                    ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .hostAskUnmute)
                    if let self = self {
                        self.hostAskingUnmuteAlert = alert
                    } else {
                        alert.dismiss()
                    }
                }
        }
        if UIApplication.shared.applicationState != .active {
            let body = alertTitle
            UNUserNotificationCenter.current().addLocalNotification(withIdentifier: alertNotificationId, body: body)
        }
    }

    private func dismissHostAskingUnmuteAlert() {
        hostAskingUnmuteAlert?.dismiss()
        hostAskingUnmuteAlert = nil
    }

    private var lastRequestTime = CFAbsoluteTimeGetCurrent()
    private var isRequestingUnmute = false
    private var isRequesting = false
    private var lastRequestMuted: Bool?
    @RwAtomic private var lastUnmuteRequestId: UUID?
    private func muteOrUnmteMircrophone(_ muted: Bool, requestByHost: Bool, showToastOnSuccess: Bool = true, audioMode: ParticipantSettings.AudioMode? = nil, completion: ((Result<Void, Error>) -> Void)? = nil) {
        if isReleased {
            completion?(.failure(VCError.unknown))
            return
        }

        let actionCompletion: ((Result<Void, Error>) -> Void)?
        lastRequestMuted = muted
        if muted {
            isRequestingUnmute = false
            if showToastOnSuccess && !isPadMicSpeakerDisabled {
                Toast.showOnVCScene(I18n.View_VM_MicOff)
            }
            actionCompletion = nil
        } else {
            let toastConfig = setting.microphoneCameraToastConfig
            if toastConfig.needCheckNetworkDisconnected,
               !ReachabilityUtil.isConnected {
                Toast.showOnVCScene(BundleI18n.ByteView.View_G_MicFailCheckNet_Toast)
                Logger.ui.error("unmutedMyMicrophone failed, show disconnected toast")
                completion?(.failure(VCError.unknown))
                return
            }
            guard !isRequestingUnmute else {
                Logger.ui.error("unmutedMyMicrophone is requesting, skip")
                completion?(.failure(VCError.unknown))
                return
            }
            let reqId = UUID()
            isRequestingUnmute = true
            lastUnmuteRequestId = reqId
            if toastConfig.needShowLoadingToast {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(toastConfig.showLoadingToastMS)) { [weak self] in
                    guard let self = self else { return }
                    if self.lastUnmuteRequestId == reqId, self.isRequestingUnmute {
                        Toast.showOnVCScene(BundleI18n.ByteView.View_G_UnstableNetReconnect_Toast, duration: Double(toastConfig.loadingToastDurationMS) / 1000)
                    }
                }
            }
            actionCompletion = { [weak self] result in
                guard let self = self else { return }
                if self.isRequesting {
                    Toast.showOnVCScene(BundleI18n.ByteView.View_G_UnstableNetReconnect_Toast, duration: Double(toastConfig.loadingToastDurationMS) / 1000)
                }
                self.isRequestingUnmute = false
                switch result {
                case .success:
                    if self.lastRequestMuted == muted {
                        completion?(.success(()))
                        if showToastOnSuccess {
                            Toast.showOnVCScene(I18n.View_VM_MicOn)
                        }
                    }
                case .failure(let error):
                    let vcError = error.toVCError()
                    if vcError == .shouldHandsUp {
                        self.changeHandsStatus(.putUp)
                    } else if vcError == .badNetwork || vcError == .badNetworkV2 {
                        Toast.showOnVCScene(I18n.View_G_MicFailCheckNet_Toast)
                    }
                    completion?(.failure(error))
                }
            }
        }
        // 如果是mute操作，端上针对接口的调用默认成功，由Rust无限重试，开麦需要等Rust请求的response
        if muted {
            completion?(.success(()))
            assert(actionCompletion == nil)
            Logger.ui.info("muteMyMicrophone successfuly by default, because muted = 1")
        }
        setting.updateParticipantSettings({
            $0.requestedByHost = requestByHost
            $0.participantSettings.isMicrophoneMuted = muted
            if let audioMode = audioMode {
                $0.participantSettings.audioMode = audioMode
                $0.changeAudioReason = .changeAudio
            }
        }, completion: actionCompletion)
    }

    private func requestMuteAll(_ isMuted: Bool, allowPartiUnmute: Bool) {
        if isReleased { return }
        ParticipantTracks.trackEnableAllMic(enabled: !isMuted, isOpenBreakoutRoom: setting.isOpenBreakoutRoom,
                                            isInBreakoutRoom: setting.isInBreakoutRoom)
        setting.updateHostManage(.muteAllMicrophone, update: {
            $0.isMuted = isMuted
            $0.isMuteOnEntry = isMuted
            $0.allowPartiUnmute = allowPartiUnmute
        }, completion: { [weak self] result in
            if let self = self, !self.isReleased, result.isSuccess {
                let text = isMuted ? I18n.View_M_AllCurrentAndNewParticipantsMuted : I18n.View_G_RequestSent
                Toast.showOnVCScene(text)
            }
        })
    }

    private func showMuteAllAlert(_ mute: Bool, allowPartiUnmute: Bool) {
        Util.runInMainThread { [weak self] in
            let config = ByteViewDialogConfig.CheckboxConfiguration(
                content: "\(I18n.View_M_AllowParticipantsToUnmute)\t\t",
                isChecked: allowPartiUnmute,
                affectLastButtonEnabled: false,
                itemImageSize: CGSize(width: 20, height: 20)
            )
            ByteViewDialog.Builder()
                .id(.muteMicrophoneForAll)
                .checkbox(config)
                .title(I18n.View_M_MuteAllCurrentAndNewParticipants)
                .adaptsLandscapeLayout(false)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ [weak self] alert in
                    guard let self = self else { return }
                    let allowParticipantUnmute = alert.isChecked
                    HandsUpTracks.trackConfirmMuteAllByHost(allowParticipantUnmute, confirm: false,
                                                            isOpenBreakoutRoom: self.setting.isOpenBreakoutRoom,
                                                            isInBreakoutRoom: self.setting.isInBreakoutRoom)
                })
                .rightTitle(I18n.View_M_MuteAll)
                .rightHandler({ [weak self] alert in
                    guard let self = self else { return }
                    let allowParticipantUnmute = alert.isChecked
                    HandsUpTracks.trackConfirmMuteAllByHost(allowParticipantUnmute, confirm: true,
                                                            isOpenBreakoutRoom: self.setting.isOpenBreakoutRoom,
                                                            isInBreakoutRoom: self.setting.isInBreakoutRoom)
                    self.requestMuteAll(mute, allowPartiUnmute: allowParticipantUnmute)
                })
                .needAutoDismiss(true)
                .show()
        }
    }

    private func setMutedInternal(_ isMuted: Bool) {
        if isMuted == self.isUserMuted { return }
        self.isUserMuted = isMuted
        self.didChangeMicrophoneMuted()
        if !isMuted {
            dismissHostAskingUnmuteAlert()
        }
    }

    private func setAvailable(_ isAvailable: Bool) {
        if isAvailable == self.isAvailable { return }
        self.isAvailable = isAvailable
        self.didChangeMicrophoneMuted()
    }

    private func didChangeMicrophoneMuted() {
        listeners.forEach { $0.didChangeMicrophoneMuted(self) }
        self.service.postMeetingChanges { $0.isMicrophoneMuted = self.isMuted }
        setting.updateSettings {
            $0.isInMeetMicrophoneMuted = self.isMuted
        }
    }

    private var handsUpAlert: InMeetHandsupAlert?
    // 改变自身举手状态，需要弹窗确认
    private func changeHandsStatus(_ handsStatus: ParticipantHandsStatus) {
        if setting.hasCohostAuthority { return }
        self.handsUpAlert?.dismiss()
        self.handsUpAlert = InMeetHandsupAlert(service: self.service, handsupType: .mic)
        self.handsUpAlert?.show(handsStatus: handsStatus, onDismiss: { [weak self] in
            self?.handsUpAlert = nil
        })
    }

    private func showEchoDetectionAlert(requestByHost: Bool) {
        ByteViewDialog.Builder()
            .id(.unmuteAlert)
            .colorTheme(.redLight)
            .title(I18n.View_MV_OpenMicEcho)
            .message(nil)
            .leftTitle(I18n.View_MV_CancelButtonTwo)
            .leftHandler({ _ in
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .unmuteOnOutputMuted, action: "cancel")
            })
            .rightTitle(I18n.View_MV_ConfirmButtonTwo)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .unmuteOnOutputMuted, action: "confirm")

                // 同意开麦走 unmute 请求
                let requestID = UUID().uuidString
                UserActionTracks.trackChangeMicAction(isOn: true, source: .echo_detection, requestID: requestID, result: .request_sent)
                self.muteOrUnmteMircrophone(false, requestByHost: requestByHost) { result in
                    if case .failure(let error) = result {
                        UserActionTracks.trackUnmuteMicRequestFailure(requestID: requestID, error: error)
                    }
                }
            })
            .show { _ in
                ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .unmuteOnOutputMuted)
            }
    }

    private func updateMicrophoneStatus(isInterrupted: Bool) {
        setting.updateParticipantSettings {
            $0.participantSettings.microphoneStatus = isInterrupted ? .unavailable : Privacy.audioDenied ? .noPermission : .normal
        }
    }

    func prepareForRecvingUltrawave() {
        rtc.setAudioUnitMuted(false)
    }

    func recoverForRecvingUltrawave() {
        rtc.setAudioUnitMuted(self.isUserMuted)
    }
}

extension InMeetMicrophoneManager {
    private func setPadMicSpeakeDisabled(_ isDisabled: Bool) {
        if isDisabled, !isUserMuted || setting.meetingType == .call && Privacy.audioAuthorized {
            muteMyself(true, source: .setting, completion: nil)
        }
    }
}

extension InMeetMicrophoneManager: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        let settings = myself.settings
        let oldSettings = oldValue?.settings
        if settings.isMicrophoneMuted == oldSettings?.isMicrophoneMuted &&
           settings.microphoneStatus == oldSettings?.microphoneStatus &&
           settings.rtcMode == oldSettings?.rtcMode {
            return
        }

        // 更新 rtc 麦摄状态之前必须正确设置当前的 clientRole，两者有严格时序要求
        if let clientRole = settings.rtcMode.toRtc() {
            rtc.setClientRole(clientRole)
        }

        if updateRustMuted(settings), settings.isMicrophoneMuted {
            let meetingId = self.meetingId
            Logger.meeting.info("sendMutePushAck, meetingId = \(meetingId), globalSeqID = \(myself.globalSeqId)")
            let request = UpdateVideoChatRequest(meetingId: meetingId, action: .mutePushAck(globalSeqId: myself.globalSeqId), interactiveId: myself.interactiveId, role: myself.meetingRole, leaveWithSyncRoom: nil)
            service.httpClient.send(request) { result in
                switch result {
                case .success:
                    Logger.meeting.info("sendMutePushAck(\(meetingId)) successfully")
                case .failure(let error):
                    Logger.meeting.error("Update video chat(\(meetingId)) fail, error = \(error).")
                }
            }
        }
    }
}

extension InMeetMicrophoneManager: LarkMicrophoneObserver {
    func applicationMicrophoneMuteStateDidChange(isMuted: Bool, isTriggeredInApp: Bool?) {
        guard service.setting.muteAudioConfig.enableNotification else {
            return
        }
        Logger.audioSession.info("receive applicationMicrophoneMuteStateDidChange: \(isMuted) isTriggeredInApp: \(isTriggeredInApp)")
        guard LarkAudioSession.shared.isBluetoothActive,
              isTriggeredInApp == false,
              !UltrawaveManager.shared.isRecvingUltrawave else {
            // 没有连接蓝牙耳机时忽略同步
            // App内触发变化时忽略同步
            // 超声波检测时忽略同步
            return
        }
        guard service.setting.muteAudioConfig.enableSyncMuteState else {
            Toast.show(I18n.View_M_CantTurnOnOffMic_Toast)
            return
        }
        if self.isUserMuted != isMuted {
            muteMyself(isMuted, source: .input_mute_notification) { [weak self] result in
                switch result {
                case .success:
                    break
                case .failure:
                    self?.forceUpdateMute()
                }
            }
        }
    }

    private func forceUpdateMute() {
        rtc.setAudioUnitMuted(self.isUserMuted)
        didChangeMicrophoneMuted()
    }
}

enum MicrophoneActionSource: String {
    case toolbar
    case callkit
    case phone_call_status //在非callkit场景下接听系统电话
    case sync
    case howling_detection
    case echo_detection
    case floating_button
    /// 点击键盘快捷键
    case keyboardShortcut
    /// 长按键盘快捷键
    case keyboardLongPress
    case host_request
    case participant_action
    case grid_action
    case speaker_mute
    case record
    case transcribe
    case setting
    case direct_call
    case nearby_room
    case webinar_change_role
    case webinar_attendee_unmute
    case token_check_failure
    case input_mute_notification
}

extension MicrophoneActionSource {
    fileprivate var mayHaveAudioBinder: Bool {
        switch self {
        case .toolbar, .floating_button:
            return true
        case .callkit, .phone_call_status, .sync, .howling_detection, .echo_detection,
                .keyboardShortcut, .keyboardLongPress, .host_request, .participant_action,
                .grid_action, .speaker_mute, .record, .transcribe, .setting, .direct_call,
                .nearby_room, .webinar_change_role, .webinar_attendee_unmute,
                .token_check_failure, .input_mute_notification:
            return false
        }
    }
}

enum MicrophoneActionResult: String {
    case hands_up
    case audience_host
    case echo_detected
    case request_sent
}

enum MicrophoneActionError: Error, Equatable {
    case unknown // 未知错误
    case echoDetected // 触发回声检测
    case handsUp // 举手逻辑
    case padMicDisabled // PadMicSpeaker禁用
    case systemPhoneCalling
    case webinarAttendeeNoPermission
    case micSncToken
}
