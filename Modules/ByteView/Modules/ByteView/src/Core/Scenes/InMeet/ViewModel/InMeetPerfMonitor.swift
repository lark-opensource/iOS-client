//
//  InMeetPerfMonitor.swift
//  ByteView
//
//  Created by kiri on 2021/5/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import ByteViewNetwork
import ByteViewRtcBridge
import ByteViewSetting
import ByteViewTracker
import Foundation
import LarkMedia
import LarkSensitivityControl
import RxSwift

extension ByteViewThreadBizScope: CustomStringConvertible {
    public var description: String {
        switch self {
        case ByteViewThreadBizScope_RTC:
            return "rtc"
        case ByteViewThreadBizScope_VideoConference:
            return "vc"
        default:
            return "\(self.rawValue)"
        }
    }
}

extension ByteViewThreadCPUUsage: CustomStringConvertible {
    override public var description: String {
        "(tid:0x\(String(self.threadID, radix: 16, uppercase: true)), tn:\(self.threadName), qn:\(self.queueName), biz:\(self.bizScope), usage:\(String(format: "%.4f", self.cpuUsage)))"
    }
}

enum CoreCpuHighLoadType: String {
    /// 无高负载
    case none
    /// 性能核峰值
    case peakPerf
    /// 效能核高峰值
    case peakEfficient
    /// 性能核持久高负载
    case prolongPerf
    /// 效能核持久高负载
    case prolongEfficient

    var isValidPeak: Bool {
        switch self {
        case .peakPerf, .peakEfficient:
            return true
        case .none, .prolongPerf, .prolongEfficient:
            return false
        }
    }

    var isValidProlong: Bool {
        switch self {
        case .none, .peakPerf, .peakEfficient:
            return false
        case .prolongPerf, .prolongEfficient:
            return true
        }
    }
}

final class InMeetPerfMonitor {
    struct CpuCoreInfo {
        /// 设备所有核数
        let coreCount: Int

        /// 性能核数
        let perfCount: Int

        /// 效能核数
        let efficientCount: Int

        /// 各类型核的数量
        ///
        /// 0：表示性能核
        /// 1：表示效能核
        let perfLevels: [Int: Int]

        /// 性能核起始位置
        ///
        /// nil：表示没获取到
        var perfCoreStartIndex: Int? {
            guard perfCount > 0 else { return nil }
            return efficientCount > 0 ? efficientCount : nil
        }
    }

    // CPU 核心数
    @RwAtomic private(set) static var cpuCoreInfo: CpuCoreInfo?

    static let logger = Logger.monitor
    let disposeBag = DisposeBag()
    private let resolver: InMeetViewModelResolver
    let meeting: InMeetMeeting
    let batteryMonitor: BatteyMonitor?
    private var sampleCollector: InMeetPerfCollector?

    // 电量监控
    var batteryMonitorStartTime: Double = 0
    var batteryMonitorStartLevel: Float = 0

    @RwAtomic private var lastTemperature: ProcessInfo.ThermalState = .nominal
    @RwAtomic private var lastEffectStatus: RtcCameraEffectStatus
    @RwAtomic private var lastMicrophoneMuted: Bool
    @RwAtomic private var lastCameraMuted: Bool
    @RwAtomic private var lastFrontCamera: Bool
    @RwAtomic private var lastEcoMode: Bool
    @RwAtomic private var lastVoiceMode: Bool
    @RwAtomic private var lastWebSpace: Bool
    @RwAtomic private var lastSubtitle: Bool = false
    @RwAtomic private var lastShareScene: InMeetShareScene
    @RwAtomic private var lastNetworkQuality: RtcNetworkQuality
    @RwAtomic private var lastLowPowerMode: Bool
    @RwAtomic private var lastNotesOn: Bool
    @RwAtomic private var lastMSFollow: InMeetFollowViewModelStatus?

    /// 记录上次网络状态，用于判断仅在网络类型有变化时触发上报等相关逻辑
    @RwAtomic var lastNetworkType: NetworkConnectionType?

    init(resolver: InMeetViewModelResolver) {
        self.resolver = resolver
        self.meeting = resolver.meeting
        self.batteryMonitor = resolver.resolve(InMeetBatteryStatusManager.self)
        lastMicrophoneMuted = meeting.microphone.isMuted
        lastEffectStatus = meeting.camera.effect.effectStatus
        lastCameraMuted = meeting.camera.isMuted
        lastFrontCamera = meeting.camera.isFrontCamera
        lastShareScene = meeting.shareData.shareContentScene
        lastNetworkQuality = meeting.rtc.network.localNetworkStatus.networkQuality
        lastNetworkType = ReachabilityUtil.currentNetworkType
        lastEcoMode = meeting.setting.isEcoModeOn
        lastVoiceMode = meeting.setting.isVoiceModeOn
        lastWebSpace = meeting.webSpaceData.isWebSpace
        lastLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        lastNotesOn = meeting.notesData.isNotesOn
        lastMSFollow = resolver.resolve(InMeetFollowManager.self)?.status
        _ = Self.getCpuCoreInfo()
        setupScenesAndMonitor()
        startBatteryMonitor()
        startMemoryPressureMonitor()
        bindSceneListeners()
        DispatchQueue.global().async { [weak self] in
            self?.bindRx()
            self?.trackInMeetingMemroy()
        }
    }

