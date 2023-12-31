//
//  OPGadgetLoader.swift
//  OPGadget
//
//  Created by lixiaorui on 2020/12/2.
//

import Foundation
import OPSDK
import TTMicroApp
import LKCommonsLogging

extension OPAppLoaderStrategy {
    func toLoadType() -> CommonAppLoadType {
        var load_type: CommonAppLoadType = .normal
        if (self == .update) {
            load_type = .async
        } else if (self == .preload) {
            load_type = .preload
        }
        return load_type
    }
}

extension OPGadgetLoader: BDPPreloadHandleInjector {
    public func onInjectMeta(uniqueID: OPAppUniqueID, handleInfo: BDPPreloadHandleInfo) -> OPBizMetaProtocol? {
        if let extra = handleInfo.extra,
           let injectedMeta = extra["injectedMeta"] as? OPBizMetaProtocol? {
            return injectedMeta
        }
        return nil
    }
    
    public func onInjectInterceptor(scene: BDPPreloadScene, handleInfo: BDPPreloadHandleInfo) -> [BDPPreHandleInterceptor]? {
        return nil
    }
}

/// 小程序的Loader，对外提供基础方法及回调协议事件，内部目前使用了统一的metaModule和packageModule
public final class OPGadgetLoader: NSObject, OPAppLoaderProtocol {
    static let logger = Logger.oplog(OPGadgetLoader.self, category: "OPGadgetLoader")

    public let loaderContext:  OPAppLoaderContext
    public let startPage:  String?
    private let metaProvider: MetaInfoModuleProtocol
    private let packageProvider: BDPPackageModuleProtocol

    init?(applicationContext: OPApplicationContext, startPage: String?, uniqueID: OPAppUniqueID, previewToken: String) {
        guard let metaManager = BDPModuleManager(of: .gadget)
            .resolveModule(with: MetaInfoModuleProtocol.self) as? MetaInfoModuleProtocol else {
            _ = OPError.error(monitorCode: OPSDKMonitorCode.has_no_module_manager, message: "has no meta module manager for gadget for app \(uniqueID)")
            OPAssertionFailureWithLog("has no meta module manager for gadget for app \(uniqueID)")
            return nil
        }
        guard let packageManager = BDPModuleManager(of: .gadget)
            .resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol else {
            _ = OPError.error(monitorCode: OPSDKMonitorCode.has_no_module_manager, message: "has no pkg module manager for gadget for app \(uniqueID)")
            OPAssertionFailureWithLog("has no pkg module manager for gadget for app \(uniqueID)")
            return nil
        }
        self.startPage = startPage
        self.metaProvider = metaManager
        self.packageProvider = packageManager
        self.loaderContext = OPAppLoaderContext(applicationContext: applicationContext, uniqueID: uniqueID, previewToken: previewToken)
    }
    
