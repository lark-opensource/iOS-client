//
//  PrivacyMonitor.swift
//  LarkPrivacyMonitor
//
//  Created by huanzhengjie on 2022/9/27.
//

import TSPrivacyKit
import BDRuleEngine
import LarkSnCService
import ThreadSafeDataStructure

private let kHasAgreedPrivacyStorageKey = "has_agreed_privacy_storage_key"
/// 策略规则配置内置文件对应的 key 值
private let kRuleStrategyConfigBuildInKey = "rule_strategy_config"
/// Monitor SDK 初始化配置内置文件对应的 key 值
private let kMonitorSettingConfigBuildInKey = "monitor_setting_config"
/// 低端机 初始化配置内置文件名
private let kLowMachineMonitorSettingBuildInKey = "low_machine_monitor_setting"
/// Monitor SDK 内置文件压缩包的文件名，包含：rule_strategy_config、monitor_setting_config 两个内容
private let kMonitorSettingsZipKey = "monitor_settings"

private final class BundleFileReader {
    /// 读取内置文件的缓存
    private static var dictCache: [String: [String: Any]] = [:]
    
    /// 从Bundle读取配置文件
    static func readConfigFromBundle(forResource name: String, ofType ext: FileType, forKey key: String? = nil) throws -> [String: Any] {
        // 有缓存时从缓存中取数据
        if let key = key, let cachedDict = dictCache[name] {
            return (cachedDict[key] as? [String: Any]) ?? [:]
        }
        let dict = try Bundle.LPMBundle?.readFileToDictionary(forResource: name, ofType: ext) ?? [:]
        PrivacyMonitor.shared.logger?.info("PrivacyMonitor reads config file successfully.")
        
        // 当读取需要解压的文件时，缓存内容
        if let key = key {
            dictCache[name] = dict
            return dict[key] as? [String: Any] ?? [:]
        } else {
            return dict
        }
    }
}

private extension MonitorConfig {
    /// Monitor SDK 初始化参数
    func getSettings() -> [String: Any] {
        if PrivacyMonitor.shared.isLowMachineOrPrivateKA {
            var defaultSetting: [String: Any] = [:]
            do {
                defaultSetting = try BundleFileReader.readConfigFromBundle(forResource: kLowMachineMonitorSettingBuildInKey, ofType: .json)
            } catch {
                PrivacyMonitor.shared.logger?.error("Error when reading LowMachineOrPrivateKA config: \(error.localizedDescription)")
            }
            return defaultSetting
        }
        let remoteSetting = settings()
        guard let remoteSetting = remoteSetting, !remoteSetting.isEmpty else {
            var defaultSetting: [String: Any] = [:]
            do {
                defaultSetting = try BundleFileReader.readConfigFromBundle(forResource: kMonitorSettingsZipKey, ofType: .zip, forKey: kMonitorSettingConfigBuildInKey)
            } catch {
                PrivacyMonitor.shared.logger?.error("Error when reading kMonitorSettingConfigBuildInKey config: \(error.localizedDescription)")
            }
            return defaultSetting
        }
        return remoteSetting
    }
}

/// 隐私弹窗协议
public protocol MonitorPrivacy {
    /// 是否已经同意隐私弹窗
    func hasAgreedPrivacy() -> Bool
}

public final class PrivacyMonitor: NSObject {
    /// 单例
    public static let shared = PrivacyMonitor()
    /// 外部注入存储能力，用于缓存
    public var storage: Storage? {
        didSet {
            updateHasAgreedPrivacy()
        }
    }
    /// 输出log
    public var logger: Logger?
    /// 上报Slardar
    public var monitor: Monitor?
    /// 低端机 或 私有化场景 判断
    public var isLowMachineOrPrivateKA: Bool = false
    /// 隐私弹窗协议
    private var privacy: MonitorPrivacy?

    private var config: MonitorConfig?
    private var logEnabled: Bool = false
    private var consumer: Consumer?
    private var hasAgreedPrivacyCache: Bool = false
    private var hasShownFirstRender: Bool = false
    private let lock = NSLock()
    private var vcScene = SafeSet<String>()

