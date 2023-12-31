//
//  DeviceSyncChecker.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/8/16.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import ByteViewMeeting
import ByteViewNetwork

protocol MicrophoneStateRepresentable: AnyObject {
    var isMicMuted: Bool? { get }
    // used for debug & indexing
    var micIdentifier: String { get }
}

protocol CameraStateRepresentable: AnyObject {
    var isCameraMuted: Bool? { get }
    var cameraIdentifier: String { get }
}

final class DeviceSyncChecker {
    /// 为了防止刚入会时 rtc 未初始化完成，从 rtc 接口处取得的麦摄状态不准，导致隐私监控误报的问题，
    /// 入会后（InMeetRTCViewModel 创建后）延迟 `syncStartTime` 秒钟后才开始监控。
    private static let syncStartTime: TimeInterval = 5
    /// 收到 Rust 推送后延迟 `syncDelayTime` 秒后检查设备状态一致性并上报埋点
    private static let syncDelayTime: TimeInterval = 4
    private static let sysStatusCapacity = 3

    @RwAtomic
    private var readyForSync = false
    @RwAtomic
    private var micSyncTask: DispatchWorkItem?
    @RwAtomic
    private var cameraSyncTask: DispatchWorkItem?
    private let microphone: InMeetMicrophoneManager
    private let camera: InMeetCameraManager
    weak var transition: TransitionManager?

    private var microphones: [String: WeakRef<AnyObject>] = [:]
    private var cameras: [String: WeakRef<AnyObject>] = [:]
    private let syncDeviceQueue = DispatchQueue(label: "lark.byteview.syncDeviceQueue")
    // TODO: @chenyizhuo 目前此 fg 未开，因此兜底逻辑暂时不生效
    private let isAutoMuteWhenConflictEnabled: Bool
    @RwAtomic
    private var taskID = 0

    private var rtcSysStats: [RtcSysStats] = []
    private let reportQueue = DispatchQueue(label: "com.byteview.syncchecker")

    private var isTransitioning: Bool {
        transition?.isTransitioning ?? false
    }

    init(session: MeetingSession,
         microphone: InMeetMicrophoneManager,
         camera: InMeetCameraManager,
         isAutoMuteWhenConflictEnabled: Bool) {
        self.microphone = microphone
        self.camera = camera
        self.isAutoMuteWhenConflictEnabled = isAutoMuteWhenConflictEnabled
        session.addListener(self)
        camera.addRtcListener(self)
    }

    func release() {
        camera.removeRtcListener(self)
    }

    func registerMicrophone(_ mic: MicrophoneStateRepresentable, for key: String? = nil) {
        assertMain()
        let id = key ?? mic.micIdentifier
        Logger.privacy.info("[Mic] Register microphone state monitor for UI: \(id)")
        microphones[id] = WeakRef(mic)
    }

    func unregisterMicrophone(_ mic: MicrophoneStateRepresentable, for key: String? = nil) {
        assertMain()
        let id = key ?? mic.micIdentifier
        if microphones.removeValue(forKey: id) != nil {
            Logger.privacy.info("[Mic] Unregister microphone state monitor for UI: \(id)")
        }
    }

    func registerCamera(_ camera: CameraStateRepresentable, for key: String? = nil) {
        let id = key ?? camera.cameraIdentifier
        Logger.privacy.info("[Camera] Register camera state monitor for UI: \(id)")
        cameras[id] = WeakRef(camera)
    }

    func unregisterCamera(_ camera: CameraStateRepresentable, for key: String? = nil) {
        let id = key ?? camera.cameraIdentifier
        if cameras.removeValue(forKey: id) != nil {
            Logger.privacy.info("[Camera] Unregister camera state monitor for UI: \(id)")
        }
    }

    private func syncCheck(settings: ParticipantSettings) {
        guard readyForSync && !self.isTransitioning else { return }
        Logger.privacy.info("Start sync check task with task ID \(taskID), current settings: (mic = \(settings.isMicrophoneMutedOrUnavailable), cam = \(settings.isCameraMutedOrUnavailable))")
        taskID = taskID &+ 1
        let capturedTaskID = taskID
        // 摄像头任务可能因进入打断态而被取消，因此两个任务单独记录
        micSyncTask?.cancel()
        cameraSyncTask?.cancel()
        let micTask = DispatchWorkItem { [weak self] in
            guard self?.taskID == capturedTaskID else { return }
            self?.checkMicrophone(capturedTaskID, isRustMuted: settings.isMicrophoneMuted, isUnavailable: settings.microphoneStatus.isUnavailable)
        }
        let cameraTask = DispatchWorkItem { [weak self] in
            guard self?.taskID == capturedTaskID else { return }
            self?.checkCamera(capturedTaskID, isRustMuted: settings.isCameraMuted, isUnavailable: settings.cameraStatus.isUnavailable)
        }
        micSyncTask = micTask
        cameraSyncTask = cameraTask
        syncDeviceQueue.asyncAfter(deadline: .now() + Self.syncDelayTime, execute: micTask)
        syncDeviceQueue.asyncAfter(deadline: .now() + Self.syncDelayTime, execute: cameraTask)
    }

