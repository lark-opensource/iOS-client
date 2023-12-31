//
//  BDPPreloadHelper.swift
//  TTMicroApp
//
//  Created by Nicholas Tau on 2022/09/13.
//
import Foundation
import OPSDK
import ECOInfra
import LKCommonsLogging
import LarkContainer

/// 清理策略settings数据结构
struct BDPPreloadCleanStrategyConfig {
    public let enable: Bool
    public let cleanBeforeDays: Int
    public let cleanMaxRetainAppCount: Int
    public let cleanMaxRetainVersion: Int

    init(enable: Bool = false, cleanBeforeDays: Int = Int.cleanBeforeDays, cleanMaxRetainAppCount: Int = Int.cleanMaxRetainAppCount, cleanMaxRetainVersion: Int = Int.cleanMaxRetainVersion) {
        self.enable = enable
        self.cleanBeforeDays = cleanBeforeDays
        self.cleanMaxRetainAppCount = cleanMaxRetainAppCount
        self.cleanMaxRetainVersion = cleanMaxRetainVersion
    }

    init(settings: [String : Any]?) {
        enable = settings?["enable"] as? Bool ?? false
        // 默认时间为30天
        cleanBeforeDays = settings?["cleanBeforeDays"] as? Int ?? Int.cleanBeforeDays
        // 默认保留应用数10个
        cleanMaxRetainAppCount = settings?["cleanMaxRetainAppCount"] as? Int ?? Int.cleanMaxRetainAppCount
        //默认的最大版本数为3个
        cleanMaxRetainVersion = settings?["cleanMaxRetainVersion"] as? Int ?? Int.cleanMaxRetainVersion
    }
}

/// 预安装针对定制人群settings开关配置(针对'custom_package_prehandle'中配置的应用)
public struct BDPPrehandleCustomizeConfig {
    public let enable: Bool

    public let customizePrehandleAppInfoList: [[String : Any]]

    public let customizePrehandleAppIDs: [String]

    init(settings: [String : Any]?) {
        enable = settings?["customPreHandleEnable"] as? Bool ?? false
        let appInfoList = settings?["customPreHandleAppInfoList"] as? [[String : Any]] ?? [[String : Any]]()
        customizePrehandleAppInfoList = appInfoList
        customizePrehandleAppIDs = appInfoList.compactMap {
            return $0["appId"] as? String
        }
    }

    init(enable: Bool = false, customizePrehandleAppInfoList: [[String : Any]] = [[String : Any]]()) {
        self.enable = enable
        self.customizePrehandleAppInfoList = customizePrehandleAppInfoList
        customizePrehandleAppIDs = customizePrehandleAppInfoList.compactMap {
            return $0["appId"] as? String
        }
    }
}

@objcMembers open class BDPPreloadHelper: NSObject {
    private static let logger = Logger.oplog(BDPPreloadHelper.self)
    /// 返回预安装重构preHandleEnable状态(总开关)
    static public func preHandleEnable() -> Bool {
        guard let config = preHandleConfig(),
              let enable = config["preHandleEnable"] as? Bool else {
            Self.logger.warn("[BDPPreloadHelper] can not get preHandleEnable")
            return false
        }

        return enable
    }

    /// 返回预安装频率控制的值（前后台切换之间的时间间隔）
    static public func minPullSilenceInAppFront() -> Int {
        guard let config = preHandleConfig(),
              let silenceConfig = config["silence"] as? [String : Any],
              let minPullSilenceInAppFront = silenceConfig["minPullSilenceInAppFront"] as? Int else {
            Self.logger.warn("[BDPPreloadHelper] can not get preHandleEnable")
            return 0
        }

        return minPullSilenceInAppFront
    }

    /// 预安装是否走新逻辑
    static public func preloadEnable() -> Bool {
        guard let config = preHandleConfig(),
              let preloadConfig = config["preload"] as? [String : Any],
              let enable = preloadConfig["enable"] as? Bool else {
            Self.logger.warn("[BDPPreloadHelper] can not get preloadEnable")
            return false
        }

        return enable && preHandleEnable()
    }

    /// 预安装拉取是否走本地策略开关
    static public func clientStrategyEnable() -> Bool {
        guard let config = preHandleConfig(),
              let preloadConfig = config["preload"] as? [String : Any],
              let enable = preloadConfig["enableClientStrategy"] as? Bool else {
            Self.logger.warn("[BDPPreloadHelper] can not get enableClientStrategy")
            return false
        }

        return enable
    }

    /// 是否允许记录应用启动数据到数据库中
    static public func recordAppLaunchInfoEnable() -> Bool {
        return BDPPreloadHelper.clientStrategyEnable() || OPSDKFeatureGating.enableGadgetLaunchInfoRecord()
    }

