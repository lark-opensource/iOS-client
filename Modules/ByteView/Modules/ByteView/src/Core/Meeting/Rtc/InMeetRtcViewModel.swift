//
//  InMeetRtcViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import AVFoundation
import ByteViewMeeting
import ByteViewNetwork
import ByteViewTracker
import RxSwift
import LarkMedia
import ByteViewSetting
import ByteViewRtcBridge
import UniverseDesignToast
import ByteViewUI

final class InMeetRtcViewModel: InMeetingChangedInfoPushObserver {
    private let logger = Logger.ui
    private let meeting: InMeetMeeting
    private let context: InMeetViewContext
    private let breakoutRoom: BreakoutRoomManager
    private var allowPartiUnmute: Bool = false
    private let disposeBag = DisposeBag()
    private let collectQueue = DispatchQueue(label: "lark.byteview.collectEquipmentInfoQueue")

    private var oldEquipmentInfo: (String, String, String)?
    /// 参会人rtc连接状态
    @RwAtomic
    private(set) var rtcDisconnectStatus: [String: Bool] = [:]

    var canShowUserNetworkToast = false
    private var shouldShowLocalNetworkToast = false
    @RwAtomic
    private var needShowToastUsers = Set<RtcUID>()
    private var engine: InMeetRtcEngine { meeting.rtc.engine }

    var canShowCellularToast = false
    /// 会中是否显示过 “使用移动网络提升语音通话质量 toast”
    private var useCellularForAudioQualityDisplayed: Bool = false