    /// 仅提供批量拉取场景使用
    /// - Parameter builder:
    public convenience override init() {
        //如果要在外部获得block 的metaprovider，需要伪造一系列的对象
        let appID = "gadget_batch"
        let batchUniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType:.current, appType: .gadget)
        // 这边从OPApplicationService单例中取applicationServiceContext,避免在子线程中构造OPApplicationServiceContext对象(该对象构造方法会读取UIApplication对象)
        let applicationServiceCtx = OPApplicationService.current.applicationServiceContext
        let applicationContext = OPApplicationContext(applicationServiceContext: applicationServiceCtx, appID: appID)
        self.init(applicationContext: applicationContext, startPage: nil, uniqueID: batchUniqueID, previewToken: "")!
    }
    
    public func batchRemoteMetaWith(_ params: [String: String],
                                    strategy: OPAppLoaderStrategy,
                                    batchCompleteCallback: (([(String, AppMetaProtocol?, OPError?)]?, OPError?) -> Void)?) {
        Self.logger.info("batchRemoteMetaWith parameters:\(params) strategy:\(strategy.rawValue)")
        let metaContext = MetaContext(uniqueID:self.loaderContext.uniqueID, token: nil, extra: params)
        self.getRemoteMeta(metaContext: metaContext,
                           params: params,
                           scene: .preloadLaunch,
                           strategy: strategy,
                           listener: nil,
                           batchCompleteCallback: batchCompleteCallback,
                           completeHandler: nil)
    }

    //小程序启动的 meta 拉取入口
    private func getRemoteMeta(metaContext: MetaContext,
                               strategy: OPAppLoaderStrategy,
                               listener: OPAppLoaderMetaAndPackageEvent?,
                               batchCompleteCallback: (([(String, AppMetaProtocol?, OPError?)]?, OPError?) -> Void)? = nil,
                               completeHandler: ((AppMetaProtocol?, (()->Void)?) -> Void)?) {
        //如果是预安装，且参数里带了extra，也走批量接口
        let enablePreloadBatch = BDPBatchMetaHelper.batchMetaConfig().enable && metaContext.extra != nil && batchCompleteCallback != nil && strategy == .preload
        //如果开关开启，且更新类型为异步更新，则用批量更新方式
        let enableGadgetLaunchBatch = BDPBatchMetaHelper.batchMetaConfig().enable && BDPBatchMetaHelper.batchMetaConfig().enableOnLaunchGadget && strategy == .update
        Self.logger.info("fetch meta with enablePreloadBatch:\(enablePreloadBatch) enableGadgetLaunchBatch:\(enableGadgetLaunchBatch)")
        var params:[String: String] = metaContext.extra as? [String: String] ?? [:]
        var scene: BatchLaunchScene? = nil

        // 这边现在批量请求参数中加入预拉取定制化数据(配置在'custom_package_prehandle'这个settings)
        let prehandleCustomizeConfig = BDPPreloadHelper.prehandleCustomizeConfig()

        if enablePreloadBatch || enableGadgetLaunchBatch {
            scene = .preloadLaunch
            if enableGadgetLaunchBatch {
                //先添加一个启动的 appID，这个版本可以为任意
                params = [metaContext.uniqueID.appID: ""]
                scene = .gadgetLaunch
            }
            //拼装参数，先拿列表，然后去数据库查版本信息
            let appIDArray = LaunchInfoAccessorFactory.launchInfoAccessor(type: .gadget)?.queryTop(most: BDPPreloadHelper.clientStrategySingleMaxCount(), beforeDays: BDPPreloadHelper.clientStrategyBeforeDays())

            // 过滤掉当前启动的小程序的appID
            if prehandleCustomizeConfig.enable {
                let prehandleCustomizeAppIDs = prehandleCustomizeConfig.customizePrehandleAppIDs.filter{ $0 != metaContext.uniqueID.appID }
                Self.logger.info("[PreloadSettings] gadgetLaunch batch customs: \(prehandleCustomizeAppIDs)")
                prehandleCustomizeAppIDs.forEach {
                    params[$0] = ""
                }
            }

            appIDArray?.filter{ $0 != metaContext.uniqueID.appID }.forEach {
                let metaContext = MetaContext(uniqueID: BDPUniqueID(appID: $0, identifier: nil, versionType: .current, appType: .gadget), token: nil)
                let gadgetMeta = self.metaProvider.getLocalMeta(with: metaContext) as? OPBizMetaProtocol
                params[$0] = gadgetMeta?.appVersion ?? ""
            }
        }
        self.getRemoteMeta(metaContext: metaContext,
                           params: params,
                           scene: scene,
                           strategy: strategy,
                           listener: listener,
                           batchCompleteCallback: { resultList, error in
            //非当前启动的小程序, 不需要对外触发 success/fail 的callback
            //直接启动预安装任务流程
            //过滤掉已经在异步启动任务里的 appID（走默认的异步流程），以及异常 meta 的结果后
            //映射到 BDPPreloadHandleInfo 模型，开始批量拉取任务
            batchCompleteCallback?(resultList, error)
            if let resultList = resultList {
                let preloadHanleInfoList = resultList.filter{
                    $0.0 != metaContext.uniqueID.appID &&
                    $0.1 != nil &&
                    $0.2 == nil }.compactMap {
                        return self.configPreloadHandleInfo(customizeConfig: prehandleCustomizeConfig, appID: BDPSafeString($0.0), injectedMeta: $0.1)
                    }
                Self.logger.info("begin to handle pkg preload event with list:\(preloadHanleInfoList)")
                BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: preloadHanleInfoList)
            }
        }, completeHandler: completeHandler)
    }
    
    private func getRemoteMeta(metaContext: MetaContext,
                               params: [String: String],
                               scene: BatchLaunchScene?,
                               strategy: OPAppLoaderStrategy,
                               listener: OPAppLoaderMetaAndPackageEvent?,
                               batchCompleteCallback: (([(String, AppMetaProtocol?, OPError?)]?, OPError?) -> Void)? = nil,
                               completeHandler: ((AppMetaProtocol?, (()->Void)?) -> Void)?) {
        /// meta started
        listener?.onMetaLoadStarted(strategy: strategy)
        
        OPMonitor(kEventName_op_common_load_meta_start)
            .setAppLoadInfo(metaContext, strategy.toLoadType())
            .flush()
        let loadMetaResult = OPMonitor(kEventName_op_common_load_meta_result)
            .setAppLoadInfo(metaContext, strategy.toLoadType())
            .addCategoryValue("meta_cache", 0)
            .timing()
        
        let successCallback : ((AppMetaProtocol, (() -> Void)?) -> Void) = {(meta, saveMetaHandler) in
            /// meta completed
            listener?.onMetaLoadProgress(strategy: strategy, current: 1.0, total: 1.0)
            guard let gadgetMeta = meta as? OPBizMetaProtocol else {
                let error = OPError.error(monitorCode: GDMonitorCodeAppLoad.invalid_meta_type, message: "meta invalid type for app \(metaContext.uniqueID)")
                listener?.onMetaLoadComplete(strategy: strategy, success: false, meta: nil, error: error, fromCache: false)
                loadMetaResult
                    .setError(error)
                    .setResultTypeFail()
                    .timing()
                    .flush()
                return
            }
            listener?.onMetaLoadComplete(strategy: strategy, success: true, meta: gadgetMeta, error: nil, fromCache: false)
            loadMetaResult
                .setResultTypeSuccess()
                .timing()
                .flush()
            completeHandler?(meta, saveMetaHandler)
        }
        
        let failureCallback: ((OPError) -> Void) = { (error) in
            /// meta error
            loadMetaResult
                .setError(error)
                .setResultTypeFail()
                .timing()
                .flush()
            listener?.onMetaLoadProgress(strategy: strategy, current: 1.0, total: 1.0)
            listener?.onMetaLoadComplete(strategy: strategy, success: false, meta: nil, error: error, fromCache: false)
            ///失败时需要执行批量的回调
            batchCompleteCallback?(nil, error)
            ///如果调用失败，增加一次回调
            completeHandler?(nil, nil)
        }
        if let scene = scene {
            loadMetaResult.addCategoryValue("batch_meta", true)
            loadMetaResult.addCategoryValue("batch_scene", scene.rawValue)
            Self.logger.info("batch fetch meta with parameters:\(params) size:\(params.keys.count) with scene:\(scene)")
            _ = (metaProvider as? MetaInfoModule)?.batchRequestRemoteMeta(params,
                                                                          scene: scene,
                                                                          shouldSaveMeta: false,
                                                                          success: { (resultList, saveMetaHandler) in
                Self.logger.info("begin to callback with result:\(resultList)")
                //保证原有的事件回调
                resultList.forEach {appID, meta, error in
                    if metaContext.uniqueID.appID == appID {
                        if let meta = meta as? GadgetMeta {
                            successCallback(meta, saveMetaHandler)
                        } else {
                            let opError = error ?? OPError.error(monitorCode: CommonMonitorCodeMeta.meta_response_not_exist, message: "batch meta return with nil")
                            failureCallback(opError)
                        }
                    }
                }
                let batch_result = resultList.compactMap{
                    return "\($0.0):\($0.1 != nil ? "success" : "fail")"
                }.joined(separator: "*")
                loadMetaResult.addCategoryValue("batch_result", batch_result)
                //执行批量的回调
                batchCompleteCallback?(resultList, nil)
            },
                                                                      failure: failureCallback)
            
            return
        }
        
        metaProvider.requestRemoteMeta(with: metaContext, shouldSaveMeta: false, success: successCallback, failure: failureCallback)
    }

    private func getRemotePackage(strategy: OPAppLoaderStrategy, meta: AppMetaProtocol, metaTrace: BDPTracing, listener: OPAppLoaderMetaAndPackageEvent?, successHandler: (()->Void)?) {
        let packageContext = BDPPackageContext(appMeta: meta, packageType: .pkg, packageName: nil, trace: metaTrace)
        packageContext.updateStartPage(startPage)

        let downloadBeginBlock: BDPPackageDownloaderBegunBlock  = { (reader) in
            guard let gadgetReader = reader as? BDPPackageStreamingFileHandle else {
                _ = OPError.error(monitorCode: GDMonitorCodeAppLoad.package_manager_return_error_file_reader, message: "package manager return error file reader for app \(meta.uniqueID)")
                OPAssertionFailureWithLog("has no meta module manager for gadget for app \(meta.uniqueID)")
                return
            }
            gadgetReader.handle(whenHeaderReady: {
                listener?.onPackageReaderReady(strategy: strategy, reader: gadgetReader)
            })
        }
        let downloadProgressBlock: BDPPackageDownloaderProgressBlock  = {(current, total, _) in
            listener?.onPackageLoadProgress(strategy: strategy, current: Float(current), total: Float(total))
        }
        OPMonitor(kEventName_op_common_load_package_start)
            .addTag(.appLoad)
            .setUniqueID(meta.uniqueID)
            .setLoadType(strategy.toLoadType())
            .flush()
        let loadPkgResult = OPMonitor(kEventName_op_common_load_package_result)
            .addTag(.appLoad)
            .setUniqueID(meta.uniqueID)
            .setLoadType(strategy.toLoadType())
            .timing()
        let downloadCompletion: BDPPackageDownloaderCompletedBlock = {(error, _, reader) in
            var packageCache = 0
            if let createLoadStatus = reader?.createLoadStatus(),
                createLoadStatus.rawValue >= BDPPkgFileLoadStatus.downloaded.rawValue {
                packageCache = 1
            }
            loadPkgResult.addCategoryValue("package_cache", packageCache)
            let pkgSource = PKMDiffPackageDownloader.packageSourceType(with: packageContext)
            loadPkgResult.addCategoryValue("package_source", pkgSource.rawValue)
            guard error == nil , reader != nil else {
                loadPkgResult
                    .setError(error)
                    .timing()
                    .setResultTypeFail()
                    .flush()
                listener?.onPackageLoadComplete(strategy: strategy, success: false, error: error)
                return
            }
            successHandler?()
            loadPkgResult
                .setResultTypeSuccess()
                .timing()
                .flush()
            listener?.onPackageLoadComplete(strategy: strategy, success: true, error: nil)
        }
        switch strategy {
        case .preload:
            packageProvider.predownloadPackage(with: packageContext, priority: strategy.packageDownloadPriority, begun: downloadBeginBlock, progress: downloadProgressBlock, completed: downloadCompletion)
        case .normal:
            packageProvider.normalLoadPackage(with: packageContext, priority: strategy.packageDownloadPriority, begun: downloadBeginBlock, progress: downloadProgressBlock, completed: downloadCompletion)
        default:
            packageProvider.asyncDownloadPackage(with: packageContext, priority: strategy.packageDownloadPriority, begun: downloadBeginBlock, progress: downloadProgressBlock, completed: downloadCompletion)
        }

    }

    private func getLocalPackage(strategy: OPAppLoaderStrategy, meta: AppMetaProtocol, metaTrace: BDPTracing, listener: OPAppLoaderMetaAndPackageEvent?) {
        let packageContext =  BDPPackageContext(appMeta: meta, packageType: .pkg, packageName: nil, trace: metaTrace)
        listener?.onPackageLoadStart(strategy: strategy)
        listener?.onPackageLoadProgress(strategy: strategy, current: 1.0, total: 1.0)
        // 本地有包时，返回reader
        if self.packageProvider.isLocalPackageExsit(packageContext) {
            let reader = BDPPackageManagerStrategy.packageReaderAfterDownloaded(for: packageContext)
            listener?.onPackageReaderReady(strategy: strategy, reader: reader as! OPPackageReaderProtocol)
            listener?.onPackageLoadComplete(strategy: strategy, success: true, error: nil)
        } else {
            listener?.onPackageLoadComplete(strategy: strategy, success: false, error: nil)
        }
    }

    private func internalUpdateMetaAndPackage(strategy: OPAppLoaderStrategy, listener: OPAppLoaderMetaAndPackageEvent?, failHandler: (() -> Void)?) {
        let uniqueID = loaderContext.uniqueID
        let metaContext = MetaContext(uniqueID: uniqueID, token: loaderContext.previewToken)
        getRemoteMeta(metaContext: metaContext, strategy: strategy, listener: listener) { (meta, saveMetaHandler) in
            guard let meta = meta else {
                failHandler?()
                return;
            }
            let localMeta = self.metaProvider.getLocalMeta(with: metaContext)
            let localVersion = localMeta?.version
            //FG打开时，不管meta版本与本地的差异，都去「尝试」下一次包（并不会真正去下载，内部有 isDownlaoded 判断）
            if OPSDKFeatureGating.enableMetaSaveVersionCheckRemove() {
                // 包有更新，需要去下载
                self.getRemotePackage(strategy: strategy, meta: meta, metaTrace: metaContext.trace, listener: listener) {
                    saveMetaHandler?()
                }
            } else {
                //  版本更新才需要异步更新包（之前头条还判断了version_code和md5，但是在飞书开放平台，version不一样，必定是发了个新包上去，需要下载）
                if meta.version == localVersion {
                    // meta更新了但是包没更新也需要持久化
                    saveMetaHandler?()
                    // 本地有包时，返回reader
                    self.getLocalPackage(strategy: strategy, meta: meta, metaTrace: metaContext.trace, listener: listener)
                } else {
                    // 包有更新，需要去下载
                    self.getRemotePackage(strategy: strategy, meta: meta, metaTrace: metaContext.trace, listener: listener) {
                        saveMetaHandler?()
                    }
                }
            }
            if let module = BDPModuleManager(of: .gadget).resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol ,
               let localMeta = localMeta as? GadgetMeta,
                let meta = meta as? GadgetMeta {
                let pkgName = localMeta.packageData.urls.first?.path.bdp_fileName() ?? ""
                let readTypes = module.packageInfoManager.queryPkgReadType(of: uniqueID, pkgName: pkgName)
                // 获取包对应的预安装信息
                let prehandleInfo = self.prehandlMonitorInfo(module.packageInfoManager, for: uniqueID, with: pkgName)
                let prehandleSceneName = prehandleInfo.0
                let preUpdatePullType = prehandleInfo.1
                if let readType = readTypes.first {
                    //如果异步更新的版本和缓存的一致，作为有效预处理
                    let prehandle_effective = (localMeta.appVersion == meta.appVersion) && (localMeta.version == localMeta.version)
                    OPMonitor(EPMClientOpenPlatformGadgetPrehandleCode.op_prehandle_accuracy)
                        .setUniqueID(uniqueID)
                        .addCategoryValue("package_type", BDPPkgFileReadTypeInfo(BDPPkgFileReadType(rawValue: readType.intValue) ?? BDPPkgFileReadType.unknown))
                        .addCategoryValue("cache_version", localMeta.appVersion)
                        .addCategoryValue("async_version", meta.appVersion)
                        .addCategoryValue("prehandle_effective", prehandle_effective ? 1 : 0)
                        .addCategoryValue("prehandle_scene", prehandleSceneName)
                        .addCategoryValue("pull_type", preUpdatePullType)
                        .flush()
                }
                
            }
        }
    }

    public func preloadMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?) {
        internalUpdateMetaAndPackage(strategy: .preload, listener: listener){}
    }

    public func asyncUpdateMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?) {
        internalUpdateMetaAndPackage(strategy: .update, listener: listener){}
    }

    public func loadMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?) {
        let uniqueID = loaderContext.uniqueID
        let metaContext = MetaContext(uniqueID: uniqueID, token: loaderContext.previewToken)
        // perview每次都获取最新的，不取本地
        var localMeta = metaProvider.getLocalMeta(with: metaContext)

        // 这边记录包加载时间
        if let newUpdater = OPSDKConfigProvider.silenceUpdater?(.gadget), newUpdater.enableSlienceUpdate() {
            // 新产品化止血逻辑
            newUpdater.updateAppLaunchTime(uniqueID)
        } else {
            //原产品化止血逻辑
            OPPackageSilenceUpdateServer.shared.updateAppLaunchTime(uniqueID)
        }

        // 判断是否满足产品化止血方案
        var canSilenceUpdate = false
        // 新产品化止血逻辑
        if let newUpdater = OPSDKConfigProvider.silenceUpdater?(.gadget), newUpdater.enableSlienceUpdate(), let gadgetMeta = localMeta as? GadgetMeta {
            if let mountData = OPApplicationService.current.getContainer(uniuqeID: uniqueID)?.containerContext.currentMountData as? OPGadgetContainerMountData,
               let launchLeastAppVersion = mountData.customFields?["least_app_version"] as? String {
                canSilenceUpdate = newUpdater.canSilenceUpdate(uniqueID: uniqueID, metaAppVersion: gadgetMeta.appVersion, launchLeastAppVersion: launchLeastAppVersion)
            } else {
                canSilenceUpdate = newUpdater.canSilenceUpdate(uniqueID: uniqueID, metaAppVersion: gadgetMeta.appVersion)
            }
        } else if let gadgetMeta = localMeta as? GadgetMeta  {
            //原产品化止血逻辑
            // 如果用户在applink中传入了least_app_version字段,则需要带上该字段一起判断是否满足止血要求
            if let application = OPApplicationService.current.getApplication(appID: uniqueID.appID),
               let mountData = application.getContainer(uniqueID: uniqueID)?.containerContext.currentMountData as? OPGadgetContainerMountData,
               let launchLeastAppVersion = mountData.customFields?["least_app_version"] as? String {
                canSilenceUpdate = OPPackageSilenceUpdateServer.shared.canSilenceUpdate(uniqueID: uniqueID, metaAppVersion: gadgetMeta.appVersion, launchLeastAppVersion: launchLeastAppVersion)
            } else {
                canSilenceUpdate = OPPackageSilenceUpdateServer.shared.canSilenceUpdate(uniqueID: uniqueID, metaAppVersion: gadgetMeta.appVersion)
            }
        } else {
            Self.logger.info("silenceUpdate can not convert localMeta to GadgetMeta")
        }
        //isBoxOff 为 true的时候，不能执行止血（过期）操作
        if OPSDKFeatureGating.isBoxOff() {
            canSilenceUpdate = false
        } else if OPSDKFeatureGating.isEnableApplePie() {
            //应用ID在ODR名单内的时候，不止血
            canSilenceUpdate = canSilenceUpdate && OPSDKFeatureGating.canSilenceUpdateOrExpire(uniqueID)
        } else {
            Self.logger.info("canSilenceUpdate:\(canSilenceUpdate), default logic")
        }
        // 当应用满足产品化止血要求时,走产品化止血逻辑; 否则进入原止血判断逻辑.
        if localMeta != nil && canSilenceUpdate { // 产品化止血方案
            localMeta = nil
            uniqueID.silenceUpdateType = .product
            Self.logger.info("uniqueID: \(uniqueID) canSilenceUpdate: \(canSilenceUpdate)")
        } else if localMeta != nil { // 原止血方案, 走的settings
            //比较止血版本，如果比本地meta版本高，则清空 localMeta～需要走GetRemoteMeta
            localMeta = BDPVersionManager.compareVersion(uniqueID.leastVersion, with: localMeta?.version) > 0 ? nil : localMeta
            uniqueID.silenceUpdateType = localMeta == nil ? .settings : .none
            Self.logger.info("uniqueID: \(uniqueID) is old update: \(localMeta == nil)")
        } else { // 不走任何止血方案
            uniqueID.silenceUpdateType = .none
        }
        //处理 sync_try/sync_froce 的逻辑
        var strategy = OPGadgetMetaUpdateStrategy.async
        if let timestamp = localMeta?.getLastUpdateTimestamp() {
            strategy = OPMetaChecker(uniqueID).checkGadgetMetaUpdateStrategy(timestamp.doubleValue)
        }

        uniqueID.metaUpdateStrategy = strategy

        Self.logger.info("\(uniqueID.fullString) metaUpdateStrategy is \(strategy)")
        
        //检查批量数据版本是否过期策略
        if let gadgetMeta = localMeta as? GadgetMeta,
           gadgetMeta.batchMetaVersion > 0,
           gadgetMeta.batchMetaVersion < BDPBatchMetaHelper.batchMetaConfig().batchMetaVersion {
            //数据来自批量获取，且版本已经过期，需要丢弃
            localMeta = nil
            Self.logger.info("\(uniqueID.fullString) batchMetaVersion is \(gadgetMeta.batchMetaVersion), but latest is:\(BDPBatchMetaHelper.batchMetaConfig().batchMetaVersion), meta expired")
        }

        // 是否走PKM新架构逻辑
        if OPSDKFeatureGating.pkmLoadMetaAndPkgEnable() {
            //使用PKM去加载meta和pkg
            pkmLoadMetaAndPkg(metaContext: metaContext,
                              useLocalMeta: localMeta != nil,
                              startPage: startPage,
                              strategy: strategy,
                              listener: listener)
            return
        }

        // 是否开启prerun能力开关
        if BDPPreRunManager.sharedInstance.enablePreRun, let cacheModel = BDPPreRunManager.sharedInstance.cacheModel(for: uniqueID) {
            let gadgetMeta = localMeta as? GadgetMeta
            // 1.这边如果没有本地包(可能是无包或者需要止血)
            // 2.这边如果触发了meta过期策略
            // 3.prerun缓存的Meta的应用版本与启动使用的版本信息不一致
            // 满足3个条件中任意一个,则清除prerun缓存.
            if localMeta == nil
                || strategy != .async
                || cacheModel.cachedMeta?.appVersion != gadgetMeta?.appVersion {
                Self.logger.info("[PreRun] clean cache localMeta is nil? \(localMeta == nil), expired strategy: \(strategy.rawValue) cached version: \(String(describing: cacheModel.cachedMeta?.appVersion)) localMeta version: \(String(describing: gadgetMeta?.appVersion))")
                BDPPreRunManager.sharedInstance.reportCacheModalFailMonitor(.cacheNotMatch)
                BDPPreRunManager.sharedInstance.cleanAllCache()
            }
        }

        if uniqueID.versionType != .preview, strategy != .syncForce, let localMeta = localMeta {
        //把原有的 async 处理流程封成闭包，降级时复用
        let asyncOperation = {
            OPMonitor(kEventName_op_common_load_meta_start)
                .setAppLoadInfo(metaContext, CommonAppLoadType.normal)
                .flush()

            let loadMetaResult = OPMonitor(kEventName_op_common_load_meta_result)
                .setAppLoadInfo(metaContext, CommonAppLoadType.normal)
                .addCategoryValue("meta_cache", 1)
                .timing()

            listener?.onMetaLoadStarted(strategy: .normal)
            listener?.onMetaLoadProgress(strategy: .normal, current: 1.0, total: 1.0)
            guard let gadgetMeta = localMeta as? OPBizMetaProtocol else {
                let error = OPError.error(monitorCode: GDMonitorCodeAppLoad.invalid_meta_type, message: "meta invalid type for app \(uniqueID)")
                assertionFailure("meta invalid type for app \(uniqueID)")
                listener?.onMetaLoadComplete(strategy: .normal, success: false, meta: nil, error: error, fromCache: false)
                loadMetaResult
                    .setError(error)
                    .setResultTypeFail()
                    .flush()
                return
            }
            listener?.onMetaLoadComplete(strategy: .normal, success: true, meta: gadgetMeta, error: nil, fromCache: true)
            loadMetaResult
                .setResultTypeSuccess()
                .flush()
            self.getRemotePackage(strategy: .normal, meta: localMeta, metaTrace: metaContext.trace, listener: listener, successHandler: nil)
            //异步 getAppMeta 和更新包的操作，延长调用。保障首次启动时候的 TTI
            //延迟发起异步更新请求
            DispatchQueue.global().asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(4)) {
                self.internalUpdateMetaAndPackage(strategy: .update, listener: listener) {}
            }
        }
            if strategy == .async {
                asyncOperation()
            } else {
                //同步尝试更新，如果失败了需要降级，流程和无缓存启动时一致。
                self.getRemoteMeta(metaContext: metaContext, strategy: .normal, listener: listener) { meta, saveMetaHandler in
                    guard let meta = meta else {
                        Self.logger.info("sync try with uniqueID: \(uniqueID) but meta is nil，downgrade to cache local")
                        //降级处理
                        asyncOperation()
                        return
                    }
                    self.getRemotePackage(strategy: .normal, meta: meta, metaTrace: metaContext.trace, listener: listener) {
                        //这里保证了pkg下载完成之后才会保存meta，如果包没有下载成功本地就不存meta
    //                    https://bytedance.feishu.cn/wiki/wikcnPgXrgAngsnZDnKgqq7oSkg
                        saveMetaHandler?()
                    }
                }
            }
        } else {
            self.getRemoteMeta(metaContext: metaContext, strategy: .normal, listener: listener) { (meta, saveMetaHandler) in
                guard let meta = meta else {
                    Self.logger.info("uniqueID: \(uniqueID) meta is nil")
                    return
                }
                self.getRemotePackage(strategy: .normal, meta: meta, metaTrace: metaContext.trace, listener: listener) {
                    //这里保证了pkg下载完成之后才会保存meta，如果包没有下载成功本地就不存meta
//                    https://bytedance.feishu.cn/wiki/wikcnPgXrgAngsnZDnKgqq7oSkg
                    saveMetaHandler?()
                }
            }
        }
    }

    public func cancelLoadMetaAndPackage() {
        // 目前逻辑并没有取消，还是继续相关请求，只是UI自己不处理回调了
    }

}

