//
//  OPLarkCacheImp.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/10/8.
//  开放平台接入LarkCache, 实现CleanTask协议类

import Foundation
import LarkCache
import LKCommonsLogging
import ECOProbe

public typealias DeleteActionCallback = (_ allMetas: [AppMetaProtocol],
                                         _ needRetainAppList: [String],
                                         _ needDeleteAppMetas: [AppMetaProtocol],
                                         _ appPkgSizeMap: [String : Int]) -> Void

public protocol OPGadgetCleanStrategyProtocol {
    func cleanGadgetMetaAndPkg(deleteAction: DeleteActionCallback)
}

public final class OPGadgetCacheCleanTask: CleanTask {
    static let logger = Logger.log(OPGadgetCacheCleanTask.self, category: "OPGadgetCacheCleanTask")

    public var name: String { "OpenplatformCacheCleanTask" }

    private var _cleanStrategy: OPGadgetCleanStrategyProtocol?
    var cleanStrategy: OPGadgetCleanStrategyProtocol {
        get {
            if _cleanStrategy == nil {
                _cleanStrategy = OPGadgetCleanStrategy(cleanStrategyConfig: BDPPreloadHelper.cleanStrategyConfig())
            }
            return _cleanStrategy ?? OPGadgetCleanStrategy(cleanStrategyConfig: BDPPreloadHelper.cleanStrategyConfig())
        }
    }

    public init() {}

    public func clean(config: LarkCache.CleanConfig, completion: @escaping Completion) {
        Self.logger.info("[OPGadgetCacheCleanTask] receive clean message, trigger by user: \(config.isUserTriggered)")
        if config.isUserTriggered {
            // settings配置飞书设置入口可以使用容灾能力进行清理，调用容灾框架进行清理，并且当前用户已经完成登录，否则使用之前清理逻辑
            // isUserTriggered 状态不准确，被passport 修改，实际并非用户手动触发
            if OPGadgetDRManager.shareManager.isFinishLogin, OPGadgetDRManager.shareManager.enableLarkSettingDR() {
                // 手动触发飞书设置清理缓存逻辑，调用容灾框架执行
                OPGadgetDRManager.shareManager.larkSettingClearCache(completion: completion)
            }else {
                userCleanGadgetCache(completion: completion)
            }
        } else {
            clientCleanGadgetCache(completion: completion)
        }
    }

    // 用户触发小程序pkg和meta缓存清理
    func userCleanGadgetCache(completion: @escaping Completion) {
        guard OPSDKFeatureGating.gadgetPackageUserCleanEnable() else {
            Self.logger.info("[OPGadgetCacheCleanTask] gadgetPackageUserCleanEnable is false")
            completion(TaskResult(completed: false, costTime: 0, size: .bytes(0)))
            return
        }

        callGadgetCleanStrategy(cleanStrategy: cleanStrategy, isUserTriggered: true, completion: completion)
    }

    // 客户端触发小程序pkg和meta缓存清理
    func clientCleanGadgetCache(completion: @escaping Completion) {
        guard OPSDKFeatureGating.gadgetPackageClientCleanEnable() else {
            Self.logger.info("[OPGadgetCacheCleanTask] gadgetPackageClientCleanEnable is false")
            completion(TaskResult(completed: false, costTime: 0, size: .bytes(0)))
            return
        }
        callGadgetCleanStrategy(cleanStrategy: cleanStrategy, isUserTriggered: false, completion: completion)
    }