    init(meeting: InMeetMeeting, context: InMeetViewContext, breakoutRoom: BreakoutRoomManager) {
        self.meeting = meeting
        self.context = context
        self.breakoutRoom = breakoutRoom
        handleMuteVoiceToast()
        collectEquipmentInfo()
        breakoutRoom.transition.addObserver(self)
        meeting.rtc.engine.addListener(self)
        meeting.rtc.network.addListener(self)
        meeting.push.inMeetingChange.addObserver(self)
        meeting.camera.addListener(self)
        DispatchQueue.global().async { [weak self] in
            self?.startTrackDevice()
        }
        // center stage 需要设置
        InMeetOrientationToolComponent.isLandscapeModeRelay.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLandscape in
                self?.setupVideoProfiles(isPortrait: !isLandscape)
            })
            .disposed(by: disposeBag)
        updateCellularConfig()
        joinChannel()
        meeting.setting.addListener(self, for: .useCellularImproveAudioQuality)
    }

    private func handleRtcEndEvent(_ event: RtcEndEvent) {
        logger.info("leave from rtc, reason = \(event)")
        meeting.leave(.rtcError(event))
    }

    private func updateCellularConfig() {
        let val = meeting.setting.useCellularImproveAudioQuality
        let config = RtcCellularEnhancementConfig(enhanceAudio: val, enhanceVideo: false,
                                                  enhanceScreenAudio: val, enhanceScreenVideo: false)
        self.logger.info("setCellularEnhancement \(val) ")
        self.meeting.rtc.engine.setCellularEnhancement(config)
    }

    private func joinChannel() {
        let isHost = meeting.type == .meet && meeting.account == meeting.info.host
        logger.info("join rtc, isHost = \(isHost)")
        // 判断当前用户是否是主持人
        LarkAudioSession.shared.waitAudioSession("joinChannel") { [weak self] in
            let joinWithMic: () -> Void = { [weak self] in
                Privacy.requestMicrophoneAccess { _ in
                    self?.meeting.callCoordinator.waitAudioSessionActivated { result in
                        guard let self = self else { return }
                        if !result.isSuccess || !self.joinChannelInternal() {
                            self.handleRtcEndEvent(isHost ? .startFailed : .joinFailed)
                        }
                    }
                }
            }
            if isHost {
                Privacy.requestCameraAccess { _ in
                    joinWithMic()
                }
            } else {
                joinWithMic()
            }
        }
    }

    private func joinChannelInternal() -> Bool {
        if meeting.setting.isBoxSharing || meeting.subType == .screenShare {
            engine.setChannelProfile(.share1v1)
            engine.setScreenVideoEncoderConfig(.screenP2PEncoderConfig)
        } else {
            engine.setScreenVideoEncoderConfig(.screenEncoderConfig)
        }

        if !meeting.rtc.joinChannel() {
            return false
        }
        let myself = meeting.myself
        if let clientRole = myself.settings.rtcMode.toRtc() {
            engine.setClientRole(clientRole)
        }
        meeting.camera.onJoinChannel(shouldMute: myself.settings.isCameraMuted)
        meeting.microphone.onJoinChannel(shouldCapture: meeting.audioMode == .internet, shouldMute: myself.settings.isMicrophoneMuted)
        meeting.audioDevice.output.onJoinChannel()
        return true
    }

    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        if data.meetingID == meeting.meetingId {
            Util.runInMainThread {
                self.handleToastAndAlert(data)
            }
        }
    }

    func showUserNetworkToastIfNeeded() {
        if !canShowUserNetworkToast {
            return
        }
        defer {
            self.shouldShowLocalNetworkToast = false
            self.needShowToastUsers.removeAll()
        }
        let info = self.checkShouldShowToast()
        guard let toast = info.0, info.1 else { return }
        Logger.networkStatus.debug("show network toast: \(toast)")
        Toast.show(toast)
    }

    func showCellularToastIfNeeded() {
        guard canShowCellularToast, !useCellularForAudioQualityDisplayed else {
            return
        }

        useCellularForAudioQualityDisplayed = true
        Util.runInMainThread { [weak self] in
            guard let self = self else {
                return
            }
            let config = UDToastConfig(toastType: .info,
                                       text: I18n.View_MV_UsingCellularCanSet,
                                       operation: UDToastOperationConfig(text: I18n.View_G_ChangesSetting, displayType: .horizontal),
                                       delay: 6.0)
            if let view = self.meeting.router.window, !view.isFloating {
                Toast.hideToasts(in: view)
                UDToast.showToast(with: config, on: view, delay: 6.0, operationCallBack: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    let settingContext = InMeetSettingContext(meeting: self.meeting, context: self.context, isFromToast: true)
                    let handler = InMeetSettingHandlerImpl(meeting: self.meeting, context: self.context)
                    let vc = self.meeting.setting.ui.createInMeetSettingViewController(context: settingContext, handler: handler)
                    self.meeting.router.presentDynamicModal(vc,
                                                            regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                                            compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
                })
            }
        }
    }

    private func checkShouldShowToast() -> (String?, Bool) {
        if self.shouldShowLocalNetworkToast {
            return self.meeting.rtc.network.localNetworkStatus.toastInfo()
        }
        /// 会议只有2个人，并且都在同一个分组才弹toast
        if meeting.participant.global.nonRingingCount == 2,
            meeting.participant.currentRoom.nonRingingCount == 2,
           let uid = meeting.participant.otherParticipant?.rtcUid,
           self.needShowToastUsers.contains(uid),
           let info = meeting.rtc.network.remoteNetworkStatuses[uid]?.toastInfo() {
            return info
        }
        return (nil, false)
    }

    private func clearNeedShowToastCache() {
        self.shouldShowLocalNetworkToast = false
        self.needShowToastUsers.removeAll()
    }

    private func startTrackDevice() {
        LarkAudioSession.rx.routeChangeObservable
            .map { _ in AVAudioSession.sharedInstance().currentRoute }
            .subscribe(onNext: { [weak self] currentRoute in
                self?.collectEquipmentInfo(currentRoute)
            })
            .disposed(by: disposeBag)

        MeetSettingTracks.trackDeviceStatus(name: meeting.type.trackName, isMicOn: !meeting.microphone.isMuted,
                                            isCameraOn: !meeting.camera.isMuted,
                                            audioOutput: LarkAudioSession.shared.currentOutput)
    }

    private func handleToastAndAlert(_ event: InMeetingData) {
        switch event.type {
        case .hostMuteMic:
            meeting.microphone.muteByHost()
        case .hostMuteCamera:
            meeting.camera.muteByHost()
        case .allMicrophoneMuted:
            guard let data = event.muteAllData else { return }
            meeting.microphone.handleHostMuteAll(data.isMuted, operationUser: data.operationUser)
        case .unmuteCameraConfirmed:
            meeting.camera.unmuteByHost()
        case .unmuteMicrophoneConfirmed:
            meeting.microphone.unmuteByHost()
        case .settingsChanged:
            guard let settings = event.settingsChangedData?.meetingSettings else { return }
            if settings.allowPartiUnmute != allowPartiUnmute {
                /// 维持原有逻辑，只有InMeetingData时调用
                self.allowPartiUnmute = settings.allowPartiUnmute
                self.meeting.microphone.handleAllowPartiUnmute(allowPartiUnmute)
            }
        default:
            break
        }
    }

    private func handleMuteVoiceToast() {
        guard meeting.setting.isMuteOnEntry, meeting.microphone.isMuted,
              meeting.info.host != meeting.account,
              meeting.audioMode != .noConnect, !meeting.audioModeManager.isPadMicSpeakerDisabled else {
            return
        }
        Toast.showOnVCScene(I18n.View_M_HostMutedYourMic)
    }

    @objc private func collectEquipmentInfo(_ currentRoute: AVAudioSessionRouteDescription = AVAudioSession.sharedInstance().currentRoute) {
        collectQueue.async { [weak self] in
            guard let self = self else { return }
            let user = self.meeting.myself.user
            var microphoneName = ""
            for mic in currentRoute.inputs {
                microphoneName += mic.portType.rawValue + " | "
            }
            microphoneName = microphoneName.vc.substring(from: 0, length: microphoneName.count - 3)
            var speakerName = ""
            for speaker in currentRoute.outputs {
                speakerName += speaker.portType.rawValue + " | "
            }
            speakerName = speakerName.vc.substring(from: 0, length: speakerName.count - 3)
            let isFrontCamera = self.meeting.camera.isFrontCamera
            let cameraName = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: isFrontCamera ? .front : .back)?.localizedName ?? ""

            if let info = self.oldEquipmentInfo, info == (microphoneName, speakerName, cameraName) {
                return
            }
            self.oldEquipmentInfo = (microphoneName, speakerName, cameraName)

            let request = UploadEquipmentInfoRequest(user: user, meetingID: self.meeting.meetingId, microphoneName: microphoneName,
                                                     speakerName: speakerName, cameraName: cameraName)
            self.meeting.httpClient.send(request)
        }
    }

    lazy var multiResolutionConfig = meeting.setting.multiResolutionConfig
    lazy var multiResPublishConfig = Display.phone ? multiResolutionConfig.phone.publish : multiResolutionConfig.pad.publish
    // disable-lint: magic number
    let centerStagePublishConfig = [
        MultiResPublishResolution(res: 720, fps: 30, maxBitrate: 1200, maxBitrate1To1: 1200),
        MultiResPublishResolution(res: 360, fps: 15, maxBitrate: 450, maxBitrate1To1: 450),
        MultiResPublishResolution(res: 180, fps: 15, maxBitrate: 300, maxBitrate1To1: 300)
    ]
    let defaultPublishConfig = [
        MultiResPublishResolution(res: 360, fps: 15, maxBitrate: 450, maxBitrate1To1: 450),
        MultiResPublishResolution(res: 180, fps: 15, maxBitrate: 300, maxBitrate1To1: 300),
        MultiResPublishResolution(res: 90, fps: 15, maxBitrate: 120, maxBitrate1To1: 120)
    ]
    // enable-lint: magic number

    private var isSquareVideoProfiles: Bool?
    //开启center stage时需要提高采集分辨率，因此将有能力开启center stage的设备都提示一个分辨率
    //https://bytedance.feishu.cn/docs/doccn8wZXeytEQ5NSC48jDtucsd
    func setupVideoProfiles(isPortrait: Bool) {
        let isSquare = isPortrait
        if self.isSquareVideoProfiles == isSquare { return }
        let rtc = meeting.rtc.engine
        let isHDModeEnabled = meeting.setting.isHDModeEnabled
        let encoderCfgs = multiResPublishConfig
        logger.info("isPortrait: \(isPortrait), MultiResolutionConfig: \(encoderCfgs)")
        let channel = isHDModeEnabled ? multiResPublishConfig.channelHigh ?? multiResPublishConfig.channel : multiResPublishConfig.channel
        let main = isHDModeEnabled ? multiResPublishConfig.mainHigh ?? multiResPublishConfig.main : multiResPublishConfig.main
        // disable-lint: magic number
        let rtcChannelCfgs = channel.map({ cfg -> RtcVideoEncoderConfig in
            let w = isSquare ? cfg.res : cfg.res * 16 / 9
            return RtcVideoEncoderConfig(width: w, height: cfg.res, frameRate: cfg.fps, maxBitrate: cfg.maxBitrate)
        })
        let rtcMainCfgs = main.map({ cfg -> RtcVideoEncoderConfig in
            let w = isSquare ? cfg.res : cfg.res * 16 / 9
            let bitrate = isSquare ? cfg.maxBitrate1To1 : cfg.maxBitrate
            return RtcVideoEncoderConfig(width: w, height: cfg.res, frameRate: cfg.fps, maxBitrate: bitrate)
        })
        // enable-lint: magic number
        rtc.enableSimulcastMode(true)
        logger.info("setVideoEncoderConfig(channel: \(rtcChannelCfgs), main: \(rtcMainCfgs))")
        trackVideoStreamPublishSettings(encoderCfgs.channel)
        rtc.setVideoEncoderConfig(channel: rtcChannelCfgs, main: rtcMainCfgs)
    }

    private func trackVideoStreamPublishSettings(_ settings: [MultiResPublishResolution]) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        if let data = try? encoder.encode(settings), let str = String(data: data, encoding: .utf8) {
            VCTracker.post(name: .vc_video_stream_send_setting_status,
                           params: ["is_share_screen": 0, "settings": str])
        }
    }
}