    // === For Unit Test ===

    struct CheckResult {
        let isConsistant: Bool
        let isUIConsistant: Bool
        let isRtcConsistant: Bool
    }

    static func doCheck(isRustMutedOrUnavailable: Bool, isRtcMutedOrUnavailable: Bool, uiMutes: [Bool?]) -> CheckResult {
        let uiConsistancy = uiMutes.allSatisfy { $0 == nil || $0 == isRustMutedOrUnavailable }
        let rtcConsistancy = isRustMutedOrUnavailable == isRtcMutedOrUnavailable
        return CheckResult(isConsistant: uiConsistancy && rtcConsistancy,
                           isUIConsistant: uiConsistancy,
                           isRtcConsistant: rtcConsistancy)
    }

    // === For Unit Test ===

    // MARK: - Private

    private func startSyncTask() {
        // 等待一段时间后将开关打开
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.syncStartTime) { [weak self] in
            self?.readyForSync = true
        }
    }

    private func checkMicrophone(_ currentTaskID: Int, isRustMuted: Bool, isUnavailable: Bool) {
        microphone.fetchRtcAudioMuted { [weak self] isRtcMuted in
            Util.runInMainThread {
                guard let self = self, currentTaskID == self.taskID, !self.isTransitioning else { return }
                let isRustMutedOrUnavailable = isRustMuted || isUnavailable
                let isRtcMutedOrUnavailable = isRtcMuted || isUnavailable
                let uiMutes = self.microphones.values.compactMap { $0.ref as? MicrophoneStateRepresentable }

                let result = Self.doCheck(isRustMutedOrUnavailable: isRustMutedOrUnavailable, isRtcMutedOrUnavailable: isRtcMutedOrUnavailable, uiMutes: uiMutes.map { $0.isMicMuted })
                let uiDesc = uiMutes.map { "\($0.micIdentifier): \($0.isMicMuted)" }

                Logger.privacy.info("[Mic] Microphone state check: uiMutes = \(uiDesc), rtcMuted = \(isRtcMutedOrUnavailable), rustMuted = \(isRustMutedOrUnavailable)")
                if !result.isConsistant {
                    Logger.privacy.error("[Mic] Microphone is not synced, authorized = \(Privacy.micAccess.value.isAuthorized)")
                    assertionFailure("Microphone is not synced between UI(\(uiDesc)), RTC(\(isRtcMutedOrUnavailable)) and Rust(\(isRustMutedOrUnavailable))")
                    let isUIMuted = result.isUIConsistant ? isRustMutedOrUnavailable : !isRustMutedOrUnavailable
                    self.handleInconsistant(mediaType: "mic",
                                            uiMuted: isUIMuted,
                                            rtcMuted: isRtcMutedOrUnavailable,
                                            rustMuted: isRustMutedOrUnavailable)
                    // fallback
                    if self.isAutoMuteWhenConflictEnabled {
                        Logger.privacy.warn("[Mic] Mute microhpone on unsync")
                        self.microphone.muteMyself(true, source: .sync, requestByHost: false, showToastOnSuccess: false, completion: nil)
                    }
                }
            }
        }
    }

    private func checkCamera(_ currentTaskID: Int, isRustMuted: Bool, isUnavailable: Bool) {
        camera.fetchRtcVideoMuted { [weak self] isRtcMuted in
            Util.runInMainThread {
                guard let self = self, currentTaskID == self.taskID, !self.camera.isInterrupted && !self.isTransitioning else { return }
                let isRustMutedOrUnavailable = isRustMuted || isUnavailable
                let isRtcMutedOrUnavailable = isRtcMuted || isUnavailable
                let uiMutes = self.cameras.values.compactMap { $0.ref as? CameraStateRepresentable }

                let result = Self.doCheck(isRustMutedOrUnavailable: isRustMutedOrUnavailable, isRtcMutedOrUnavailable: isRtcMutedOrUnavailable, uiMutes: uiMutes.map { $0.isCameraMuted })
                let uiDesc = uiMutes.map { "\($0.cameraIdentifier): \($0.isCameraMuted)" }

                Logger.privacy.info("[Camera] Camera state check: uiMutes = \(uiDesc), rtcMuted = \(isRtcMutedOrUnavailable), rustMuted = \(isRustMutedOrUnavailable)")
                if !result.isConsistant {
                    Logger.privacy.error("[Camera] Camera is not synced, isAuthorized = \(Privacy.cameraAccess.value.isAuthorized), isInterrupted = \(self.camera.isInterrupted)")
                    assertionFailure("Camera is not synced between UI(\(uiDesc)), RTC(\(isRtcMutedOrUnavailable)) and Rust(\(isRustMutedOrUnavailable))")
                    let isUIMuted = result.isUIConsistant ? isRustMutedOrUnavailable : !isRustMutedOrUnavailable
                    self.handleInconsistant(mediaType: "cam",
                                            uiMuted: isUIMuted,
                                            rtcMuted: isRtcMutedOrUnavailable,
                                            rustMuted: isRustMutedOrUnavailable)
                    // fallback
                    if self.isAutoMuteWhenConflictEnabled {
                        Logger.privacy.warn("[Camera] Mute camera on unsync")
                        self.camera.muteMyself(true, source: .sync, requestByHost: false, showToastOnSuccess: false, completion: nil)
                    }
                }
            }
        }
    }

    private func handleInconsistant(mediaType: String, uiMuted: Bool, rtcMuted: Bool, rustMuted: Bool) {
        reportQueue.async { [weak self] in
            guard let self = self else { return }
            InMeetRtcTracker.trackMuteStatusConflict(mediaType: mediaType,
                                                     uiMuted: uiMuted,
                                                     rtcMuted: rtcMuted,
                                                     rustMuted: rustMuted)
            if rtcMuted != rustMuted && rustMuted == uiMuted {
                // 如果是 rtc 与其他两端不一致，上报此时系统 cpu 等状态，帮助分析原因
                Logger.privacy.warn("\(mediaType) rtc status not match. last \(Self.sysStatusCapacity) sysStatus are \(self.rtcSysStats)")
                DevTracker.post(.privacy(.total_cpu_overload_on_unsync_check).params([
                    "latestTotalCPU": self.rtcSysStats.last?.cpuTotalUsage ?? 0,
                    "latestAppCPU": self.rtcSysStats.last?.cpuAppUsage ?? 0
                ]))
            }
        }
    }

    private func cancelCameraTask() {
        cameraSyncTask?.cancel()
        cameraSyncTask = nil
    }

    private func cancelMicTask() {
        micSyncTask?.cancel()
        micSyncTask = nil
    }
}