    private override init() {
        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// 开启初始化逻辑
    public func start(withConfig config: MonitorConfig) {
        self.config = config
        // 1. 切面逻辑注入
        PNSServiceCenter.sharedInstance().bindClass(HostEnv.self, to: TSPKHostEnvProtocol.self)
        PNSServiceCenter.sharedInstance().bindClass(RuleEngineImpl.self, to: PNSRuleEngineProtocol.self)
        // 2. 注册规则引擎默认函数
        TSPKRuleEngineManager.sharedEngine().registerDefaultFunc()
        // 3. 注册自定义参数
        registerParameters()
        // 4. 注册策略引擎相关配置
        let provider = StrategyProvider(config: config)
        BDStrategyCenter.register(provider)
        BDStrategyCenter.setup(with: PrivacyMonitor.shared)
        BDREPrivacyCenter.registerExtensions()
        // 5. Monitor SDK 初始化
        TSPKMonitor.setMonitorConfig(config.getSettings())
        updateFrequencyRuleConfig()
        // 6. 数据上报切面
        consumer = Consumer(privacy: self)
        TSPKReporter.shared().add(consumer)
        // 7. 启动
        TSPKMonitor.start()
        if !isLowMachineOrPrivateKA {
            // 8. 音视频配对白名单
            setPairAllowList()
            // 9. 通知
            addObservers()
        }
    }

    ///  设置音视频配对白名单
    private func setPairAllowList() {
        TSPKMonitor.setContextBlock({ self.vcScene.getImmutableCopy() }, forApiType: TSPKPipelineAudioOfAudioOutput)
        TSPKMonitor.setContextBlock({ self.vcScene.getImmutableCopy() }, forApiType: TSPKPipelineAudioOfAVCaptureDevice)
        TSPKMonitor.setContextBlock({ self.vcScene.getImmutableCopy() }, forApiType: TSPKPipelineVideoOfAVCaptureDevice)
        TSPKMonitor.setContextBlock({ self.vcScene.getImmutableCopy() }, forApiType: TSPKPipelineAudioOfAVAudioSession)
        TSPKMonitor.setContextBlock({ self.vcScene.getImmutableCopy() }, forApiType: TSPKPipelineVideoOfAVCaptureSession)
        TSPKMonitor.setContextBlock({ self.vcScene.getImmutableCopy() }, forApiType: TSPKPipelineAudioOfAudioQueue)
    }

    /// 在Monitor初始化和privacyConfig赋值之间有一定gap，使用缓存状态值
    private func updateHasAgreedPrivacy() {
        hasAgreedPrivacyCache = (try? storage?.get(key: kHasAgreedPrivacyStorageKey)) ?? false
    }

    /// 频控降级配置
    public func updateFrequencyConfig(_ config: FrequencyConfig) {
        if !config.enabled() {
            return
        }
        let timeThreshold = config.timeThreshold()
        let countThreshold = config.countThreshold()
        logger?.info("PrivacyMonitor frequency limited enabled, timeThreshold \(timeThreshold), countThreshold \(countThreshold).")
        FrequencyLimitManager.shared.updateThreshold(timeThreshold: timeThreshold, countThreshold: countThreshold)
        // 注册自定义频控拦截器
        TSPKEntryManager.shared()?.registerCustomCanHandleBuilder { (model: TSPKAPIModel?) -> Bool in
            guard let apiMethod = model?.apiMethod else {
                return false
            }
            if FrequencyLimitManager.shared.limited(of: apiMethod) {
                self.printLog(withApiModel: model, event: nil, needReport: true)
                self.logger?.info("PrivacyMonitor frequency limited api \(apiMethod).")
                return false
            }
            return true
        }
    }

    private func updateFrequencyRuleConfig() {
        guard let settings = config?.getSettings(),
              let monitorConfig = settings["frequency_monitor_config"] as? [String: Any] else {
            return
        }
        FrequencyRuleManager.shared.updateConfig(monitorConfig)
        TSPKEventManager.registerSubsciber(FrequencyRuleSubscriber(), on: .accessEntryResult)
    }

    /// 日志配置
    public func updateLogConfig(_ config: LogConfig) {
        logEnabled = config.enabled()
        guard logEnabled else {
            return
        }
        logger?.info("PrivacyMonitor log enabled.")
        /// 注册敏感API调用切面逻辑
        TSPKEventManager.registerSubsciber(self, on: .accessEntryResult)
    }

    /// 上报缓存的数据
    public func uploadEventCacheAfterHasAgreedPrivacy() {
        consumer?.uploadEventCacheAfterHasAgreedPrivacy()
        // 此时已经同意隐私弹窗
        try? storage?.set(true, forKey: kHasAgreedPrivacyStorageKey)
        lock.lock()
        hasAgreedPrivacyCache = true
        lock.unlock()
    }

    /// 设置隐私弹窗协议
    public func configPrivacy(with privacy: MonitorPrivacy) {
        lock.lock()
        self.privacy = privacy
        hasAgreedPrivacyCache = privacy.hasAgreedPrivacy()
        lock.unlock()
    }

    /// 标记用户已经看到界面
    public func markHasShownFirstRender() {
        lock.lock()
        hasShownFirstRender = true
        lock.unlock()
    }

    private func getHasShownFirstRender() -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        return hasShownFirstRender
    }
}