    // 调用OPGadgetCleanStrategy来清理缓存
    func callGadgetCleanStrategy(cleanStrategy: OPGadgetCleanStrategyProtocol,
                                 isUserTriggered: Bool,
                                 completion: @escaping Completion) {

        let startTime = Date().timeIntervalSince1970

        cleanStrategy.cleanGadgetMetaAndPkg {[weak self] allGadgetMetas, needRetainAppList, needDeleteAppMetas, appPkgSizeMap in
            guard let `self` = self else {
                Self.logger.error("[OPGadgetCacheCleanTask] self is nil")
                completion(TaskResult(completed: false, costTime: 0, size: .bytes(0)))
                return
            }

            guard !needDeleteAppMetas.isEmpty else {
                Self.logger.info("[OPGadgetCacheCleanTask] needDeleteAppMetas is empty")
                completion(TaskResult(completed: false, costTime: 0, size: .bytes(0)))
                return
            }
            // 真正的删包逻辑
            BDPAppLoadManager.shareService().deletePackageAndMeta(needDeleteAppMetas.map({
                $0.uniqueID
            })) { deletedUniqueIDs in
                let pkgSizes = self.packageTaskSizeArray(uniqueIDs: deletedUniqueIDs, appPkgSizeMap: appPkgSizeMap)

                let endTime = Date().timeIntervalSince1970
                // 计算耗时
                let cost = Int((endTime - startTime) * 1000)

                let monitor = self.configGadgetCleanMonitor(allGedgetMetas: allGadgetMetas, deletedUniqueIDs: deletedUniqueIDs, appPkgSizeMap: appPkgSizeMap, costTime: cost, isUserTriggered: isUserTriggered)

                monitor.flush()

                completion(TaskResult(completed: true, costTime: cost, sizes: pkgSizes.map {
                    TaskResult.Size.bytes($0)
                }))
            }
            //调用PKM里新的删包逻辑（需要检查一下多版本的数据条数是否超限制）
            needRetainAppList.forEach { appID in
                do {
                    try BDPAppLoadManager.shareService().cleanMetasInPKMDB(withAppID: appID)
                } catch {
                    Self.logger.error("[OPGadgetCacheCleanTask] cleanMetasInPKMDB with error:\(error)")
                }
            }
        }
    }

    func packageTaskSizeArray(uniqueIDs: [OPAppUniqueID], appPkgSizeMap: [String : Int]) -> [Int] {
        var pkgSizes = [Int]()
        uniqueIDs.forEach { uniqueID in
            if let fileSize = appPkgSizeMap[BDPSafeString(uniqueID.appID)] {
                pkgSizes.append(fileSize)
            }
        }
        return pkgSizes
    }

    func configGadgetCleanMonitor(allGedgetMetas: [AppMetaProtocol],
                                  deletedUniqueIDs: [OPAppUniqueID],
                                  appPkgSizeMap: [String : Int],
                                  costTime: Int,
                                  isUserTriggered: Bool) -> OPMonitor {
        let allMetasSizeSum = packageTaskSizeArray(uniqueIDs: allGedgetMetas.map({
            $0.uniqueID
        }), appPkgSizeMap: appPkgSizeMap).reduce(0) { total, value in
            total + value
        }

        let deletedMetasSum = packageTaskSizeArray(uniqueIDs: deletedUniqueIDs, appPkgSizeMap: appPkgSizeMap).reduce(0) { total, value in
            total + value
        }

        let remainCount = allGedgetMetas.count - deletedUniqueIDs.count
        let remainSize = allMetasSizeSum - deletedMetasSum

        return OPMonitor(EPMClientOpenPlatformGadgetPrehandleCode.op_prehandle_pkg_clean)
            .addMap(["app_type" : "gadget",
                     "clean_count" : deletedUniqueIDs.count,
                     "remain_count" : remainCount,
                     "clean_size" : deletedMetasSum,
                     "remain_size" : remainSize,
                     "clean_type" : isUserTriggered ? 0 : 1,
                     "duration" : costTime])
    }
}


/// 小程序数据清理策略类(获取需要清理的小程序信息)
final class OPGadgetCleanStrategy: OPGadgetCleanStrategyProtocol {
    static let logger = Logger.log(OPGadgetCleanStrategy.self, category: "OPGadgetCleanStrategy")

    // 清除小程序包的配置信息
    public let cleanStrategyConfig: BDPPreloadCleanStrategyConfig

    public init(cleanStrategyConfig: BDPPreloadCleanStrategyConfig) {
        self.cleanStrategyConfig = cleanStrategyConfig
    }

