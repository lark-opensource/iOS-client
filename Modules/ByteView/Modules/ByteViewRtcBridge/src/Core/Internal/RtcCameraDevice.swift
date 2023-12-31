//
//  RtcCameraDevice.swift
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/5/26.
//

import Foundation
import ByteViewCommon

extension RtcCameraOrientation {
    @RwAtomic fileprivate static var cache: [RtcCameraOrientation] = []
    static var current: RtcCameraOrientation? { cache.last }
}

final class RtcCameraDevice {
    let logger: Logger
    let sessionId: String
    let orientation: RtcCameraOrientation
    let listeners = Listeners<RtcCameraListener>()
    private weak var rtc: MeetingRtcEngine?

    var isFrontCamera: Bool { storage.isFrontCamera }
    var isCapturing: Bool { storage.isRtcCapturing ?? false }
    var isInterrupted: Bool { storage.isInterrupted }
    var lastInterruptionReason: RtcCameraInterruptionReason? { storage.lastInterruptionReason }
    var effectStatus: RtcCameraEffectStatus { storage.effectStatus }
    private var storage: StatusCache {
        get { StatusCache.shared }
        set { StatusCache.shared = newValue }
    }

    init(engine: MeetingRtcEngine) {
        let sessionId = engine.sessionId
        self.logger = Logger.camera.withContext(sessionId).withTag("[RtcCameraDevice(\(sessionId))]")
        self.sessionId = sessionId
        self.orientation = RtcCameraOrientation(sessionId: engine.sessionId, proxy: engine.proxy)
        self.rtc = engine
        RtcInternalListeners.addListener(self)

        orientation.delegate = self
        /// 这两个通知暂时用来对比观察rtc的回调是否有问题。
        NotificationCenter.default.addObserver(self, selector: #selector(cameraWasInterrupted(_:)),
                                               name: .AVCaptureSessionWasInterrupted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cameraInterruptionEnded(_:)),
                                               name: .AVCaptureSessionInterruptionEnded, object: nil)
        RtcCameraOrientation.cache.append(self.orientation)
        logger.info("init RtcCameraDevice")
    }

    deinit {
        logger.info("deinit RtcCameraDevice")
        self.storage.sceneMutes.removeValue(forKey: self.sessionId)
        RtcCameraOrientation.cache.removeAll(where: { $0.sessionId == self.sessionId })
    }

    func setMuted(_ isMuted: Bool, for scene: RtcCameraScene, file: String = #fileID, function: String = #function, line: Int = #line) {
        logger.info("setMuted \(isMuted), for \(scene)", file: file, function: function, line: line)
        if !isMuted {
            rtc?.ensureRtc()
        }
        var mutes = self.storage.sceneMutes[sessionId, default: [:]]
        mutes[scene] = isMuted
        self.storage.sceneMutes[sessionId] = mutes
        resetCaptureIfNeeded()
    }

    func isMuted(for scene: RtcCameraScene) -> Bool {
        self.storage.sceneMutes[sessionId, default: [:]][scene, default: true]
    }

    func switchCamera() {
        let isFront = !self.storage.isFrontCamera
        self.storage.isFrontCamera = isFront
        rtc?.execute({ rtcKit in
            rtcKit.switchCamera(isFront: isFront)
        })
        listeners.forEach { $0.didSwitchFrontCamera(isFront) }
    }

    func release() {
        logger.info("release RtcCameraDevice")
        self.storage.sceneMutes.removeValue(forKey: self.sessionId)
        self.resetCaptureIfNeeded()
    }

    private func resetCaptureIfNeeded() {
        guard let rtc = self.rtc, !rtc.isDestroyed, let instanceId = self.storage.instanceId else { return }
        /// 把本地状态同步到rtc
        var shouldCapture = false
        var shouldMuteStream = true
        var captureScene: RtcCameraScene = .inMeet

        for mutes in self.storage.sceneMutes.values {
            for (scene, isMuted) in mutes {
                if !isMuted {
                    shouldCapture = true
                    captureScene = scene
                    if scene.hasStream {
                        shouldMuteStream = false
                        break
                    }
                }
            }
            if shouldCapture, !shouldMuteStream {
                break
            }
        }

        let shouldMuteLocalVideo = !shouldCapture
        self.logger.info("sync camera status to \(rtc), shouldCapture = \(shouldCapture), shouldMuteStream = \(shouldMuteStream)")
        rtc.execute { rtcKit in
            if rtcKit.instanceId != instanceId {
                self.logger.warn("sync camera status cancelled, rtc instance changed: \(instanceId) -> \(rtcKit.instanceId)")
                return
            }
            if shouldCapture != self.storage.isRtcCapturing || shouldMuteLocalVideo != rtcKit.isMuteLocalVideo() {
                // 采集状态改变，重置所有操作
                if shouldCapture {
                    self.logger.info("perform startVideoCapture, muteLocalVideoStream = \(shouldMuteStream)")
                    if let degree = self.orientation.toRtcDegree() {
                        rtcKit.setDeviceOrientation(degree)
                    }
                    // 由于RTC 5.24开始的bughttps://bytedance.feishu.cn/docx/IBCTdlaxmodChTxg2yCcrD9BnQg
                    // 每次调用startVideoCapture前需要设置videoCaptureConfig
                    let captureConfig = rtc.createParams.videoCaptureConfig
                    rtcKit.setVideoCaptureConfig(videoSize: captureConfig.videoSize, frameRate: captureConfig.frameRate)
                    do {
                        try rtcKit.startVideoCapture(scene: captureScene)
                    } catch {
                        self.listeners.forEach({ $0.didFailedToStartVideoCapture(scene: captureScene, error: error) })
                    }
                    rtcKit.muteLocalVideoStream(shouldMuteStream)
                    self.orientation.startMonitor()
                } else {
                    self.logger.info("perform stopVideoCapture")
                    self.orientation.stopMonitor()
                    rtcKit.muteLocalVideoStream(true)
                    rtcKit.stopVideoCapture()
                }
                self.storage.isRtcCapturing = shouldCapture
                self.storage.isRtcStreamMuted = shouldMuteStream
            } else if shouldMuteStream != self.storage.isRtcStreamMuted || shouldMuteStream != rtcKit.isMuteLocalVideo() {
                // 采集状态不变则仅操作流发送
                self.logger.info("muteLocalVideoStream \(shouldMuteStream)")
                rtcKit.muteLocalVideoStream(shouldMuteStream)
                self.storage.isRtcStreamMuted = shouldMuteStream
            }
        }
    }

    @objc private func cameraWasInterrupted(_ notification: Notification) {
        logger.info("SystemNotification: cameraWasInterrupted: \(notification)")
    }

    @objc private func cameraInterruptionEnded(_ notification: Notification) {
        logger.info("SystemNotification: cameraInterruptionEnded: \(notification)")
    }
}

