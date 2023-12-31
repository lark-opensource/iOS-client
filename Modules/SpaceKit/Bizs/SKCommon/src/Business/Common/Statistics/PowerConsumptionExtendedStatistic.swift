//
//  PowerConsumptionExtendedStatistic.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/9/11.
//  


import Dispatch
import Foundation
import SKFoundation
import LarkMonitor
import LarkSetting
import LKCommonsTracker
import TTNetworkManager
import ThreadSafeDataStructure
import RxSwift

/// 5.23版本，功耗统计工具类-扩展场景
public final class PowerConsumptionExtendedStatistic {
    
    static let logPrefix = "==PowerConsumption=="
    
    private static let isCCMBiz = "isCCMScene" // Bool
    private static let timeStampKey = "ccm_timeStamp" // Int
    private static let startTimeKey = "ccm_startTime" // Int
    private static let endTimeKey = "ccm_endTime" // Int
    private static let startPowerKey = "ccm_startPower" // Float, 0.xx
    private static let endPowerKey = "ccm_endPower" // Float, 0.xx
    
    static let workQueue = DispatchQueue(label: "lark.ccm.power_consumption_statistic", qos: .background)
    
    /// 多个自定义场景的暂存，key 为 sceneId
    private static var sceneDict = ThreadSafeDictionary<String, CCMPowerLogSession>()
    
    private static var _powerlogConfig = SafeAtomic<[String: Any]?>(nil, with: .readWriteLock)
    private static var powerlogConfig: [String: Any] {
        if let value = _powerlogConfig.value { // 只计算一次,节约性能
            return value
        }
        let rawDict = (try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_powerlog_config"))) ?? [:]
        _powerlogConfig.value = rawDict
        return rawDict
    }
    
    private static var sceneCapacity: Int {
        let value: Int
        if let config = powerlogConfig["ccm_scene_config"] as? [String: Any],
           let count = config["capacity"] as? Int, count > 0 {
            value = count
        } else {
            value = 100 // 本地兜底值
        }
        return value
    }
    /// 场景采样间隔
    private static var sampleIntervals = [String: Int]()
    
    private static var _cachedCommonParams = [String: Any]() // 缓存起来的所有场景的公用参数,访问时需要保证线程安全
    static var _isJSMonitorFeatureEnabled = SafeAtomic<Bool?>(nil, with: .readWriteLock)
    
    static var jsbCallDict = ThreadSafeDictionary<String, JSBCallLogger>()
    public weak var docsMSContext: DocsPowerLogMagicShareContext?
    /// MS降级的rust监听
    var degradeRustObservation: Disposable?
    /// MS降级的rust监听处理者们
    var msDegradeHandlers = ObserverContainer<MSDegradeRustPushHandler>()
    
    public static let shared = PowerConsumptionExtendedStatistic()
    
    public private(set) var isForeground = true
    
    private init() {
        setupNotification()
        refreshAppState()
        setupRustObservation()
    }
}

extension PowerConsumptionExtendedStatistic {
    
    enum ReportEvent: String {
        case jsbCall = "wb_lark_webview_bridge_call"
        case jsbFreq = "wb_lark_webview_ccmbridge_freq"
        case consumption = "ccm_powerlog_consumption"
        case thermalstate = "ccm_powerlog_thermalstate"
        
        var teaEvent: String { rawValue + "_dev" }
    }
    
    private static func getCurrentSessions(size: Int = 10) -> [CCMPowerLogSession] {
        var sessions = [CCMPowerLogSession]()
        sceneDict.enumerateObjectUsingBlock { (_, value) in
            sessions.append(value)
        }
        let result = Array(sessions.prefix(size))
        return result
    }
}

extension PowerConsumptionExtendedStatistic { // MARK: 自定义场景
    
    private class func isFeatureEnabled() -> Bool {
        let value: Bool
        if let enabled = powerlogConfig["monitor_enabled"] as? Bool { // 优先使用settings中的配置
            value = enabled
        } else {
            value = LKFeatureGating.performanceMonitorEnabled // 兜底使用FG中的配置
        }
        return value
    }
    
    public class func markStart(scene: PowerConsumptionStatisticScene) {
        workQueue.async {
            _markStart(scene: scene)
        }
    }
    