    private func setupScenesAndMonitor() {
        // 入会后及时清理上次的场景数据
        AggregateTracker.resetSceneEvents()
        // 麦克风
        AggregateTracker.entry(scene: .microphone(lastMicrophoneMuted ? .off : .on))
        // 摄像头
        let (cameraState, cameraExtra) = cameraStateAndExtra(mute: lastCameraMuted, front: lastFrontCamera)
        AggregateTracker.entry(scene: .camera(cameraState, cameraExtra))
        // 特效
        restoreEffectScenes()
        // 共享
        if let scene = lastShareScene.shareSceneType.aggregateSceneType(state: .on) {
            AggregateTracker.entry(scene: scene)
        }
        // 画中画
        if meeting.pip.isActive {
            AggregateTracker.entry(scene: .pip(.on))
        }
        // 字幕
        if let subtitle = resolver.resolve(InMeetSubtitleViewModel.self) {
            lastSubtitle = subtitle.isTranslationOn
            AggregateTracker.entry(scene: .subtitle(lastSubtitle ? .on : .off))
        }
        // 语音模式
        AggregateTracker.entry(scene: .voiceMode(lastVoiceMode ? .on : .off))
        // 节能模式
        AggregateTracker.entry(scene: .ecoMode(lastEcoMode ? .on : .off))
        // 大小窗
        let windowState = windowState(floating: meeting.router.isFloating)
        AggregateTracker.entry(scene: .windowState(windowState))
        // 前后台
        let appState = appState(state: AppInfo.shared.applicationState)
        AggregateTracker.entry(scene: .appState(appState))
        // 网络类型
        if let networkType = lastNetworkType {
            AggregateTracker.entry(scene: .networkType(networkType.description))
        }
        // 网络质量
        AggregateTracker.entry(scene: .networkQuality(lastNetworkQuality.description))
        // 面试空间
        AggregateTracker.entry(scene: .webSpace(lastWebSpace ? .on : .off))
        // 低电量模式
        AggregateTracker.entry(scene: .lowPowerMode(lastLowPowerMode ? .on : .off))
        // 纪要
        AggregateTracker.entry(scene: .notes(lastNotesOn ? .on : .off))

        if let follow = lastMSFollow?.aggDescription, !follow.isEmpty {
            AggregateTracker.entry(scene: .magicShareFollow(follow))
        }

        if #available(iOS 12.0, *) {
            startCellularMonitor()
        }
        self.sampleCollector = InMeetPerfMonitor.startSampleCollector(sampleConfig: meeting.setting.perfSampleConfig,
                                                                      batteryMonitor: batteryMonitor)
    }

    private func bindSceneListeners() {
        meeting.addListener(self)
        meeting.microphone.addListener(self)
        meeting.camera.addEffectLisenter(self)
        meeting.camera.addListener(self)
        meeting.shareData.addListener(self)
        meeting.pip.addObserver(self)
        Util.runInMainThread {
            if let subtitle = self.resolver.resolve(InMeetSubtitleViewModel.self) {
                subtitle.addObserver(self)
            }
        }
        meeting.router.addListener(self)
        AppInfo.shared.addObserver(self)
        meeting.rtc.network.addListener(self)
        meeting.webSpaceData.addListener(self, fireImmediately: false)
        meeting.setting.addListener(self, for: [.isEcoModeOn, .isVoiceModeOn])
        meeting.notesData.addListener(self)
        resolver.resolve(InMeetPerfAdjustViewModel.self)?.addAdjustListener(self)
        resolver.resolve(InMeetFollowManager.self)?.addListener(self)
    }

    private func bindRx() {
        lastTemperature = ThermalStateMonitor.shared.thermalState
        AggregateTracker.entry(scene: .thermal(lastTemperature.aggDescription))
        AladdinTracks.trackThermalState(lastTemperature)
        CommonReciableTracker.trackThermalState(lastTemperature)
        ThermalStateMonitor.shared.thermalStateObservable.subscribe(onNext: { [weak self] thermalState in
            guard thermalState != self?.lastTemperature else { return }
            let lastThermalValue = self?.lastTemperature.aggDescription ?? "unknown"
            let thermalValue = thermalState.aggDescription
            Logger.monitor.info("ThermalState change `\(lastThermalValue)` -> `\(thermalValue)`")
            self?.lastTemperature = thermalState
            AggregateTracker.entry(scene: .thermal(thermalValue))
            AladdinTracks.trackThermalState(thermalState)
            CommonReciableTracker.trackThermalState(thermalState)
        }).disposed(by: disposeBag)
        startObservingNetworkTypeChange()
        updateNetworkTypeIfNeeded(joinMeeting: true)
        monitorCamMicSelect()
    }

    private static func audioEquipName() -> String {
        let inputs = LarkAudioSession.shared.currentRoute.inputs
        let outputs = LarkAudioSession.shared.currentRoute.outputs
        let inputPortName = inputs.map(\.portType.rawValue).joined(separator: ",")
        let outputPortName = outputs.map(\.portType.rawValue).joined(separator: ",")
        let equipPortName = "\(inputPortName)|\(outputPortName)"
        return equipPortName
    }

    func monitorCamMicSelect() {
        let equipName = Self.audioEquipName()
        AladdinTracks.trackJoinCamMic(isFront: meeting.camera.isFrontCamera, micName: equipName)
        LarkAudioSession.rx.routeChangeObservable
            .map { _ -> String in
                Self.audioEquipName()
            }
            .startWith(equipName)
            .distinctUntilChanged()
            .skip(1)
            .subscribe(onNext: {
                AladdinTracks.trackMicSelected(micName: $0)
            })
            .disposed(by: self.disposeBag)
    }

    private func trackInMeetingMemroy() {
        let usage = ByteViewMemoryUsage.getCurrentMemoryUsage()
        CommonReciableTracker.trackMetricMeeting(event: .vc_metric_in_meeting,
                                                 appMemory: usage.appUsageBytes,
                                                 systemMemory: usage.systemUsageBytes,
                                                 availableMemory: usage.availableUsageBytes)
    }

    deinit {
        self.sampleCollector?.stop()
        stopBatteryMonitor()
        stopObservingNetworkTypeChange()
    }

    func startBatteryMonitor() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(batteryMonitorChanged),
                                               name: UIDevice.batteryStateDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(lowPowerModeMonitorChanged),
                                               name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
                                               object: nil)
        batteryMonitorChanged()
    }

    func stopBatteryMonitor() {
        batteryMonitorChanged(forcedStop: true)
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryStateDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSProcessInfoPowerStateDidChange, object: nil)
    }

    // nolint: long_function
    private static func startSampleCollector(sampleConfig: InMeetPerfSampleConfig, batteryMonitor: BatteyMonitor? = nil) -> InMeetPerfCollector {
        let collector = InMeetPerfCollector(sampleConfig: sampleConfig, batteryMonitor: batteryMonitor)
        collector.start()
        return collector
    }

    @objc private func batteryMonitorChanged(forcedStop: Bool = false) {
        let batteryState = UIDevice.current.batteryState
        if batteryState == .unplugged && !forcedStop {
            // 不在充电且未开始统计电量消耗，则开始统计
            if batteryMonitorStartTime <= 0 {
                batteryMonitorStartTime = Date().timeIntervalSince1970
                batteryMonitorStartLevel = UIDevice.current.batteryLevel
            }
        } else {
            // (开始充电 || 强制停止) 且已开始统计电量消耗，则结束统计、上报埋点
            if batteryMonitorStartTime > 0 {
                let duration: Int = .init(Date().timeIntervalSince1970 - batteryMonitorStartTime)
                let endLevel: Float = UIDevice.current.batteryLevel
                batteryMonitorStartTime = 0
                CommonReciableTracker.trackPowerConsume(startLevel: batteryMonitorStartLevel,
                                                        endLevel: endLevel,
                                                        duration: duration)
                Self.logger.info("battery changed from \(batteryMonitorStartLevel) to \(endLevel) in \(duration)s")
            }
        }
    }

    @objc private func lowPowerModeMonitorChanged() {
        let lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        if lastLowPowerMode == lowPowerMode {
            return
        }

        lastLowPowerMode = lowPowerMode
        AggregateTracker.entry(scene: .lowPowerMode(lowPowerMode ? .on : .off))
    }
}

