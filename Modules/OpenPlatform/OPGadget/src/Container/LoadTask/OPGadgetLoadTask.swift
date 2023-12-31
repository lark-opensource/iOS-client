//
//  OPGadgetLoadTask.swift
//  OPGadget
//
//  Created by yinyuan on 2020/12/9.
//

import Foundation
import OPSDK
import TTMicroApp
import LKCommonsLogging
import OPFoundation
import UniverseDesignDialog
import LarkFeatureGating

fileprivate let logger = Logger.oplog(OPGadgetLoadTask.self, category: "OPGadgetLoadTask")

/// 应用启动加载任务
public final class OPGadgetLoadTask: OPTask<OPGadgetLoadTaskInput, OPGadgetLoadTaskOutput> {
    
    weak var delegate: OPGadgetLoadTaskDelegate?
    
    private weak var bundleLoadTask: OPGadgetBundleLoadTask?
    private weak var componentTask: OPGadgetComponentLoadTask?
    
    // 启动结果埋点
    private let launchResultMonitor: OPMonitor = OPMonitor(kEventName_mp_app_launch_result)
    private var blockTimingEvent = BDPTrackerTimingEvent()  // block 时间
    private var loadTimingEvent = BDPTrackerTimingEvent()   // 不计算 block 的时间
    
    private var isLoadingBlocking = true
    private var loadingContinuBlock: (() -> Void)?
    
    /// 本次启动是否有容灾在执行
    var isDRRuning: Bool = false
    
    public required init() {
        super.init(dependencyTasks: [])
        output = OPGadgetLoadTaskOutput()
    }
    
    public override func taskWillStart() -> OPError? {
        
        // 启动开始计时
        _ = launchResultMonitor.timing()
            .setBridgeFG()
            .setPlatform([.tea, .slardar])
        loadTimingEvent.start()
        
        guard let input = input else {
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            return GDMonitorCodeLaunch.invalid_input.error(message: "OPGadgetLoadTask invalid input, input is nil. task:\(self.name)")
        }
        
        guard let router = input.router else {
            return GDMonitorCodeLaunch.invalid_input.error(message: "OPGadgetLoadTask invalid input, input.router is nil. task:\(self.name)")
        }
        
        let uniqueID = input.containerContext.uniqueID
        
        let startPage = self.input?.router?.containerController.startPage?.absoluteString
        // 尽量提前开始 blockLoading，做到与 meta 和 pkg 加载并行
        if let plugin = BDPTimorClient.shared().lifeCyclePlugin.sharedPlugin() as? BDPLifeCyclePluginDelegate, plugin.responds(to: #selector(BDPLifeCyclePluginDelegate.bdp_blockLoading(_:startPage:continueCallback:cancelCallback:))) {
            logger.info("bdp_blockLoading. uniqueID:\(uniqueID)")
            plugin.bdp_blockLoading?(uniqueID, startPage:startPage, continueCallback: { [weak self] in
                logger.info("bdp_blockLoading continueCallback. uniqueID:\(uniqueID)")
                guard let self = self else {
                    logger.info("self released")
                    return
                }
                self.isLoadingBlocking = false
                self.loadingContinuBlock?()
            }, cancelCallback: { [weak self] (code) in
                logger.info("bdp_blockLoading cancelCallback. uniqueID:\(uniqueID), code:\(String(describing: code))")
                guard let self = self else {
                    logger.info("self released")
                    return
                }
                let code = code ?? GDMonitorCodeLaunch.app_state_cancel
                self.taskDidFailed(error: code.error())
            })
        } else {
            isLoadingBlocking = false
        }
        
        // 埋点
        _ = launchResultMonitor.setUniqueID(input.containerContext.uniqueID)

        // 初始化 bundleLoadTask
        let bundleLoadTask = OPGadgetBundleLoadTask()
        bundleLoadTask.name = "OPGadgetBundleLoadTask(\(input.containerContext.uniqueID))"
        bundleLoadTask.input = OPGadgetBundleLoadTaskInput(
            containerContext: input.containerContext,
            router: router)
        bundleLoadTask.taskDidFinshedBlock = { [weak self, weak bundleLoadTask] (task, state, error) in
            if let bundleLoadTask = bundleLoadTask{
                if state == .failed, let shouldRemovePkg = bundleLoadTask.output?.shouldRemovePkg {
                    logger.info("shouldRemovePkg. task:\(bundleLoadTask.name)")
                    self?.output?.shouldRemovePkg = shouldRemovePkg
                }
            } else {
                logger.info("bundleLoadTask is nil")
            }
        }
        bundleLoadTask.delegate = self
        self.bundleLoadTask = bundleLoadTask
        
        // 初始化 componentTask
        let componentTask = OPGadgetComponentLoadTask()
        componentTask.name = "OPGadgetComponentLoadTask(\(input.containerContext.uniqueID))"
        componentTask.delegate = self
        componentTask.input = OPGadgetComponentLoadTaskInput(
            containerContext: input.containerContext,
            router: router)
        
        _ = addDependencyTask(dependencyTask: bundleLoadTask)
        _ = addDependencyTask(dependencyTask: componentTask)
        
        self.componentTask = componentTask
        
        return super.taskWillStart()
    }
    