extension RtcCameraDevice {
    func enableBackgroundBlur(_ isEnable: Bool) {
        rtc?.execute({ rtcKit in
            rtcKit.enableBackgroundBlur(isEnable)
        })
    }

    func setBackgroundImage(_ image: String) {
        rtc?.execute({ rtcKit in
            rtcKit.setBackgroundImage(image)
        })
    }

    func applyEffect(_ effectRes: RtcFetchEffectInfo, with type: RtcEffectType, contextId: String, cameraEffectType: RtcCameraEffectType) {
        rtc?.execute({
            $0.applyEffect(effectRes, with: type, contextId: contextId, cameraEffectType: cameraEffectType)
        })
    }

    func cancelEffect(_ panel: String, cameraEffectType: RtcCameraEffectType) {
        rtc?.execute({ rtcKit in
            rtcKit.cancelEffect(panel, cameraEffectType: cameraEffectType)
        })
    }
}

extension RtcCameraDevice: RtcCameraOrientationDelegate {
    func didChangeCameraOrientation(_ orientation: UIDeviceOrientation, degree: Int) {
        logger.info("orientation from sensor changed: \(degree)")
        self.rtc?.execute({ rtcKit in
            rtcKit.setDeviceOrientation(degree)
        })
    }
}

extension RtcCameraDevice: RtcInternalListener {
    func onMediaDeviceStateChanged(_ rtc: RtcInstance, deviceType: RtcMediaDeviceType, deviceId: String, deviceState: RtcMediaDeviceState, deviceError: RtcMediaDeviceError) {
        guard rtc.sessionId == self.sessionId, deviceType == .videoCaptureDevice else { return }
        switch deviceState {
        case .interruptionBegan:
            let reason = deviceError.toInterruptionReason()
            listeners.forEach { $0.cameraWillBeInterrupted(reason: reason) }
            logger.info("cameraWasInterrupted, reason = \(reason)")
            storage.isInterrupted = true
            storage.lastInterruptionReason = reason
            listeners.forEach { $0.cameraWasInterrupted(reason: reason) }
        case .interruptionEnded, .started, .stopped, .runtimeError:
            let isInterrupted = self.storage.isInterrupted
            listeners.forEach { $0.cameraInterruptionWillEnd(oldIsInterrupted: isInterrupted) }
            self.storage.isInterrupted = false
            logger.info("cameraInterruptionEnded, deviceState = \(deviceState), last isInterrupted = \(isInterrupted)")
            if isInterrupted {
                if deviceState == .runtimeError {
                    /// AVCaptureSessionRuntimeErrorNotification后rtc会stop CaptureSession后回调，刷下rtc重新startCapture
                    self.storage.isRtcCapturing = false
                    self.resetCaptureIfNeeded()
                }
                listeners.forEach { $0.cameraInterruptionEnded() }
            }
        }
    }

