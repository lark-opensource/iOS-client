//
//  OPGadgetBundleLoadTask.swift
//  OPGadget
//
//  Created by yinyuan on 2020/12/9.
//

import Foundation
import LarkSetting
import OPSDK
import TTMicroApp
import LKCommonsLogging
import LarkFeatureGating
import UniverseDesignDialog
import OPFoundation

fileprivate let logger = Logger.oplog(OPGadgetBundleLoadTask.self, category: "OPGadgetBundleLoadTask")

/// 启动流程-应用资源加载流程
class OPGadgetBundleLoadTask: OPTask<OPGadgetBundleLoadTaskInput, OPGadgetBundleLoadTaskOutput>, OPAppLoaderMetaAndPackageEvent {
    
    weak var delegate: OPGadgetBundleLoadTaskDelegate?

    private var loader: OPGadgetLoader?
    
    public var metaFromCache: Bool?
        
    required init() {
        super.init(dependencyTasks: [])
        self.output = OPGadgetBundleLoadTaskOutput()
    }
    
    override func taskDidStarted(dependencyTasks: [OPTaskProtocol]) {
        super.taskDidStarted(dependencyTasks: dependencyTasks)
        
        // 校验入参合法
        guard let input = self.input, let router = input.router else {
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            taskDidFailed(error: GDMonitorCodeLaunch.invalid_input.error(message: "OPGadgetBundleLoadTask invalid input, input is nil"))
            return
        }
        
        // 临时代码待统一
        let uniqueID = input.containerContext.uniqueID
        
        // Check Services Enabled
        if !BDPVersionManager.serviceEnabled() {
            taskDidFailed(error: GDMonitorCodeLaunch.service_disabled.error(message: "ServiceDisabled"))
            return
        }

        // 加载失败 - 无效的appID
        if !uniqueID.isValid() {
            taskDidFailed(error: GDMonitorCodeLaunch.invalid_appid.error())
            return
        }
        
        // 加载失败 - 无效的protocol
        if uniqueID.appType != .gadget {
            taskDidFailed(error: GDMonitorCodeLaunch.invalid_host.error())
            return
        }
        
        // TarckEventInfo
        let trackEventInfo = BDPTrackEventInfo()
        trackEventInfo.mp_id = input.containerContext.uniqueID.appID
//        trackEventInfo.launch_from = input.containerConfig.launchFrom
        trackEventInfo._param_for_special = OPAppTypeToString(input.containerContext.uniqueID.appType)  // 没啥用，可以删除吧
        trackEventInfo.uniqueID = input.containerContext.uniqueID
        trackEventInfo.trace_id = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)?.traceId
        
        OPMonitor(kEventName_mp_load_meta_start).setUniqueID(uniqueID).addMap(trackEventInfo.infoDict).flush()
        BDPPerformanceProfileManager.sharedInstance().monitorLoadTimeline(withStart: .metaLoad, uniqueId: uniqueID, extra: nil)
        delegate?.onMetaLoadStart()

        loader = OPGadgetLoader(applicationContext: input.containerContext.applicationContext, startPage:input.router?.containerController.schema?.startPage , uniqueID: uniqueID, previewToken: input.containerContext.containerConfig.previewToken ?? "")
        loader?.loadMetaAndPackage(listener: self)
        
        // 牵涉到小程序的fistFrame相关的逻辑，先保留调用
        router.containerController.eventMpLoadStart()
        
        
        // VDOM 加载逻辑
        // 冷启动里有个VDOM加载逻辑
        // 创建工具栏，否则加载不同loadResultType页面时，会因为没有toolBarView从而导致insertSubview失败，进而白屏无法退出
//        [self setupToolBarView];
        
        
        
        
        // TODO
        // Setup taofengping Loading View