extension PrivacyMonitor: MonitorPrivacy {
    /// 是否已经同意隐私弹窗
    public func hasAgreedPrivacy() -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        return hasAgreedPrivacyCache
    }
}

extension PrivacyMonitor {
    /// 注册自定义参数
    func registerParameters() {
        /// 注册隐私弹窗判断逻辑
        BDRuleParameterService.registerParameter(withKey: "has_agreed_privacy",
                                                 type: .numberOrBool) { (_) -> AnyObject in
            /// 存在多线程环境的调用
            return NSNumber(value: self.hasAgreedPrivacy())
        }

        /// 注册冷启动判断逻辑，以用户看到第一帧界面为准
        BDRuleParameterService.registerParameter(withKey: "has_shown_first_render",
                                                 type: .numberOrBool) { (_) -> AnyObject in
            /// 存在多线程环境的调用
            return NSNumber(value: self.getHasShownFirstRender())
        }

        /// 注册视频会议等白名单场景
        BDRuleParameterService.registerParameter(withKey: "is_in_meeting_or_chatting",
                                                 type: .numberOrBool) { (_) -> AnyObject in
            /// 存在多线程环境的调用
            return NSNumber(value: !self.vcScene.isEmpty)
        }
    }
}

extension PrivacyMonitor {
    /// 注册事件
    func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(addSceneRecord),
                                               name: NSNotification.Name("LarkEnterContext"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(removeSceneRecord),
                                               name: NSNotification.Name("LarkLeaveContext"),
                                               object: nil)
    }

    @objc
    func applicationWillEnterForeground(notification: NSNotification) {
        BDREPrivacyCenter.appWillEnterForeground()
    }

    @objc
    func applicationDidEnterBackground(notification: NSNotification) {
        BDREPrivacyCenter.appDidEnterBackground()
    }

    /// 收到VC开始会议通知，将会议加入vcScene
    @objc
    private func addSceneRecord(noti: Notification) {
        if let scene = noti.userInfo?["name"] as? String {
            _ = vcScene.insert(scene)
        }
    }

    @objc
    private func removeSceneRecord(noti: Notification) {
        if let scene = noti.userInfo?["name"] as? String {
            _ = vcScene.remove(scene)
        }
    }
}

extension PrivacyMonitor: BDRuleEngineDelegate {

    public func report(_ event: String, tags: [AnyHashable: Any], block: @escaping BDRuleEngineReportDataBlock) {
    }

    public func ruleEngineConfig() -> [AnyHashable: Any]? {
        let remoteConfig = config?.ruleEngineConfig()
        guard let remoteConfig = remoteConfig, !remoteConfig.isEmpty else {
            return ["enable_rule_engine": true]
        }
        return remoteConfig
    }
}

