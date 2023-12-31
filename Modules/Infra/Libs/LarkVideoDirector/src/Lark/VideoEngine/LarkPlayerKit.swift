//
//  LarkPlayerKit.swift
//  LarkVideoDirector
//
//  Created by Saafo on 2023/9/6.
//

import Foundation
import LarkSetting
import LarkStorage
import TTVideoEngine
import LarkContainer
import LKCommonsLogging
import LarkAccountInterface

public enum LarkPlayerKit {

    /// FG 是否开启
    ///
    /// 因为有全局设置，启动第一次获取后不变
    public static func isEnabled(userResolver: UserResolver?) -> Bool {
        if let _enabled {
            return _enabled
        }
        guard let userResolver else {
            _enabled = false
            return false
        }
        let enable = userResolver.fg.staticFeatureGatingValue(with: "open_lark_player_config")
        _enabled = enable
        return enable
    }

    /// 创建 Engine 并根据 tag 设置 setting 上对应的 options
    ///
    /// 鉴于目前所有业务方均使用 MDL，内部会默认启动 MDL，不需要手动调用 setupMDLAndStartIfNeeded
    public static func buildEngine(userResolver: UserResolver, tag: String, subTag: String?) -> TTVideoEngine {
        lock.lock(); defer { lock.unlock() }

        let start = CACurrentMediaTime()
        _setupMDLAndStartIfNeeded(userResolver: userResolver)
        setupGlobalEngineIfNeeded(userResolver: userResolver)
        let videoEngine = TTVideoEngine(ownPlayer: true)
        setupEngine(videoEngine, tag: tag, subTag: subTag, userResolver: userResolver)
        let end = CACurrentMediaTime()
        logger.info("build engine from \(tag) \(subTag ?? ""), cost: \(end - start)s")
        return videoEngine
    }

    /// 初始化 MDL 并启动
    ///
    /// 主要用于预加载场景，不需要创建 engine 实例，但是需要启动 MDL 的情况
    public static func setupMDLAndStartIfNeeded(userResolver: UserResolver, file: String = #fileID) {
        lock.lock(); defer { lock.unlock() }

        _setupMDLAndStartIfNeeded(userResolver: userResolver, file: file)
    }

    // MARK: - Cache Path

    public static var cacheRootPath: IsoPath {
        IsoPath.in(space: .global,
                   domain: Domain.biz.messenger.child("VideoCache")
        ).build(.cache)
    }

    @discardableResult
    internal static func createTTVideoEngineCachePathIfNeeded() -> IsoPath {
        let cachePath = cacheRootPath + "ttVideoCache"
        if !cachePath.exists {
            try? cachePath.createDirectory()
        }
        return cachePath
    }

    // MARK: - Legacy
    /// 行为对齐 VideoEngineSetupManager.setupTTVideoEngine()
    ///
    /// - Note: 在所有业务线接入之后，才能不在启动的时候设置，改成完全的懒加载
    internal static func setupLegacyEngine(userResolver: UserResolver) {
        lock.lock(); defer { lock.unlock() }
        // 设置 mdl、mdl range、cache path
        setupMDLConfigIfNeeded(userResolver: userResolver)
        // 设置 global engine、logFlag
        setupGlobalEngineConfigIfNeeded(userResolver: userResolver)
    }

    // MARK: - Private

    private static let lock = NSLock()
    private static let logger = Logger.log(LarkPlayerKit.self, category: "LarkPlayerKit")
    private static var _enabled: Bool?

    private static var globalEngineDidSetup = false
    private static var mdlDidSetup = false
    private static var commonDidSetup = false
    private static var mdlConfigDidSet = false
    private static var globalEngineConfigDidSet = false

    private static let preloadDelegate = VideoEnginePreloadDelegate()
    private static let traceDelegate = VideoEngineTraceDelegate()

    private static var config: [String: Any]?

    private static func _setupMDLAndStartIfNeeded(userResolver: UserResolver, file: String = #fileID) {
        guard !mdlDidSetup else { return }
        mdlDidSetup = true

        let start = CACurrentMediaTime()
        guard !TTVideoEngine.ls_isStarted() else {
            assertionFailure("Should setup MDL before MDL start!")
            return
        }

        setupCommonIfNeeded()
        setupMDLConfigIfNeeded(userResolver: userResolver)
        /// 初始化 MDL 埋点代理
        TTVideoEngine.ls_setPreloadDelegate(preloadDelegate)
        TTVideoEngine.ls_start()
        let end = CACurrentMediaTime()
        logger.info("setup MDL from \(file), cost: \(end - start)s")
    }

    private static func setupGlobalEngineIfNeeded(userResolver: UserResolver) {
        guard !globalEngineDidSetup else { return }
        globalEngineDidSetup = true

        setupCommonIfNeeded()
        setupGlobalEngineConfigIfNeeded(userResolver: userResolver)
    }

    private static func setupCommonIfNeeded() {
        guard !commonDidSetup else { return }
        commonDidSetup = true

        let eventManager = TTVideoEngineEventManager.shared()
        if eventManager.delegate == nil {
            eventManager.delegate = traceDelegate
        }
        eventManager.setLogVersion(TTEVENT_LOG_VERSION_NEW)
    }

    private static func fetchConfigIfNeeded(userResolver: UserResolver) {
        guard config == nil else { return }
        do {
            let config = try userResolver.settings
                .setting(with: UserSettingKey.make(userKeyLiteral: "lark_player_settings"))
            logger.debug("load lark_player_settings: \(config)")
            self.config = config
        } catch {
            logger.error("Failed to fetch lark_player_settings, error: \(error)")
        }
    }