    /// 端策略本地最小应用阀值
    static public func clientStrategyMinAppCount() -> Int {
        guard let config = preHandleConfig(),
              let preloadConfig = config["preload"] as? [String : Any],
              let clientStrategyMinAppCount = preloadConfig["clientStrategyMinAppCount"] as? Int else {
            Self.logger.warn("[BDPPreloadHelper] can not get clientStrategyMinAppCount")
            return Int.clientStrategyMinAppCount
        }

        return clientStrategyMinAppCount
    }

    ///端策略往前计算的时间，默认七天内有效
    static public func clientStrategyBeforeDays() -> Int {
        guard let config = preHandleConfig(),
              let preloadConfig = config["preload"] as? [String : Any],
              let clientStrategyBeforeDays = preloadConfig["clientStrategyBeforeDays"] as? Int else {
            Self.logger.warn("[BDPPreloadHelper] can not get clientStrategyBeforeDays")
            return Int.clientStrategyBeforeDays
        }

        return clientStrategyBeforeDays
    }

    ///端策略单次获取的最大应用数量
    static public func clientStrategySingleMaxCount() -> Int {
        guard let config = preHandleConfig(),
              let preloadConfig = config["preload"] as? [String : Any],
              let clientStrategySingleMaxCount = preloadConfig["clientStrategySingleMaxCount"] as? Int else {
            Self.logger.warn("[BDPPreloadHelper] can not get clientStrategySingleMaxCount")
            return Int.clientStrategySingleMaxCount
        }

        return clientStrategySingleMaxCount
    }

    /// 流量白名单(在这边列表中,可以不通过WiFi进行下载操作)
    static public func cellularDataAllowList() -> [String] {
        guard let config = preHandleConfig(),
              let allowList = config["cellularDataAllowList"] as? [String] else {
            Self.logger.warn("[BDPPreloadHelper] can not get cellularDataAllowList")
            return []
        }
        return allowList
    }

    /// 过期功能是否走重构逻辑
    static public func expiredEnable() -> Bool {
        guard let config = preHandleConfig(),
              let expiredConfig = config["expire"] as? [String : Any],
              let enable = expiredConfig["enable"] as? Bool else {
            Self.logger.warn("[BDPPreloadHelper] can not get expiredEnable")
            return false
        }

        return enable && preHandleEnable()
    }

    /// 应用是否开启了过期
    static public func expiredEnable(appID: String) -> Bool {
        guard let config = preHandleConfig(),
              let expiredConfig = config["expire"] as? [String : Any],
              let appConfig = expiredConfig[appID] as? [String : Any],
              let enable = appConfig["enable"] as? Bool else {
            Self.logger.warn("[BDPPreloadHelper] can not get expired enable for \(appID)")
            return expiredEnable()
        }

        return enable
    }

    /// 获取某个应用具体的过期时间
    static public func expiredDuration(appID: String?) -> TimeInterval {
        // 默认值设置为极大
        let defualtDuration: TimeInterval = TimeInterval.defatultExpiredTime
        guard let config = preHandleConfig(),
              let expiredConfig = config["expire"] as? [String : Any] else {
            Self.logger.warn("[BDPPreloadHelper] can not get expired duration for \(String(describing: appID))")
            return defualtDuration
        }

        // 先检查一下对应appID是否配置了单独的过期时间,没有配置的话则返回通用默认时间
        if let appID = appID,
           let appConfig = expiredConfig[appID] as? [String : Any],
           let duration = appConfig["expireDuration"] as? TimeInterval {
            return duration
        } else {
            return expiredConfig["expireDuration"] as? TimeInterval ?? defualtDuration
        }
    }

    /// 产品化止血是否走重构逻辑
    static public func silenceEnable() -> Bool {
        guard let config = preHandleConfig(),
              let silenceConfig = config["silence"] as? [String : Any],
              let enable = silenceConfig["enable"] as? Bool else {
            Self.logger.warn("[BDPPreloadHelper] can not get silenceEnable")
            return false
        }

        return enable && preHandleEnable()
    }

    // 获取package_prehandle配置信息
    static func preHandleConfig() -> [String : Any]? {
        let configService = Injected<ECOConfigService>().wrappedValue
        return configService.getLatestDictionaryValue(for: "package_prehandle")
    }

    /// 获取settings 'custom_package_prehandle' 配置信息
    static func customPackagePrehandleSettings() -> [String : Any]? {
        let configService = Injected<ECOConfigService>().wrappedValue
        return configService.getLatestDictionaryValue(for: "custom_package_prehandle")
    }