private final class Consumer: NSObject, TSPKConsumer {
    private var privacy: MonitorPrivacy
    private var uploadEventCaches: [TSPKUploadEvent] = []
    private let lock = NSLock()

    init(privacy: MonitorPrivacy) {
        self.privacy = privacy
        super.init()
    }

    func tag() -> String {
        return TSPKEventTagBadcase
    }

    /// 数据上报切面逻辑
    func consume(_ event: TSPKBaseEvent?) {
        let hasAgreedPrivacy = privacy.hasAgreedPrivacy()
        if hasAgreedPrivacy {
            return
        }
        // 背景：在隐私弹窗点击同意按钮前Slardar初始化任务不会执行（避免采集数据导致合规问题），导致监控的数据上报不上去。
        // 解决方案：在隐私弹窗同意前缓存上报数据，同意后再统一上报。
        guard let event = event as? TSPKUploadEvent else {
            return
        }
        // 多线程场景，加锁保证线程安全
        lock.lock()
        // 添加到缓存
        uploadEventCaches.append(event)
        lock.unlock()
    }

    /// 上报缓存的数据
    func uploadEventCacheAfterHasAgreedPrivacy() {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .seconds(3)) {
            self.lock.lock()
            // 上报缓存数据
            for uploadEvent in self.uploadEventCaches {
                TSPKReporter.shared().report(uploadEvent)
            }
            // 清理缓存数据
            self.uploadEventCaches.removeAll()
            self.lock.unlock()
        }
    }
}

private final class StrategyProvider: NSObject, BDStrategyProvider {

    private var config: MonitorConfig

    init(config: MonitorConfig) {
        self.config = config
        super.init()
    }

    func priority() -> Int {
        return 0
    }

    /// 策略规则
    func strategies() -> [AnyHashable: Any] {
        if PrivacyMonitor.shared.isLowMachineOrPrivateKA {
            return [:]
        }
        if let remoteStrategies = config.ruleStrategies(), !remoteStrategies.isEmpty {
            return remoteStrategies
        }
        var defaultStrategies: [String: Any]?
        do {
            defaultStrategies = try BundleFileReader.readConfigFromBundle(forResource: kMonitorSettingsZipKey, ofType: .zip, forKey: kRuleStrategyConfigBuildInKey)
        } catch {
            PrivacyMonitor.shared.logger?.info("Error when PrivacyMonitor get strategies: \(error.localizedDescription)")
        }
        return defaultStrategies ?? [:]
    }
}

private final class HostEnv: NSObject, TSPKHostEnvProtocol {

    func urlIfTopIsWebViewController() -> String? {
        return nil
    }

    func userRegion() -> String? {
        return nil
    }
}

/// 敏感API调用切面，收集调用信息
extension PrivacyMonitor: TSPKSubscriber {

    public func uniqueId() -> String {
        return "MonitorLogSubscriber"
    }

    public func canHandelEvent(_ event: TSPKEvent) -> Bool {
        return true
    }

    public func hanleEvent(_ event: TSPKEvent) -> TSPKHandleResult? {
        printLog(withApiModel: event.eventData?.apiModel, event: event)
        return nil
    }

    /// 输出调用日志
    private func printLog(withApiModel apiModel: TSPKAPIModel?,
                          event: TSPKEvent? = nil,
                          needReport: Bool = false) {
        guard logEnabled else {
            return
        }
        guard let apiModel = apiModel,
              let apiMethod = apiModel.apiMethod,
              let dataType = apiModel.dataType else {
              return
        }
        DispatchQueue.global().async {
            let appStatus = (event?.eventData?.appStatus) ?? ""
            let topPage = (event?.eventData?.topPageName) ?? ""
            self.logger?.info("PrivacyMonitor call api \(apiMethod) at page \(topPage), data type is \(dataType), app status is \(appStatus).")
            if needReport {
                self.monitor?.info(service: "api_frequency_limited_event",
                                   category: ["api_name": apiMethod,
                                              "data_type": dataType,
                                              "top_page": topPage,
                                              "app_status": appStatus])
            }
        }
    }
}