// MARK: - NetworkTypeChange

extension InMeetPerfMonitor {
    /// 开始监听网络状态变化
    private func startObservingNetworkTypeChange() {
        AladdinTracks.trackNetwork(ReachabilityUtil.currentNetworkType)
        NotificationCenter.default.addObserver(self, selector: #selector(updateNetworkTypeIfNeeded),
                                               name: Notification.Name.reachabilityChanged, object: nil)
    }

    /// 停止监听网络状态变化
    private func stopObservingNetworkTypeChange() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.reachabilityChanged, object: nil)
    }

    /// 当网络状态有变化时，更新相应数据
    @objc
    private func updateNetworkTypeIfNeeded(joinMeeting: Bool = false) {
        let currentNetworkType = ReachabilityUtil.currentNetworkType
        var needReport = false
        if lastNetworkType != currentNetworkType {
            // 记录最新网络类型
            AggregateTracker.entry(scene: .networkType(currentNetworkType.description))
            lastNetworkType = currentNetworkType
            needReport = true
        }
        if joinMeeting || needReport {
            AladdinTracks.trackNetwork(currentNetworkType)
            reportNetworkToAdmin()
        }
    }

    private func reportNetworkToAdmin() {
        // 上报新类型到Admin接口
        let networkType = ReachabilityUtil.currentNetworkType.uploadType
        let internalIP = getWifiAddresses().joined(separator: "|")
        let req = UploadParticipantInfoRequest(meetingID: meeting.meetingId, networkType: networkType, internalIP: internalIP, useRtcProxy: false)
        meeting.httpClient.send(req)
    }

    /// Get IP addresses of WiFi interface (en0)
    private func getWifiAddresses() -> [String] {
        var ifAddrsPtr: UnsafeMutablePointer<ifaddrs>?
        let res = try? DeviceSncWrapper.getifaddrs(for: .perfMonitorGetWifi, &ifAddrsPtr)
        guard res == 0 else { return [] }
        guard let firstAddr = ifAddrsPtr else { return [] }
        defer { freeifaddrs(ifAddrsPtr) }
        var addresses = [String]()
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let addr = ptr.pointee.ifa_addr
            let addrLen = ptr.pointee.ifa_addr.pointee.sa_len
            let addrFamily = ptr.pointee.ifa_addr.pointee.sa_family
            let name = String(cString: ptr.pointee.ifa_name)
            if [AF_INET, AF_INET6].contains(Int32(addrFamily)) && name == "en0" {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(addr, socklen_t(addrLen), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                addresses.append(String(cString: hostname))
            }
        }
        return addresses
    }
}

// MARK: - MemoryPressureMonitor

extension InMeetPerfMonitor {
    private func startMemoryPressureMonitor() {
        Logger.monitor.info("start MemoryPressureMonitor")
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(memoryPressureWarning(_:)),
                                               name: NSNotification.Name(rawValue: "KHMDMemoryMonitorMemoryWarningNotificationName"),
                                               object: nil)
    }

    // memoryPressureTypeValue含义：
    // | 2 | 内存从高水位降到正常水位
    // | 4 | 内存上升到高水位
    // | 8 | 收到内存警告
    // | 16 | 收到『系统内存压力』告警，即MemoryPressure2
    // | 32 | 收到『系统内存压力』告警，即MemoryPressure4，随时有可能OOM
    // | 128 | 收到『App内存压力』告警，即MemoryPressure16，随时有可能OOM
    // https://bytedance.feishu.cn/docx/HJpzdhZDZoG0TRxKXfYciTqSn0g
    @objc func memoryPressureWarning(_ noti: NSNotification) {
        Util.runInMainThread {
            if let memoryPressureTypeValue = noti.userInfo?["type"] as? Int32 {
                let background = UIApplication.shared.applicationState == .background ? 1 : 0
                Logger.monitor.info("receive memoryPressureWarning:\(memoryPressureTypeValue), inBackground:\(background)")
                CommonReciableTracker.trackMemoryPressure(pressureType: memoryPressureTypeValue, inBackground: background)
            }
        }
    }
}

private extension NetworkConnectionType {
    /// 网络类型变化时上传Admin
    var uploadType: UploadParticipantInfoRequest.NetworkType {
        switch self {
        case .cell5G:
            return .networkType5G
        case .cell4G:
            return .networkType4G
        case .cell3G:
            return .networkType3G
        case .cell2G:
            return .networkType2G
        case .wifi:
            return .wireless
        case .others:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}

extension InMeetPerfMonitor: InMeetMicrophoneListener {
    func didChangeMicrophoneMuted(_ microphone: InMeetMicrophoneManager) {
        let isMuted = microphone.isMuted
        if lastMicrophoneMuted == isMuted {
            return
        }
        lastMicrophoneMuted = isMuted
        AggregateTracker.entry(scene: .microphone(isMuted ? .off : .on))
    }
}

extension InMeetPerfMonitor: InMeetCameraListener {
    func didChangeCameraMuted(_ camera: InMeetCameraManager) {
        handleCameraChanged(camera)
    }

    func didSwitchCamera(_ camera: InMeetCameraManager) {
        handleCameraChanged(camera)
    }

    private func handleCameraChanged(_ camera: InMeetCameraManager) {
        if lastCameraMuted == camera.isMuted, lastFrontCamera == camera.isFrontCamera {
            return
        }
        lastFrontCamera = camera.isFrontCamera
        lastCameraMuted = camera.isMuted
        let (state, extra) = cameraStateAndExtra(mute: camera.isMuted, front: camera.isFrontCamera)
        AggregateTracker.entry(scene: .camera(state, extra))
        if lastCameraMuted {
            shutdownEffectScenes()
        } else {
            restoreEffectScenes()
        }
    }
}

extension InMeetShareSceneType {
    func aggregateSceneType(state: AggSceneEvent.SwitchState) -> AggSceneEvent.Scene? {
        switch self {
        case .magicShare:
            return .magicShare(state)
        case .othersSharingScreen:
            return .sharedScreen(state)
        case .selfSharingScreen:
            return .selfShareScreen(state)
        case .shareScreenToFollow:
            return .shareScreenToFollow(state)
        case .whiteboard:
            return .whiteboard(state)
        default:
            return nil
        }
    }
}

extension InMeetPerfMonitor: InMeetShareDataListener, InMeetFollowListener {
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        if lastShareScene == newScene {
            return
        }
        if let scene = lastShareScene.shareSceneType.aggregateSceneType(state: .on) {
            AggregateTracker.leave(scene: scene)
        }
        if let scene = newScene.shareSceneType.aggregateSceneType(state: .on) {
            AggregateTracker.entry(scene: scene)
        }
        lastShareScene = newScene
    }

    func didUpdateFollowStatus(_ status: InMeetFollowViewModelStatus, oldValue: InMeetFollowViewModelStatus) {
        guard lastMSFollow != status else { return }
        let follow = status.aggDescription
        if follow.isEmpty {
            // 如果是 none，则表示退出 ms follow，需要退出上一次跟随场景
            AggregateTracker.leaveAll(scene: .magicShareFollow(follow))
        } else {
            AggregateTracker.entry(scene: .magicShareFollow(follow))
        }
        lastMSFollow = status
    }
}

extension InMeetPerfMonitor: PIPObserver {
    func pictureInPictureDidStart() {
        AggregateTracker.entry(scene: .pip(.on))
    }

