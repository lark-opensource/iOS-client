//
//  SetupCacheTask.swift
//  LarkBaseService
//
//  Created by 李晨 on 2020/8/20.
//

import Foundation
import BootManager
import LKCommonsLogging
import LarkContainer
import LarkCache
import LarkRustClient
import RustPB
import RxSwift
import LarkFeatureGating
import LarkAccountInterface
import LarkAssembler

public final class SetupCacheTask: FlowBootTask, Identifiable {
    public static var identify = "SetupCacheTask"

    static let logger = Logger.log(SetupCacheTask.self, category: "SetupCacheTask")

    static let configKey = "global_clean_config"

    static var disposeBag = DisposeBag()

    public override var scheduler: Scheduler { return .async }

    public override func execute(_ context: BootContext) {
        SetupCacheTask.cleanAllOldResource()
        SetupCacheTask.fetchCacheConfig()
    }

    @_silgen_name("Lark.LarkCache_CleanTaskRegistry_regist.SetupCacheTask")
    public static func registerCacheCleanTask() {
        CleanTaskRegistry.register(cleanTask: RustCacheCleanTask())
    }

    static func cleanAllOldResource() {
        resourceMigrationV1()
        resourceMigrationV2()
    }

    static let migrationVersionKey = "cache.migration.version"
    static var migrationVersion: Int {
        get {
            UserDefaults.standard.integer(forKey: migrationVersionKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: migrationVersionKey)
        }
    }

    static func resourceMigrationV1() {
        guard migrationVersion < 1 else {
            return
        }
        defer {
            migrationVersion = 1
        }

        /// 清理 mail 缓存
        let cleanMailCache = {
            let cachePath = Directory.library.path + "/MailSDK"
            try? FileManager.default.removeItem(atPath: cachePath)
        }
        cleanMailCache()

        /// 清理 SDWebImage 缓存
        let cleanSDImageCache = {
            let cachePath = Directory.cache.path + "/default/com.hackemist.SDWebImageCache.default"
            try? FileManager.default.removeItem(atPath: cachePath)
        }
        cleanSDImageCache()

        /// 清理 BDWebImage 缓存
        let cleanBDImageCache = {
            let cachePath = Directory.cache.path + "/com.bytedance.imagecache"
            try? FileManager.default.removeItem(atPath: cachePath)
        }
        cleanBDImageCache()

        /// 清理 Kingfisher 默认 缓存
        let cleanDefaultKFImageCache = {
            let cachePath = Directory.cache.path + "/com.onevcat.Kingfisher.ImageCache.default"
            try? FileManager.default.removeItem(atPath: cachePath)
        }
        cleanDefaultKFImageCache()

        /// 清理 User  下载文件 缓存
        let cleanUserDownloadCache = {
            let rootCachePath = Directory.document.path
            guard let paths = try? FileManager.default.contentsOfDirectory(atPath: rootCachePath) else {
                return
            }
            let userPaths = paths.filter { (path) -> Bool in
                return path.hasPrefix("LarkUser_")
            }
            if userPaths.isEmpty { return }

            userPaths.forEach { (subPath) in
                let downloadPath = rootCachePath + "/" + subPath + "/downloads"
                guard let downloadPaths = try? FileManager.default.contentsOfDirectory(atPath: downloadPath).filter({ (path) -> Bool in
                    let fullPath = downloadPath + "/" + path
                    var isDirectory: ObjCBool = false
                    let exist = FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory)
                    return isDirectory.boolValue && exist
                }) else {
                    return
                }
                downloadPaths.forEach { (path) in
                    let fullPath = downloadPath + "/" + path
                    try? FileManager.default.removeItem(atPath: fullPath)
                }
            }
        }
        cleanUserDownloadCache()

        /// 清理 User Kingfisher 图片缓存
        let cleanUserKFImageCache = {
            let rootCachePath = Directory.document.path
            guard let paths = try? FileManager.default.contentsOfDirectory(atPath: rootCachePath) else {
                return
            }
            let userPaths = paths.filter { (path) -> Bool in
                return path.hasPrefix("LarkUser_")
            }
            if userPaths.isEmpty { return }

            userPaths.forEach { (subPath) in
                let fullPath = rootCachePath + "/" + subPath + "/com.onevcat.Kingfisher.ImageCache.Lark"
                try? FileManager.default.removeItem(atPath: fullPath)
            }
        }
        cleanUserKFImageCache()