    private class func _markStart(scene: PowerConsumptionStatisticScene) {
        
        guard isFeatureEnabled() else { return }
        
        let config = BDPowerLogSessionConfig()
        let sampleInterval = getSampleInterval(scene: scene)
        config.dataCollectInterval = Int32(sampleInterval)
        let session = BDPowerLogManager.beginSession(scene.name, config: config)
        session.autoUpload = true
        session.logInfoCallback = { (logInfo, extra) in
            Self.checkPowerConsumptionSpeed(info: logInfo, scene: scene)
        }
        let ccmSession = CCMPowerLogSession(identifier: scene.identifier, larkSession: session)
        var customFilter = [String: Any]()
        customFilter[isCCMBiz] = true
        customFilter[startTimeKey] = ccmSession.ccmStartTime
        customFilter[startPowerKey] = UIDevice.current.batteryLevel
        session.addCustomFilter(customFilter)
        _doAddSession(ccmSession, for: scene.identifier)
        _setCommonParamsFor(scene: scene)
        
        DocsLogger.info("\(Self.logPrefix) start scene: \(scene.name)")
    }
    
    public class func updateParams(_ value: Any, forKey: String, scene: PowerConsumptionStatisticScene) {
        workQueue.async {
            _updateParams([forKey: value], scene: scene)
        }
    }
    
    public class func updateParams(_ params: [String: Any], scene: PowerConsumptionStatisticScene) {
        workQueue.async {
            _updateParams(params, scene: scene)
        }
    }
    
    private class func _updateParams(_ params: [String: Any], scene: PowerConsumptionStatisticScene) {
        
        guard isFeatureEnabled() else { return }
        
        if let session = sceneDict.value(ofKey: scene.identifier) {
            session.addCustomFilter(params)
        } else {
            DocsLogger.info("updateParams, can NOT find PowerLogSession")
        }
    }
    
    public class func markEnd(scene: PowerConsumptionStatisticScene) {
        workQueue.async {
            _markEnd(scene: scene)
        }
    }
    
    private class func _markEnd(scene: PowerConsumptionStatisticScene) {
        
        guard isFeatureEnabled() else { return }
        
        if let session = sceneDict.value(ofKey: scene.identifier) {
            var customFilter = [String: Any]()
            customFilter[endTimeKey] = Int(CFAbsoluteTimeGetCurrent())
            customFilter[endPowerKey] = UIDevice.current.batteryLevel
            session.addCustomFilter(customFilter)
            session.end()
            sceneDict.removeValue(forKey: scene.identifier)
            _setCommonParamsFor(scene: scene)
            _clearUnfinishedScene(endingScene: scene)
            DocsLogger.info("\(Self.logPrefix) end scene: \(scene.name)")
        } else {
            DocsLogger.info("markEnd, can NOT find PowerLogSession for: \(scene.name)")
        }
    }
}

extension PowerConsumptionExtendedStatistic { // MARK: 自定义事件
    
    public class func addEvent(name: String, params: [String: Any]?) {
        workQueue.async {
            _addEvent(name: name, params: params)
        }
    }
    
    private class func _addEvent(name: String, params: [String: Any]?) {
        
        guard isFeatureEnabled() else { return }
        
        var newParams = params ?? [:]
        newParams.merge(other: [timeStampKey: Int(CFAbsoluteTimeGetCurrent())])
        BDPowerLogManager.addEvent(name, params: newParams)
        
        DocsLogger.info("\(Self.logPrefix) add event: \(name), params: \(newParams))")
    }
}

private extension PowerConsumptionExtendedStatistic { // MARK: 额外处理
    
    /// 场景结束时主动清理掉还存在的scroll场景，避免未按预期被end的scroll场景一直留在字典中
    class func _clearUnfinishedScene(endingScene: PowerConsumptionStatisticScene) {
        
        guard isFeatureEnabled() else { return }
        guard endingScene.isViewScene() else { return }
        
        var scrollSessions = [CCMPowerLogSession]()
        sceneDict.enumerateObjectUsingBlock { (key, value) in
            if PowerConsumptionStatisticScene.isScrollScene(key) {
                scrollSessions.append(value)
            }
        }
        for session in scrollSessions {
            session.end()
            sceneDict.removeValue(forKey: session.identifier)
        }
    }
    