    func pictureInPictureDidStop() {
        AggregateTracker.entry(scene: .pip(.off))
    }
}

extension InMeetPerfMonitor: InMeetSubtitleViewModelObserver {
    func didChangeTranslationOn(_ isTranslationOn: Bool) {
        guard lastSubtitle != isTranslationOn else { return }
        lastSubtitle = isTranslationOn
        AggregateTracker.entry(scene: .subtitle(isTranslationOn ? .on : .off))
    }
}

extension InMeetPerfMonitor: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isVoiceModeOn, lastVoiceMode != isOn {
            lastVoiceMode = isOn
            AggregateTracker.entry(scene: .voiceMode(isOn ? .on : .off))
        }
        if key == .isEcoModeOn, lastEcoMode != isOn {
            lastEcoMode = isOn
            AggregateTracker.entry(scene: .ecoMode(isOn ? .on : .off))
        }
    }
}

extension InMeetPerfMonitor: RouterListener {
    func didChangeWindowFloatingAfterAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        let windowState = windowState(floating: isFloating)
        AggregateTracker.entry(scene: .windowState(windowState))
    }
}

extension InMeetPerfMonitor: AppInfoObserver {
    func didChangedApplicationState(_ state: UIApplication.State) {
        let appState = appState(state: state)
        AggregateTracker.entry(scene: .appState(appState))
    }
}

extension InMeetPerfMonitor: InMeetRtcNetworkListener {
    func didChangeLocalNetworkStatus(_ status: RtcNetworkStatus,
                                     oldValue: RtcNetworkStatus,
                                     reason: InMeetRtcNetwork.NetworkStatusChangeReason)
    {
        guard lastNetworkQuality != status.networkQuality else { return }
        lastNetworkQuality = status.networkQuality
        AggregateTracker.entry(scene: .networkQuality(status.networkQuality.description))
    }
}

extension InMeetPerfMonitor: InMeetEffectListener {
    func didChangeEffectStatus(_ status: RtcCameraEffectStatus, oldStatus: RtcCameraEffectStatus) {
        guard lastEffectStatus != status, !lastCameraMuted else {
            // 摄像头关闭情况下，只记录最后的特效状态，待摄像头开启后，恢复特效场景
            lastEffectStatus = status
            return
        }
        // 当前开启的特效类型
        let virtualBg = status.contains(.virtualbg)
        let animoji = status.contains(.animoji)
        let filter = status.contains(.filter)
        let retuschieren = status.contains(.retuschieren)
        // 上次开启的特效类型
        let lastVirtualBg = lastEffectStatus.contains(.virtualbg)
        let lastAnimoji = lastEffectStatus.contains(.animoji)
        let lastFilter = lastEffectStatus.contains(.filter)
        let lastRetuschieren = lastEffectStatus.contains(.retuschieren)

        lastEffectStatus = status
        // 虚拟背景
        let virtualBgState = RtcCameraEffectStatus.virtualbg.aggDescription
        if virtualBg && !lastVirtualBg {
            AggregateTracker.entry(scene: .effect(virtualBgState))
        }
        if !virtualBg && lastVirtualBg {
            AggregateTracker.leave(scene: .effect(virtualBgState))
        }
        // animoji
        let animojiState = RtcCameraEffectStatus.animoji.aggDescription
        if animoji && !lastAnimoji {
            AggregateTracker.entry(scene: .effect(animojiState))
        }
        if !animoji && lastAnimoji {
            AggregateTracker.leave(scene: .effect(animojiState))
        }
        //  滤镜
        let filterState = RtcCameraEffectStatus.filter.aggDescription
        if filter && !lastFilter {
            AggregateTracker.entry(scene: .effect(filterState))
        }
        if !filter && lastFilter {
            AggregateTracker.leave(scene: .effect(filterState))
        }
        // 美颜
        let retuschierenState = RtcCameraEffectStatus.retuschieren.aggDescription
        if retuschieren && !lastRetuschieren {
            AggregateTracker.entry(scene: .effect(retuschierenState))
        }
        if !retuschieren && lastRetuschieren {
            AggregateTracker.leave(scene: .effect(retuschierenState))
        }
    }

    private func restoreEffectScenes() {
        guard lastEffectStatus.rawValue != 0, !lastCameraMuted else { return }
        // 上次开启的特效类型
        let lastVirtualBg = lastEffectStatus.contains(.virtualbg)
        let lastAnimoji = lastEffectStatus.contains(.animoji)
        let lastFilter = lastEffectStatus.contains(.filter)
        let lastRetuschieren = lastEffectStatus.contains(.retuschieren)
        let virtualBgState = RtcCameraEffectStatus.virtualbg.aggDescription
        // 虚拟背景
        if lastVirtualBg {
            AggregateTracker.entry(scene: .effect(virtualBgState))
        }
        // animoji
        let animojiState = RtcCameraEffectStatus.animoji.aggDescription
        if lastAnimoji {
            AggregateTracker.entry(scene: .effect(animojiState))
        }
        //  滤镜
        let filterState = RtcCameraEffectStatus.filter.aggDescription
        if lastFilter {
            AggregateTracker.entry(scene: .effect(filterState))
        }
        // 美颜
        let retuschierenState = RtcCameraEffectStatus.retuschieren.aggDescription
        if lastRetuschieren {
            AggregateTracker.entry(scene: .effect(retuschierenState))
        }
    }

    private func shutdownEffectScenes() {
        guard lastCameraMuted else { return }
        AggregateTracker.leaveAll(scene: .effect(""))
    }
}

extension InMeetPerfMonitor: InMeetWebSpaceDataListener {
    func didChangeWebSpace(_ isShow: Bool) {
        guard lastWebSpace != isShow else { return }
        lastWebSpace = isShow
        AggregateTracker.entry(scene: .webSpace(isShow ? .on : .off))
    }
}

extension InMeetPerfMonitor: PerfAdjustorListener {
    func reportAdjustLevels(_ levels: [String: Int]) {
        sampleCollector?.lastPerfAdjustLevel = levels
    }
}