extension OPGadgetLoader {
    func prehandlMonitorInfo(_ packageInfoManager: BDPPackageInfoManagerProtocol?, for uniqueID: OPAppUniqueID, with pkgName: String ) -> (String, Int) {
        let commonDefaultValue = ("unknown", -1)
        guard OPSDKFeatureGating.packageExtReadWriteEnable() else {
            return commonDefaultValue
        }

        guard let packageInfoManager = packageInfoManager,
              let extDic = packageInfoManager.extDictionary(uniqueID, pkgName: pkgName) else {
            return commonDefaultValue
        }

        let prehandleSceneName = extDic[kPkgTableExtPrehandleSceneKey] as? String ?? "unknown"
        let preUpdatePullType = extDic[kPkgTableExtPreUpdatePullTypeKey] as? Int ?? -1

        return (prehandleSceneName, preUpdatePullType)
    }

    /// 创建对应的PrehandleInfo对象
    /// - Parameters:
    ///   - customizeConfig: 定制化拉取settings配置对象
    ///   - appID: 应用ID
    ///   - injectedMeta: 注入的meta对象
    /// - Returns: PrehandleInfo对象
    func configPreloadHandleInfo(customizeConfig: BDPPrehandleCustomizeConfig,
                                 appID: String,
                                 injectedMeta: AppMetaProtocol?) -> BDPPreloadHandleInfo {
        var extra: [String : Any]? = nil
        if let _injectedMeta = injectedMeta {
            extra = ["injectedMeta": _injectedMeta]
        }

        // 当前appID是否在定制化拉取白名单中
        let hitCustomizeStrategy = customizeConfig.enable && customizeConfig.customizePrehandleAppIDs.contains(appID)
        if hitCustomizeStrategy {
            if var _extra = extra {
                _extra["PreUpdatePullType"] = BDPPrehandleDataSource.settings.rawValue
            } else {
                extra = ["PreUpdatePullType" : BDPPrehandleDataSource.settings.rawValue]
            }
        }
        return BDPPreloadHandleInfo(uniqueID: BDPUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget), scene: .AppLaunch, scheduleType: .toBeScheduled, extra: extra, listener: nil, injector: self)
    }
}

