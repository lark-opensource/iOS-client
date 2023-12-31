//
//  InMeetCameraManager.swift
//  ByteView
//
//  Created by kiri on 2022/8/19.
//

import Foundation
import ByteViewMeeting
import ByteViewTracker
import UIKit
import RxSwift
import AVFoundation
import LarkMedia
import ByteViewNetwork
import ByteViewUI
import ByteViewSetting
import ByteViewRtcBridge

protocol InMeetCameraListener: AnyObject {
    func didInterruptedByAllowVirtualBg(_ muteModel: NoVirtualBgMuteParam)
    func didChangeCameraMuted(_ camera: InMeetCameraManager)
    func didSwitchCamera(_ camera: InMeetCameraManager)
}

protocol InMeetEffectListener: AnyObject {
    func didChangeEffectStatus(_ status: RtcCameraEffectStatus, oldStatus: RtcCameraEffectStatus)
}

extension InMeetCameraListener {
    func didInterruptedByAllowVirtualBg(_ muteModel: NoVirtualBgMuteParam) {}
    func didChangeCameraMuted(_ camera: InMeetCameraManager) {}
    func didSwitchCamera(_ camera: InMeetCameraManager) {}
}

final class InMeetCameraManager {
    private let logger = Logger.camera
    private let rtc: LabCamera
    var effect: RtcEffect { rtc.effect }

    /// 当前摄像头是否mute，取自ParticipantSettings
    @RwAtomic
    private var isUserMuted: Bool
    @RwAtomic
    private var isAvailable: Bool
    private let listeners = Listeners<InMeetCameraListener>()
    private let effectListeners = Listeners<InMeetEffectListener>()
    var isMuted: Bool { isUserMuted || !isAvailable || rtc.isInterrupted }
    var isInterrupted: Bool { rtc.isInterrupted }
    private let isOriginMuted: Bool

    private var isReleased: Bool { rtc.isReleased }
    private let service: MeetingBasicService
    private var setting: MeetingSettingManager { service.setting }
    private var effectManger: MeetingEffectManger?
    private let bag = DisposeBag()