extension DeviceSyncChecker: RtcCameraListener {
    func cameraWillBeInterrupted(reason: RtcCameraInterruptionReason) {
        Logger.privacy.info("[Camera] Cancel camera sync check task because of the beginning of interruption")
        cancelCameraTask()
    }

    func cameraInterruptionWillEnd(oldIsInterrupted: Bool) {
        if oldIsInterrupted {
            // 从打断态中止，到UI收到推送进行更新，中间一段时间，UI的状态可能跟另外两端不一致，因此打断态期间屏蔽一致性检测
            Logger.privacy.info("[Camera] Cancel camera sync check task because of the ending of interruption")
            cancelCameraTask()
        }
    }
}

extension DeviceSyncChecker: TransitionManagerObserver {
    func transitionStatusChange(isTransition: Bool, info: BreakoutRoomInfo?, isFirst: Bool?) {
        if isTransition {
            // 分组讨论转场期间会mute本地音视频，是正常业务逻辑
            Logger.privacy.info("Cancel sync check task because of the beginning of breakout room transition")
            cancelMicTask()
            cancelCameraTask()
        }
    }
}

extension DeviceSyncChecker: MeetingSessionListener {
    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        if state == .onTheCall {
            startSyncTask()
        }
    }
}

extension DeviceSyncChecker: RtcListener {
    func reportSysStats(_ stats: RtcSysStats) {
        reportQueue.async { [weak self] in
            guard let self = self else { return }
            if self.rtcSysStats.count > Self.sysStatusCapacity {
                self.rtcSysStats.removeFirst()
            }
            self.rtcSysStats.append(stats)
        }
    }
}

extension DeviceSyncChecker: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        syncCheck(settings: myself.settings)
    }
}
