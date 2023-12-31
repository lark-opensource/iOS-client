//
//  OPBlockContainer.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/2.
//

import Foundation
import OPSDK
import OPBlockInterface
import ECOProbe
import LKCommonsLogging
import LarkOPInterface
import TTMicroApp
import LarkContainer
import LarkSetting

@objcMembers
class OPBlockContainer: OPBaseContainer,
                        OPBlockContainerProtocol,
                        OPBlockHostProtocol,
                        OPBlockContainerRouterDelegate,
                        OPBlockContainerPluginDelegate,
                        OPBlockLoadTaskDelegate,
                        OPContainerLifeCycleDelegate,
                        OPComponentLifeCycleProtocol {

	let lifeCycleStateMachine = OPBlockStateMachine<OPBlockLifeCycleTriggerEvent, OPBlockLifeCycleStatus>.init(initalStatus: .loading)

	private let router: OPBlockContainerRouter

    private var loadTask: OPBlockLoadTask?
    
    private var packageReader: OPPackageReaderProtocol?

    /// Block timeout strategy: biz-level timeout interval, nil means no timer
    private var bizTimeoutInterval: TimeInterval?
    /// Block timeout strategy: biz-level timer
    private var bizTimer: Timer?
    
    private var blockProjectConfig: OPBlockProjectConfig? {
        get {
            projectConfig as? OPBlockProjectConfig
        }
    }

    private var trace: BlockTrace {
        containerContext.blockTrace
    }
    
    private var blockConfig: OPBlockConfig? {
        get {
            blockProjectConfig?.blocks?.first
        }
    }
    
    var component: OPComponentProtocol? {
        get {
            router.currentComponent
        }
    }

    override var runtimeVersion: String {
        return OPBlockSDK.runtimeSDKVersion
    }
    
    weak var hostDelegate: OPBlockHostProtocol?
    
    let serviceContainer = OPBlockServiceContainer()

    private let userResolver: UserResolver

    private var loadAsyncEnable: Bool {
        return userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableLoadAsync.key)
    }

    private let networkAPISetting = NetworkAPISetting()

    init(
        userResolver: UserResolver,
        applicationContext: OPApplicationContext,
        uniqueID: OPAppUniqueID,
        containerConfig: OPBlockContainerConfigProtocol,
        trace: BlockTrace
    ) {
        self.userResolver = userResolver
        // 构造 containerContext
        let containerContext = OPContainerContext(applicationContext: applicationContext, uniqueID: uniqueID, containerConfig: containerConfig)

        // baseBlockTrace仅在向BlockTrace做类型转换时中转用，并非实际使用的trace对象
        containerContext.baseBlockTrace = trace
        // trace是container的正常trace对象，也被BlockTrace类型持有
        containerContext.trace = trace.bdpTracing

        router = OPBlockContainerRouter(context: containerContext, userResolver: userResolver)
        if containerConfig.bizTimeoutInterval > 0 { bizTimeoutInterval = TimeInterval(containerConfig.bizTimeoutInterval) / 1_000.0 }
        // 父类中初始化containerContext
        super.init(containerContext: containerContext, updater: nil)

        trace.info("OPBlockContainer.init")

        containerConfig.blockContext.lifeCycleTrigger = OPBlockCustomLifeCyclePreProcessor(container: self, trace: containerConfig.trace)
        reigsterLifeCycleStatusTrigger()
        containerConfig.blockContext.blockAbilityHandler = OPBlockCheckUpdateService(container: self, trace: containerConfig.trace)

        addLifeCycleDelegate(delegate: self)

        // 这里先与小程序和Tab小程序的逻辑保持一致，每次在初始化/mount的时候去加载一次plugin
        // 多次调用也没关系，但后续要优化
        // 原注释：注册所有的plugin(防止优化load方法后,plugin注册过晚导致问题)
        BDPBootstrapKit.launch()

        let plugin = OPBlockContainerPlugin(
            userResolver: userResolver,
            delegate: self,
            containerContext: containerContext
        )
        registerPlugin(plugin: plugin)
        router.delegate = self
        debugService = BlockDebugService()
    }
    
    override func onLoad() {
        trace.info("OPBlockContainer.onLoad")
        super.onLoad()

        let loadTask = OPBlockLoadTask(containerContext: containerContext)
        loadTask.delegate = self

        let tempTrace = trace
        loadTask.taskDidFinshedBlock = { [weak self] (task, state, error) in
            guard let self = self else {
                tempTrace.error("OPBlockContainer.onLoad.loadTask.taskdidfinishedblock self is released")
                return
            }
            if state == .succeeded {
                // 启动成功
                self.onReady()
            } else {
                // 启动失败
                let err = error ?? OPBlockitMonitorCodeMountLaunch.internal_error.error()
                self.trace.error("OPBlockContainer.onLoad.loadtask.taskdidfinishedblock error: \(err.localizedDescription)")
                self.onFail(error: err)
            }
        }
        loadTask.input = OPBlockLoadTaskInput(
            containerContext: containerContext,
            router: router,
            serviceContainer: serviceContainer)
        self.loadTask = loadTask
        
        if loadAsyncEnable {
            DispatchQueue.global().async {
                loadTask.start()
            }
        } else {
            loadTask.start()
        }
    }

    override func onUnload(monitorCode: OPMonitorCode) {
        trace.info("OPBlockContainer.onUnload monitorCode: \(monitorCode)")

        // 停止现有的资源加载任务
        // 停止现有的Component加载任务 OPError.error(monitorCode: OPSDKMonitorCode.cancel)
        loadTask?.cancel(monitorCode: monitorCode)
        loadTask = nil
        trace.info("OPBlockContainer.onUnload loadtask stopped")
        
        // 重建 Router
        router.unload()
        trace.info("OPBlockContainer.onUnload router unloaded")
        
        packageReader = nil
        
        super.onUnload(monitorCode: monitorCode)
    }
    
    override func onBindSlot(renderSlot: OPRenderSlotProtocol) -> Bool {
        trace.info("OPBlockContainer.onBindSlot renderSlot: \(renderSlot)")

        guard let renderSlot = renderSlot as? OPViewRenderSlot else {
            trace.error("OPBlockContainer.onBindSlot error: renderSlot == nil or casting OPViewRenderSlot error")
            return false
        }

        guard let slotView = renderSlot.view else {
            trace.error("OPBlockContainer.onBindSlot error: renderSlot.view == nil")
            return false
        }

        // 按照 OPRenderSlot 协议加载视图
        slotView.addSubview(router.containerView)
        router.containerView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        setDebugGestureAndContext(view: router.containerView, blockConfig: blockConfig, context: containerContext)
        return super.onBindSlot(renderSlot: renderSlot)
    }
    
    override func onUnbindSlot(renderSlot: OPRenderSlotProtocol) -> Bool {
        trace.info("OPBlockContainer.onUnbindSlot renderSlot: \(renderSlot)")
        router.containerView.removeFromSuperview()
        return super.onUnbindSlot(renderSlot: renderSlot)
    }

    override func supportDarkMode() -> Bool {
        let appId = containerContext.applicationContext.appID
        let blockTypeId = containerContext.uniqueID.identifier
        let blockId = containerContext.blockContext.uniqueID.blockID
        let isSupportDarkMode = blockConfig?.darkmode ?? false
        trace.info("block supportDarkMode: \(isSupportDarkMode), appId: \(appId), blockTypeId: \(blockTypeId), blockId: \(blockId)")
        return isSupportDarkMode
    }

    override func onThemeChange(_ theme: String) {
        trace.info("OPBlockContainer.onThemeChange theme: \(theme)")
        // 不支持 dark mode，不进行通知
        if !isSupportDarkMode {
            trace.error("OPBlockContainer.onThemeChange error: No darkmode")
            return
        }
        do {
            try onSendEventToBridge(eventName: "onThemeChange", params: ["theme" : theme], callback: nil)
        } catch let e {
            trace.error("OPBlockContainer.onThemeChange.onSendEventToBridge error: \(e.localizedDescription)")
        }
    }

    override func onSendEventToBridge(eventName: String, params: [AnyHashable : Any]?, callback: OPBridgeCallback?) throws {
        trace.info("OPBlockContainer.onSendEventToBridge eventName: \(eventName)")

        guard let bridge = router.currentComponent?.bridge else {
            let error = OPSDKMonitorCode.unknown_error.error()
            trace.error("OPBlockContainer.onSendEventToBridge No bridge for current component error: \(error.localizedDescription)")
            throw error
        }
        // TODO: send uniqueID
        try bridge.sendEvent(eventName: eventName, params: params, callback: callback)
    }
    
    private func genBlockInitDataByPath(_ path: String) -> OPBlockComponentData {
        trace.info("OPBlockContainer.genBlockInitDataByPath path: \(path)")

        let data = OPBlockComponentData(templateFilePath: path, containerContext: containerContext)
        if let config = containerContext.containerConfig as? OPBlockContainerConfig {
            trace.info("OPBlockContainer.genBlockInitDataByPath got containerConfig")
            if let apis = config.customApis {
                trace.info("OPBlockContainer.genBlockInitDataByPath got customApis")
                data.updateCustomAPIs(apis)
            }
            if let info = config.blockInfo {
                trace.info("OPBlockContainer.genBlockInitDataByPath got blockInfo")
                data.updateBlockInfo(info.toDictionary())
            }
            data.updateDataCollection(config.dataCollection)
        }
        if networkAPISetting.checkEnableRequest(appId: containerContext.uniqueID.appID) {
            data.updateUseNewRequestAPI(true)
        }
        return data
    }

    // MARK: - OPBlockHostProtocol
    func didReceiveLogMessage(_ sender: OPBlockEntityProtocol, level: OPBlockDebugLogLevel, message: String, context: OPBlockContext) {
        if level != .info {
            trace.info("OPBlockContainer.didReceiveLogMessage level: \(level), message: \(message)")
        } else {
            trace.info("OPBlockContainer.didReceiveLogMessage level: \(level)")
        }

        guard sender.isEqual(router.currentComponent) else {
            trace.error("OPBlockContainer.didReceiveLogMessage error: sender != router.currentComponent")
            return
        }
        hostDelegate?.didReceiveLogMessage(self, level: level, message: message, context: context)
    }

    func contentSizeDidChange(_ sender: OPBlockEntityProtocol, newSize: CGSize, context: OPBlockContext) {
        trace.info("OPBlockContainer.contentSizeDidChange newsize: \(newSize)")
        guard sender.isEqual(router.currentComponent) else {
            trace.error("OPBlockContainer.contentSizeDidChange error: sender != router.currentComponent")
            return
        }
        hostDelegate?.contentSizeDidChange(self, newSize: newSize, context: context)
    }

    func hideBlockHostLoading(_ sender: OPBlockEntityProtocol) {
        hostDelegate?.hideBlockHostLoading(self)
    }

	func onBlockLoadReady(_ sender: OPBlockEntityProtocol, context: OPBlockContext) {
		trace.info("OPBlockContainer.onBlockLoadReady")
		guard sender.isEqual(router.currentComponent) else {
			trace.error("OPBlockContainer.onBlockLoadReady error: sender != router.currentComponent")
			return
		}
		let lifeCycleTrigger = containerContext.blockContext.lifeCycleTrigger as? OPBlockInternalCustomLifeCycleTriggerProtocol
		lifeCycleTrigger?.triggerBlockLifeCycle(.finishLoad)
		hostDelegate?.onBlockLoadReady(self, context: context)
	}
    
    // MARK: - OPBlockLoadTaskDelegate

    // Block 配置的默认加载项，首次启动加载回调
    func componentLoadStart(task: OPBlockLoadTask, component: OPComponentProtocol, jsPtah: String) {
        trace.info("OPBlockContainer.componentLoadStart jsPtah: \(jsPtah)")
        // component 开始加载，此时router可以切换为该 component
        do {
            (component as? OPBlockComponentProtocol)?.hostDelegate = self
            (component as? OPBlockWebComponent)?.addLifeCycleListener(listener: self)
            trace.info("OPBlockContainer.componentLoadStart router.switchToComponent")
            try router.switchToComponent(
                parentNode: self,
                component: component,
                initData: genBlockInitDataByPath(jsPtah)
            )

        } catch {
            let monitorCode = OPBlockitMonitorCodeMountLaunchComponent.component_fail
            let err = error.newOPError(monitorCode: monitorCode)
            OPMonitor(name: String.OPBlockitMonitorKey.eventName,
                      code: monitorCode)
                .setResultTypeFail()
                .setError(err)
                .setUniqueID(containerContext.uniqueID)
                .tracing(containerContext.blockContext.trace)
                .addCategoryValue("biz_error_code", "\(OPBlockitComponentErrorCode.switchToComponentFail.rawValue)")
                .flush()
            trace.error("OPBlockContainer.componentLoadStart router.switchToComponent error: \(err.localizedDescription)")
            onFail(error: err)
        }
    }
    
    func packageReaderReady(packageReader: OPPackageReaderProtocol) {
        trace.info("OPBlockContainer.packageReaderReady")

        self.packageReader = packageReader
        guard let reader = packageReader as? BDPPackageUncompressedFileHandle else {
            trace.error("OPBlockContainer.packageReaderReady error: packageReader == nil || casting BDPPackageUncompressedFileHandle failed")
            return
        }

        sandbox = (BDPModuleManager(of: .block)
                    .resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol)?
                    .createSandbox(with: containerContext.uniqueID, pkgName: reader.packageContext.packageName)
    }
    
    func configReady(projectConfig: OPBlockProjectConfig, blockConfig: OPBlockConfig) {
        trace.info("OPBlockContainer.configReady")
        onConfigReady(projectConfig: projectConfig)
        if userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableTimeoutOptimize.key) {
            startBizTimerIfNeeded(projectConfig: projectConfig)
        }
    }

    /// Check if  `userStartLoading` is true
    ///
    /// - Parameter projectConfig: block project settings
    private func checkIfUseStartLoading(projectConfig: OPBlockProjectConfig) -> Bool {
        let blockSettings = projectConfig.blocks?.first?.configData
        guard let useStartLoading = blockSettings?["useStartLoading"] as? Bool else { return false }
        return useStartLoading
    }

    /// Start timer if `userStartLoading` is `true`
    ///
    /// - Parameter projectConfig: block project settings
    private func startBizTimerIfNeeded(projectConfig: OPBlockProjectConfig) {
        guard let timeInterval = bizTimeoutInterval, checkIfUseStartLoading(projectConfig: projectConfig) else { return }
        trace.info("OPBlockContainer.startBizTimerIfNeeded: start biz-level timer")
        let timer = Timer(timeInterval: timeInterval, repeats: false, block: { [weak self] _ in self?.onBizTimeout() })
        RunLoop.main.add(timer, forMode: .common)
        bizTimer = timer
    }

    private func onBizTimeout() {
        trace.info("OPBlockContainer.onBizTimeout")
        dispatchBlockEvent { $0.containerBizTimeout(context: containerContext.blockContext) }
    }

    func bundleUpdateSuccess(info: OPBlockUpdateInfo) {
        trace.info("OPBlockContainer.bundleUpdateSuccess")
        dispatchBlockEvent { $0.containerUpdateReady(info: info, context: containerContext.blockContext) }
    }

    func metaLoadSuccess(meta: OPBizMetaProtocol) {
        trace.info("OPBlockContainer.metaLoadSuccess")
        setDebugData(meta: meta)
        containerContext.blockContext.blockAbilityHandler?.setLocalMetaVersion(metaVersion: meta.appVersion)
    }

    // MARK: - OPBlockContainerPluginDelegate
    // Block 通过 API 重新加载数据（例如 Creator 创建 Block）
    func setBlockInfo(event: OPEvent, callback: OPEventCallback) -> Bool {
        trace.info("OPBlockContainer.setBlockInfo event: \(event.eventName)")
        dispatchBlockEvent { $0.containerCreatorDidReady(param: event.params, context: containerContext.blockContext) }
        return true
    }

    // Block Creator 创建 Block，开发者主动调用 API 取消
    func onCancel(event: OPEvent, callback: OPEventCallback) -> Bool {
        trace.info("OPBlockContainer.onCancel event: \(event.eventName)")
        dispatchBlockEvent { $0.containerCreatorDidCancel(context: containerContext.blockContext) }
        return true
    }
    
    /// 用于 setBlockInfo api plugin 调用
    func setBlockInfo(params: [AnyHashable : Any]) {
        trace.info("OPBlockContainer.setBlockInfo")
        dispatchBlockEvent { $0.containerCreatorDidReady(param: params, context: containerContext.blockContext) }
    }
    
    /// 用于 cancel api plugin 调用
    func onCancel() {
        trace.info("OPBlockContainer.onCancel")
        dispatchBlockEvent { $0.containerCreatorDidCancel(context: containerContext.blockContext) }
    }

    /// hideBlockLoading plugin callback
    func hideBlockLoading(callback: @escaping (Result<[AnyHashable: Any]?, OPError>) -> Void) -> Bool {
        trace.info("OPBlockContainer.hideBlockLoading")
        // make sure call the invalidate method from the same thread on which the timer was installed.
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            guard let projectSettings = self.projectConfig as? OPBlockProjectConfig, self.checkIfUseStartLoading(projectConfig: projectSettings) else {
                callback(.failure(.unknownError(detail: "useStartLoading config missing")))
                return
            }
            // Do nothing if already timeout
            if let timer = self.bizTimer, !timer.isValid {
                self.trace.info("Already timeout, do nothing.")
                callback(.success(nil)); return
            }
            self.bizTimer?.invalidate()
            self.dispatchBlockEvent { $0.containerBizSuccess(context: self.containerContext.blockContext) }
            callback(.success(nil))
        }
        return true
    }

    func updateBlockShareEnableStatus(_ enable: Bool) {
        trace.info("OPBlockContainer.updateBlockShareEnableStatus")
        dispatchBlockEvent { $0.containerShareStatusUpdate(context: containerContext.blockContext, enable: enable) }
    }

    func receiveBlockShareInfo(_ info: OPBlockShareInfo) {
        trace.info("OPBlockContainer.receiveBlockShareInfo")
        dispatchBlockEvent { $0.containerShareInfoReady(context: containerContext.blockContext, info: info) }
    }

    func tryHideBlock() {
        trace.info("OPBlockContainer.tryHideBlock")
        dispatchBlockEvent { $0.tryHideBlock(context: containerContext.blockContext) }
    }

    private func dispatchBlockEvent(handle: (OPBlockContainerLifeCycleDelegate) -> Void) {
        enumerateLifeCycleDelegate { wDelegate in
            guard let delegate = wDelegate.value as? OPBlockContainerLifeCycleDelegate else {
                trace.error("OPBlockContainer.dispatchBlockEvent error: no wDelegate.value or casting OPBlockContainerLifeCycleDelegate error")
                return
            }
            handle(delegate)
        }
    }

    // MARK: - OPBlockContainerRouterDelegate
    
    // Container 尺寸变化
    func onContainerViewSizeChange(old: CGSize, new: CGSize) {
        trace.info("OPBlockContainer.onContainerViewSizeChange old: \(old), new: \(new)")
        do {
            trace.info("OPBlockContainer.onContainerViewSizeChange.sendEventToBridge")
            // TODO: on消息回调是否要封装成一个 Bridge 需要设计
            try sendEventToBridge(
                eventName: "onWindowResize",
                params: [
                    "size": [
                        "windowWidth": Int(new.width),
                        "windowHeight": Int(new.height),
                    ]
                ],
                callback: nil)
        } catch {
            // TODO: 异常处理逻辑
            trace.error("OPBlockContainer.onContainerViewSizeChange.sendEventToBridge error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - OPContainerLifeCycleDelegate
    func containerDidLoad(container: OPContainerProtocol) {}
    
    func containerDidFail(container: OPContainerProtocol, error: OPError) {
        trace.error("OPBlockContainer.containerDidFail container: \(container) error: \(error.localizedDescription)")

        OPBlockExceptionResolver.resolve(error: error, router: router)
    }
    
    func containerDidUnload(container: OPContainerProtocol) {

    }
    
    func containerDidDestroy(container: OPContainerProtocol) {
        trace.info("OPBlockContainer.containerDidDestroy container: \(container)")
        /// containerContext销毁时trace自然销毁
    }
    
    func containerDidShow(container: OPContainerProtocol) {
        trace.info("OPBlockContainer.containerDidShow container: \(container)")
        router.currentComponent?.onShow()
    }
    
    func containerDidHide(container: OPContainerProtocol) {
        trace.info("OPBlockContainer.containerDidHide container: \(container)")
        router.currentComponent?.onHide()
    }
    
    func containerDidPause(container: OPContainerProtocol) {
        
    }
    
    func containerDidResume(container: OPContainerProtocol) {
        
    }
    
    func containerConfigDidLoad(container: OPContainerProtocol, config: OPProjectConfig) {

    }
    
    func containerDidReady(container: OPContainerProtocol) {
        trace.info("OPBlockContainer.containerDidReady container: \(container)")

        /// 异步探测沙箱数据并上报
        SandboxDetection.asyncDetectAndReportSandboxInfo(uniqueId: containerContext.uniqueID)
    }

    func reRednerCurrentPage() {
        router.currentComponent?.reRender()
    }

    // OPComponentLifeCycleProtocol
    // 外部传入的是BlockitDelegate，内部包含了OPBlockWebLifeCycleDelegate，但原接口协议声明hostDelegate为BlockHostProtocol，避免对现有逻辑影响，此处适配转换；后续收敛BlockitDelegate的三个协议后使用新的hostDelegate
    var webHostDelegate: OPBlockWebLifeCycleDelegate? {
        return hostDelegate as? OPBlockWebLifeCycleDelegate
    }

    /// Component 内容高度发生变化 （实际等同于render内部真实内容发生变化），高度单位为px
    func contentHeightDidChange(component: OPComponentProtocol, height: CGFloat) {
        guard component === router.currentComponent else {
            trace.error("contentSizeDidChange form other component",
                        additionalData: ["componentUniqueID": component.context.uniqueID.fullString,
                                         "currentUniqueID": containerContext.uniqueID.fullString])
            return
        }
        if let webRender = router.currentComponent?.getChild(where: { $0 is OPBlockWebRender
        }) as? OPBlockWebRender {
            let zoomScale = webRender.webBrowser.webview.scrollView.zoomScale
			trace.info("web render update content height \(height) zoomScale \(zoomScale)")
            webHostDelegate?.onBlockContentSizeChanged(height: height * zoomScale, context: containerContext.blockContext)
        } else {
            // 目前仅有web会发送conentHeight方法
            trace.error("only web render can tigger contentHeightDidChange")
            assertionFailure("should not enter here")
        }
    }

    /// Component  页面开始加载，可能会多次回调
    func onPageStartRender(component: OPComponentProtocol, pageInfo: OPRenderPageDataProtocol) {
        guard component === router.currentComponent else {
            trace.error("onPageStartRender form other component",
                        additionalData: ["componentUniqueID": component.context.uniqueID.fullString,
                                         "currentUniqueID": containerContext.uniqueID.fullString])
            return
        }
        if let page = pageInfo as? OPBlockWebPageInfo {
            webHostDelegate?.onPageStart(url: page.url, context: containerContext.blockContext)
        } else {
            // 目前仅有web会发送page方法
            trace.error("only web render can tigger onPageStartRender")
            assertionFailure("should not enter here")
        }
    }

    /// Component  页面加载成功，可能会多次回调
    func onPageRenderSuccess(component: OPComponentProtocol, pageInfo: OPRenderPageDataProtocol) {
        guard component === router.currentComponent else {
            trace.error("onPageRenderSuccess form other component",
                        additionalData: ["componentUniqueID": component.context.uniqueID.fullString,
                                         "currentUniqueID": containerContext.uniqueID.fullString])
            return
        }
        if let page = pageInfo as? OPBlockWebPageInfo {
            webHostDelegate?.onPageSuccess(url: page.url, context: containerContext.blockContext)
        } else {
            // 目前仅有web会发送page方法
            trace.error("only web render can tigger onPageRenderSuccess")
            assertionFailure("should not enter here")
        }
    }

    /// Component 页面加载失败，可能会多次回调
    func onPageRenderFail(component: OPComponentProtocol, pageInfo: OPRenderPageDataProtocol, error: OPError) {
        guard component === router.currentComponent else {
            trace.error("onPageRenderFail form other component",
                        additionalData: ["componentUniqueID": component.context.uniqueID.fullString,
                                         "currentUniqueID": containerContext.uniqueID.fullString])
            return
        }
        if let page = pageInfo as? OPBlockWebPageInfo {
            webHostDelegate?.onPageError(url: page.url, error: error, context: containerContext.blockContext)
        } else {
            // 目前仅有web会发送page方法
            trace.error("only web render can tigger onPageRenderFail")
            assertionFailure("should not enter here")
        }
    }

    /// Component 页面运行崩溃，可能会多次回调
    func onPageRenderCrash(component: OPComponentProtocol, pageInfo: OPRenderPageDataProtocol, error: OPError?) {
        guard component === router.currentComponent else {
            trace.error("onPageRenderCrash form other component",
                        additionalData: ["componentUniqueID": component.context.uniqueID.fullString,
                                         "currentUniqueID": containerContext.uniqueID.fullString])
            return
        }
        if let page = pageInfo as? OPBlockWebPageInfo {
            webHostDelegate?.onPageCrash(url: page.url, context: containerContext.blockContext)
        } else {
            // 目前仅有web会发送page方法
            trace.error("only web render can tigger onPageRenderCrash")
            assertionFailure("should not enter here")
        }

    }
}

// 错误页控制
extension OPBlockContainer {
    func hideStatusView() {
        router.hideStatusView()
    }
    func isShowingStatusView() -> Bool {
        return router.isShowingStatusView()
    }

    func showErrorPage(
        errorMessage: String,
        buttonText: String?,
        success: ((Bool) -> Void)?,
        failure: (() -> Void)?
    ) {
        trace.info("OPBlockContainer.showErrorPage", additionalData: [
            "errorMessage": errorMessage,
            "buttonText": String(describing: buttonText)
        ])
        guard let config = containerContext.containerConfig as? OPBlockContainerConfig else {
            assertionFailure("OPBlockContainer.showErrorPage config empty")
            trace.error("OPBlockContainer.showErrorPage config empty")
            failure?()
            return
        }
        let creator = config.errorPageCreator ?? { (router) in
            return OPCustomBlockErrorPage(delegate: router)
        }
        router.showErrorPage(
            errorPageCreator: creator,
            isFromHost: (config.errorPageCreator != nil),
            errorMessage: errorMessage,
            buttonText: buttonText,
            onButtonClicked: { [weak self] in
                do {
                    self?.trace.info("OPBlockContainer.onBlockErrorPageButtonClicked send event")
                    try self?.bridge.sendEvent(eventName: "onBlockErrorPageButtonClick", params: [:], callback: nil)
                } catch {
                    self?.trace.error("OPBlockContainer.onBlockErrorPageButtonClicked send event failed", error: error)
                }
            },
            success: { [weak self] (isFromHost) in
                if let `self` = self {
                    self.hostDelegate?.hideBlockHostLoading(self)
                }
                success?(isFromHost)
            },
            failure: {
                failure?()
            }
        )
    }
    func hideErrorPage(
        success: ((Bool) -> Void)?,
        failure: (() -> Void)?
    ) {
        trace.info("OPBlockContainer.hideErrorPage")
        router.hideErrorPage { (isFromHost) in
            success?(isFromHost)
        } failure: {
            failure?()
        }

    }
    func isShowingErrorPage() -> Bool {
        let isShowing = router.isShowingErrorPage()
        trace.info("OPBlockContainer.isShowingErrorPage: \(isShowing)")
        return isShowing
    }
}

extension OPContainerContext {
    // blockTrace为实际使用的trace对象，在这里统一做强制类型转换
    var blockTrace: BlockTrace {
        self.baseBlockTrace as! BlockTrace
    }
}

private var opBlockDebugService: Void?

extension OPBlockContainer {
    
    private var debugService: BlockDebugService? {
        get {
            return objc_getAssociatedObject(self, &opBlockDebugService) as? BlockDebugService
        }
        set {
            objc_setAssociatedObject(
                self,
                &opBlockDebugService,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // 用于传入block debug所需的信息以及定义手势
    private func setDebugData(meta: OPBizMetaProtocol) {
        if let debugService = debugService, debugService.getOpenBlockDetailDebug(), let meta = meta as? OPBlockMeta {
            debugService.setAppName(appName: meta.appName)
            debugService.setBlockVersion(blockVersion: meta.appVersion)
            debugService.setPackageUrl(packageUrl: meta.packageUrls.joined(separator: ","))
            debugService.setBlockType(blockType: meta.extConfig.pkgType.rawValue)
        }
    }

    private func setDebugGestureAndContext(view: UIView, blockConfig: OPBlockConfig?, context: OPContainerContext) {
        if let debugService = debugService, debugService.getOpenBlockDetailDebug() {
            debugService.setDarkMode(isSupportDarkMode: blockConfig?.darkmode)
            debugService.setContainerContext(context: context)
            debugService.addDebugGesture(slot: view)
        }
    }
}