extension InMeetPerfMonitor: InMeetNotesDataListener {
    func didChangeNotesOn(_ isOn: Bool) {
        guard lastNotesOn != isOn else { return }
        lastNotesOn = isOn
        AggregateTracker.entry(scene: .notes(isOn ? .on : .off))
    }
}

/// 生成聚合埋点的 state 及 extra
extension InMeetPerfMonitor {
    private func cameraStateAndExtra(mute: Bool, front: Bool) -> (AggSceneEvent.SwitchState, String?) {
        let state: AggSceneEvent.SwitchState = mute ? .off : .on
        let extra: String? = state == .off ? nil : (front ? "front" : "back")
        return (state, extra)
    }

    private func windowState(floating: Bool) -> String {
        return floating ? "mini" : "full"
    }

    private func appState(state: UIApplication.State) -> String {
        return state == .background ? "background" : "foreground"
    }
}

extension InMeetPerfMonitor: InMeetMeetingListener {
    func willReleaseInMeetMeeting(_ meeting: InMeetMeeting) {
        reportAggScenesWhenEnded()
        if #available(iOS 12.0, *) {
            stopCellularMonitor()
        }
    }

    private func reportAggScenesWhenEnded() {
        guard meeting.setting.perfSampleConfig.enabled, sampleCollector?.isExecuting ?? false else {
            return
        }
        self.sampleCollector?.stop()
        self.sampleCollector?.reportAggTrack()
    }
}

extension InMeetPerfMonitor {
    /// 获取系统 CPU 核心数信息
    ///
    /// 详细请戳 https://developer.apple.com/documentation/kernel/1387446-sysctlbyname/determining_system_capabilities
    /// - Returns: CpuCoreInfo
    static func getCpuCoreInfo() -> CpuCoreInfo? {
        guard Self.cpuCoreInfo == nil else {
            return Self.cpuCoreInfo
        }
        var typeCount = 0
        var typeSize = MemoryLayout.size(ofValue: typeCount)
        var ret = sysctlbyname("hw.nperflevels", &typeCount, &typeSize, nil, 0)
        if ret == -1 {
            return nil
        }
        var logicalCpuCnt = 0
        var logicalCpuSize = MemoryLayout.size(ofValue: logicalCpuCnt)
        ret = sysctlbyname("hw.logicalcpu_max", &logicalCpuCnt, &logicalCpuSize, nil, 0)
        if ret == -1 || logicalCpuCnt == 0 {
            return nil
        }
        var perfLevels = [Int: Int]()
        for i in 0 ..< typeCount {
            var logicalCount = 0
            var logicalSize = MemoryLayout.size(ofValue: logicalCount)
            ret = sysctlbyname("hw.perflevel\(i).logicalcpu_max", &logicalCount, &logicalSize, nil, 0)
            if ret == -1 {
                continue
            }
            perfLevels[i] = logicalCount
        }
        let perfCount: Int
        if perfLevels.count > 1 {
            perfCount = perfLevels[0] ?? 0
        } else {
            perfCount = 0
        }
        // NOTE: 非 0 的都算作效能核，如果后续增加中核，需要及时更正
        let efficientCount = logicalCpuCnt - perfCount
        let info = CpuCoreInfo(coreCount: logicalCpuCnt, perfCount: perfCount, efficientCount: efficientCount, perfLevels: perfLevels)
        Self.cpuCoreInfo = info
        Self.logger.info("CPU Cores=\(info), perfCoreStartIndex=\(info.perfCoreStartIndex)")
        return info
    }
}

import Network

private var perfMonitorCellularKey: UInt8 = 0

