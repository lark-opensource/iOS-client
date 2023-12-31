//
//  MonitorApplicationDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/12/4.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkFoundation
import AppContainer
import LKCommonsLogging
import LarkReleaseConfig
import LKCommonsTracker
import LarkTracker
import LarkAccountInterface
import LarkPerf
import RxSwift
import LKMetric
import BDABTestSDK
import RangersAppLog
import BDDataDecoratorTob
import RunloopTools
import LarkMonitor
import LarkContainer
import RustPB
import RustSDK
import Heimdallr
import LarkRustClient
import LarkAppConfig
import LarkSetting
import LarkKAFeatureSwitch
import LarkRustClientAssembly
import BootManager
import LarkEnv
import LarkFeatureGating
import LarkStorage
import BDFishhook

private let tracingId = UUID().uuidString
private let crashId: MetricID = -1

var globalTeaMonitorService: TeaMonitorService?

public final class MonitorApplicationDelegate: ApplicationDelegate {
    static public let config = Config(name: "Monitor", daemon: true)

    static let logger = Logger.log(MonitorApplicationDelegate.self, category: "Application.Monitor")

    static let aLogger = Logger.log(MonitorApplicationDelegate.self, category: "ALog.")

    private let disposeBag = DisposeBag()

    @Provider var trackService: TrackService // Global

    required public init(context: AppContext) {
    }

    func setupMonitor() {
        AppStartupMonitor.shared.start(key: .monitor)
        self.setupSlardar()
        self.setupTea()
        self.setupLogMonitor()
        AppStartupMonitor.shared.end(key: .monitor)
    }
    
    func setupLogMonitor() {
        if LarkLoggerMonitor.shared.setupSlardarLogMonitor() {
            Tracker.register(key: .slardar, tracker: SlardarLogMonitorService())
        }
        
        if LarkLoggerMonitor.shared.setupApplogMonitor() {
            Tracker.register(key: .tea, tracker: TeaLogMonitorService())
        }
    }

    func setupSlardar() {
        // 判断 slardar 是否需要使用私有化加密
        if !LarkKAFeatureSwitch.FeatureSwitch.share.bool(for: .ttSlardarOldCryption) {
            HMDNetworkInjector.sharedInstance().configEncryptBlock({ (data) -> Data? in
                guard let dataValue = data else { return data }
                return (dataValue as NSData).bd_dataByPrivateDecorated()
            })
        }
        //禁止国内云控回捞文件类型
        #if !OVERSEA
        HMDCloudCommandManager.sharedInstance()?.setIfForbidCloudCommand { model in
            if model?.type == "file"{
                return true
            } else {
                return false
            }
        }
        #endif
        let appConfiguration = ConfigurationManager.shared

        appConfiguration
            .envSignalV2
            .skip(1)
            .subscribe(onNext: { _ in
                Self.updateSlardarConfig(setup: false)
            }).disposed(by: disposeBag)
        LarkMonitor.addCrashDetectorCallBack {(record) in
            if let record = record {
                let time = record.timestamp
                let crashTime = Date(timeIntervalSince1970: time)
                MonitorApplicationDelegate.logger.error("crash time \(crashTime)")
                let params = [
                    "is_background": "\(record.isBackground)",
                    "crash_exception_name": record.crashExceptionName ?? "",
                    "crash_reason": record.crashReason ?? "",
                    "crash_type": "\(record.crashType.rawValue)",
                    "mach_crash_type": "\(record.machCrashType.rawValue)"
                ]
                LKMetric.log(domain: Root.unknown.domain, type: .business, id: crashId, params: params)
            }
        }
        Tracker.register(key: .slardar, tracker: SlardarMonitorService())
    }

    // Read remote setting || 读取远程配置
    private static func remoteSetting(for key: DomainKey, append path: String?) -> [String] {
        let hosts = DomainSettingManager.shared.currentSetting[key] ?? []

        guard let path = path else { return hosts }

        return hosts.compactMap {
            URL(string: "https://\($0)")?
                .appendingPathComponent(path)
                .absoluteString
        }
    }