extension OPGadgetLoader {
    func pkmLoadMetaAndPkg(metaContext: MetaContext,
                           useLocalMeta: Bool,
                           startPage: String?,
                           strategy: OPGadgetMetaUpdateStrategy,
                           listener: OPAppLoaderMetaAndPackageEvent?) {
        let uniqueID = metaContext.uniqueID

        let pkmID = PKMUniqueID(appID: uniqueID.appID, identifier: nil)

        var extra: [String : Any]?
        if let startPage = startPage {
            extra = ["pkm_startPage" : startPage]
        }

        let updateStrategy = OPGadgetPKMStrategy(uniqueID: metaContext.uniqueID, loadType: .normal, useLocalMeta: useLocalMeta, expireStrategy: strategy, metaProvider: GadgetMetaProvider(type: .gadget), extra: extra)

        let params = PKMAppTriggerParams(uniqueID: pkmID, bizeType: .gadget, appVersion: nil, previewToken: metaContext.token, strategy: updateStrategy, metaBuilder: updateStrategy)

        PKMTriggerManager.shared.triggerOpenAppUpdate(with: params) { prepareProgress, pkgResource, params in
            let loadStrategy = params.strategy.loadType.toAppLoaderStrategy()
            if prepareProgress.process == .loadMetaStart {
                listener?.onMetaLoadStarted(strategy: loadStrategy)
            }
            if prepareProgress.process == .loadMetaComplete {
                listener?.onMetaLoadProgress(strategy: loadStrategy, current: 1, total: 1)
                if let appMeta = pkgResource?.meta as? GadgetMeta {
                    // 获取meta中的BDPUniqueID对象是PKM内部构造的
                    // 需要替换成原上下文中的BDPUniqueID对象,否则一些信息会丢失(例如instanceID)
                    appMeta.updateUniqueID(uniqueID)
                    listener?.onMetaLoadComplete(strategy: loadStrategy, success: true, meta: appMeta, error: nil, fromCache: pkgResource?.metaFromCache ?? false)
                } else {
                    listener?.onMetaLoadComplete(strategy: loadStrategy, success: false, meta: nil, error: nil, fromCache: false)
                }
            }

            if prepareProgress.process == .loadPkgReady, let gadgetReader = pkgResource?.pkgReader?.originReader as? BDPPackageStreamingFileHandle {
                gadgetReader.handle(whenHeaderReady: {
                    listener?.onPackageReaderReady(strategy: loadStrategy, reader: gadgetReader)
                })
            }

            if prepareProgress.process == .loadPkgProgress {
                listener?.onPackageLoadProgress(strategy: loadStrategy, current: Float(prepareProgress.pkgReceiveSize), total: Float(prepareProgress.pkgExpectedSize))
            }
        } completionCallback: { result, pkgResource, params in
            let loadStrategy = params.strategy.loadType.toAppLoaderStrategy()
            guard result.success, result.error == nil else {
                let opError = result.error?.originError as? OPError ?? OPSDKMonitorCode.unknown_error.error(message: "origin error type incorrect")
                // 这边要区分是meta出错了还是pkg出错
                if let pkmError = result.error {
                    switch pkmError.domain {
                    case .MetaError:
                        listener?.onMetaLoadComplete(strategy: loadStrategy, success: false, meta: nil, error: opError, fromCache: false)
                    case .PkgError:
                        listener?.onPackageLoadComplete(strategy: loadStrategy, success: false, error: opError)
                    @unknown default:
                        OPAssertionFailureWithLog("[PKM] should not enter unknown default \(pkmID.appID)")
                        listener?.onPackageLoadComplete(strategy: loadStrategy, success: false, error: opError)
                    }
                } else {
                    Self.logger.warn("[PKM] pkmError is nil \(pkmID.appID)")
                    listener?.onPackageLoadComplete(strategy: loadStrategy, success: false, error: opError)
                }
                return
            }

            guard let _ = pkgResource?.pkgReader?.originReader else {
                listener?.onPackageLoadComplete(strategy: loadStrategy, success: false, error: nil)
                return
            }

            listener?.onPackageLoadComplete(strategy: loadStrategy, success: true, error: nil)
        }

    }
}