    public override func taskDidStarted(dependencyTasks: [OPTaskProtocol]) {
        
        super.taskDidStarted(dependencyTasks: dependencyTasks)
        
        // 这里暂时没有其他事情直接返回成功(后续如果增加其他逻辑则需要调整)
        taskDidSucceeded()
    }
    
    public override func taskDidFinished(error: OPError?) {
        super.taskDidFinished(error: error)
        
        self.loadTimingEvent.stop()
        
        if let packageReader = bundleLoadTask?.output?.packageReader {
            var loadType: String?
            if packageReader.createLoadStatus().rawValue > BDPPkgFileLoadStatus.noFileInfo.rawValue {
                loadType = "restart"
            } else if packageReader.usedCacheMeta {
                loadType = "local_meta"
            }
            _ = launchResultMonitor.addCategoryValue(kEventKey_load_type, loadType)
            
            let isFirstOpen = packageReader.basic().isFirstOpen
            
            _ = launchResultMonitor.addCategoryValue("load_first_launch", isFirstOpen ? 0 : 1)
        }
        
        if let uniqueID = input?.containerContext.uniqueID {
            _ = launchResultMonitor.addCategoryValue("isXScreen", BDPXScreenManager.isXScreenMode(uniqueID) ? 1 : 0)
            _ = launchResultMonitor.addCategoryValue("js_engine_type", uniqueID.jsEngineType.rawValue)
        }
        
        if let input = input {
            let loadState = BDPTrackerHelper.getLoadState(by: input.containerContext.uniqueID)
            _ = launchResultMonitor.addCategoryValue("load_state", OPSafeObject(loadState, ""))

            // 记录是否走产品止血启动
            launchResultMonitor.addCategoryValue("is_silence_update", input.containerContext.uniqueID.silenceUpdateType != .none)
            launchResultMonitor.addCategoryValue("silence_update_type", input.containerContext.uniqueID.silenceUpdateType.rawValue)

            // 记录meta更新的策略
            launchResultMonitor.addCategoryValue("meta_expire_type", input.containerContext.uniqueID.metaUpdateStrategy.rawValue)
        }
        
        if let error = error {
            _ = launchResultMonitor
                .setError(error)
                .setResultTypeFail()
                .setResultType(error.monitorCode.message)
        } else {
            _ = launchResultMonitor.setResultTypeSuccess()
            input?.router?.containerController.markLaunchSuccess()
        }
        
        if OPSDKFeatureGating.isBuildInPackageProcessEnable(),
           let uniqueID = input?.containerContext.uniqueID {
            let provider = GadgetMetaProvider(type: .gadget)
            let metaLocalAccessor = MetaLocalAccessor(type: .gadget)
            let metaContext = MetaContext(uniqueID: uniqueID , token: nil)
            if let existedMetaString = metaLocalAccessor.getLocalMeta(with: metaContext),
               let gadgetBusinessData = try? provider.buildMetaModel(with: existedMetaString, context: metaContext).businessData as? GadgetBusinessData {
                _ = launchResultMonitor.addCategoryValue(kEventKey_is_buildin, gadgetBusinessData.isFromBuildin)
            } else {
                logger.info("taskDidFinished with buildin package enable. but exsited meta is invalid or not gadget biz data")
            }
        }
        //开启了分包模式
        if output?.common?.isSubpackageEnable() ?? false {
            launchResultMonitor.addCategoryValue("is_subpackage_mode", "true")
        }
        
        if(EMAFeatureGating.boolValue(forKey: "gadget.worker.upgrade.priority")){
            launchResultMonitor.addCategoryValue("upgrade_priority", 1)
        }

        //这边记录一下应用启动数据(只要有1个开关打开, 这边就记录小程序启动数据)
        if BDPPreloadHelper.recordAppLaunchInfoEnable() {
            let scene = input?.containerContext.currentMountData?.scene ?? .undefined
            let appVersion = output?.common?.model.appVersion ?? "unknown"
            recordAppLaunchInfo(appID: BDPSafeString(BDPSafeString(input?.containerContext.uniqueID.appID)), scene: scene.rawValue, appVersion: appVersion)
        }
        
        // 增加是否是同步加载，用于启动问题归因
        if let bundleLoadTask = bundleLoadTask,let metaFromCache = bundleLoadTask.metaFromCache, metaFromCache {
            launchResultMonitor.addCategoryValue("meta_from_cache", "true")
        } else {
            launchResultMonitor.addCategoryValue("meta_from_cache", "false")
        }

        // preRun埋点上报
        if BDPPreRunManager.sharedInstance.enablePreRun {
            if let uniqueID = input?.containerContext.uniqueID,
                let cacheModel = BDPPreRunManager.sharedInstance.cacheModel(for: uniqueID) {
                launchResultMonitor.addCategoryValue("hitPrerunCache", cacheModel.hitCache)
                // 当前启动的小程序有prerun缓存才需要上报
                cacheModel.reportMonitorResult()
            } else {
                // 没有缓存则认为没有命中prerun缓存
                launchResultMonitor.addCategoryValue("hitPrerunCache", false)
            }
        }
        // 本次启动任务是否有容灾在执行
        launchResultMonitor.addCategoryValue("dr_running", isDRRuning)

        launchResultMonitor
            .addCategoryValue("block_duration", blockTimingEvent.duration)  // 单独统计 block_duration
            .addCategoryValue("total_duration", loadTimingEvent.duration)
            .setDuration((Double)(loadTimingEvent.duration) / 1000).flush()
    }
    
}