extension InMeetRtcViewModel: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .useCellularImproveAudioQuality {
            updateCellularConfig()
            if !isOn {
                self.useCellularForAudioQualityDisplayed = false
            }
        }
    }
}

// MARK: - TransitionManagerObserver
extension InMeetRtcViewModel: TransitionManagerObserver {

    func transitionStatusChange(isTransition: Bool, info: BreakoutRoomInfo?, isFirst: Bool?) {
        if !isTransition {
            handleMuteVoiceToast()
        }
    }
}

extension InMeetRtcViewModel: RtcListener {
    func onRtcError(_ error: RtcError) {
        if error == .overDeadlockNotify {
            // RTC内部卡死,不调用离会逻辑
            return
        }
        handleRtcEndEvent(.sdkError(error.rawValue))
    }

    func onRoomStats(_ roomStats: RtcRoomStats) {
        if roomStats.rxCellularKbitrate > 0 || roomStats.txCellularKbitrate > 0, !ReachabilityUtil.isCellular,
           meeting.setting.useCellularImproveAudioQuality {
            self.showCellularToastIfNeeded()
        }
    }

    func onConnectionTypeUpdated(isP2P: Bool) {
        engine.setScreenVideoEncoderConfig(isP2P ? .screenP2PEncoderConfig : .screenEncoderConfig)
    }
}