struct OPGadgetPKMStrategy: PKMMetaBuilderProtocol & PKMTriggerStrategyProtocol {
    static let logger = Logger.oplog(OPGadgetLoader.self, category: "OPGadgetPKMStrategy")

    let useLocalMeta: Bool

    let uniqueID: BDPUniqueID

    let expireStrategy: OPGadgetMetaUpdateStrategy

    var loadType: TTMicroApp.PKMLoadType

    let metaProvider: MetaFromStringProtocol?

    var pkgDownloadPriority: Float {
        switch loadType {
        case .normal:
            return URLSessionDataTask.highPriority
        default:
            return URLSessionDataTask.lowPriority
        }
    }

    var extra: [String : Any]?

    init(uniqueID: BDPUniqueID,
         loadType: TTMicroApp.PKMLoadType,
         useLocalMeta: Bool,
         expireStrategy: OPGadgetMetaUpdateStrategy,
         metaProvider: MetaFromStringProtocol? = nil,
         extra: [String : Any]? = nil) {
        self.uniqueID = uniqueID
        self.loadType = loadType
        self.useLocalMeta = useLocalMeta
        self.expireStrategy = expireStrategy
        self.metaProvider = metaProvider
        self.extra = extra
    }

    func updateStrategy(_ context: TTMicroApp.PKMTriggerStrategyContext, beforeInvoke: (() -> ())?) -> TTMicroApp.PKMMetaUpdateStrategy {
        //在触发更新逻辑之前的回调事件
        beforeInvoke?()
        // 这里拿到本地meta后去判断是否需要清理prerun缓存
        cleanPrerunCache(with: context.localMeta as? GadgetMeta)
        // 如果本地没有meta信息,则直接走远程策略
        guard let _ = context.localMeta else {
            return .forceRemote
        }
        // 止血或者(批量的meta过期)走远程策略
        guard useLocalMeta else {
            return .forceRemote
        }
        // 根据过期类型决定使用哪种策略
        switch expireStrategy {
        case .async:
            return .useLocal
        case .syncTry:
            return .tryRemote
        default:
            return .forceRemote
        }
    }