extension OPGadgetLoadTask: OPGadgetComponentLoadTaskDelegate {
    
    func componentLoadStart(
        task: OPGadgetComponentLoadTask,
        component: OPComponentProtocol,
        jsPtah: String) {
        
        self.delegate?.componentLoadStart(
            task: self,
            component: component,
            jsPtah: jsPtah)
    }
    
}

extension OPGadgetLoadTask: OPGadgetBundleLoadTaskDelegate {
    
    public func onMetaLoadSuccess(model: BDPModel) {
        logger.info("onMetaLoadSuccess. \(model)")
        output?.model = model
        self.delegate?.onMetaLoadSuccess(model: model)
    }
    
    public func onAppConfigLoaded(model: BDPModel,
                                  appFileReader: BDPPkgFileReadHandleProtocol,
                                  uniqueID: BDPUniqueID,
                                  pkgName: String,
                                  appConfigData: Data) {
        logger.info("onAppConfigLoaded. uniqueID:\(uniqueID), pkgName:\(pkgName)")
        blockTimingEvent.reStart()
        loadTimingEvent.stop()  // 暂停计时
        loadingContinuBlock = { [weak self] in
            logger.info("loadingContinuBlock run")
            guard let self = self else {
                logger.warn("self released")
                return
            }
            // 只能执行一次
            self.loadingContinuBlock = nil
            
            self.blockTimingEvent.stop()
            self.loadTimingEvent.start()    // 继续计时
            
            // 埋点增加 block 耗时，增加小程序编译版本信息compile_version
            _ = self.launchResultMonitor.addCategoryValue("block_duration", self.blockTimingEvent.duration)
            
            guard let input = self.input else {
                // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
                self.taskDidFailed(error: GDMonitorCodeLaunch.invalid_input.error(message: "OPGadgetLoadTask invalid input, input is nil"))
                return
            }
            
            guard let router = input.router else {
                // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
                self.taskDidFailed(error: GDMonitorCodeLaunch.invalid_input.error(message: "OPGadgetLoadTask invalid input, input.router is nil"))
                return
            }
            
            OPMonitor(kEventName_mp_app_load_start)
                .setUniqueID(uniqueID)
                .addCategoryValue("pkg_md5", model.md5)
                .addCategoryValue("package_type", BDPPkgFileReadTypeInfo(appFileReader.basic().dbReadType))
                .addCategoryValue("block_duration", self.blockTimingEvent.duration)
                .addCategoryValue("pkg_md5", model.md5)
                .addCategoryValue(kEventKey_app_version, model.version)
                .addCategoryValue(kEventKey_app_name, model.name)
                .flush()
            
            do {
                let appConfigDic = (appConfigData as NSData).jsonValue() as? [AnyHashable: Any]
                let (task, common) = try self.setupCommonAndTask(model: model, appConfigData: appConfigDic, router: router)
                
                // 设置 componentTask 参数
                self.componentTask?.input?.common = common
                self.componentTask?.input?.task = task
                
                common.reader = appFileReader
                
                // fetch完之后就可以把reader赋值给common了，发送通知，就可以加载page-frame。
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: kBDPCommonReaderReadyNotification), object: nil)
                
                // TODO: 关于 startPage、schema、启动参数相关的的处理逻辑，现在很分散而且有些乱，需要重构整理将其逻辑定义清楚
                // 检查时机必须放在[冷/热启动完成]前，保证[self childRootViewController]时startPage是正确的值
                OPGadgetLoadTask.fixStartPageIfNeed(warmLaunch: false, router: router, task: task, common: common)
                //进行prefetch操作
                if let prefetchManager = BDPAppPagePrefetchManager.shared(), prefetchManager.isAllowPrefetch(with: common.schema) {
                    prefetchManager.decodeAndPrefetch(withConfigDict: appConfigDic,
                                                      schema: common.schema,
                                                      uniqueID: uniqueID,
                                                      version: common.model.version)
                }
                
                executeOnMainQueueAsync {
                    self.delegate?.didTaskSetuped(uniqueID: uniqueID, task: task, common: common)
                    // 更新临时区
                    router.containerController.updateTemporary()
                }
            } catch {
                self.taskDidFailed(error: (error as? OPError) ?? error.newOPError(monitorCode: OPSDKMonitorCode.unknown_error))
                return
            }
        }
        if isLoadingBlocking {
            // 正在等待返回
            logger.info("waiting for LoadingBlocking continu")
            return
        }
        loadingContinuBlock?()
    }
    
    func onUpdateMetaInfoModelCompleted(error: OPError?, model: BDPModel?) {
        input?.router?.containerController.getUpdatedMetaInfoModelCompletion(error, model: model)
    }
    
    func onUpdatePkgCompleted(error: OPError?, model: BDPModel?) {
        input?.router?.containerController.getUpdatedPkgCompletion(error, model: model)
    }
    
    func onPackageLoadFailed(error: OPError) {
        delegate?.onPackageLoadFailed(error: error)
    }
    
}