        // 如果vdom的情况下，1秒时候还没有vdom渲染好，就显示loading
        if router.containerController.launchParam?.vdom != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if let common = BDPCommonManager.shared()?.getCommonWith(uniqueID), common.isSnapshotReady {
                    // 已经渲染
                } else {
                    // TODO: taofengping 显示 Loading View
                }
            }
        } else {
            // 非 vdom模式直接显示loadingview。
            // TODO: taofengping 显示 Loading View
        }
    }

    // cancelLoad终止整个流程
    override func taskDidCancelled(error: OPError) {
        super.taskDidCancelled(error: error)
        
    }
    
    override func taskDidFailed(error: OPError) {
        super.taskDidFailed(error: error)
        
    }

    private func metaInfoDidComplete(input: OPGadgetBundleLoadTaskInput, error: OPError?, model: BDPModel?, fromCache: Bool) {
        metaFromCache = fromCache
        // 临时代码待统一
        let bdpUniqueID = input.containerContext.uniqueID

        let monitor = OPMonitor(kEventName_mp_load_meta_result).setUniqueID(bdpUniqueID)

        defer {
            // 函数结束时统一上报
            monitor.flush()
        }
        _ = monitor.addCategoryValue("meta_cache", fromCache ? 1 : 0)
        BDPPerformanceProfileManager.sharedInstance().monitorLoadTimeline(withEnd: .metaLoad, uniqueId: bdpUniqueID, extra: ["isCache": fromCache ? 1 : 0])
        if let error = error {
            _ = monitor.setResultTypeFail().setError(error)
            delegate?.onMetaLoadFailed(error: error)
            taskDidFailed(error: error)
            return
        }

        guard let model = model else {
            let error = GDMonitorCodeLaunch.meta_info_fail.error(message: "meta callback model is nil")
            _ = monitor.setResultTypeFail().setError(error)
            delegate?.onMetaLoadFailed(error: error)
            taskDidFailed(error: error)
            return
        }

        if let error = checkModelStatus(model: model, isAsyncUpdate: false) {
            _ = monitor.setResultTypeFail().setError(error)
            delegate?.onMetaLoadFailed(error: error)
            taskDidFailed(error: error)
            return
        }

//        let traceID = BDPTracingManager.sharedInstance().getTracingBy(bdpUniqueID)?.traceId

        output?.model = model
        
        delegate?.onMetaLoadSuccess(model: model)
        

        // TODO
//        [self setTrackerCommonParams:@{BDPTrackerMPNameKey: model.name ?: @"",
//                                       BDPTrackerMPVersion: model.version ?: @"",
//                                       BDPTrackerTraceID: traceID ?: @""
//                                       }];

        logger.info("metaInfoFetchSuccess, uniqueID=\(model.uniqueID), model=\(model)")

        _ = monitor.setResultTypeSuccess()
    }

    private func packageReaderDidReady(model: BDPModel, packageReader: BDPPkgFileReadHandleProtocol) {

        self.output?.packageReader = packageReader

        // 被用来做权限同步，暂时保留
        if let plugin = BDPTimorClient.shared().lifeCyclePlugin.sharedPlugin() as? BDPLifeCyclePluginDelegate {
            plugin.bdp_onModelFetched?(for: model.uniqueID, isSilenceFetched: false, isModelCached: packageReader.usedCacheMeta, appModel: model, error: nil)
        }
        
        startLoadFiles(model: model, appFileReader: packageReader, uniqueID: model.uniqueID)
        self.delegate?.onPackageReaderReady(packageReader: packageReader)
    }
    
    private func didPkgCompleted(success: Bool, model: BDPModel?, error: OPError?) {
        // 下包结束埋点
        let monitor = OPMonitor(kEventName_mp_load_package_result).setUniqueID(input?.containerContext.uniqueID)
        if let createLoadStatus = output?.packageReader?.createLoadStatus(), createLoadStatus.rawValue >= BDPPkgFileLoadStatus.downloaded.rawValue {
            _ = monitor.addCategoryValue("package_cache", 1)
            BDPPerformanceProfileManager.sharedInstance().monitorLoadTimeline(withEnd: .packageLoad, uniqueId: input?.containerContext.uniqueID, extra: ["isCache":1])
        } else {
            _ = monitor.addCategoryValue("package_cache", 0)
            BDPPerformanceProfileManager.sharedInstance().monitorLoadTimeline(withEnd: .packageLoad, uniqueId: input?.containerContext.uniqueID, extra: ["isCache":0])
        }
        if success, error == nil {
            _ = monitor.setResultTypeSuccess()
        } else {
            _ = monitor.setResultTypeFail().setError(error)
        }
        monitor.flush()
        
        if success, error == nil {
            delegate?.onPackageLoadSuccess()
        } else {
            // 包下载失败，都认定为失败
            let error = error ?? OPSDKMonitorCode.unknown_error.error(message: "pkg load failed")
            taskDidFailed(error: error)
            // 由于 Task 失败时，启动任务可能已经完成(流式加载)，所以这里还要回调另外处理
            delegate?.onPackageLoadFailed(error: error)
        }
        //.output?.packageReader 如果是未下载的情况，这里会有循环应用，可以通过这个打破
        if let packageReader = self.output?.packageReader as? BDPPackageStreamingFileHandle ,
           OPSDKFeatureGating.enablePackageFileHandleLeakFix() {
            self.output?.packageReader = BDPPackageStreamingFileHandle(afterDownloadedWith: packageReader.packageContext)
        }
    }
    
    private func didUpdateMetaInfoModelCompleted(error: OPError?, model: BDPModel?) {
        output?.updateModel = model
        self.delegate?.onUpdateMetaInfoModelCompleted(error: error, model: model)
    }
    
    private func didUpdatePkgCompleted(error: OPError?, model: BDPModel?) {
        // TODO: 新容器需要对更新结果进行校验，即使没有更新它也会回调？代码需要优化
        guard let uniqueID = input?.containerContext.uniqueID else {
            logger.warn("uniqueID is nil")
            return
        }
        guard let model = model else {
            logger.info("model is nil")
            return
        }
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            logger.info("common is nil")
            return
        }
        
        guard let currentModel = common.model else {
            logger.info("currentModel is nil")
            return
        }
        
        if !model.isNewerThanAppModel(currentModel) {
            logger.info("!updateModel.isNewerThanAppModel")
            return
        }
        self.delegate?.onUpdatePkgCompleted(error: error, model: model)
    }
    
    /// 检测小程序model状态
    private func checkModelStatus(model: BDPModel, isAsyncUpdate: Bool) -> OPError? {
        
        var error: OPError?
        
        // 加载失败 - 小程序被下架
        switch model.state {
        case .disable:
            error = GDMonitorCodeLaunch.offline.error(message: "This App has Offline. uniqueID=\(model.uniqueID)")
            // 下线标记清除
            output?.shouldRemovePkg = true  // 下线包需要清除
            logger.info("checkModelStatus This App has Offline, uniqueID=\(model.uniqueID)")
        case .normal:
            // 什么也不做
            break
        case .unpublished:
            // 什么也不做
            break
        @unknown default:
            // 加日志
            OPAssertionFailureWithLog("unknown model.state \(model.state.rawValue) please check your logic")
        }
        
        if !isAsyncUpdate {
            //以下判定仅在正常加载的时候触发,异步更新不检查.
            switch model.versionState {
            case .normal:
                // 正常情况
                break
            case .noPermission:
                // 加载失败 - 当前用户无权限访问小程序
                error = GDMonitorCodeLaunch.no_permission.error(message: "No Access Permission for This App. uniqueID=\(model.uniqueID)")
            case .incompatible:
                // 加载失败 - 小程序不支持当前宿主环境
                error = GDMonitorCodeLaunch.incompatible.error(message: "This App Version Incompatible. uniqueID=\(model.uniqueID)")
            case .previewExpired:
                error = GDMonitorCodeLaunch.preview_expired.error(message: "This qr code is expired. uniqueID=\(model.uniqueID)")
            @unknown default:
                // 加日志
                assertionFailure("unknown model.versionState \(model.versionState.rawValue) please check your logic")
            }
        } else {
            switch model.versionState {
            case .noPermission, .incompatible, .previewExpired:
                // 异步更新, 且versionState 非Normal的, 退出时移除缓存, 下次走正常加载流程, 重新请求meta
                // TODO:        self.removePkgBitMask |= BDPRemovePkgFromVersionStateAbnormal;
                output?.shouldRemovePkg = true
                logger.info("checkModelStatus BDPRemovePkgFromVersionStateAbnormal, uniqueID=\(model.uniqueID)")
                break
            case .normal:
                // 正常情况
                break
            @unknown default:
                // 加日志
                assertionFailure("unknown model.versionState \(model.versionState.rawValue) please check your logic")
            }
        }
        
        if !BDPDeviceManager.infoPlistSupportedInterfaceOrientationsMask().contains(.portrait) {
            error = GDMonitorCodeLaunch.orientation_portrait_unsupport.error(message: "App/Game orientation portrait is not supported. uniqueID=\(model.uniqueID)")
        }

        if OPSDKFeatureGating.gadgetCheckMinLarkVersion(),
           BDPVersionManager.isValidLarkVersion(model.minLarkVersion),
           BDPVersionManager.isValidLocalLarkVersion() {
            if BDPVersionManager.isLocalLarkVersionLowerThanVersion(model.minLarkVersion) {
                error = GDMonitorCodeLaunch.lark_version_old.error(message: "lark version is too old. uniqueID=\(model.uniqueID)")
            }
        } else {
            // 加载失败 - JSSDK版本过低
            if BDPVersionManager.isLocalSdkLowerThanVersion(model.minJSsdkVersion) {
                //尝试走一遍同步强制更新逻辑
                let isSuccess = BDPJSSDKForceUpdateManager.sharedInstance().forceJSSDKUpdateWaitUntilCompeteOrTimeout()
                //如果强制更新成功后版本还是比的minSDKVersion小
                //或者 isSuccess 是fail，走error逻辑，否则认为 JSSDK 依赖没问题
                if isSuccess&&BDPVersionManager.isLocalSdkLowerThanVersion(model.minJSsdkVersion) || !isSuccess {
                    error = GDMonitorCodeLaunch.jssdk_old.error(message: "SDK Version is too old. uniqueID=\(model.uniqueID)")
                }
            }
        }
        
        logger.info("checkModelStatus success, uniqueID=\(model.uniqueID)")        
        return error
    }
    
    private func startLoadFiles(model: BDPModel, appFileReader: BDPPkgFileReadHandleProtocol, uniqueID: BDPUniqueID) {
        logger.info("startLoadFiles. uniqueID:\(uniqueID)")
        
        delegate?.onPackageLoadStart()
        
        OPMonitor(kEventName_mp_load_package_start).setUniqueID(uniqueID).flush()
        BDPPerformanceProfileManager.sharedInstance().monitorLoadTimeline(withStart: .packageLoad, uniqueId: uniqueID, extra: nil)
        // TODO: BDPMonitorLoadTimeline(@"get_file_content_from_ttpkg_begin", @{ @"file_path": @"app-config.json" }, self.uniqueID);
        //如果加载的是一个分包（独立分包case），需要加载对应独立分包下的app-config.json
        var filePath = "app-config.json"
        if let pagePath = appFileReader.basic().pagePath  {
            filePath = "\(pagePath)/app-config.json"
        }
        appFileReader.readData(withFilePath: filePath,
                               syncIfDownloaded: true,
                               dispatchQueue: nil) { [weak self] (error, pkgName, data) in
            guard let self = self else {
                logger.info("Task released. uniqueID:\(uniqueID)")
                return
            }
            
            // TODO: BDPMonitorLoadTimeline(@"get_file_content_from_ttpkg_end", @{ @"file_path": @"app-config.json" }, self.uniqueID);
            
            if let error = error {
                self.taskDidFailed(error: error.newOPError(monitorCode: GDMonitorCodeLaunch.download_fail))
                return
            }
            
            guard let data = data else {
                self.taskDidFailed(error: GDMonitorCodeAppLoad.pkg_data_failed.error(message: "data is nil"))
                return
            }
            
            self.delegate?.onAppConfigLoaded(model: model,
                                             appFileReader: appFileReader,
                                             uniqueID: uniqueID,
                                             pkgName: pkgName,
                                             appConfigData: data)
            
            // 对于启动流程来说，到这里本任务已经是成功了，后续流程为异步加载流程，不阻塞启动
            self.taskDidSucceeded()
        }
        
    }