    /// 读取域名配置
    /// - Parameters:
    ///   - fsKey: KA Feature Switch Config Key
    ///   - key: Remote domain key
    ///   - path: url path
    ///   - isKAOnly: The current value is only for KA.
    /// - Returns: 返回对应相应的配置
    private static func config(
        from fsKey: LarkKAFeatureSwitch.FeatureSwitch.ConfigKey,
        remote key: DomainKey,
        append path: String? = nil,
        isKAOnly: Bool = false
    ) -> [String] {

        // KA 优先使用FeatureSwitch
        if ReleaseConfig.isPrivateKA {
            let preference = LarkKAFeatureSwitch.FeatureSwitch.share.config(for: fsKey)
            return preference.isEmpty ? remoteSetting(for: key, append: path) : preference
        } else {
            return isKAOnly ? [] : remoteSetting(for: key, append: path)
        }
    }

    func setupTea() {
        let trackService = self.trackService
        let teaMonitorService = TeaMonitorService(trackService: trackService)
        globalTeaMonitorService = teaMonitorService

        trackService.setupTeaEndpointsURL(LarkKAFeatureSwitch.FeatureSwitch.share.config(for: .ttTeaEndpoints))

        Tracker.register(key: .tea, tracker: teaMonitorService)
        NewBootManager.shared.addSerialTask { [weak self] in
            pullGeneralSettings { globalTeaMonitorService?.updateFilterType(by: $1) }
            updateTeaDomain(self?.trackService)
        }
    }

    static func updateSlardarConfig(setup: Bool) {
        let configHost = config(from: .ttSlardarSettingDomain, remote: .ttSlardarSetting)
        let crashUploadHost = config(from: .ttSlardarExceptionDomain, remote: .ttSlardarException).first
        let exceptionUploadHost = crashUploadHost
        let userExceptionUploadHost = exceptionUploadHost
        let logHost = config(from: .ttSlardarLogDomain, remote: .ttSlardarReport).first

        #if DEBUG
        let groupId = "group.com.bytedance.ee.lark.yzj"
        #else
        let groupId = Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String ?? ""
        #endif

        let injectedInfo = HMDInjectedInfo.default()
        injectedInfo.appGroupID = groupId

        @Injected var passport: PassportService // Global
        if setup {
            let appId = ReleaseConfig.appIdForAligned
            let versionCode = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
            let updateVersionCode = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? ""
            let deviceType = LarkFoundation.Utils.machineType
            let osVersion = UIDevice.current.systemVersion
            let region = Locale.current.regionCode ?? "CN"

            var channel = ReleaseConfig.channelName
            // 上传Slardar时判断逻辑,非KA上报channelName,KA上报releaseChannel
            if ReleaseConfig.isKA {
                channel = ReleaseConfig.kaChannelForAligned
            }
            if KVPublic.FG.oomDetectorOpen.value() {
                channel = "oom_test"
            }
            if KVPublic.FG.spacePerformanceDetector.value() {
                channel = "space_performance_test"
            }
            let appName = "Lark"

            let deviceId = passport.deviceID
            // 在slardar注入租户维度能力，用于稳定性分析和上报配置
            // cailiang评估串的影响不大，不再专门做隔离..
            let user = passport.foregroundUser
            let userID = user?.userID ?? ""    //用于做slardar kdm报警监控
            let tenant = user?.tenant
            let tenantId = tenant?.tenantID ?? ""
            injectedInfo.setCustomFilterValue(tenantId, forKey: "tenant_id")
            injectedInfo.setCustomFilterValue(userID, forKey: "user_id")
            injectedInfo.commonParamsBlock = {
                return [
                    "app_id": appId,
                    "device_id": deviceId,
                    "version_code": versionCode,
                    "update_version_code": updateVersionCode,
                    "device_type": deviceType,
                    "app_name": appName,
                    "channel": channel,
                    "os_version": osVersion,
                    "device_platform": plaform,
                    "region": region,
                    "tenant_id": tenantId,
                    "user_id": userID
                ]
            }
            
            if UserDefaults.standard.bool(forKey: "optimize_hmd_power_enable") {
                injectedInfo.stopWriteToDiskWhenUnhit = true
                injectedInfo.enableLegacyDBOptimize = true
                lark_disableUITrackerRecords()
            }
            
            if UserDefaults.standard.bool(forKey: "messenger_ios_bdfishhook_patch_enable") {
                open_bdfishhook_patch()
            }
            
            LarkMonitor.setupMonitor(
                appId,
                appName: appName,
                channel: channel,
                deviceID: deviceId,
                userID: "",
                userName: "",
                crashUploadHost: crashUploadHost,
                exceptionUploadHost: exceptionUploadHost,
                userExceptionUploadHost: userExceptionUploadHost,
                performanceUploadHost: logHost,
                fileUploadHost: logHost,
                configHostArray: configHost
            )
        } else {
            LarkMonitor.updateCrashUploadHost(
                crashUploadHost,
                exceptionUploadHost: exceptionUploadHost,
                userExceptionUploadHost: userExceptionUploadHost,
                performanceUploadHost: logHost,
                fileUploadHost: logHost,
                configHostArray: configHost
            )
        }
    }