        /// 清理 Doc 缓存
        let cleanDocSDKCache = {
            let cachePath = Directory.library.path + "/DocsSDK/CacheService"
            try? FileManager.default.removeItem(atPath: cachePath)
        }
        cleanDocSDKCache()
    }

    static func resourceMigrationV2() {
        guard migrationVersion < 2 else {
            return
        }
        defer {
            migrationVersion = 2
        }

        /// 清理 User  下载文件 缓存
        let cleanUserDownloadCache = {
            let rootCachePath = Directory.document.path
            guard let paths = try? FileManager.default.contentsOfDirectory(atPath: rootCachePath) else {
                return
            }
            let userPaths = paths.filter { (path) -> Bool in
                return path.hasPrefix("LarkUser_")
            }
            if userPaths.isEmpty { return }

            userPaths.forEach { (subPath) in
                let downloadPath = rootCachePath + "/" + subPath + "/downloads"
                try? FileManager.default.removeItem(atPath: downloadPath)
            }
       }
       cleanUserDownloadCache()

        let cleanSDKImage = {
            let rootCachePath = Directory.document.path + "/" + "sdk_storage"
            let allIds = AccountServiceAdapter.shared.accounts.map { $0.userID.md5() }
            allIds.forEach { (id) in
                let rootResourcesPath = rootCachePath + "/" + id + "/" + "resources"
                let imagesPath = rootResourcesPath + "/" + "images"
                let avatarsPath = rootResourcesPath + "/" + "avatars"
                let stickersPath = rootResourcesPath + "/" + "stickers"

                [imagesPath, avatarsPath, stickersPath].forEach { (path) in
                    try? FileManager.default.removeItem(atPath: path)
                    try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
                }
            }
        }
        cleanSDKImage()
    }

    static func fetchCacheConfig() {        
        CacheManager.shared.autoCleanEnable = true
        SetupCacheTask.pullCacheConfig { (config, autoCleanMaxTimes) in
            if let maxCount = autoCleanMaxTimes {
                CacheManager.shared.autoCleanMaxCount = UInt(maxCount)
            }
            CacheManager.shared.autoClean(cleanConfig: config ?? CleanConfig())
        }
    }

    /// 拉取网络配置配置
    static func pullCacheConfig(configCallback: @escaping ((CleanConfig?, Int?) -> Void)) {
        let rustService = implicitResolver?.resolve(RustService.self)
        guard let client = rustService else {
            assertionFailure()
            SetupCacheTask.logger.debug("[通用配置拉取] LarkRustClient还未被创建，拉取通用配置失败")
            configCallback(nil, nil)
            return
        }
        disposeBag = DisposeBag()
        var request = Settings_V1_GetSettingsRequest()
        request.fields = [SetupCacheTask.configKey]
        client.sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
            return response.fieldGroups
        }).subscribe(onNext: { (settingDic) in
            guard
                let cacheConfig = settingDic[SetupCacheTask.configKey],
                let data = cacheConfig.data(using: .utf8),
                let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let cleanConfig = parseCleanConfig(json: jsonDict)
            else {
                SetupCacheTask.logger.error("parse cache config failed")
                configCallback(nil, nil)
                return
            }
            let autoCleanMaxTimes = parseMaxCleanTimes(json: jsonDict)
            configCallback(cleanConfig, autoCleanMaxTimes)
        }, onError: { (error) in
            SetupCacheTask.logger.error("pull cache config failed", error: error)
            configCallback(nil, nil)
        }).disposed(by: disposeBag)
    }

    /// 解析最大清理次数
    static func parseMaxCleanTimes(json: [String: Any]) -> Int? {
        guard
            let globalJson = json["global"] as? [String: Any],
            let maxTimes = globalJson["auto_clean_max_times"] as? Int
        else {
            return nil
        }
        return maxTimes
    }

    /// 解析配置
    static func parseCleanConfig(json: [String: Any]) -> CleanConfig? {
        guard let globalJson = json["global"] as? [String: Any],
            let cleanInterval = globalJson["clean_interval"] as? Int,
            let sdkTaskCostLimit = globalJson["sdk_task_cost_limit"] as? Int,
            let taskCostLimit = globalJson["task_cost_limit"] as? Int,
            let cacheTimeLimit = globalJson["cache_time_limit"] as? Int else {
            return nil
        }
        var cacheConfigs: [String: CleanConfig.CacheConfig] = [:]
        if let cacheConfigsJson = json["cache_config"] as? [String: Any] {
            cacheConfigsJson.forEach { (key, value) in
                if let configJson = value as? [String: Any],
                    let timeLimit = configJson["time_limit"] as? Int,
                    let sizeLimit = configJson["size_limit"] as? Int {
                        cacheConfigs[key] = CleanConfig.CacheConfig(
                            timeLimit: timeLimit,
                            sizeLimit: sizeLimit
                        )
                }
            }
        }

        return CleanConfig(
            cleanInterval: cleanInterval,
            sdkTaskCostLimit: sdkTaskCostLimit,
            taskCostLimit: taskCostLimit,
            cacheTimeLimit: cacheTimeLimit,
            cacheConfig: cacheConfigs
        )
    }
}

enum Directory: Hashable {
    // 对应Document目录
    case document
    // 对应Library目录
    case library
    // 对应Library/Cache目录
    case cache

    /// 缓存存放路径，cacheDirecotry标识的路径+biz标识的文件夹
    var path: String {
        switch self {
        case .document:
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            return paths[0]
        case .cache:
            let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            return paths[0]
        case .library:
            let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
            return paths[0]
        }
    }
}