extension InMeetRtcViewModel: InMeetCameraListener {
    func didSwitchCamera(_ camera: InMeetCameraManager) {
        collectEquipmentInfo()
    }
}

extension InMeetRtcViewModel: InMeetRtcNetworkListener {

    // 流媒体连线中断
    func didChangeRtcReachableState(_ state: InMeetRtcReachableState) {
        if meeting.type == .call, state == .lost {
            handleRtcEndEvent(.streamingLost)
        } else if meeting.type == .meet, state == .lost || state == .timeout {
            handleRtcEndEvent(.streamingLost)
        }
    }

    func didChangeLocalNetworkStatus(_ status: RtcNetworkStatus, oldValue: RtcNetworkStatus, reason: InMeetRtcNetwork.NetworkStatusChangeReason) {
        if reason == .networkQualityChanged, status.networkShowStatus == .bad {
            self.shouldShowLocalNetworkToast = true
            showUserNetworkToastIfNeeded()
        }
    }

    func didChangeRemoteNetworkStatus(_ status: [RtcUID: RtcNetworkStatus], upsertValues: [RtcUID: RtcNetworkStatus],
                                      removedValues: [RtcUID: RtcNetworkStatus], reason: InMeetRtcNetwork.NetworkStatusChangeReason) {
        if reason == .networkQualityChanged {
            let isShowTips = meeting.participant.global.nonRingingCount == 2 && meeting.participant.currentRoom.nonRingingCount == 2 && meeting.rtc.network.isWeakNetworkEnabled
            upsertValues.forEach { (uid, status) in
                self.needShowToastUsers.insert(uid)
                VCTracker.post(name: .vc_remote_network_quality_status, params: [
                    "network_status": status.networkQuality.description, "is_show_tips": isShowTips, "remote_device_id": uid
                ])
            }
            showUserNetworkToastIfNeeded()
        } else if reason == .iceDisconnected {
            upsertValues.forEach { (uid, status) in
                if status.isIceDisconnected,
                   meeting.participant.find({ $0.rtcUid == uid }) != nil {
                    self.needShowToastUsers.insert(uid)
                }
            }
            if !self.needShowToastUsers.isEmpty {
                showUserNetworkToastIfNeeded()
            }
        }
    }
}

extension ParticipantSettings.RtcMode {
    func toRtc() -> RtcClientRole? {
        switch self {
        case .normal:
            return .broadcaster
        case .audience:
            return .audience
        default:
            return nil
        }
    }
}