//
    // MARK: - OPAppLoaderMetaAndPackageEvent
    func onMetaLoadStarted(strategy: OPAppLoaderStrategy) {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webcomponent.safedomain.doublecheck")),
           let identifier = input?.containerContext.uniqueID.fullString {
            NotificationCenter.default.post(name: Notification.Name.MetaLoadStatusNotification,
                                            object: nil,
                                            userInfo: [MetaLoadStatus.metaLoadStatusKey: MetaLoadStatus.started,
                                                       MetaLoadStatus.metaLoadIdentifierKey: identifier])
        }
        guard strategy == .normal else {
            // 非正常加载流程的暂不处理
            return
        }
        logger.info("onMetaLoadStarted. task:\(name), strategy:\(strategy.rawValue)")
        self.delegate?.onMetaLoadStart()
    }

    func onMetaLoadProgress(strategy: OPAppLoaderStrategy, current: Float, total: Float) {
        guard strategy == .normal else {
            // 非正常加载流程的暂不处理
            return
        }
        logger.info("onMetaLoadProgress. task:\(name), strategy:\(strategy.rawValue), current:\(current), total:\(total)")
        self.delegate?.onMetaLoadProgress(current: current, total: total)
    }

    func onMetaLoadComplete(strategy: OPAppLoaderStrategy, success: Bool, meta: OPBizMetaProtocol?, error: OPError?, fromCache: Bool) {
        logger.info("onMetaLoadComplete. task:\(name), strategy:\(strategy.rawValue), fromCache: \(fromCache)")

        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webcomponent.safedomain.doublecheck")),
            let identifier = input?.containerContext.uniqueID.fullString {
            var userInfo = [MetaLoadStatus.metaLoadStatusKey: MetaLoadStatus.success,
                            MetaLoadStatus.metaLoadIdentifierKey: identifier] as [String : Any]
            if let _ = error {
                userInfo[MetaLoadStatus.metaLoadStatusKey] = MetaLoadStatus.fail
            } else {
                if let _ = meta as? GadgetMeta {} else {
                    userInfo[MetaLoadStatus.metaLoadStatusKey] = MetaLoadStatus.fail
                }
            }
            NotificationCenter.default.post(name: Notification.Name.MetaLoadStatusNotification, object: nil, userInfo: userInfo)
        }

        switch strategy {
        // 正常加载，对应旧版getModelCallback
        case .normal:
            
            guard let input = self.input, let router = input.router else {
                // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
                taskDidFailed(error: GDMonitorCodeLaunch.invalid_input.error(message: "OPGadgetBundleLoadTask invalid input"))
                return
            }
            if let error = error {
                taskDidFailed(error: error)
                return
            }
            guard let meta = meta as? GadgetMeta else {
                taskDidFailed(error: GDMonitorCodeAppLoad.invalid_meta_type.error(message: "OPGadgetBundleLoadTask invalid meta type"))
                return
            }
            
            let model = BDPModel(gadgetMeta: meta)
            
            let vdomRender = router.containerController.loadVdom(with: model);
            if vdomRender == true {
                logger.info("model callback use vdom render")
                // 如果是 渲染了vdom， 则需要将正常的加载流程放到下一次 runloop里面。
                // 因为 BDPBaseContainerVC的 viewDidLoad 会早于 BDPAppVC的viewDidLoad，所以会导致加载page-frame.js 早于 vdom的加载。
                // 从而出现基础库加载vdom的时序不正确的问题. 原则上， 加载了 page-frame.html之后，就需要加载vdom
                DispatchQueue.main.async {
                    self.metaInfoDidComplete(input: input, error: error, model: model, fromCache: fromCache)
                }
            } else {
                self.metaInfoDidComplete(input: input, error: error, model: model, fromCache: fromCache)
            }
        // 异步更新，对应旧版getPkgCompletion
        case .update:
            var model: BDPModel?
            var error: OPError? = error
            if error == nil {
                if let meta = meta as? GadgetMeta {
                    model = BDPModel(gadgetMeta: meta)
                } else {
                    error = GDMonitorCodeAppLoad.invalid_meta_type.error(message: "OPGadgetBundleLoadTask invalid meta type")
                }
            }
            
            self.didUpdateMetaInfoModelCompleted(error: error, model: model)
        default:
            assertionFailure("should not enter here")
        }
    }

    func onPackageLoadStart(strategy: OPAppLoaderStrategy) {
        guard strategy == .normal else {
            // 非正常加载流程的暂不处理
            return
        }
        logger.info("onPackageLoadStart. task:\(name), strategy:\(strategy.rawValue)")
        self.delegate?.onPackageLoadStart()
    }

    func onPackageReaderReady(strategy: OPAppLoaderStrategy, reader: OPPackageReaderProtocol) {
        guard strategy == .normal else {
            // 非正常加载流程的暂不处理
            return
        }
        logger.info("onPackageReaderReady. task:\(name), strategy:\(strategy.rawValue)")
        guard let model = output?.model, let packageReader = reader as? BDPPkgFileReadHandleProtocol else {
            // 不应当出现的错误，如果出现，说明逻辑出现问题，要立即排查修复
            taskDidFailed(error: GDMonitorCodeLaunch.invalid_input.error(message: "OPGadgetBundleLoadTask package ready with model \(String(describing: output?.model?.uniqueID)) reader \(type(of: reader))"))
            return
        }
        self.packageReaderDidReady(model: model, packageReader: packageReader)
    }

    func onPackageLoadProgress(strategy: OPAppLoaderStrategy, current: Float, total: Float) {
        guard strategy == .normal else {
            // 非正常加载流程的暂不处理
            return
        }
        logger.info("onPackageLoadProgress. task:\(name), strategy:\(strategy.rawValue), current:\(current), total:\(total)")
        self.delegate?.onPackageLoadProgress(current: current, total: total)
    }

    func onPackageLoadComplete(strategy: OPAppLoaderStrategy, success: Bool, error: OPError?) {
        logger.info("onPackageLoadComplete. task:\(name), strategy:\(strategy.rawValue), success:\(success)")
        switch strategy {
        case .normal:   // 正常加载: 对应旧版getPkgCompletion
            self.didPkgCompleted(success: success, model: output?.model, error: error)
        case .update: // 正常加载: 对应旧版getUpdatedPkgCompletion
            self.didUpdatePkgCompleted(error: error, model: output?.updateModel)
        default:
            OPAssertionFailureWithLog("should not enter here")
        }
    }
}

extension OPGadgetBundleLoadTask {
    
}