    func copy() -> PKMTriggerStrategyProtocol {
        return OPGadgetPKMStrategy(uniqueID: uniqueID, loadType: loadType, useLocalMeta: useLocalMeta, expireStrategy: expireStrategy)
    }

    func buildMeta(with json: String?) -> TTMicroApp.PKMBaseMetaProtocol? {
        guard let json = json else {
            Self.logger.warn("build pkm meta failed: jsonStr is nil")
            return nil
        }
        do {
            guard let gadgetMeta = try metaProvider?.buildMetaModel(with: json) as? GadgetMeta  else {
                Self.logger.warn("build pkm meta failed")
                return nil
            }
            // 获取meta中的BDPUniqueID对象是PKM内部构造的
            // 需要替换成原上下文中的BDPUniqueID对象,否则一些信息会丢失(例如instanceID)
            gadgetMeta.updateUniqueID(self.uniqueID)
            return gadgetMeta
        } catch {
            Self.logger.warn("build pkm meta failed")
            return nil
        }
    }
}

extension OPGadgetPKMStrategy {
    // 清理Prerun缓存
    func cleanPrerunCache(with localMeta: GadgetMeta?) {
        guard BDPPreRunManager.sharedInstance.enablePreRun, let cacheModel = BDPPreRunManager.sharedInstance.cacheModel(for: uniqueID), loadType == .normal else {
            return
        }

        // 1.启动时没有本地meta; 2.meta过期策略非aync;
        // 3.prerun缓存的meta应用版本与启动的meta应用版本不同;4.强制不使用本地缓存meta启动
        if localMeta == nil || expireStrategy != .async || cacheModel.cachedMeta?.appVersion != localMeta?.appVersion || !useLocalMeta {
            Self.logger.info("[PreRun] clean cache localMeta is nil? \(localMeta == nil), expired strategy: \(expireStrategy.rawValue) cached version: \(String(describing: cacheModel.cachedMeta?.appVersion)) localMeta version: \(String(describing: localMeta?.appVersion)) useLocalMeta: \(useLocalMeta)")
            BDPPreRunManager.sharedInstance.reportCacheModalFailMonitor(.cacheNotMatch)
            BDPPreRunManager.sharedInstance.cleanAllCache()
        }
    }
}

fileprivate extension PKMLoadType {
    func toAppLoaderStrategy() -> OPAppLoaderStrategy {
        switch self {
        case .normal:
            return .normal
        case .update:
            return .update
        case .prehandle:
            return .preload
        @unknown default:
            assertionFailure("should not get unknown type")
            return .normal
        }
    }
}
