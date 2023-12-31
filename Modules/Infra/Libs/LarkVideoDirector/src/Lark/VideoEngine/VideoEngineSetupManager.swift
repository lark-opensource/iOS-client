//
//  VideoEngineSetupManager.swift
//  LarkBaseService
//
//  Created by 李晨 on 2022/6/10.
//

import Foundation
import BDABTestSDK
import RangersAppLog
import LarkKAFeatureSwitch
import TTVideoEngine
import LarkTracker
import LarkAppLog
import LKCommonsLogging
import LKCommonsTracker
import LarkFeatureGating
import LarkContainer
import LarkSetting
import LarkStorage
import LarkReleaseConfig

public final class VideoEngineSetupManager {

    public static var shared = VideoEngineSetupManager()

    private static let logger = Logger.log(VideoEngineSetupManager.self)

    private var traceDelegate = VideoEngineTraceDelegate()
    private var preloadDelegate = VideoEnginePreloadDelegate()
    private let lock = NSLock()

    private var delegateDidSetup = false
    private static let imVideoPlayerConfigKey = UserSettingKey.make(userKeyLiteral: "im_video_player_config")

    /// 初始化 MDL log 以及 delegate
    public func setupVideoEngineDelegateIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !delegateDidSetup else { return }
        delegateDidSetup = true
        Self.logger.info("setupVideoEngineDelegateIfNeeded")

        let eventManager = TTVideoEngineEventManager.shared()
        if eventManager.delegate == nil {
            eventManager.delegate = traceDelegate
        }
        eventManager.setLogVersion(TTEVENT_LOG_VERSION_NEW)

        /// 初始化 MDL 埋点代理
        TTVideoEngine.ls_setPreloadDelegate(preloadDelegate)
    }

    /// 初始化 TTVideoEngine 配置
    static func setupTTVideoEngine() {
        let path = setupTTVideoEnginePath()
        let videoCacheConfig = TTVideoEngine.ls_localServerConfigure()
        videoCacheConfig.maxCacheSize = 2 * 1_024 * 1_024 * 1_024

        /// merge two dict, when the key is same and value is different and is not a dict, use the second dict's value
        func merge(_ lowPriorityDict: [String: Any], _ highPriorityDict: [String: Any]) -> [String: Any] {
            lowPriorityDict.merging(highPriorityDict) { lowValue, highValue in
                if let lowDict = lowValue as? [String: Any],
                   let highDict = highValue as? [String: Any] {
                    return merge(lowDict, highDict)
                } else {
                    return highValue
                }
            }
        }

        let settings = try? SettingManager.shared.setting(with: Self.imVideoPlayerConfigKey)
        let abSetting = Tracker.experimentValue(key: "im_video_player_ab_config",
                                                shouldExposure: true) as? [String: Any]
        if let mergedSettings = {
            if let settings, let abSetting {
                return merge(settings, abSetting)
            } else {
                return abSetting ?? settings
            }
        }() {
            Self.logger.info("[VideoEngine][AB] mergedSettings: \(mergedSettings)")
            if let videoConfig = mergedSettings["mdl"] as? [String: Any] {
                updateMDL(setting: videoConfig)
                Self.logger.debug("[VideoEngine][AB] updateMDL setting: \(videoConfig)")
            }
            if let onlineSwitch = mergedSettings["online_switch"] as? [String: Any] {
                if let mdlConfig = onlineSwitch["mdl"] as? [[String: Any]] {
                    updateMDLOnline(settings: mdlConfig)
                    Self.logger.debug("[VideoEngine][AB] updateMDLOnline setting: \(mdlConfig)")
                }
                if let globalEngineConfig = onlineSwitch["globalEngine"] as? [[String: Any]] {
                    updateGlobalEngineOnline(settings: globalEngineConfig)
                    Self.logger.debug("[VideoEngine][AB] updateGlobalEngineOnline setting: \(globalEngineConfig)")
                }
            }

            // 设置内核日志, 正常不会下发使用默认配置，追查用户特定问题时 可以扩大日志范围
            if let videoConfig = mergedSettings["lark"] as? [String: Any] {
                if let videoEngineLogFlag = videoConfig["VideoEngineLogFlag"] as? Int {
                    let flag = TTVideoEngineLogFlag(rawValue: videoEngineLogFlag)
                    TTVideoEngine.setLogFlag(flag)
                    Self.logger.debug("[VideoEngine][AB] setLogFlag: \(flag)")
                }
            }

            // 设置 MDL 请求 Range
            if let strategyConfig = mergedSettings["strategy"] as? [String: Any] {
                videoCacheConfig.enableIOManager = true
                if let playRangeConfig = strategyConfig["play_range"] as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: playRangeConfig),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    TTVideoEngineStrategy.helper().configAlgorithmJson(.algoConfigPlayRange, json: jsonString)
                    Self.logger.debug("[VideoEngine][AB] configAlgorithmJson playRange jsonString: \(jsonString)")
                }
            }
        } else {
            Self.logger.error("[VideoEngine][AB] failed to get VideoEngine AB! "
                              + "\(String(describing: settings)), \(String(describing: abSetting))")
        }

        /// 设置缓存路径
        videoCacheConfig.cachDirectory = path.absoluteString
    }

    private static func updateGlobalEngineOnline(settings: [[String: Any]]) {
        settings.forEach { config in
            if let key = config["key"] as? NSInteger,
               let vekesKey = VEKGSKey(rawValue: key),
               let value = config["value"] {
                TTVideoEngine.setGlobalFor(vekesKey, value: value)
            }
        }
    }

    private static func updateMDLOnline(settings: [[String: Any]]) {
        let videoCacheConfig = TTVideoEngine.ls_localServerConfigure()
        settings.forEach { config in
            if let key = config["key"] as? NSInteger,
               let value = config["value"] {
                videoCacheConfig.setOptionForKey(VEMDLKeyType(value: key), value: value)
            }
        }
    }

    private static func updateMDL(setting: [String: Any]) {
        let videoCacheConfig = TTVideoEngine.ls_localServerConfigure()
        if let maxCacheSize = setting["DATALOADER_KEY_INT_MAXCACHESIZE"] as? Int {
            videoCacheConfig.maxCacheSize = maxCacheSize
        }
        if let enableSoccketReuse = setting["DATALOADER_SOCCKET_REUSE_ENABLE"] as? Int {
            videoCacheConfig.enableSoccketReuse = enableSoccketReuse == 1
        }
        if let enableExternDNS = setting["DATALOADER_EXTERN_DNS_ENABLE"] as? Int {
            videoCacheConfig.enableExternDNS = enableExternDNS == 1
        }
        if (setting["DATALOADER_DNS_PARSE_TYPE_ENABLE"] as? Int) == 1 {
            TTVideoEngine.ls_mainDNSParseType(.local, backup: ReleaseConfig.isFeishu ? .httpTT : .httpGoogle)
        }
        if let enableRefreshDNS = setting["DATALOADER_DNS_REFRESH_ENABLE"] as? Int {
            TTVideoEngine.ls_setDNSRefresh(enableRefreshDNS)
        }
        if let enableParallelDNS = setting["DATALOADER_DNS_PARALLEL_ENABLE"] as? Int {
            TTVideoEngine.ls_setDNSParallel(enableParallelDNS)
        }
        if let maxTlsVersion = setting["DATALOADER_MAX_TLS_VERSION"] as? Int {
            videoCacheConfig.maxTlsVersion = maxTlsVersion
        }
        if let enableSessionReuse = setting["DATALOADER_SESSION_REUSE_ENABLE"] as? Int {
            videoCacheConfig.isEnableSessionReuse = enableSessionReuse == 1
        }
    }

    public static func videoCacheRootPath() -> IsoPath {
        let domain = Domain.biz.messenger.child("VideoCache")
        return IsoPath.in(space: .global, domain: domain).build(.cache)
    }

    @discardableResult
    static func setupTTVideoEnginePath() -> IsoPath {
        let rootPath = videoCacheRootPath()
        let cachePath = rootPath + "ttVideoCache"
        if !cachePath.exists {
            try? cachePath.createDirectory()
        }
        return cachePath
    }
}