    private static func setupMDLConfigIfNeeded(userResolver: UserResolver) {
        guard !mdlConfigDidSet else { return }
        mdlConfigDidSet = true

        fetchConfigIfNeeded(userResolver: userResolver)
        guard let mdl = config?["mdl"] as? [String: Any] else { return }

        let mdlConfig = TTVideoEngine.ls_localServerConfigure()

        if let nonStandard = mdl["non_standard"] as? [String: Any] {
            if let enableExternDNS = nonStandard["enableExternDNS"] as? Bool {
                mdlConfig.enableExternDNS = enableExternDNS
            }
            if let rawMainDNSType = nonStandard["mainDNSType"] as? UInt,
               let rawBackupDNSType = nonStandard["backupDNSType"] as? UInt,
               let mainDNSType = TTVideoEngineDnsType(rawValue: rawMainDNSType),
               let backupDNSType = TTVideoEngineDnsType(rawValue: rawBackupDNSType) {
                TTVideoEngine.ls_mainDNSParseType(mainDNSType, backup: backupDNSType)
            }
            if let setDNSRefresh = nonStandard["setDNSRefresh"] as? Int {
                TTVideoEngine.ls_setDNSRefresh(setDNSRefresh)
            }
            if let setDNSParallel = nonStandard["setDNSParallel"] as? Int {
                TTVideoEngine.ls_setDNSParallel(setDNSParallel)
            }
            if let maxTlsVersion = nonStandard["maxTlsVersion"] as? Int {
                mdlConfig.maxTlsVersion = maxTlsVersion
            }
            if let isEnableSessionReuse = nonStandard["isEnableSessionReuse"] as? Bool {
                mdlConfig.isEnableSessionReuse = isEnableSessionReuse
            }
            if let maxCacheSize = nonStandard["maxCacheSize"] as? Int {
                mdlConfig.maxCacheSize = maxCacheSize
            }
            if let enableIOManager = nonStandard["enableIOManager"] as? Bool {
                mdlConfig.enableIOManager = enableIOManager
            }
        }
        if let base = mdl["base"] as? [[String: Any]] {
            base.forEach { config in
                if let key = config["key"] as? NSNumber, let value = config["value"] {
                    mdlConfig.setOptionForKey(key, value: value)
                }
            }
        }
        if let strategy = mdl["strategy"] as? [[String: Any]] {
            strategy.forEach { config in
                if let rawKey = config["key"] as? Int,
                   let key = TTVideoEngineStrategyAlgoConfigType(rawValue: rawKey),
                   let value = config["value"] as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: value),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    TTVideoEngineStrategy.helper().configAlgorithmJson(key, json: jsonString)
                }
            }
        }
        mdlConfig.cachDirectory = createTTVideoEngineCachePathIfNeeded().absoluteString // 设置缓存路径
    }

    private static func setupGlobalEngineConfigIfNeeded(userResolver: UserResolver) {
        guard !globalEngineConfigDidSet else { return }
        globalEngineConfigDidSet = true

        fetchConfigIfNeeded(userResolver: userResolver)
        guard let engine = config?["engine"] as? [String: Any] else { return }

        if let global = engine["global"] as? [[String: Any]] {
            global.forEach { config in
                if let rawKey = config["key"] as? Int,
                   let key = VEKGSKey(rawValue: rawKey),
                   let value = config["value"] {
                    TTVideoEngine.setGlobalFor(key, value: value)
                }
            }
        }
        if let nonStandard = engine["non_standard"] as? [String: Any] {
            if let setLogFlag = nonStandard["setLogFlag"] as? Int {
                TTVideoEngine.setLogFlag(.init(rawValue: setLogFlag))
            }
        }
    }

    private static func setupEngine(_ videoEngine: TTVideoEngine, tag: String, subTag: String?,
                                    userResolver: UserResolver) {
        guard let engine = config?["engine"] as? [String: Any] else { return }

        videoEngine.setOptionForKey(VEKKey.VEKKeyLogTag_NSString.rawValue, value: tag)
        if let subTag {
            videoEngine.setOptionForKey(VEKKey.VEKKeyLogSubTag_NSString.rawValue, value: subTag)
        }
        if let tenantID = try? userResolver.resolve(assert: PassportUserService.self).userTenant.tenantID {
            videoEngine.setCustomCompanyID(tenantID)
        }

        if let base = engine["base"] as? [[String: Any]] {
            base.forEach { config in
                if let key = config["key"] as? Int, let value = config["value"] {
                    videoEngine.setOptionForKey(key, value: value)
                }
            }
        }
        if let tags = engine["tags"] as? [[String: Any]],
           let tagConfig = tags.first(where: { $0["name"] as? String == tag }) {
            if let tagBase = tagConfig["base"] as? [[String: Any]] {
                tagBase.forEach { config in
                    if let key = config["key"] as? Int, let value = config["value"] {
                        videoEngine.setOptionForKey(key, value: value)
                    }
                }
            }
            if let subTag, let subtags = tagConfig["subtags"] as? [[String: Any]],
               let subtagConfig = subtags.first(where: { $0["name"] as? String == subTag }),
               let subtagBase = subtagConfig["base"] as? [[String: Any]] {
                subtagBase.forEach { config in
                    if let key = config["key"] as? Int, let value = config["value"] {
                        videoEngine.setOptionForKey(key, value: value)
                    }
                }
            }
        }
    }
}