    class func _doAddSession(_ session: CCMPowerLogSession, for key: String) {
        let currentCount = sceneDict.count()
        if currentCount > sceneCapacity {
            var sessions = [CCMPowerLogSession]()
            sceneDict.enumerateObjectUsingBlock { (_, value) in
                sessions.append(value)
            }
            sessions.sort { (session1, session2) -> Bool in
                session1.ccmStartTime < session2.ccmStartTime
            }
            let olderHalfSessions = sessions.prefix(sceneCapacity / 2) // 开始时间更早的一半sessions
            for session in olderHalfSessions {
                session.end()
                sceneDict.removeValue(forKey: session.identifier)
            }
            DocsLogger.info("\(Self.logPrefix) old count: \(currentCount), capacity:\(sceneCapacity)")
        }
        if let oldSession = sceneDict.value(ofKey: key) { // scene的identifier与视图id无关时，避免旧的scene未结束
            oldSession.end()
        }
        sceneDict.updateValue(session, forKey: key)
    }
    
    private class func _setCommonParamsFor(scene: PowerConsumptionStatisticScene) {
        var params = [String: Any]()
        params[PowerConsumptionStatisticParamKey.isForeground] = shared.isForeground
        
        // 只需计算一次
        if _cachedCommonParams["jsBatchLogEnabled"] == nil {
            _cachedCommonParams["jsBatchLogEnabled"] = UserScopeNoChangeFG.CS.jsBatchLogEnabled
        }
        if _cachedCommonParams["cpuDowngradeEnabled"] == nil {
            _cachedCommonParams["cpuDowngradeEnabled"] = UserScopeNoChangeFG.CS.powerOptimizeDowngradeEnabled
        }
        if _cachedCommonParams["jsbDispatchOptimization"] == nil {
            _cachedCommonParams["jsbDispatchOptimization"] = UserScopeNoChangeFG.CS.jsbDispatchOptimizationEnabled
        }
        if _cachedCommonParams["rn_log_sample_rate"] == nil {
            let config = powerlogConfig["rn_config"] as? [String: Any]
            let rate = config?["log_sample_rate"] as? Double
            _cachedCommonParams["rn_log_sample_rate"] = rate
        }
        if _cachedCommonParams[PowerConsumptionStatisticParamKey.fepkgVersion] == nil {
            let info = DocsSDK.getCurUsingPkgInfo()
            _cachedCommonParams[PowerConsumptionStatisticParamKey.fepkgVersion] = info.version
            _cachedCommonParams[PowerConsumptionStatisticParamKey.fepkgIsSlim] = info.isSlim
        }
        
        params.merge(other: _cachedCommonParams)
        _updateParams(params, scene: scene)
    }
    
    class func getSampleInterval(scene: PowerConsumptionStatisticScene) -> Int {
        let sampleConfig = (powerlogConfig["ccm_sample_config"] as? [String: Any]) ?? [:]
        let defaultSampleInterval = (sampleConfig["default_sample_interval"] as? Int) ?? 20 //默认采样间隔(秒)
        let sessionConfigs = (sampleConfig["sessions"] as? [[String: Any]]) ?? []
        if sampleIntervals.isEmpty {
            for config in sessionConfigs {
                let sessionName = (config["session_name"] as? String) ?? ""
                let interval = (config["sample_interval"] as? Int) ?? defaultSampleInterval //指定采样间隔(秒)
                sampleIntervals[sessionName] = interval
            }
        }
        let interval = sampleIntervals[scene.name] ?? defaultSampleInterval
        return interval
    }
}

extension PowerConsumptionExtendedStatistic {
    // TTNet网络质量等级
    public static var ttNetworkQualityRawValue: Int {
        TTNetworkManager.shareInstance().getEffectiveConnectionType().rawValue
    }
}

private extension PowerConsumptionExtendedStatistic { // MARK: 异常情况监控
    