    static var plaform: String = {
        if LarkFoundation.Utils.isiOSAppOnMacSystem {
            return "mac"
        }
        if UIDevice.current.model.contains("iPhone") {
            return "iphone"
        }
        if UIDevice.current.model.contains("iPad") {
            return "ipad"
        }
        return "ios"
    }()

    static func setupAlog() {
        let alogPath = AbsPath.library + "alog"
        HMDLogWrapper.alogOpenDefault(alogPath.absoluteString, namePrefix: "BDALog")
        HMDLogWrapper.setAlogSetLogLevel(AlogAdaptorLogLevel.info)
        #if DEBUG
        HMDLogWrapper.alogSetConsoleLogOpen(true)
        #endif
        HMDLogUploader.sharedInstance().uploadAlogIfCrashed()
    }
    // swiftlint:enable function_body_length
}

/// LKCommonsTracker.Event
public typealias Event = LKCommonsTracker.Event

public final class TeaMonitorService: TrackerService {

    enum FilterType: Int {
        case none       /// no filter
        case filter     /// filter track event by rust API
        case filterAll  /// filter all track event
    }

    typealias KeyAndValue = (key: AnyHashable, value: Any)
    private let stringSemaphore = DispatchSemaphore(value: 1)
    private var unfairLock = os_unfair_lock_s()
    let trackService: TrackService
    fileprivate let queue = DispatchQueue(
        label: "lark.tea.abtest.update",
        qos: .background,
        autoreleaseFrequency: .inherit
    )
    fileprivate var absdkVersions: String?
    fileprivate static let logger = Logger.log(TeaMonitorService.self, category: "TeaMonitorService")
    @InjectedLazy private var rustService: LarkRustService // Global

    var filterType: FilterType = .none

    func updateFilterType(by filterStatus: Int) {
        if let type = FilterType(rawValue: filterStatus) {
            self.filterType = type
        }
    }

    public init(trackService: TrackService) {
        self.trackService = trackService
    }

    private func postEvent(_ event: Event, trackBlock: @escaping (String, _ userID: String?, _ category: String?, [String: Any]) -> Void) {
        let transform = { (result: [String: Any], info: KeyAndValue) -> [String: Any] in
            var result = result
            if let keyStr = info.key as? String {
                result[keyStr] = info.value
            } else {
                result["\(info.key)"] = info.value
            }
            return result
        }

        if let teaEvent = event as? TeaEvent {
            // 对md5AllowList的value进行加密
            self.md5EncryptionForTeaEvent(teaEvent)
            let params: [String: Any] = teaEvent.params.reduce([String: Any](), transform)
            #if DEBUG
            /// Check params is valid
            assert(JSONSerialization.isValidJSONObject(params))
            #endif
            // 埋点参数过滤
            if self.filterType == .filter {
                // params 全部删除 or 删除部分params返回为新的params
                //  - 全部删除 -> [:]
                //  - 删除多余参数 -> 应该上传的参数
                // params 没有变化, params返回nil
                //  - 没有变化 -> 过滤前传入的params
                // event 不在白名单，不上传, onSuccess方法不会被调用
                rustService.trackDataFilter(
                    event: teaEvent.name,
                    params: teaEvent.params.reduce([String: Any](), transform),
                    onSuccess: { newParams in
                        trackBlock(teaEvent.name, teaEvent.userID, teaEvent.category, newParams)
                    }
                )
            } else if self.filterType == .none {
                trackBlock(
                    teaEvent.name,
                    teaEvent.userID,
                    teaEvent.category,
                    teaEvent.params.reduce([String: Any](), transform)
                )
            }
        } else {
            assertionFailure("event should be TeaEvent")
        }
    }