extension OPGadgetLoadTask {
    
    private func setupCommonAndTask(
        model: BDPModel,
        appConfigData: [AnyHashable: Any]?,
        router: OPGadgetContainerRouterProtocol
    ) throws -> (BDPTask, BDPCommon) {
        logger.info("onAppConfigLoaded. uniqueID:\(model.uniqueID)")
        guard let input = input else {
            throw GDMonitorCodeLaunch.invalid_input.error()
        }
        
        
        guard let config = appConfigData  else {
            throw GDMonitorCode.invalid_params.error(message: "appConfigData.jsonValue invalid")
        }
        
        guard let schema = router.containerController.schema else {
            throw GDMonitorCode.parse_schem_error.error()
        }
        
        if router.containerController.launchParam?.vdom != nil,
           let task = BDPTaskManager.shared()?.getTaskWith(model.uniqueID),
           let common = BDPCommonManager.shared()?.getCommonWith(model.uniqueID) {
            logger.info("vdom update task and common")
            // 如果有vdom，并且task 和common都已经有了，就证明之前创建好了，只需要更新即可。
            common.update(with: model)
            task.update(with: model, configDict: config)
            return (task, common)
        } else {
            logger.info("setup task and common")
            
            guard let common = BDPCommon(model: model, schema: schema) else {
                throw GDMonitorCode.invalid_params.error(message: "common is nil")
            }
            
            // setup comon
            common.realMachineDebugAddress = model.realMachineDebugSocketAddress
            common.performanceTraceAddress = model.performanceProfileAddress
            if let containerConfig = input.containerContext.containerConfig as? OPGadgetContainerConfig,
               let _ = containerConfig.wsForDebug, common.realMachineDebugAddress == nil {
                // 启动参数中包含真机调试 socket 地址且 meta 中不包含，需要提示用户升级 IDE
                // TODO: 小程序 IDE 版本线上均 >= 2.11 时删除此逻辑
                logger.info("show upgrade IDE alert, wsForDebug:\(containerConfig.wsForDebug), meta:\(common.realMachineDebugAddress)")
                showUpgradeIDEAlert()
            }

            output?.common = common
            
            // 加入缓存
            BDPCommonManager.shared()?.add(common, uniqueID: model.uniqueID)
            
            // 创建、热缓存Task
            guard let task = BDPTask(
                    model: model,
                    configDict: config,
                    schema: schema,
                containerVC: router.containerController,
                    containerContext: input.containerContext
            ) else {
                throw OPSDKMonitorCode.unknown_error.error(message: "create BDPTask failed")
            }
            
            output?.task = task
            
            // 加入缓存
            BDPTaskManager.shared()?.add(task, uniqueID: model.uniqueID)
            task.context?.appConfigLoaded?(model.uniqueID)
            return (task, common)
        }
    }