    public func cleanGadgetMetaAndPkg(deleteAction: DeleteActionCallback) {
        // 检查settings总开关是否开启
        guard cleanStrategyConfig.enable else {
            Self.logger.info("[OPGadgetCleanStrategy] settings enable is false, delete nothing")
            deleteAction([AppMetaProtocol](), [String](), [AppMetaProtocol](), [String : Int]())
            return
        }

        // 获取当前磁盘小程序meta信息
        let allGadgetMetas = MetaLocalAccessorBridge.getAllMetas(appType: .gadget)
        // 获取近期常用小程序appID
        let needRetainApps = retainAppArray(retainCount: cleanStrategyConfig.cleanMaxRetainAppCount, beforeDays: cleanStrategyConfig.cleanBeforeDays)

        deleteGadgetMetaAndPkg(allGadgetMetas: allGadgetMetas,
                               needRetainApps: needRetainApps,
                               deleteAction: deleteAction)
    }

    func deleteGadgetMetaAndPkg(allGadgetMetas: [AppMetaProtocol],
                                needRetainApps: [String],
                                deleteAction: DeleteActionCallback) {
        let needDeleteAppMetas = needDeleteGadgetMetaArray(allAppArray: allGadgetMetas, retainAppArray: needRetainApps)

        Self.logger.info("[OPGadgetCleanStrategy] allAppCount: \(allGadgetMetas.count) retainApps: \(needRetainApps) needDeleteCount: \(needDeleteAppMetas.count)")

        // 获取所有小程序包大小Map表, 后面数据上报使用
        let pkgSizeMap = OPGadgetCleanStrategy.packageSizeMap(metas: allGadgetMetas)

        deleteAction(allGadgetMetas, needRetainApps, needDeleteAppMetas, pkgSizeMap)
    }
    
    static func packageSizeMap(metas: [AppMetaProtocol]) -> [String : Int] {
        var pkgSizeMap = [String : Int]()
        metas.map {
            let tracing = BDPTracingManager.sharedInstance().getTracingBy($0.uniqueID) ?? BDPTracingManager.sharedInstance().generateTracing(by:$0.uniqueID)
            return BDPPackageContext(appMeta: $0, packageType: .pkg, packageName: nil, trace: tracing)
        }.forEach({ context in
            let pkgReader = BDPPackageManagerStrategy.packageReaderAfterDownloaded(for: context)

            var fileSize = 0
            // 获取对应包的大小
            if let streamReader = pkgReader as? BDPPackageStreamingFileHandle {
                fileSize = Int(LSFileSystem.fileSize(path: streamReader.pkgPath))
            } else {
                Self.logger.error("[OPGadgetCleanStrategy] cannot convert BDPPackageStreamingFileHandle")
            }
            // 这边只是小程序,使用appID作为Key
            pkgSizeMap[BDPSafeString(context.uniqueID.appID)] = fileSize
        })

        return pkgSizeMap
    }

    /// 筛选出需要删除的小程序meta(近期经常使用和在热缓存中的不需要删除)
    public func needDeleteGadgetMetaArray(allAppArray: [AppMetaProtocol],
                                          retainAppArray: [String]) -> [AppMetaProtocol] {
        var needDeleteAppArray = [AppMetaProtocol]()

        for appMeta in allAppArray {
            // 正在运行的小程序的pkg包不应删除
            if BDPWarmBootManager.shared().appIsRunning(appMeta.uniqueID) {
                continue
            }
            // 近期常用小程序的pkg包不应删除
            if retainAppArray.contains(BDPSafeString(appMeta.uniqueID.appID)) {
                continue
            }

            needDeleteAppArray.append(appMeta)
        }

        return needDeleteAppArray
    }

    /// 获取用户常用小程序AppIDs
    public func retainAppArray(retainCount: Int, beforeDays: Int) -> [String] {
        return LaunchInfoAccessorFactory.launchInfoAccessor(type: .gadget)?.queryTop(most: retainCount, beforeDays: beforeDays) ?? [String]()
    }
}