    func transformToNSObject(value: Any) -> NSObject {

        func transformToNSNumber(value: Any) -> NSNumber? {
            if let number = value as? CChar {
                return NSNumber(value: number)
            } else if let number = value as? Int {
                return NSNumber(value: number)
            } else if let number = value as? UInt {
                return NSNumber(value: number)
            } else if let number = value as? UInt8 {
                return NSNumber(value: number)
            } else if let number = value as? Int16 {
                return NSNumber(value: number)
            } else if let number = value as? UInt16 {
                return NSNumber(value: number)
            } else if let number = value as? Int32 {
                return NSNumber(value: number)
            } else if let number = value as? UInt32 {
                return NSNumber(value: number)
            } else if let number = value as? Int64 {
                return NSNumber(value: number)
            } else if let number = value as? UInt64 {
                return NSNumber(value: number)
            } else if let number = value as? Float {
                return NSNumber(value: number)
            } else if let number = value as? CGFloat {
                return NSNumber(value: number)
            } else if let number = value as? Double {
                return NSNumber(value: number)
            } else if let number = value as? Bool {
                return NSNumber(value: number)
            }
            return nil
        }
        if let str = value as? String {
            // 给字符串加锁，防止多线程造成崩溃
            os_unfair_lock_lock(&unfairLock)
            defer {
                os_unfair_lock_unlock(&unfairLock)
            }
            return NSString(string: str)
        } else if let number = transformToNSNumber(value: value) {
            return number
        } else if let dic = value as? [AnyHashable: Any] {
            let mutableDic = NSMutableDictionary()
            for item in dic {
                let ocKey: NSCopying
                if let number = transformToNSNumber(value: item.key) {
                    ocKey = number
                } else if let string = item.key as? String {
                    ocKey = NSString(string: string)
                } else {
                    ocKey = NSString(string: "\(item.key)")
                    assertionFailure("can not judge key type, please message to kangsiwan@bytedance.com")
                }
                let ocValue = transformToNSObject(value: item.value)
                mutableDic.setObject(ocValue, forKey: ocKey)
            }
            return mutableDic
        } else if let array = value as? [Any] {
            let mutableArray = NSMutableArray()
            for item in array {
                let value = transformToNSObject(value: item)
                mutableArray.add(value)
            }
            return mutableArray
        // 递归解开option内的值
        } else if getOptionalValue(value: value) == nil {
            return NSString(string: "")
        } else if value is NSNull {
            return NSString(string: "")
        }
        // 待上报的数据类型应该是可以转为NSObject的
        // 当前支持NSNumber、NSString、NSMutableDictionary、NSMutableArray
        // 如果你的数据类型不能转为上述几种，请尽量修改他们，如果存疑请联系kangnsiwan@bytedance.com
        assertionFailure("can not judge value type, please message to kangnsiwan@bytedance.com")
        return NSString(string: "\(value)")
    }

    func transformToNSDictionary(dic: [String: Any]) -> [String: Any] {
        let mutableDic = NSMutableDictionary()
        for item in dic {
            let ocKey = NSString(string: item.key)
            let ocValue = transformToNSObject(value: item.value)
            mutableDic.setObject(ocValue, forKey: ocKey)
        }
        if let swiftDic = mutableDic as? [String: Any] {
            return swiftDic
        }
        return [:]
    }

    public func post(event: Event) {
        self.postEvent(event) { [weak self] (name, userID, category, params) in
            guard let self = self else { return }
            self.trackService.track(
                event: name,
                userID: userID,
                category: category,
                params: self.transformToNSDictionary(dic: params)
            )
        }
    }

    /// 对teaEvent中的字段进行加密
    /// - Parameter teaEvent: 待处理的teaEvent
    private func md5EncryptionForTeaEvent(_ teaEvent: TeaEvent) {
        if teaEvent.md5AllowList.isEmpty {
            return
        }
        /// 遍历数组进行加密
        for key in teaEvent.md5AllowList {
            let value = teaEvent.params[key]
            // 如果value存在且为String，进行加密
            if let encryptoId = value as? String {
                let encryptionStr = Encrypto.encryptoId(encryptoId)
                teaEvent.params.updateValue(encryptionStr, forKey: key)
            } else if let encryptoIdArray = value as? [String] {
                // 如果value存在且为String的数组，进行加密
                let encryptionStrArray = encryptoIdArray.map { (id) -> String in
                    Encrypto.encryptoId(id)
                }
                teaEvent.params.updateValue(encryptionStrArray, forKey: key)
            }
        }
    }