    private func showUpgradeIDEAlert() {
        let dialog = UDDialog()
        dialog.setTitle(text: BDPI18n.openPlatform_RealdeviceDebug_IdeVerPrompt2Ttl)
        dialog.setContent(text: BDPI18n.openPlatform_RealdeviceDebug_IdeVerPrompt2)
        dialog.addPrimaryButton(text: BDPI18n.openPlatform_RealdeviceDebug_OkBttn)
        DispatchQueue.main.async {
            let containerVC = self.input?.router?.containerController
            let window = containerVC?.view.window ?? OPWindowHelper.fincMainSceneWindow()
            let topVC = OPNavigatorHelper.topMostVC(window: window)
            topVC?.present(dialog, animated: true, completion: nil)
        }
    }
    
    // TODO: 代码位置待迁移
    static func fixStartPageIfNeed(
        warmLaunch: Bool,
        router: OPGadgetContainerRouterProtocol,
        task: BDPTask,
        common: BDPCommon) {
        logger.info("fixStartPageIfNeed. warmLaunch:\(warmLaunch)")
        if let startPage = router.containerController.startPage,
           let config = task.config {
            var entryPagePath: String = "";
            let enableRedirect = LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.enable_applink_path_replace")
            logger.info("fixStartPageIfNeed. enableRedirect \(enableRedirect)")
            var hitFix: Bool = false // 是否需要修正startPage
            
            var redirectStartPage = startPage
            // fixStartPageIfNeed两次问题修复开关，方案2
            let enableFixStartPageIssueFromSource = LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.enable_fix_startpage_source")
            if enableFixStartPageIssueFromSource, warmLaunch, let sourceStartPage = router.containerController.sourceStartPage { // 修复热启动fixStartPageIfNeed的问题，第一次命中无效页定向至首页，第二次命中redirect。预期应该是只命中一次（redirect优先）
                redirectStartPage = sourceStartPage
            }
            if enableRedirect, let redirectResult: String = config.redirectPage(redirectStartPage.path), redirectResult.count > 0 {
                hitFix = true
                logger.info("fixStartPageIfNeed. hit redirect fromPath:\(redirectStartPage.path) toPath:\(redirectResult)")
                entryPagePath = redirectResult
                if let uniqueID = task.uniqueID {
                    var trackerParams = [AnyHashable: Any]()
                    trackerParams["application_id"] = uniqueID.appID
                    trackerParams["program_version_id"] = common.model.appVersion ?? ""
                    BDPTracker.event("openplatform_micro_program_redirect_page_path_view", attributes: trackerParams, uniqueID: uniqueID)
                }
            } else if !config.containsPage(startPage.path) { // 检查startPage的path是否有效，无效则变成首页
                hitFix = true
                entryPagePath = task.config?.entryPagePath ?? ""
            }
            if hitFix {
                logger.info("fixStartPageIfNeed. entryPagePath:\(entryPagePath)")

                router.containerController.startPage = BDPAppPageURL(urlString: entryPagePath)

                // path无效时也需更新queryParams中的startPage参数，保证其他场景直接获取的数据正确
                common.schema.updateStartPage(entryPagePath)

                if !warmLaunch {
                    common.coldBootSchema.updateStartPage(entryPagePath)
                }
            }
        }
    }
}

extension OPGadgetLoadTask {
    // 记录小程序启动参数(延迟5秒)
    func recordAppLaunchInfo(appID: String, scene: Int, appVersion: String) {
        let ts = NSDate().timeIntervalSince1970 * 1000
        DispatchQueue.global().asyncAfter(deadline: .now() + 5, qos: .utility) {
            let _ = LaunchInfoAccessorFactory.launchInfoAccessor(type: .gadget)?.addLaunchInfo(appID: appID, scene: scene, applicationVersion: appVersion, timestamp: ts)
        }
    }
}