    func setupNotification() {
        let name1 = ProcessInfo.thermalStateDidChangeNotification
        NotificationCenter.default.addObserver(self, selector: #selector(onThermalStateChange), name: name1, object: nil)
        let name2 = UIApplication.didEnterBackgroundNotification
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAppState), name: name2, object: nil)
        let name3 = UIApplication.willEnterForegroundNotification
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAppState), name: name3, object: nil)
        let name4 = Notification.Name(rawValue: "byteview.didChangeClientMutex")
        NotificationCenter.default.addObserver(self, selector: #selector(onVCMutexChanged), name: name4, object: nil)
    }
    
    @objc
    private func onThermalStateChange() {
        
        guard Self.isFeatureEnabled() else { return }
        
        Self.workQueue.async {
            self._handleThermalStateChange()
        }
    }
    
    private func _handleThermalStateChange() {
        let state = ProcessInfo.processInfo.thermalState
        let sessions = Self.getCurrentSessions()
        let sessionIds: String = sessions.map { $0.identifier }.joined(separator: ", ")
        let sessionNames: String = Set(sessions.map { $0.sessionName }).description
        let parameters: [String: Any] = ["thermal_state": state.rawValue,
                                         "session_types": sessionNames,
                                         "current_sessions": sessionIds]
        let event = SlardarEvent(name: ReportEvent.thermalstate.rawValue,
                                 metric: [:],
                                 category: parameters,
                                 extra: [:])
        Tracker.post(event)
        
        DocsTracker.newLog(event: ReportEvent.thermalstate.teaEvent, parameters: parameters) // Tea埋点
        
        DocsLogger.info("\(Self.logPrefix) thermal state changed => \(state)")
    }
    
    class func checkPowerConsumptionSpeed(info: [AnyHashable: Any], scene: PowerConsumptionStatisticScene) {
        
        guard isFeatureEnabled() else { return }
        
        guard let startTime = info[startTimeKey] as? Int else { return }
        guard let startPower = info[startPowerKey] as? Float else { return }
        guard let endTime = info[endTimeKey] as? Int else { return }
        guard let endPower = info[endPowerKey] as? Float else { return }
        guard endTime > startTime, endPower <= startPower else { return }
        
        let powerLoss = startPower - endPower
        let duration = max(1, Float(endTime - startTime)) // 秒
        
        guard duration > 10, powerLoss > 0 else { return } // 过滤出有效数据
        
        let metric: [String: Any] = ["session_duration": duration, "battery_loss": powerLoss * 100]
        let event = SlardarEvent(name: ReportEvent.consumption.rawValue,
                                 metric: metric,
                                 category: ["session_name": scene.name],
                                 extra: [:])
        Tracker.post(event)
        
        var parameters = metric
        parameters.merge(other: ["session_name": scene.name])
        DocsTracker.newLog(event: ReportEvent.consumption.teaEvent, parameters: parameters) // Tea埋点
        
        DocsLogger.info("\(Self.logPrefix) consumption powerLoss: \(powerLoss), duration: \(duration)")
    }
    
    @objc
    private func refreshAppState() {
        DispatchQueue.main.async {
            self.isForeground = (UIApplication.shared.applicationState != .background)
        }
    }
    
    @objc
    private func onVCMutexChanged(_ noti: Notification) {
        let obj = String(describing: noti.object)
        let info = String(describing: noti.userInfo)
        let isVCRuning = (HostAppBridge.shared.call(GetVCRuningStatusService()) as? Bool) ?? false
        DocsLogger.info("did change VC client mutex, obj:\(obj), info:\(info), isVCRuning:\(isVCRuning)")
        if isVCRuning {
            Self.markStart(scene: .videoConference)
        } else {
            markEndMagicShare()
            Self.markEnd(scene: .videoConference)
        }
    }
}

private extension LKFeatureGating {
    
    /// 是否开启功耗监控
    @FeatureGating(key: "ccm.perf.monitor")
    static var performanceMonitorEnabled: Bool = false
}

class CCMPowerLogSession: NSObject {
    
    let identifier: String
    
    let ccmStartTime: Int
    
    private let larkSession: BDPowerLogSession
    
    var sessionName: String { larkSession.sessionName }
    
    init(identifier: String, larkSession: BDPowerLogSession) {
        self.identifier = identifier
        self.ccmStartTime = Int(CFAbsoluteTimeGetCurrent())
        self.larkSession = larkSession
    }
    
    func addCustomFilter(_ params: [AnyHashable: Any]) {
        larkSession.addCustomFilter(params)
    }
    
    func end() {
        BDPowerLogManager.end(larkSession)
    }
}