    // Any类型里可能是optional的，采用递归调用取出option内的值，因为可能有Int?或者Int??等类型
    private func getOptionalValue(value: Any) -> Any? {
        // 是否是Option类型
        if let optionA = value as? OptionProtocol {
            // 解开一层option
            if let optionB = optionA.wrapped {
                return getOptionalValue(value: optionB)
            }
            return nil
        }
        return value
    }
}

protocol OptionProtocol {
    var wrapped: Any? { get }
}

extension Optional: OptionProtocol {
    var wrapped: Any? {
        if let wrapped = self {
            return wrapped
        }
        return nil
    }
}

extension TeaMonitorService: ExternalABTestService {
    public var abVersions: String { trackService.abVersions }

    public var allAbVersions: String { trackService.allAbVersions }

    public var allABTestConfigs: [AnyHashable: Any] { trackService.allABTestConfigs }

    public func addPullABTestConfigObserve(observer: Any, selector: Selector) {
        trackService.addPullABTestConfigObserve(observer: observer, selector: selector)
    }

    public func abTestValue(key: String, defaultValue: Any) -> Any? {
        trackService.abTestValue(key: key, defaultValue: defaultValue)
    }

    public func setABSDKVersions(versions: String?) {
        trackService.setABSDKVersions(versions: versions)
    }

    public func commonABExpParams(appId: String) -> [AnyHashable: Any] {
        return trackService.commonABExpParams(appId: appId)
    }
}

extension TeaMonitorService: InternalABTestService {
    public func fetchAndSaveExperimentData(
        url: String,
        completionCallBack: @escaping (Error?, [AnyHashable: Any]?) -> Void
    ) {
        BDABTestManager.fetchExperimentData(
            withURL: url,
            maxRetryCount: 3,
            completionBlock: completionCallBack
        )
    }

    public func registerABExposureExperimentsObserve(
        observer: Any,
        selector: Selector
    ) {
        NotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: NSNotification.Name(rawValue: Tracker.LKExperimentDidExposured),
            object: nil
        )
    }

    public func registerFetchExperimentDataObserver(
        observer: Any,
        selector: Selector
    ) {
        NotificationCenter.default.addObserver(
            observer,
            selector: selector,
            name: NSNotification.Name(rawValue: Tracker.LKExperimentDataDidFetch),
            object: nil
        )
    }

    public var exposuredExperiments: String? { BDABTestManager.queryExposureExperiments() }

    public func experimentValue(key: String, shouldExposure: Bool) -> Any? {
        let value = BDABTestManager.getExperimentValue(forKey: key, withExposure: shouldExposure)
        TeaMonitorService.logger.info("ABTest.experimentValue >>> key: \(key) shouldExposure: \(shouldExposure)")
        if shouldExposure {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Tracker.LKExperimentDidExposured),
                                            object: nil,
                                            userInfo: ["value": value ?? ""])
            queue.async {
                /// Fix vid not being stored in time after exposure
                // lint:disable:next lark_storage_check
                UserDefaults.standard.synchronize()
                let newVids = self.exposuredExperiments
                if self.absdkVersions == newVids { return }
                /// Update absdkVersions for TEA buried report
                self.trackService.setABSDKVersions(versions: newVids)
                TeaMonitorService.logger.info("ABTest.setABSDKVersions >>> versions: \(String(describing: newVids))")

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name(rawValue: Tracker.LKABSDKVersionsDidChanged),
                        object: nil,
                        userInfo: ["absdkVersions": newVids ?? ""])
                }
            }
        }
        return value
    }
}

public final class SlardarMonitorService: TrackerService {
    static var hasSetupNTPTime: Bool = false
    public func post(event: Event) {
        if !SlardarMonitorService.hasSetupNTPTime {
            self.setupNTPTime()
        }
        if let slardarEvent = event as? SlardarEvent {
            if slardarEvent.immediately {
                LarkMonitor.immediatelyTrackService(
                    slardarEvent.name,
                    metric: slardarEvent.metric,
                    category: slardarEvent.category,
                    extra: slardarEvent.extra
                )
            } else {
                LarkMonitor.trackService(
                    slardarEvent.name,
                    metric: slardarEvent.metric,
                    category: slardarEvent.category,
                    extra: slardarEvent.extra
                )
            }
        } else if let customEvent = event as? SlardarCustomEvent {
            LarkMonitor.trackData(customEvent.params, logTypeStr: customEvent.name)
        } else {
            assertionFailure("event should be SlardarEvent")
        }
    }