/// 蜂窝网络基站变更
@available(iOS 12.0, *)
extension InMeetPerfMonitor {
    private var nwPathMonitor: NWPathMonitor? {
        get {
            objc_getAssociatedObject(self, &perfMonitorCellularKey) as? NWPathMonitor
        }
        set {
            objc_setAssociatedObject(self, &perfMonitorCellularKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private func startCellularMonitor() {
        guard nwPathMonitor == nil else { return }
        Self.logger.info("NWPathMonitor start")
        let monitor: NWPathMonitor
        if #available(iOS 14.0, *) {
            monitor = NWPathMonitor(requiredInterfaceType: .cellular)
        } else {
            monitor = NWPathMonitor()
        }
        monitor.pathUpdateHandler = { path in
            Self.logger.info("NWPathMonitor changed: \(path.debugDescription)")
            if path.availableInterfaces.contains(where: { $0.type == .cellular }) {
                AggregateTracker.entry(scene: .cellularSwitch)
            }
        }
        monitor.start(queue: DispatchQueue.global())
        nwPathMonitor = monitor
    }

    private func stopCellularMonitor() {
        guard let monitor = nwPathMonitor else {
            return
        }
        monitor.cancel()
        Self.logger.info("NWPathMonitor stop")
    }
}

/// 入会过程AppCPU收集与上报
extension InMeetPerfMonitor {

    private static var onthecallCPUs: [Float] = []
    // 系统每 1/8 秒采集一次CPU，因此采样频率需低于该值
    private static var onthecallCPUInterval: TimeInterval = 1 / 4
    private static var isEnteringOnthecall = false

    static func startCollectOnthecallCPUs() {
        isEnteringOnthecall = true
        onthecallCPUs.removeAll()
        collectCPU()
    }

    static func endCollectOnthecallCPUs() {
        isEnteringOnthecall = false
        reportOnthecallCPU()
    }

    private static func collectCPU() {
        guard isEnteringOnthecall, onthecallCPUs.count < 30, let coreCount = Self.getCpuCoreInfo()?.coreCount else {
            return
        }
        let appCPU = ByteViewThreadCPUUsage.appCPU() / Float(coreCount)
        onthecallCPUs.append(appCPU)
        DispatchQueue.global().asyncAfter(deadline: .now() + onthecallCPUInterval) {
            collectCPU()
        }
    }

    private static func reportOnthecallCPU() {
        guard !onthecallCPUs.isEmpty else {
            return
        }
        let avg = onthecallCPUs.reduce(0.0) { $0 + $1 } / Float(onthecallCPUs.count)
        let max = onthecallCPUs.max() ?? 0
        AladdinTracks.trackOnthecallCPU(appCPUAvg: avg, appCPUMax: max)
    }
}

protocol BatteyMonitor {
    func reportRealtimePower(level: Float, isPlugging: Bool, time: Double)
}

extension RtcCameraEffectStatus {
    var aggDescription: String {
        switch self {
        case .none:
            return "none"
        case .animoji:
            return "animoji"
        case .filter:
            return "filter"
        case .retuschieren:
            return "retuschieren"
        case .virtualbg:
            return "virtualBg"
        case .filterAndRetuschieren:
            return "filterAndRetuschieren"
        default:
            return "\(self.rawValue)"
        }
    }
}

extension ProcessInfo.ThermalState {
    var aggDescription: String {
        switch self {
        case .nominal:
            return "nominal"
        case .fair:
            return "fair"
        case .serious:
            return "serious"
        case .critical:
            return "critical"
        @unknown default:
            return "\(self.rawValue)"
        }
    }
}

extension InMeetFollowViewModelStatus {
    var aggDescription: String {
        switch self {
        case .free:
            return "free"
        case .following:
            return "following"
        case .sharing:
            return "sharing"
        case .shareScreenToFollow:
            return "shareScreenToFollow"
        case .none:
            return ""
        }
    }
}

private final class InMeetPerfCollector {
    let sampleConfig: InMeetPerfSampleConfig
    let batteryMonitor: BatteyMonitor?
    private var thread: Thread?

    private var reportPeriod: Int64 { sampleConfig.reportPeriod }
    private var threadCPUMonitorConfig: InMeetPerfSampleConfig.ThreadCPU { sampleConfig.threadCPU }
    private var coreCPUConfig: InMeetPerfSampleConfig.General { sampleConfig.coreCPU }
    private var rawCoreCPUConfig: InMeetPerfSampleConfig.General { sampleConfig.rawCoreCPU }
    private var batteryConfig: InMeetPerfSampleConfig.General { sampleConfig.battery }
    private var highLoadConfig: InMeetPerfSampleConfig.HighLoad { sampleConfig.highLoad }
    private var perfCoreStartIdx: Int {
        InMeetPerfMonitor.cpuCoreInfo?.perfCoreStartIndex ?? highLoadConfig.perfCoreStartIdx
    }

    private lazy var coreUsageCollector: CPUCoreUsagesCollector = {
        // 必须采集线程内初始化
        return CPUCoreUsagesCollector()
    }()
    private var coreUsages: [[Float]] = []
    private var coreCPUSampleTs: Int64 = 0
    private var battery: TrackParams = .init()
    private var threadUsages: [AggregateSubEvent] = []

    @RwAtomic var lastPerfAdjustLevel: [String: Int] = [:]
    /// 采样 seq
    @RwAtomic private var reportSampleSeq: Int = 0

    // p core 持续高负载进入时间戳
    @RwAtomic private var pCoreProlongEntryTs: Int64 = 0
    // p core 持续高负载退出时间戳
    @RwAtomic private var pCoreProlongLeaveTs: Int64 = 0
    // e core 持续高负载进入时间戳
    @RwAtomic private var eCoreProlongEntryTs: Int64 = 0
    // e core 持续高负载退出时间戳
    @RwAtomic private var eCoreProlongLeaveTs: Int64 = 0

    // 高负载尖刺，p core
    @RwAtomic private var pCorePeak: CoreCpuHighLoadType = .none
    // 高负载尖刺，e core
    @RwAtomic private var eCorePeak: CoreCpuHighLoadType = .none
    // 高负载持续，p core
    @RwAtomic private var pCoreProlong: CoreCpuHighLoadType = .none
    // 高负载持续，e core
    @RwAtomic private var eCoreProlong: CoreCpuHighLoadType = .none

    init(sampleConfig: InMeetPerfSampleConfig, batteryMonitor: BatteyMonitor? = nil) {
        self.sampleConfig = sampleConfig
        self.batteryMonitor = batteryMonitor
    }

    var isExecuting: Bool {
        thread?.isExecuting ?? false
    }

    var isFinished: Bool {
        thread?.isFinished ?? true
    }

    var isStoped: Bool {
        thread?.isCancelled ?? true
    }

    @objc private func collect() {
        resetSampleProperties()
        reportAggTrackWhenEntryMeeting()
        // cpu core 占用率第一次采集返回 nil，需要提前采集初始化
        if coreCPUConfig.enabled {
            _ = coreUsageCollector.collect()
        }
        Logger.monitor.info("vc_monitor_thread started, thread_cpu_monitor_config: \(threadCPUMonitorConfig)")
        var scheduledCnt: Int64 = 0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if Thread.current.isCancelled {
                Logger.monitor.info("vc_monitor_thread stopped")
                timer.invalidate()
                CFRunLoopStop(CFRunLoopGetCurrent())
                return
            }
            scheduledCnt += 1
            if scheduledCnt % self.batteryConfig.period == 0 {
                self.collectBattery()
            }

            if scheduledCnt % self.coreCPUConfig.period == 0 {
                self.collectCPUCoreUsage()
            }

            if self.highLoadConfig.pCore.prolong.isValid,
               self.pCoreProlong == .prolongPerf,
               scheduledCnt % self.highLoadConfig.pCore.prolong.period == 0
            {
                self.collectThreadCPU(.prolongPerf)
            } else if self.highLoadConfig.eCore.prolong.isValid,
                      self.eCoreProlong == .prolongEfficient,
                      scheduledCnt % self.highLoadConfig.eCore.prolong.period == 0
            {
                self.collectThreadCPU(.prolongEfficient)
            }

            if scheduledCnt % self.reportPeriod == 0 {
                self.reportAggTrack()
            }
        }

        RunLoop.current.run(until: .distantFuture)
    }

    func start() {
        if thread == nil {
            thread = Thread(target: self, selector: #selector(collect), object: nil)
            thread?.name = "vc_monitor_thread"
        }
        guard isExecuting == false else { return }
        thread?.start()
    }

    func stop() {
        thread?.cancel()
        thread = nil
    }
}

extension InMeetPerfCollector {
    func resetSampleProperties() {
        self.lastPerfAdjustLevel.removeAll()
        self.coreUsages.removeAll()
        self.coreCPUSampleTs = 0
        self.threadUsages.removeAll()
        self.reportSampleSeq = 0
        self.pCorePeak = .none
        self.eCorePeak = .none
        self.pCoreProlong = .none
        self.eCoreProlong = .none
        self.pCoreProlongEntryTs = 0
        self.pCoreProlongLeaveTs = 0
        self.eCoreProlongEntryTs = 0
        self.eCoreProlongLeaveTs = 0
    }

    func collectCPUCoreUsage() {
        guard coreCPUConfig.enabled else { return }
        assert(Thread.current == self.thread)
        if coreCPUSampleTs == 0 {
            coreCPUSampleTs = TrackCommonParams.clientNtpTime
        }
        let collectTs = Int64(Date().timeIntervalSince1970)
        if let item = coreUsageCollector.collect() {
            coreUsages.append(item)
            checkCoreCPUHighLoad(usages: item, ts: collectTs)
        }
    }

    func collectBattery() {
        guard batteryConfig.enabled, UIDevice.current.isBatteryMonitoringEnabled else { return }
        assert(Thread.current == self.thread)
        let power = UIDevice.current.batteryLevel
        let charging = UIDevice.current.batteryState != .unplugged
        var params: TrackParams = .init(self.lastPerfAdjustLevel)
        params["power"] = power
        params["is_charging"] = charging ? 1 : 0
        AladdinTracks.trackPower(params)
        battery = params
        CommonReciableTracker.trackRealtimePower(level: power, isPlugging: charging)
        batteryMonitor?.reportRealtimePower(level: power, isPlugging: charging, time: Date().timeIntervalSince1970)
    }

    func collectThreadCPU(_ source: CoreCpuHighLoadType? = nil) {
        let threadBizEnabled = sampleConfig.threadCPU.enableBizHook
        // 尖刺、持续高负载，采集 TopN 线程 CPU
        let pCoreEnabled = self.pCorePeak.isValidPeak || self.pCoreProlong.isValidProlong
        let eCoreEnabled = self.eCorePeak.isValidPeak || self.eCoreProlong.isValidProlong
        guard pCoreEnabled || eCoreEnabled else {
            return
        }
        assert(Thread.current == self.thread)
        var from: CoreCpuHighLoadType?
        if let source {
            from = source
        } else {
            let prolongPerf = self.pCoreProlong == .prolongPerf
            let prolongEfficient = self.eCoreProlong == .prolongEfficient
            from = prolongPerf ? .prolongPerf : (prolongEfficient ? .prolongEfficient : nil)
        }
        let ntpTime = TrackCommonParams.clientNtpTime
        var appCPU: CGFloat = 0
        var rtcCPU: CGFloat = 0
        let usages = ByteViewThreadCPUUsage.threadCPUUsagesTopN(threadCPUMonitorConfig.topN,
                                                                threadThreshold: CGFloat(threadCPUMonitorConfig.threshold),
                                                                rtcCPU: &rtcCPU,
                                                                appCPU: &appCPU)
        Logger.monitor.info("source: \(from?.rawValue ?? ""), app_cpu: \(String(format: "%.4f", appCPU)), rtc_cpu: \(String(format: "%.4f", threadBizEnabled ? rtcCPU : -1.0)), thread_usages: \(usages)")
        if var params = AladdinTracks.trackThreadUsages(appCPU: Float(appCPU),
                                                        rtcCPU: threadBizEnabled ? Float(rtcCPU) : nil,
                                                        threadUsages: usages,
                                                        source: from?.rawValue)
        {
            params["ntp_time"] = ntpTime
            let event = AggregateSubEvent(
                name: .vc_perf_cpu_state_mobile_dev,
                params: params,
                time: ntpTime
            )
            threadUsages.append(event)
        }
    }

    func checkCoreCPUHighLoad(usages: [Float], ts: Int64) {
        let validPerfCoreIdx = CPUCoreUsagesCollector.canSampleHighLoad(pCoreIdx: perfCoreStartIdx)
        guard validPerfCoreIdx, usages.count > perfCoreStartIdx else { return }
        // p core
        let pUsages = usages[perfCoreStartIdx...]
        let pSum: Float = pUsages.reduce(0.0) { $0 + $1 }
        let pAvg = pSum / Float(pUsages.count)
        // e core
        let eUsages = usages[..<perfCoreStartIdx]
        let eSum: Float = eUsages.reduce(0.0) { $0 + $1 }
        let eAvg = eSum / Float(eUsages.count)
        if !checkCoreCPUProlong(pAvg: pAvg, eAvg: eAvg, ts: ts) {
            // 非高负载模式，检查峰值
            checkCoreCPUPeak(pAvg: pAvg, eAvg: eAvg)
        }
    }

    func checkCoreCPUPeak(pAvg: Float, eAvg: Float) {
        if highLoadConfig.pCore.peak.enabled {
            self.pCorePeak = pAvg >= highLoadConfig.pCore.peak.value ? .peakPerf : .none
        } else {
            self.pCorePeak = .none
        }
        if self.pCorePeak == .peakPerf {
            let config = ["peak": highLoadConfig.pCore.peak.value]
            let sampleMeta = AggSceneEvent.SampleMeta(config: config, value: pAvg)
            let scene = CoreCpuHighLoadType.peakPerf.rawValue
            AggregateTracker.entry(scene: .highLoad(scene), meta: sampleMeta)
            collectThreadCPU(.peakPerf)
            self.pCorePeak = .none
            AggregateTracker.leave(scene: .highLoad(scene))
            return
        }

        if highLoadConfig.eCore.peak.enabled {
            self.eCorePeak = eAvg >= highLoadConfig.eCore.peak.value ? .peakEfficient : .none
        } else {
            self.eCorePeak = .none
        }
        if self.eCorePeak == .peakEfficient {
            let config = ["peak": highLoadConfig.eCore.peak.value]
            let sampleMeta = AggSceneEvent.SampleMeta(config: config, value: eAvg)
            let scene = CoreCpuHighLoadType.peakEfficient.rawValue
            AggregateTracker.entry(scene: .highLoad(scene), meta: sampleMeta)
            collectThreadCPU(.peakEfficient)
            self.eCorePeak = .none
            AggregateTracker.leave(scene: .highLoad(scene))
        }
    }

    func checkCoreCPUProlong(pAvg: Float, eAvg: Float, ts: Int64) -> Bool {
        if highLoadConfig.pCore.prolong.isValid {
            // 非高负载模式 LL，m: 4, n: 0.5, period: 2
            // 当前时间点: 01  - 03  - 05  - 07  - 09  - 11  - 13  - 15  - 17
            // 当前占用率: 0.4 - 0.5 - 0.5 - 0.4 - 0.6 - 0.7 - 0.5 - 0.6 - 0.8
            // 执行代码块: d   - a1  - a3  - d   - a1  - a3  - a2  - b   - b
            // 进入时间戳: 0   - 03  - /   - 0   - 09  - /   - /   - /   - /
            // 退出时间戳: /   - /   - /   - /   - /   - /   - 0   - 0   - 0
            // 持续时间差: /   - /   - 2   - /   - /   - 2   - 4   - /   - /
            // 负载模式值: LL  - LL  - LL  - LL  - LL  - LL  - HL  - HL  - HL
            // =========================================================
            // 高负载模式 HL，m: 4, n: 0.5, period: 2
            // 当前时间点: 19  - 21  - 23  - 25  - 27  - 29  - 31  - 33  - 35
            // 当前占用率: 0.5 - 0.4 - 0.3 - 0.5 - 0.3 - 0.4 - 0.4 - 0.2 - 0.3
            // 执行代码块: b   - c1  - c3  - b   - c1  - c3  - c2  - d   - d
            // 进入时间戳: /   - /   - /   - /   - /   - /   - 0   - 0   - 0
            // 退出时间戳: 0   - 21  - 23  - 0   - 27  - /   - /   - /   - /
            // 持续时间差: /   - /   - 2   - /   - /   - 2   - 4   - /   - /
            // 负载模式值: HL  - HL  - HL  - HL  - HL  - HL  - LL  - LL  - LL
            let pValue = highLoadConfig.pCore.prolong.value
            let pThreshold = highLoadConfig.pCore.prolong.threshold
            if pAvg >= pValue, self.pCoreProlong != .prolongPerf {
                // a.非高负载模式，持续 m 秒，使用率大于等于 n，进入高负载
                if self.pCoreProlongEntryTs == 0 {
                    // a1.记录进入时间戳
                    self.pCoreProlongEntryTs = ts
                } else if self.pCoreProlongEntryTs > 0, ts - self.pCoreProlongEntryTs >= pThreshold {
                    // a2.进入高负载模式，重置退出时间戳
                    self.pCoreProlong = .prolongPerf
                    self.pCoreProlongLeaveTs = 0
                    let scene = CoreCpuHighLoadType.prolongPerf.rawValue
                    let config: [String: Any] = [
                        "threshold": pThreshold,
                        "value": pValue
                    ]
                    let sampleMeta = AggSceneEvent.SampleMeta(config: config, value: pAvg)
                    AggregateTracker.entry(scene: .highLoad(scene), meta: sampleMeta)
                }
                // a3.do nothing
            } else if pAvg >= pValue, self.pCoreProlong == .prolongPerf {
                // b.高负载模式下，使用率大于等于 n，重置退出时间戳
                self.pCoreProlongLeaveTs = 0
            } else if pAvg < pValue, self.pCoreProlong == .prolongPerf {
                if self.pCoreProlongLeaveTs == 0 {
                    // c1.高负载模式下，使用率小于 n，记录退出时间戳
                    self.pCoreProlongLeaveTs = ts
                } else if self.pCoreProlongLeaveTs > 0, ts - self.pCoreProlongLeaveTs >= pThreshold {
                    // c2.持续 m 秒低于阈值，退出高负载模式，重置进入时间戳
                    self.pCoreProlongEntryTs = 0
                    self.pCoreProlong = .none
                    let scene = CoreCpuHighLoadType.prolongPerf.rawValue
                    AggregateTracker.leave(scene: .highLoad(scene))
                }
                // c3.do nothing
            } else if pAvg < pValue, self.pCoreProlong != .prolongPerf {
                // d.非高负载模式，未达到阈值，重置进入高负载时间戳
                self.pCoreProlongEntryTs = 0
            }
        } else {
            self.pCoreProlongEntryTs = 0
            self.pCoreProlongLeaveTs = 0
            self.pCoreProlong = .none
        }

        if highLoadConfig.eCore.prolong.isValid {
            let eValue = highLoadConfig.eCore.prolong.value
            let eThreshold = highLoadConfig.eCore.prolong.threshold
            if eAvg >= eValue, self.eCoreProlong != .prolongEfficient {
                if self.eCoreProlongEntryTs == 0 {
                    self.eCoreProlongEntryTs = ts
                } else if self.eCoreProlongEntryTs > 0, ts - self.eCoreProlongEntryTs >= eThreshold {
                    self.eCoreProlong = .prolongEfficient
                    self.eCoreProlongLeaveTs = 0
                    let scene = CoreCpuHighLoadType.prolongEfficient.rawValue
                    let config: [String: Any] = [
                        "threshold": eThreshold,
                        "value": eValue
                    ]
                    let sampleMeta = AggSceneEvent.SampleMeta(config: config, value: eAvg)
                    AggregateTracker.entry(scene: .highLoad(scene), meta: sampleMeta)
                }
            } else if eAvg >= eValue, self.eCoreProlong == .prolongEfficient {
                self.eCoreProlongLeaveTs = 0
            } else if eAvg < eValue, self.eCoreProlong == .prolongEfficient {
                if self.eCoreProlongLeaveTs == 0 {
                    self.eCoreProlongLeaveTs = ts
                } else if self.eCoreProlongLeaveTs > 0, ts - self.eCoreProlongLeaveTs >= eThreshold {
                    self.eCoreProlongEntryTs = 0
                    self.eCoreProlong = .none
                    let scene = CoreCpuHighLoadType.prolongEfficient.rawValue
                    AggregateTracker.leave(scene: .highLoad(scene))
                }
            } else if eAvg < eValue, self.eCoreProlong != .prolongEfficient {
                self.eCoreProlongEntryTs = 0
            }
        } else {
            self.eCoreProlongEntryTs = 0
            self.eCoreProlongLeaveTs = 0
            self.eCoreProlong = .none
        }

        if self.pCoreProlong == .prolongPerf {
            return true
        } else if self.eCoreProlong == .prolongEfficient {
            return true
        }

        return false
    }

    func reportAggTrack() {
        defer {
            coreUsages.removeAll(keepingCapacity: true)
            coreCPUSampleTs = 0
            threadUsages.removeAll(keepingCapacity: true)
        }
        // 聚合线程 cpu
        let threadCPUs = threadUsages
        // 聚合核心 cpu 使用率
        var aggregatedRecords: [CPUCoreAggregatedRecord] = []
        // 新原始 core cpu 数据上报，就不上报老的聚合数据
        if !rawCoreCPUConfig.enabled {
            aggregatedRecords = CPUCoreAggregatedRecord.aggregate(cpuCoreUsages: coreUsages)
            Logger.monitor.info("cpu core agg usage \(aggregatedRecords)")
        }
        let coreCPUs = AladdinTracks.trackCoreUsages(aggregatedRecords)
        // 聚合整体开关开，才上报聚合埋点，否则还是单个指标埋点
        guard sampleConfig.enabled else {
            return
        }
        // 新埋点直接上报原始数据，不进行聚合
        var rawCoreCPUs: AggregateCoreCPUEvent?
        if rawCoreCPUConfig.enabled {
            rawCoreCPUs = AggregateCoreCPUEvent.coreCPUEvent(cpuCoreUsages: coreUsages,
                                                             ts: coreCPUSampleTs,
                                                             period: coreCPUConfig.period,
                                                             pCoreStartIdx: perfCoreStartIdx)
        }
        let ntpTime = TrackCommonParams.clientNtpTime
        self.reportSampleSeq += 1
        let seqID = self.reportSampleSeq
        let event = AggregateEvent(
            ntpTime: ntpTime,
            sampleSeq: seqID,
            coreCPUs: coreCPUs,
            rawCoreCPUs: rawCoreCPUs,
            threadCPUs: threadCPUs,
            battery: battery
        )
        AggregateTracker.trackEvent(event)
    }

    func reportAggTrackWhenEntryMeeting() {
        collectBattery()
        collectThreadCPU()
        reportAggTrack()
    }
}