    init(isMuted: Bool, isAvailable: Bool, service: MeetingBasicService, effectManger: MeetingEffectManger?) {
        self.rtc = LabCamera(engine: service.rtc, scene: .inMeet, service: service, effectManger: effectManger, isFromLab: false)
        self.effectManger = effectManger
        self.service = service
        self.isUserMuted = isMuted
        self.isAvailable = isAvailable
        self.isOriginMuted = isMuted
        self.rtc.addListener(self)
        /// 初始化配置，上次断线时可能记录了一个不正确的设置（rejoin请求无settings选项）
        //        self.updateCameraStatus(isInterrupted: self.rtc.isInterrupted)
        Privacy.cameraAccess
            .map { $0.isAuthorized }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.updateCameraStatus(isInterrupted: self.rtc.isInterrupted)
                self.listeners.forEach { $0.didChangeCameraMuted(self) }
                self.service.postMeetingChanges { $0.isCameraMuted = self.isMuted }
            }).disposed(by: bag)
        self.setting.updateSettings {
            $0.isFrontCameraEnabled = self.rtc.isFrontCamera
            if self.isMuted {
                $0.isInMeetCameraMuted = true
            } else {
                $0.isInMeetCameraMuted = false
                $0.isInMeetCameraEffectOn = effectManger?.isEffectOn() ?? false
            }
        }
        self.service.postMeetingChanges {
            $0.isCameraMuted = self.isMuted
            $0.isCameraEffectOn = self.setting.isCameraEffectOn
        }
    }

    func release() {
        self.rtc.removeListener(self)
        dismissHostAskingUnmuteAlert()
        self.handsUpAlert?.dismiss()
        rtc.release()
    }

    func addListener(_ listener: InMeetCameraListener) {
        self.listeners.addListener(listener)
    }

    func removeLisenter(_ listener: InMeetCameraListener) {
        self.listeners.removeListener(listener)
    }

    func addEffectLisenter(_ listener: InMeetEffectListener) {
        self.effectListeners.addListener(listener)
    }

    func removeEffectLisenter(_ listener: InMeetEffectListener) {
        self.effectListeners.removeListener(listener)
    }

    func addRtcListener(_ listener: RtcCameraListener) {
        self.rtc.addListener(listener)
    }

    func removeRtcListener(_ listener: RtcCameraListener) {
        self.rtc.removeListener(listener)
    }

    func onJoinChannel(shouldMute: Bool) {
        logger.info("onJoinChannel(camera): setCameraMute \(shouldMute)")
        self.setMutedInternal(shouldMute)
        self.setRtcMuted(shouldMute)
    }

    /// 从Rust同步
    /// - returns: isRtcChanged
    @discardableResult
    private func updateRustMuted(_ settings: ParticipantSettings) -> Bool {
        if isReleased { return false }
        let isMuted = settings.isCameraMuted
        let isAvailable = !settings.cameraStatus.isUnavailable
        logger.info("updateRustMuted: isMuted = \(isMuted), isAvailable = \(isAvailable)")
        self.setMutedInternal(isMuted)
        self.setAvailable(isAvailable)
        self.showMuteOrUnmuteToast(isMuted)
        if rtc.isMuted != isMuted {
            // 本地与服务器不同步的情况存在两种：1. 更新麦克风请求失败 2. 主持人关闭参会者麦克风
            // 无论哪种情况，直接使用服务端的值(以前是直接关闭，举手发言需求时改为尊重服务端)
            self.setRtcMuted(isMuted)
            UserActionTracks.trackCameraPush(isOn: !isMuted)
            self.logger.info("updateParticipantSettings: isCameraMuted = \(isMuted)")
            return true
        }
        return false
    }

    func fetchRtcVideoMuted(completion: @escaping (Bool) -> Void) {
        if isReleased { return }
        rtc.fetchLocalVideoMuted(completion: completion)
    }

    var isFrontCamera: Bool {
        rtc.isFrontCamera
    }

    func switchCamera() {
        if isReleased { return }
        rtc.switchCamera()
        setting.updateSettings({ $0.isFrontCameraEnabled = self.isFrontCamera })
        listeners.forEach { $0.didSwitchCamera(self) }
    }

    /// 仅启用/停止rtc
    /// - note: 会导致三端不同步，慎用。目前仅用于分组会议转场
    func muteRtcOnly(_ muted: Bool) {
        if isReleased || rtc.isInterrupted { return }
        setRtcMuted(muted)
    }

    private var lastRequestTime = CFAbsoluteTimeGetCurrent()
    private var isRequesting = false
    // 关于 requestID 的讨论参考 InMeetMicrophoneManager.muteMyself
    func muteMyself(_ muted: Bool, source: CameraActionSource, requestByHost: Bool = false, showToastOnSuccess: Bool = true, shouldHandleBgAllow: Bool = true, completion: ((Result<Void, Error>) -> Void)?, file: String = #fileID, function: String = #function, line: Int = #line) {
        guard !isReleased else {
            completion?(.success(()))
            return
        }
        assertMain()

        if !muted, !CameraSncWrapper.getCheckResult(by: .inMeet) {
            Toast.showOnVCScene(I18n.View_VM_CameraNotWorking)
            completion?(.failure(CameraActionError.cameraSncToken))
            return
        }

        if !muted, rtc.isInterrupted {
            logger.error("mute camera \(muted) failed, from: \(source), camera is interrupted, reason = \(rtc.lastInterruptionReason)",
                         file: file, function: function, line: line)
            if rtc.lastInterruptionReason == .notAvailableWithMultipleForegroundApps {
                Toast.showOnVCScene(I18n.View_G_NoCamMultitask)
            }
            completion?(.failure(CameraActionError.interrupted))
            return
        }

        if !muted, shouldHandleBgAllow, effectManger?.virtualBgService.canShowMuteBgPreview(isOriginMuted: isOriginMuted) == true {
            logger.info("lab allow mute camera \(muted) failed, from: \(source), camera is interrupted by not AllowVirtualBg",
                        file: file, function: function, line: line)
            let noVirtualBgMuteParam = NoVirtualBgMuteParam(muted: false, source: source, requestByHost: requestByHost, shouldShowToast: showToastOnSuccess, shouldHandleBgAllow: false, file: file, function: function, line: line)
            listeners.forEach { $0.didInterruptedByAllowVirtualBg(noVirtualBgMuteParam) }
            completion?(.failure(CameraActionError.effectPreview))
            return
        }

        logger.info("mute camera \(muted), from: \(source), rtcMode:\(setting.rtcMode), showToast: \(showToastOnSuccess)",
                    file: file, function: function, line: line)

        let isHandsUp = setting.cameraHandsStatus == .putUp
        if !requestByHost && !muted && isHandsUp {
            UserActionTracks.trackChangeCameraAction(isOn: !isMuted, source: source, requestID: nil, result: .hands_up)
            changeHandsStatus(.putDown)
            completion?(.failure(CameraActionError.handsDown))
            return
        }

        // 暂时只对 unmute 请求记录 requestID，因为 mute 是本地直接改状态，属于确定事件，无需对后续请求结果追踪
        let requestID: String? = muted ? nil : UUID().uuidString
        muteOrUnmteCamera(muted, requestByHost: requestByHost, showToastOnSuccess: showToastOnSuccess) {
            if case .failure(let error) = $0 {
                UserActionTracks.trackUnmuteCameraRequestFailure(requestID: requestID, error: error)
            }
            completion?($0)
        }
        UserActionTracks.trackChangeCameraAction(isOn: !muted, source: source, requestID: requestID, result: .request_sent)
    }

    private func setMutedInternal(_ isMuted: Bool) {
        if isMuted == self.isUserMuted { return }
        self.isUserMuted = isMuted
        self.didChangeCameraMuted()
        if !isMuted {
            dismissHostAskingUnmuteAlert()
        }
    }

    private func setAvailable(_ isAvailable: Bool) {
        if isAvailable == self.isAvailable { return }
        self.isAvailable = isAvailable
        didChangeCameraMuted()
    }

    private func didChangeCameraMuted() {
        listeners.forEach { $0.didChangeCameraMuted(self) }
        setting.updateSettings {
            if self.isMuted {
                $0.isInMeetCameraMuted = true
            } else {
                $0.isInMeetCameraMuted = false
                $0.isInMeetCameraEffectOn = effectManger?.isEffectOn() ?? false
            }
        }
        self.service.postMeetingChanges {
            $0.isCameraMuted = self.isMuted
            $0.isCameraEffectOn = self.setting.isCameraEffectOn
        }
    }

    private func setRtcMuted(_ isMuted: Bool, file: String = #fileID, function: String = #function, line: Int = #line) {
        rtc.setMuted(isMuted, file: file, function: function, line: line)
        updateCameraMutex(isMuted)
    }

    private func updateCameraMutex(_ isMuted: Bool) {
        LarkMediaManager.shared.update(scene: .vcMeeting, mediaType: .camera, priority: isMuted ? nil : .high)
    }

    private func muteOrUnmteCamera(_ muted: Bool, requestByHost: Bool, showToastOnSuccess: Bool, shouldTrack: Bool = true,
                                   completion: ((Result<Void, Error>) -> Void)?) {
        Privacy.requestCameraAccessAlert { [weak self] in
            switch $0 {
            case .success:
                if shouldTrack { OnthecallReciableTracker.startOpenCamera() }
                if muted {
                    self?.muteCamera(requestByHost: requestByHost, showToastOnSuccess: showToastOnSuccess, completion: completion)
                } else {
                    self?.unmuteCamera(requestByHost: requestByHost, showToastOnSuccess: showToastOnSuccess, completion: completion)
                }
            case .failure(let e):
                completion?(.failure(e))
            }
        }
    }

    private var lastRequestMuted: Bool?
    /// mute 请求 rust 会直接推送结果
    private func muteCamera(requestByHost: Bool, showToastOnSuccess: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        lastRequestMuted = true
        isRequesting = false
        requestMuteCamera(true, requestByHost: requestByHost, showToastOnSuccess: showToastOnSuccess, completion: completion)
    }

    @RwAtomic private var lastUnmuteRequestId: UUID?
    /// 先请求远端，成功后通过InMeetRtcViewModel同步到本地
    private func unmuteCamera(requestByHost: Bool, showToastOnSuccess: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        lastRequestMuted = false
        let toastConfig = setting.microphoneCameraToastConfig
        if toastConfig.needCheckNetworkDisconnected, !ReachabilityUtil.isConnected {
            Toast.show(BundleI18n.ByteView.View_G_CameraFailCheckNet_Toast)
            logger.error("unmuteMyCamera failed, show disconnected toast")
            completion?(.failure(VCError.badNetwork))
            return
        }
        if isRequesting {
            logger.error("unmuteMyCamera is requesting, skip")
            completion?(.failure(CameraActionError.isRequesting))
            return
        }
        isRequesting = true
        let reqId = UUID()
        self.lastUnmuteRequestId = reqId
        if toastConfig.needShowLoadingToast {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(toastConfig.showLoadingToastMS)) { [weak self] in
                guard let self = self else { return }
                if self.lastUnmuteRequestId == reqId, self.isRequesting {
                    Toast.show(BundleI18n.ByteView.View_G_UnstableNetReconnect_Toast,
                               duration: Double(toastConfig.loadingToastDurationMS) / 1000)
                }
            }
        }

        requestMuteCamera(false, requestByHost: requestByHost, showToastOnSuccess: showToastOnSuccess) { [weak self] result in
            completion?(result)
            guard let self = self else { return }
            self.isRequesting = false
            let error = result.error?.toVCError()
            if error == .shouldCameraHandsUp {
                self.changeHandsStatus(.putUp)
            } else if error == .badNetwork || error == .badNetworkV2 {
                Toast.show(I18n.View_G_CameraFailCheckNet_Toast)
            }
        }
    }

    private var handsUpAlert: InMeetHandsupAlert?
    // 改变自身举手状态，需要弹窗确认
    private func changeHandsStatus(_ handsStatus: ParticipantHandsStatus) {
        if setting.hasCohostAuthority { return }
        self.handsUpAlert?.dismiss()
        self.handsUpAlert = InMeetHandsupAlert(service: self.service, handsupType: .camera)
        self.handsUpAlert?.show(handsStatus: handsStatus, onDismiss: { [weak self] in
            self?.handsUpAlert = nil
        })
    }

    // 点击手放下
    func putDownHands() {
        guard !isReleased else { return }
        let handsUpState = setting.cameraHandsStatus
        logger.info("put down hands for camera, camera handsup state is \(handsUpState) when click hands put down")
        if handsUpState == .putUp {
            setting.updateParticipantSettings {
                $0.earlyPush = false
                $0.participantSettings.cameraHandsStatus = .putDown
            }
        }
    }

    @RwAtomic
    private var showToastOnSuccess = false
    private func requestMuteCamera(_ isMuted: Bool, requestByHost: Bool = false, showToastOnSuccess: Bool,
                                   completion: ((Result<Void, Error>) -> Void)? = nil) {
        if isReleased {
            logger.error("unmuteMyCamera failed, camera is released")
            completion?(.failure(VCError.unknown))
            return
        }

        self.showToastOnSuccess = showToastOnSuccess
        setting.updateParticipantSettings({
            $0.requestedByHost = requestByHost
            $0.participantSettings.isCameraMuted = isMuted
        }, completion: {
            completion?($0)
            Logger.camera.info("muteMyRemoteCamera: \(isMuted) result: \($0)")
        })
    }

    private func showMuteOrUnmuteToast(_ isMuted: Bool) {
        if showToastOnSuccess, self.isUserMuted == lastRequestMuted {
            showToastOnSuccess = false
            if !rtc.isInterrupted {
                // 被打断时不显示摄像头on/off，但是要设回去showToastOnSuccess，不然可能会没手动设置时被推送推出来一个toast
                Toast.showOnVCScene(isMuted ? I18n.View_VM_CameraOff : I18n.View_VM_CameraOn)
            }
        }
    }

    func muteByHost() {
        /// 被主持人mute后，后端会主动推isCameraMuted = true的ParticipantChange
        dismissHostAskingUnmuteAlert()
        Toast.showOnVCScene(I18n.View_M_HostTurnedOffyourCamera)
    }

    func unmuteByHost() {
        assertMain()
        if isUserMuted, !rtc.isInterrupted {
            showHostAskingUnmuteAlert()
        } else {
            logger.warn("Receiving UNMUTE_CAMERA_CONFIRMED, while camera muted false")
        }
    }

    private weak var hostAskingUnmuteAlert: ByteViewDialog?
    private let alertNotificationId = UUID().uuidString
    private func showHostAskingUnmuteAlert() {
        guard !isReleased, hostAskingUnmuteAlert == nil else {
            logger.warn("showHostAskingUnmuteAlert ignored, alert exists = \(hostAskingUnmuteAlert != nil)")
            return
        }

        if UIApplication.shared.applicationState != .active {
            let body = I18n.View_M_HostCameraRequestStandard
            UNUserNotificationCenter.current().addLocalNotification(withIdentifier: alertNotificationId, body: body)
        }

        let rtcMode = self.setting.rtcMode
        ByteViewDialog.Builder()
            .id(.hostRequestCamera)
            .title(I18n.View_M_HostCameraRequestStandard)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ [weak self] _ in
                guard self != nil else { return }
                HandsUpTracksV2.trackRejectInvite(isAudience: rtcMode == .audience, isMicrophone: false)
                VCTracker.post(name: .vc_meeting_lark_hint,
                               params: [.action_name: "cancel",
                                        .from_source: "invite_open_camera",
                                        "audience_mode": rtcMode == .audience ? 1 : 0])
            })
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                VCTracker.post(name: .vc_meeting_lark_hint,
                               params: [.action_name: "confirm",
                                        .from_source: "invite_open_camera",
                                        "audience_mode": rtcMode == .audience ? 1 : 0])
                self.muteMyself(false, source: .host_request, requestByHost: true, completion: nil)
                ByteViewDialogManager.shared.dismiss(ids: [.cameraHandsUp, .cameraHandsDown])
            })
            .show { [weak self] alert in
                if let self = self {
                    self.hostAskingUnmuteAlert = alert
                } else {
                    alert.dismiss()
                }
            }
    }

    private func dismissHostAskingUnmuteAlert() {
        hostAskingUnmuteAlert?.dismiss()
        hostAskingUnmuteAlert = nil
    }
}