    /*
     在slardar投递的时候在header中设置ntp_time
     HMDInjectedInfo是单例所以只需设置一次即可
     get_ntp_time()方法有获取失败的情况，获取失败不设置，在下次投递再去设置。
     极端情况下会有获取时间失败的情况，如果获取时间失败，不会再去设置
     */
    func setupNTPTime() {
        let ntpTime = get_ntp_time()
        // ntp_time有获取失败的情况，获取失败的时候返回的值是时间的偏移量，和sdk同学沟可以认为通当ntp_time的值大于2010年的时间戳认为获取成功
        if ntpTime > self.baseTimestamp {
            let timeInterval: TimeInterval = Date().timeIntervalSince1970 * 1_000
            let ntpOffset = Int(timeInterval) - Int(ntpTime)
            let injectedInfo = HMDInjectedInfo.default()
            injectedInfo.setCustomHeaderValue(ntpTime, forKey: "ntp_time")
            injectedInfo.setCustomHeaderValue(ntpOffset, forKey: "ntp_offset")
            // 设置boe
            let staging: LarkEnv.Env.TypeEnum? = EnvManager.env.type
            let unit: String? = EnvManager.env.unit
            if let staging = staging, let unit = unit {
                let boeStaging = "\(staging)-\(unit)"
                injectedInfo.setCustomHeaderValue(boeStaging, forKey: "lark_env")
            }
            SlardarMonitorService.hasSetupNTPTime = true
        }
        // 如果获取基准时间失败，不会再去设置
        if self.baseTimestamp == 0 {
            SlardarMonitorService.hasSetupNTPTime = true
        }
    }

    private lazy var baseTimestamp: Int = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let ds = df.date(from: "2010-01-01 00:00:00")
        return Int((ds?.timeIntervalSince1970) ?? 0)// 极端情况下会有获取时间失败的情况，这种情况返回0
    }()
}

public final class SlardarLogMonitorService: TrackerService {
    public func post(event: Event) {
        LarkLoggerMonitor.shared.addSlardarLog(category: event.name)
    }
}

public final class TeaLogMonitorService: TrackerService {
    public func post(event: Event) {
        LarkLoggerMonitor.shared.addApplog(category: event.name)
    }
}

/// 拉取通用配置
func pullGeneralSettings(configCallback: @escaping (([String], Int) -> Void)) {
    let rustService = Container.shared.resolve(LarkRustService.self) // Global
    guard let client = rustService else {
        MonitorApplicationDelegate.logger.debug("[通用配置拉取] LarkRustClient还未被创建，拉取通用配置失败")
        return
    }
    // TODO: 这个需要用户隔离吗？
    client.getConfigSettings(onSuccess: { (settingDic) in
        /*
         如果收到空的配置: 不作任何操作
         */
        if !settingDic.isEmpty, let etConfig = settingDic["et_config"] {
            // 抽取 URL
            if let data = etConfig.data(using: .utf8) {
                do {
                    guard let jsonDict = try JSONSerialization.jsonObject(
                        with: data,
                        options: []
                    ) as? [String: Any] else {
                        MonitorApplicationDelegate.logger.error(
                            "[get config] get et_config failed"
                        )
                        return
                    }
                    guard let endpoints = jsonDict["endpoints"] as? [String] else {
                        MonitorApplicationDelegate.logger.error(
                            "[get config] get endpoints failed"
                        )
                        return
                    }
                    guard let filterStatus = jsonDict["filter_status"] as? Int else {
                        MonitorApplicationDelegate.logger.error(
                            "[get config] get filter_status failed"
                        )
                        return
                    }
                    configCallback(endpoints, filterStatus)
                } catch {
                    print(error.localizedDescription)
                    MonitorApplicationDelegate.logger.error(
                        "[get config] get config failed \(String(describing: error))"
                    )
                }
            }
        }
    })
}

public func updateTeaDomain(_ tackService: TrackService?) {
    guard let domain = DomainSettingManager.shared.currentSetting["tt_tea"]?.first else {
        return
    }
    var teaURL = domain
    if !teaURL.hasPrefix("http") {
        teaURL = "https://" + teaURL
    }
    if teaURL.hasSuffix("/") {
        teaURL += "service/2/app_log/"
    } else {
        teaURL += "/service/2/app_log/"
    }
    tackService?.updateTeaEndpointsURL([teaURL])
}