    //MARK: 分割线===下面是读取老settings的信息(用于预安装)====

    // 拉取配置时间间隔
    static public func preUpdateMinTimeSinceLastPull() -> TimeInterval {
        guard let config = oldPreHandleConfig(),
              let preUpdateMinTimeSinceLastPull = config["minTimeSinceLastPullUpdateInfo"] as? TimeInterval else {
            // 默认返回8小时
            return TimeInterval.preUpdateMinTimeSinceLastPull
        }
        return preUpdateMinTimeSinceLastPull
    }

    // 启动后延迟发起请求的时间
    static public func checkDelayAfterLaunch() -> TimeInterval {
        guard let config = oldPreHandleConfig(),
              let checkDelayAfterLaunch = config["checkDelayAfterLaunch"] as? TimeInterval else {
            // 默认值为3秒
            return TimeInterval.checkDelayAfterLaunch
        }
        return checkDelayAfterLaunch
    }

    // 每天能够更新的应用最大数量
    static public func preUpdateMaxTimesOneDay() -> Int {
        guard let config = oldPreHandleConfig(),
              let maxCount = config["maxTimesOneDay"] as? Int else {
            // 默认是15个应用限制
            return Int.preUpdateMaxCountOneDay
        }
        return maxCount
    }

    // 网络波动检查时间间隔
    static public func minTimeSinceLastCheck() -> TimeInterval {
        guard let config = oldPreHandleConfig(),
              let minTimeSinceLastCheck = config["minTimeSinceLastCheck"] as? TimeInterval else {
            // 默认是10分钟
            return TimeInterval.minTimeSinceLastNetworkCheck
        }
        return minTimeSinceLastCheck
    }

    // 网络波动延迟拉取配置时间
    static public func networkChangeCheckDelay() -> TimeInterval {
        guard let config = oldPreHandleConfig(),
              let checkDelayAfterNetworkChange = config["checkDelayAfterNetworkChange"] as? TimeInterval else {
            // 默认是30秒
            return TimeInterval.networkChangeCheckDelay
        }
        return checkDelayAfterNetworkChange
    }

    // 获取openplatform_gadget_preload配置信息(老的配置信息)
    static func oldPreHandleConfig() -> [String : Any]? {
        let configService = Injected<ECOConfigService>().wrappedValue
        return configService.getLatestDictionaryValue(for: "openplatform_gadget_preload")
    }
    
    //获取清理时本地保留的最大版本数
    static public func cleanMaxRetainVersionCount() -> Int {
        return self.cleanStrategyConfig().cleanMaxRetainVersion
    }
}

extension BDPPreloadHelper {
    // 获取'cleanStrategy'配置信息对应的数据结构
    static func cleanStrategyConfig() -> BDPPreloadCleanStrategyConfig {
        let settings = preHandleConfig()
        let cleanStrategySettings = settings?["cleanStrategy"] as? [String : Any]
        return BDPPreloadCleanStrategyConfig(settings: cleanStrategySettings)
    }

    // 获取settings'custom_package_prehandle'配置信息对应的数据结构
    public static func prehandleCustomizeConfig() -> BDPPrehandleCustomizeConfig {
        let settings = customPackagePrehandleSettings()
        return BDPPrehandleCustomizeConfig(settings: settings)
    }
}

fileprivate extension TimeInterval {
    /// 默认应用过期时间
    static let defatultExpiredTime = Double.greatestFiniteMagnitude

    /// 预安装最小拉取配置时间间隔默认值(8小时)
    static let preUpdateMinTimeSinceLastPull: TimeInterval = 28800

    /// 启动后拉取配置延迟时间默认值(3秒)
    static let checkDelayAfterLaunch: TimeInterval = 3

    /// 预安装网络波动检查时间间隔默认值(10分钟)
    static let minTimeSinceLastNetworkCheck: TimeInterval = 600

    /// 网络波动延迟拉取配置时间默认值(30秒)
    static let networkChangeCheckDelay: TimeInterval = 30
}

fileprivate extension Int {
    /// 预安装应用每天个数限制默认值
    static let preUpdateMaxCountOneDay = 15

    /// 预安装本地最小最小应用阀值
    static let clientStrategyMinAppCount = 5

    ///端策略往前计算的时间，默认七天内有效
    static let clientStrategyBeforeDays = 7

    ///端策略单次获取的最大应用数量
    static let clientStrategySingleMaxCount = 10
    
    //清理x天的数据，默认30天
    static let cleanBeforeDays = 30
    
    //清理后保留本地最多的常用应用数
    static let cleanMaxRetainAppCount = 10
    
    //清理多版本缓存数的最多版本数
    static let cleanMaxRetainVersion = 3
}