extension InMeetCameraManager: RtcCameraListener {
    private func updateCameraStatus(isInterrupted: Bool) {
        setting.updateParticipantSettings {
            $0.participantSettings.cameraStatus = isInterrupted ? .unavailable : Privacy.videoAuthorized ? .normal : .noPermission
        }
    }

    func cameraWasInterrupted(reason: RtcCameraInterruptionReason) {
        if reason == .notAvailableWithMultipleForegroundApps {
            Toast.showOnVCScene(I18n.View_G_NoCamMultitask)
        }
        updateCameraStatus(isInterrupted: true)
        self.didChangeCameraMuted()
    }

    func cameraInterruptionEnded() {
        updateCameraStatus(isInterrupted: false)
        self.didChangeCameraMuted()
    }

    func didFailedToStartVideoCapture(scene: RtcCameraScene, error: Error) {
        muteMyself(true, source: .token_check_failure, completion: nil)
    }

    func didChangeEffectStatus(_ status: RtcCameraEffectStatus, oldStatus: RtcCameraEffectStatus) {
        effectListeners.forEach { $0.didChangeEffectStatus(status, oldStatus: oldStatus) }
    }
}

extension InMeetCameraManager: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        let settings = myself.settings
        let oldSettings = oldValue?.settings
        if settings.isCameraMuted == oldSettings?.isCameraMuted &&
           settings.cameraStatus == oldSettings?.cameraStatus &&
           settings.rtcMode == oldSettings?.rtcMode {
            return
        }

        if let clientRole = settings.rtcMode.toRtc() {
            rtc.setClientRole(clientRole)
        }
        updateRustMuted(settings)
    }
}

enum CameraActionSource: String {
    case toolbar
    case callkit
    case sync
    case host_request
    case participant_action
    case grid_action
    /// 点击键盘快捷键
    case keyboardShortcut
    /// 长按键盘快捷键
    case keyboardLongPress
    case callmeLeaveWithoutPstn
    case voice_mode
    case webinar_change_role
    case notAllow_VirtualBg
    case token_check_failure
}

enum CameraActionResult: String {
    case split
    case audience_host
    case ask_host
    case request_sent
    case hands_up
}

enum CameraActionError: Error, Equatable {
    case unknown // 未知错误
    case handsDown // 手放下
    case cameraSncToken // 主端敏感 API 监控
    case interrupted // 摄像头被打断
    case effectPreview // 虚拟背景逻辑，本次开摄失败，需要先弹一个预览页提示用户
    case isRequesting // 正在操作中，忽略重复操作
}