    func onEffectStatusChanged(_ status: RtcCameraEffectStatus, oldValue: RtcCameraEffectStatus) {
        storage.effectStatus = status
        listeners.forEach { $0.didChangeEffectStatus(status, oldStatus: oldValue) }
    }

    func didStopVideoCapture(_ rtc: RtcInstance) {
        if self.isInterrupted {
            logger.info("cameraInterruptionEnded on stopVideoCapture")
            self.storage.isInterrupted = false
            listeners.forEach { $0.cameraInterruptionEnded() }
        }
    }

    func onCreateInstance(_ rtc: RtcInstance) {
        StatusCache.shared.instanceId = rtc.instanceId
        logger.info("create rtc instance \(rtc), reset camera status")
        resetCaptureIfNeeded()
    }

    func onDestroyInstance(_ rtc: RtcInstance) {
        StatusCache.shared.onDestroyRtc(for: rtc.sessionId)
        logger.info("destroy rtc instance \(rtc), reset camera storage")
    }
}

private extension RtcCameraDevice {
    struct StatusCache {
        @RwAtomic static var shared = StatusCache()

        var instanceId: String?
        /// 当前各个scene的开关状态
        var sceneMutes: [String: [RtcCameraScene: Bool]] = [:]
        var isFrontCamera = true
        /// 是否被打断
        var isInterrupted: Bool = false
        var lastInterruptionReason: RtcCameraInterruptionReason?

        /// 当前rtc方法的调用状态
        var isRtcCapturing: Bool?
        /// 当前rtc方法的调用状态
        var isRtcStreamMuted: Bool?

        /// 当前effect状态
        var effectStatus: RtcCameraEffectStatus = .none
        /// 当前effect设置值
        var effectValues: [RtcCameraEffectType: Any] = [:]

        mutating func onDestroyRtc(for sessionId: String) {
            self.instanceId = nil
            self.isFrontCamera = true
            self.isInterrupted = false
            self.lastInterruptionReason = nil
            self.isRtcCapturing = nil
            self.isRtcStreamMuted = nil
            self.effectStatus = .none
            self.effectValues = [:]
        }
    }
}

extension RtcMediaDeviceError {
    func toInterruptionReason() -> RtcCameraInterruptionReason {
        switch self {
        case .notAvailableInBackground:
            return .notAvailableInBackground
        case .videoInUseByAnotherClient:
            return .videoInUseByAnotherClient
        case .notAvailableWithMultipleForegroundApps:
            return .notAvailableWithMultipleForegroundApps
        case .notAvailableDueToSystemPressure:
            return .notAvailableDueToSystemPressure
        default:
            return .unknown
        }
    }
}

extension Logger {
    static let camera = Logger.getLogger("Camera")
}

// TODO: kiri, deprecated
struct TempEffectHelper {
    static var isCameraCapturing: Bool {
        RtcCameraDevice.StatusCache.shared.isRtcCapturing ?? false
    }
}