final class VideoEngineTraceDelegate: NSObject, TTVideoEngineEventManagerProtocol {

    private static let logger = Logger.log(VideoEngineTraceDelegate.self)

    private var eventHasPosted: Bool = false
    @InjectedSafeLazy var tracker: TrackService // Global

    func eventManagerDidUpdate(_ eventManager: TTVideoEngineEventManager) {
        let events = eventManager.popAllEvents()
        for event in events {
            LarkAppLog.shared.tracker.customEvent("log_data", params: event)
        }
    }

    func eventManagerDidUpdateV2(_ eventManager: TTVideoEngineEventManager, eventName: String, params: [AnyHashable: Any]) {
        if !eventHasPosted {
            eventHasPosted = true
            VideoEngineApplicationDelegate.logger.info("start track")
        }
        guard var event = params as? [String: Any] else {
            VideoEngineApplicationDelegate.logger.error("event format error")
            return
        }
        let uniqueKey = Int64(CFAbsoluteTimeGetCurrent() * 1_000)
        event["log_id"] = uniqueKey

        // TODO: 确认是否需要用户隔离：
        tracker.track(event: eventName, params: event)
        Self.logger.info("video engine update v2 log event \(event)")
    }
}

final class VideoEnginePreloadDelegate: NSObject, TTVideoEnginePreloadDelegate {

    private static let logger = Logger.log(VideoEnginePreloadDelegate.self)

    func localServerLogUpdate(_ logInfo: [AnyHashable: Any]) {
        LarkAppLog.shared.tracker.customEvent("log_data", params: logInfo)
        Self.logger.info("video preload log event \(logInfo)")
    }
}
