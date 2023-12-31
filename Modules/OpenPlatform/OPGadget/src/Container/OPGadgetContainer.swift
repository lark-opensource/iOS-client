//
//  OPGadgetContainer.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/12.
//

import Foundation
import OPSDK
import TTMicroApp
import LKCommonsLogging
import OPFoundation
import ECOInfra
import LarkFeatureGating
import LarkMonitor
import LarkUIKit
import EENavigator
import LarkSetting
import LarkTab
import LarkContainer
import LarkQuickLaunchInterface

fileprivate let logger = GadgetLog(OPGadgetContainer.self, category: "gadgetContainer")

@objc
public protocol OPGadgetContainerProtocol: OPContainerProtocol {
    
    func addGadgetLifeCycleDelegate(delegate: OPGadgetContainerLifeCycleDelegate)
    
}

@objcMembers
public final class OPGadgetContainer: OPBaseContainer, OPGadgetContainerProtocol,
                                OPGadgetContainerRouterDelegate,
                                OPContainerLifeCycleDelegate, OPGadgetLoadTaskDelegate,
                                OPGadgetContainerUpdaterDelegate {
    
    private let containerConfig: OPGadgetContainerConfigProtocol
    
    private var router: OPGadgetContainerRouter?
    
    private var loadTask: OPGadgetLoadTask?
    
    private var packageReader: BDPPkgFileReadHandleProtocol?
    
    private var firstAppearFlag: Bool = false
    
    @ProviderSetting(.useDefaultKeys)
    private var reloadConfig: OPGadgetContainerReloadConfig?
    
    @InjectedUnsafeLazy var temporaryTabService: TemporaryTabService
    
    
    public init(applicationContext: OPApplicationContext, uniqueID: OPAppUniqueID, containerConfig: OPGadgetContainerConfigProtocol) {
        logger.info("OPGadgetContainer.init uniqueID:\(uniqueID)")
        if BDPWarmBootManager.shared()?.hasCacheData(with: uniqueID) == true {
            logger.info("OPGadgetContainer.cleanCache uniqueID:\(uniqueID)")
            BDPWarmBootManager.shared()?.cleanCache(with: uniqueID)
        }
        
        // 构造 containerContext
        let containerContext = OPContainerContext(applicationContext: applicationContext, uniqueID: uniqueID, containerConfig: containerConfig)
        
        self.containerConfig = containerConfig
        
        let updater = OPGadgetContainerUpdater(containerContext: containerContext)
        
        super.init(containerContext: containerContext, updater: updater)
        addLifeCycleDelegate(delegate: self)
        updater.delegate = self
    }
    
    deinit {
        logger.info("OPGadgetContainer.deinit uniqueID:\(containerContext.uniqueID)")
        onDestroy(monitorCode: OPSDKMonitorCode.cancel)
    }
    
    public override func needUnmountBeforeMount(data: OPContainerMountDataProtocol, renderSlot: OPRenderSlotProtocol) -> Bool {
        // 如果当前已经在显示，则不需要执行 unmount
        /// 如果启用了新的路由体系，路由会包办小程序的移除和消失，不需要再判断是否是同window
        if slotAttatched,
           containerContext.visibility == .visible,
           containerContext.mountState == .mounted {
            return false
        }
        return true;
    }
    
    public override func onMount(data: OPContainerMountDataProtocol, renderSlot: OPRenderSlotProtocol) {
        
        configContainer(renderSlot: renderSlot)
        
        BDPTimorClient.shared().setup(beforeLaunch: containerContext.uniqueID)
        
        // 小程序 onMount 有四种场景
        // 1. 冷启动 firstMountData == nil, mountState != mounted  执行冷启动逻辑
        // 2. 热启动 firstMountData != nil, mountState != mounted  执行热启动逻辑
        // 3. 已在栈顶可见 firstMountData != nil, mountState == mounted, visibility == .visible 什么也不做
        // 4. 不在栈顶不可见 firstMountData != nil, mountState == mounted, visibility != .visible 仅将应用置顶
        
        // 在调用 super 之前通过 firstMountData 判断是否是热启动
        let warmLaunch = self.containerContext.firstMountData != nil
        logger.info("onMount. uniqueID:\(containerContext.uniqueID), warmLaunch:\(warmLaunch), scene:\(data.scene)")
        
        // 兼容现有逻辑，待迁移
        if (!warmLaunch) {
            if let trace = BDPTracingManager.sharedInstance().getTracingBy(containerContext.uniqueID) {
                logger.warn("clearTracing for last launch: \(trace.traceId)")
                BDPTracingManager.sharedInstance().clearTracing(by: containerContext.uniqueID)
            }
            
            let trace = OPUnsafeObject(BDPTracingManager.sharedInstance().generateTracing(by: containerContext.uniqueID))
            trace?.clientDurationTagStart(kEventName_mp_app_launch_start)
        }
        
        if BDPXScreenManager.isXScreenFGConfigEnable() && OPSDKFeatureGating.enableStopLaunchingSelfWhilePresentingInXScreen()  {
            let currentMountData = self.containerContext.currentMountData as? OPGadgetContainerMountData;
            // 半屏小程序展示的情况下,不允许打开自己的全屏模式,值得说明的是，单纯从代码上是可以打开自己的（这是一个比较极端的case),但是在产品逻辑上被限制.
            if let _ = currentMountData?.xScreenData, self.router?.containerController.navigationController != nil  {
                logger.info("try open self while Xscreen gadget showing")
                return
            }
        }
        
        reportStart(data: data, warmLaunch: warmLaunch)
        
        super.onMount(data: data, renderSlot: renderSlot)
        
        // 判断是否是热启动
        if warmLaunch, let mountData = data as? OPGadgetContainerMountDataProtocol {
            router?.excuteWarmBoot(mountData: mountData)
        }
    }
    
    public override func onUnmount(monitorCode: OPMonitorCode) {
        super.onUnmount(monitorCode: monitorCode)
        
        if containerContext.isReloading {
            // 如果正在 reloading 则不需要执行清理逻辑
            logger.info("onUnmount during reloading")
        } else {
            // 尝试执行清理逻辑
            if containerContext.availability != .ready, containerContext.availability != .destroyed {
                // 启动未成功就被关掉，直接 destroy，防止出现启动失败无法重试
                onDestroy(monitorCode: monitorCode)
            } else {
                // 验证退出时存在异常则清理热启动缓存
                if !OPSDKFeatureGating.isGadgetContainerRemoveCode(self.containerContext.uniqueID) {
                    // 即将删除的代码
                    // 如果旧容器内发生任何启动后运行时严重错误，都应当在退出尝试清理热缓存
                    if let loadResultType = router?.containerController.loadResultType,
                       (loadResultType.level == OPMonitorLevelError || loadResultType.level == OPMonitorLevelFatal) {
                        onDestroy(monitorCode: monitorCode)
                    }
                }
            }
        }
    }
    
    public override func onLoad() {
        super.onLoad()
        
        // 构造 router
        let router = OPGadgetContainerRouter(containerContext: containerContext)
        router.containerController.willReboot = true    // 待适配删除
        router.delegate = self
        self.router = router
        
        let loadTask = OPGadgetLoadTask()
        loadTask.name = "OPGadgetLoadTask(\(containerContext.uniqueID))"
        loadTask.delegate = self
        loadTask.taskDidFinshedBlock = { [weak self] (task, state, error) in
            guard let self = self else {
                logger.info("self released")
                return
            }
            guard self.loadTask?.taskID == task.taskID else {
                logger.info("task released")
                return
            }
            executeOnMainQueueAsync {
                if state == .succeeded {
                    // 启动成功
                    self.onReady()
                } else {
                    // 启动失败
                    self.onFail(error: error ?? OPSDKMonitorCode.unknown_error.error())
                }
            }
        }
        loadTask.taskDidProgressChangeBlock = { [weak self] (task, progress) in
            guard let self = self else {
                logger.info("self released")
                return
            }
            guard self.loadTask?.taskID == task.taskID else {
                logger.info("task released")
                return
            }
            if let plugin = BDPTimorClient.shared().lifeCyclePlugin.sharedPlugin() as? BDPLifeCyclePluginDelegate {
                logger.info("bdp_onLoading. uniqueID:\(self.containerContext.uniqueID)")
                plugin.bdp_?(onLoading: self.containerContext.uniqueID, progress: CGFloat(progress.completedUnitCount) / CGFloat(progress.totalUnitCount))
            }
        }
        loadTask.input = OPGadgetLoadTaskInput(
            containerContext: containerContext,
            router: router)
        self.loadTask = loadTask
        
        // 如果允许容灾任务执行，等待任务执行完毕后继续小程序执行
        // 小程序打开时，等待容灾任务执行完毕
        if !OPGadgetDRManager.shareManager.isDRRunning() {
            loadTask.start()
            OPGadgetDRLog.logger.info("Current DR is not running!")
        }else {
            loadTask.isDRRuning = true
            OPGadgetDRLog.logger.info("Current DR is running!")
            OPGadgetDRManager.shareManager.registerDRFinished { [weak self] in
                guard let self = self else {
                    return
                }
                DispatchQueue.main.async {
                    self.loadTask?.start()
                }
            }
        }
    }
    
    public override func onUnload(monitorCode: OPMonitorCode) {
        
        // 目前的小程序比较特殊，VC容器不能复用，unload 时必须同时 unbind 一下VC容器才能完成小程序清理
        if let renderSlot = currentRenderSlot, slotAttatched {
            logger.info("onLoad need unbindSlot. uniqueID:\(containerContext.uniqueID)")
            _ = onUnbindSlot(renderSlot: renderSlot)
        }
        
        // 重建 Router
        router?.unload()
        router?.delegate = nil
        router = nil
        
        // 需要先清理置空 loadTask，不然直接 cancel 会先出发本次的错误回调
        let tLoadTask = self.loadTask
        self.loadTask?.delegate = nil
        self.loadTask = nil
        tLoadTask?.cancel(monitorCode: monitorCode)
        
        packageReader = nil
        
        super.onUnload(monitorCode: monitorCode)
    }
    
    public override func removeTemporaryTab() {
        if Display.pad && OPTemporaryContainerService.isGadgetTemporaryEnabled() {
            guard let router = router else {
                return
            }
            if let tabcontainer = router.containerController as? TabContainable,tabcontainer.isTemporaryChild {
                logger.info("removeTemporaryTab id: \(tabcontainer.tabContainableIdentifier)")
                temporaryTabService.removeTab(id: tabcontainer.tabContainableIdentifier)
            }
        }
    }
    
    public override func onReload(monitorCode: OPMonitorCode) {
        
        if let renderSlot = currentRenderSlot, !(renderSlot is OPChildControllerRenderSlot) {
            logger.info("onReload")
            // push模式使用完全销毁重建的 reload 机制
            let uniqueID = containerContext.uniqueID
            let useCurrentMountData = reloadConfig?.useCurrentMountData(appId: uniqueID.appID) ?? false
            let mountData: OPGadgetContainerMountData?
            if(useCurrentMountData) {
                logger.info("reload use currentMountData")
                mountData = containerContext.currentMountData as? OPGadgetContainerMountData
            } else {
                mountData = containerContext.firstMountData as? OPGadgetContainerMountData
                logger.info("reload use firstMountData")
                
                // iPad临时区:通过scene来判断是否在临时区展示(当前仅工作台在splitVC展示,其余在临时区展示)
                // 当进行reload时,如果使用冷启动链接会出现一种场景(工作台冷启动,临时区热启动,临时区重启)找不到对应的slot,导致重启动异常.所以需要更新scene.
                // 后续整体将settings配置gadget_reload_current_schema全量后就不再有类似问题
                if OPTemporaryContainerService.isGadgetTemporaryEnabled() && Display.pad {
                    if let currentScene = containerContext.currentMountData?.scene {
                        logger.info("reload update scene")
                        mountData?.updateScene(scene: currentScene)
                    }
                }
            }
            
            // 对启动参数标记来源为reload
            mountData?.markAsFromReload()
            
            let containerConfig = containerContext.containerConfig as? OPGadgetContainerConfig
            let oldVC = router?.containerController
            
            
            if BDPXScreenManager.isXScreenFGConfigEnable() && !(renderSlot is OPXScreenControllerRenderSlot) {
                // 如果当前不是半屏模式,那么重新加载应用需要将半屏参数去掉，加载全屏
                mountData?.xScreenData = nil
            }
            
            self.onDestroy(monitorCode: monitorCode)
            
            // 目前还没有完善的动画监听方案，需要等动画完成
            BDPTimorClient.shared().setEnableOpenURL(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak oldVC] in
                BDPTimorClient.shared().setEnableOpenURL(true)
                if oldVC?.parent != nil {
                    logger.error("oldVC not closed")
                    // 旧 VC 还未完全退出，出现了异常，什么也不做
                    return
                }
                if OPApplicationService.current.getContainer(uniuqeID: uniqueID) != nil {
                    // 如果出现被抢占启动情况，什么也不做
                    logger.error("reload already")
                    return
                }
                if let mountData = mountData,
                      let containerConfig = containerConfig {
                    _ = OPApplicationService.current.gadgetContainerService().fastMount(
                        uniuqeID: uniqueID,
                        mountData: mountData,
                        containerConfig: containerConfig,
                        renderSlot: renderSlot)
                } else {
                    logger.error("reload data invalid")
                    return
                }
            }
        } else {
            super.onReload(monitorCode: monitorCode)
    
            onUnmount(monitorCode: monitorCode)
        }
    }
    
    public override func onBindSlot(renderSlot: OPRenderSlotProtocol) -> Bool {
        guard let router = router else {
            logger.error("onBindSlot router is nil. uniqueID:\(containerContext.uniqueID)")
            return false
        }
        
        let animated = true
        
        if let renderSlot = renderSlot as? OPChildControllerRenderSlot {
            logger.info("onBindSlot OPChildControllerRenderSlot. uniqueID:\(containerContext.uniqueID)")
            
            router.containerController.openType = .child
            renderSlot.parentViewController.addChild(router.containerController)
            renderSlot.parentViewController.view.addSubview(router.containerController.view)
            router.containerController.view.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            router.containerController.didMove(toParent: renderSlot.parentViewController)
            return super.onBindSlot(renderSlot: renderSlot)
        } else if let renderSlot = renderSlot as? OPPushControllerRenderSlot {
            logger.info("onBindSlot OPPushControllerRenderSlot. uniqueID:\(containerContext.uniqueID)")
            
            router.containerController.openType = .push
            
            // 未验证的逻辑，开启前先充分验证
//            if renderSlot.navigationController != router.containerController.navigationController,
//               let oldNavigationController = router.containerController.navigationController{
//                // 如果要 push 到不同的 navigationController 中，应当先从原有的 navigationController 中移除
//                var hasModified = false
//                var children = oldNavigationController.viewControllers
//                children.removeAll { (viewController) -> Bool in
//                    if viewController == router.containerController {
//                        hasModified = true
//                        return true
//                    }
//                    return false
//                }
//                if hasModified {
//                    oldNavigationController.setViewControllers(children, animated: false)
//                }
//             }
            
            if var children = router.containerController.navigationController?.viewControllers,
               let index = children.lastIndex(of: router.containerController) {
                // 已在界面栈中
                if index == children.count - 1 {
                    // 在栈顶, 什么也不做
                    
                } else {
                    // 在栈中，需要先移除
                    children.remove(at: index)
                    children.append(router.containerController)
                    renderSlot.navigationController.setViewControllers(children, animated: animated)
                }
            } else {
                // 直接 apppend
                renderSlot.navigationController.pushViewController(
                    router.containerController,
                    animated: animated)
            }
            return super.onBindSlot(renderSlot: renderSlot)
        } else if let renderSlot = renderSlot as? OPPresentControllerRenderSlot {
            logger.info("onBindSlot OPPresentControllerRenderSlot. uniqueID:\(containerContext.uniqueID)")
            
            router.containerController.openType = .present
            renderSlot.presentingViewController.present(router.containerController, animated: animated)
            return super.onBindSlot(renderSlot: renderSlot)
        } else if let renderSlot = renderSlot as? OPCustomControllerRenderSlot {
            logger.info("onBindSlot OPCustomControllerRenderSlot. uniqueID:\(containerContext.uniqueID)")
            if renderSlot.bindViewControllerBlock(renderSlot, router.containerController, self) == true {
                return super.onBindSlot(renderSlot: renderSlot)
            } else {
                logger.warn("onBindSlot OPCustomControllerRenderSlot failed. uniqueID:\(containerContext.uniqueID)")
            }
        }  else if let renderSlot = renderSlot as? OPXScreenControllerRenderSlot {
            logger.info("onBindSlot OPXScreenControllerRenderSlot. uniqueID:\(containerContext.uniqueID)")
            
            if let _ = router.containerController.navigationController {
                // 处理被打开的半屏已经在导航栈内，需要将其从导航栈内移除
                logger.info("onBindSlot open XScreen Already in stack uniqueID:\(containerContext.uniqueID)")
                router.containerController.op_removeFromNavigationController(animated: false) {
                    router.containerController.openType = .present
                    // 此时可能存在router.containerController又是renderSlot.presentingViewController的场景，所以抛弃不用，使用应用最上的VC来present
                    OPUserScope.userResolver().navigator.present(router.containerController, wrap: LkNavigationController.self, from:  OPNavigatorHelper.topMostVC(window: UIApplication.shared.keyWindow)!, prepare: {
                        $0.modalPresentationStyle = .custom
                        $0.transitioningDelegate = router.containerController.XScreenTransitionDelegate
                    }, animated: true)
                } failure: { error in
                    // 打开半屏时，在导航栈内的小程序不能被移除时，依旧需要调用super.onBindSlot
                    logger.info("onBindSlot open XScreen Already in stack failed to remove")
                }
                // 需要对状态进行更新，否则会导致状态异常
                return super.onBindSlot(renderSlot: renderSlot)
            }
            
            router.containerController.openType = .present
            OPUserScope.userResolver().navigator.present(router.containerController, wrap: LkNavigationController.self, from: renderSlot.presentingViewController, prepare: {
                $0.modalPresentationStyle = .custom
                $0.transitioningDelegate = router.containerController.XScreenTransitionDelegate
            }, animated: true)
            
            return super.onBindSlot(renderSlot: renderSlot)
        } else if let renderSlot = renderSlot as? OPUniversalPushControllerRenderSlot {
            router.containerController.openType = .push

            /// 如果是使用了统一路由机制，那么需要使用GadgetNavigator进行路由
            let uniqueID = containerContext.uniqueID
            logger.info("onBindSlot OPUniversalPushControllerRenderSlot. uniqueID:\(uniqueID)")
            /// ⚠️这里如果找不到renderSlot的window，那么我们就去找main window⚠️
            let windowOptional = renderSlot.window ?? OPWindowHelper.fincMainSceneWindow()
            guard let window = windowOptional else {
                logger.error("onBindSlot OPUniversalPushControllerRenderSlot. puhsh failed, windw is nil. uniqueID:\(uniqueID)")
                return false
            }
            
            if Display.pad, !OPSDKFeatureGating.gadgetRouteShowTemporaryDisable(), let mountData = containerContext.currentMountData as? OPGadgetContainerMountData, let showInTemporaray =  mountData.showInTemporaray {
                router.containerController.shouldOpenInTemporaryTab = showInTemporaray
            } else {
                if Display.pad && OPTemporaryContainerService.isGadgetTemporaryEnabled() {
                    if OPSDKFeatureGating.workplaceGadgetOpenInTemporaryEnable() {
                        router.containerController.shouldOpenInTemporaryTab = containerContext.currentMountData?.scene != .feed
                    } else {
                        router.containerController.shouldOpenInTemporaryTab = (containerContext.currentMountData?.scene != .appcenter
                                                                               && containerContext.currentMountData?.scene != .feed)
                    }
                }
            }
            
            GadgetNavigator.shared.push(viewController: router.containerController, from: window, animated: animated) {
                if let error = $0 {
                    logger.error("onBindSlot OPUniversalPushControllerRenderSlot. puhsh failed. errMsg: \(error.localizedDescription). uniqueID:\(uniqueID)")
                } else {
                    logger.info("onBindSlot OPUniversalPushControllerRenderSlot. puhsh success")
                }
            }
            return super.onBindSlot(renderSlot: renderSlot)
        }
        return false
    }
    
    public override func onUnbindSlot(renderSlot: OPRenderSlotProtocol) -> Bool {
        guard let router = router else {
            logger.error("onUnbindSlot router is nil. uniqueID:\(containerContext.uniqueID)")
            return false
        }
        
        let animated = true
        
        if let renderSlot = renderSlot as? OPChildControllerRenderSlot {
            logger.info("onUnbindSlot OPChildControllerRenderSlot. uniqueID:\(containerContext.uniqueID)")
            router.containerController.removeFromParent()
            router.containerController.view.removeFromSuperview()
            router.containerController.didMove(toParent: nil)
            return super.onUnbindSlot(renderSlot: renderSlot)
        } else if let renderSlot = renderSlot as? OPPushControllerRenderSlot {
            logger.info("onUnbindSlot OPPushControllerRenderSlot. uniqueID:\(containerContext.uniqueID)")
            guard var children = router.containerController.navigationController?.viewControllers else {
                logger.info("onUnbindSlot navigationController.viewControllers is nil. uniqueID:\(containerContext.uniqueID)")
                return super.onUnbindSlot(renderSlot: renderSlot)
            }
            guard let index = children.lastIndex(of: router.containerController) else {
                logger.info("onUnbindSlot not found in navigationController. uniqueID:\(containerContext.uniqueID)")
                return super.onUnbindSlot(renderSlot: renderSlot)
            }
            if index == children.count - 1, children.count - 2 >= 0, let lastSecondVC = children[children.count - 2] as? BDPBaseContainerController {
                // 当前隐藏的小程序是顶层VC && 即将显示的VC 也是小程序
                logger.info("onUnbindSlot backFromOtherMiniProgram. uniqueID:\(containerContext.uniqueID)")
                lastSecondVC.backFromOtherMiniProgram = true
            }
            children.remove(at: index)
            if children.isEmpty {
                /// ⚠️在iOS13系统上，如果navigationController的setViewControllers方法传入空数组
                /// 会导致navigationController的delegate的navigationController(_:animationControllerFor:from:to:)方法中的
                /// to是一个0x00000000，但是函数签名说它不是可选值，因为使用to会直接导致crash⚠️
                /// ⚠️在iOS14系统上，那个代理方法的to和from都是一样对象
                /// 都是移除前的那个对象，有可能iOS14修复了这个系统bug⚠️
                /// 这里情况比较复杂，因为这种情况是它在导航栈中，但是导航栈只有它一个，现在要移除它
                /// 我们这里只是简单的判断是不是iPad设备，如果是我们就直接什么都不做，assert然后返回
                /// 因为按照现在的业务来说，这种情况是绝对不会出现在iPhone上
                /// 但是在这里对iPad的处理逻辑存在大问题，因为思考一下，如果这个小程序在单独的Scene中打开
                /// ⚠️那个Scene中并没有LKSplitVC，那么使用showDetail会最后触发模态弹窗，造成自己意想不到的情况⚠️
                /// 所以在这里建议尽早的废弃老的路由方式，采用新的路由方式，新的方式系统性的考虑了这些情况
                guard BDPDeviceHelper.isPadDevice() else {
                    let errMSg = "there shouldn't only one in navigationController in iphone device"
                    logger.error(errMSg)
                    assertionFailure(errMSg)
                    return super.onUnbindSlot(renderSlot: renderSlot)
                }
                // TODO: 待测试验证, Pad 需要显示默认页(与 Lark 的耦合逻辑，待迁移)
                logger.info("onUnbindSlot navigationController empty children. uniqueID:\(containerContext.uniqueID)")
                OPNavigatorHelper.showDefaultDetailForPad(from: router.containerController)
            } else {
                router.containerController.navigationController?.setViewControllers(children, animated: animated)
            }
            return super.onUnbindSlot(renderSlot: renderSlot)
        } else if let renderSlot = renderSlot as? OPPresentControllerRenderSlot {
            logger.info("onUnbindSlot OPPresentControllerRenderSlot. uniqueID:\(containerContext.uniqueID)")
            if let presentingViewController = router.containerController.presentingViewController as? BDPBaseContainerController {
                logger.info("onUnbindSlot backFromOtherMiniProgram. uniqueID:\(containerContext.uniqueID)")
                presentingViewController.backFromOtherMiniProgram = true;
            }
            
            router.containerController.dismiss(animated: animated)
            return super.onUnbindSlot(renderSlot: renderSlot)
        } else if let renderSlot = renderSlot as? OPCustomControllerRenderSlot {
            logger.info("onUnbindSlot OPCustomControllerRenderSlot. uniqueID:\(containerContext.uniqueID)")
            if renderSlot.unbindViewControllerBlock(renderSlot, router.containerController, self) == true {
                return super.onUnbindSlot(renderSlot: renderSlot)
            } else {
                logger.warn("onUnbindSlot OPCustomControllerRenderSlot failed. uniqueID:\(containerContext.uniqueID)")
            }
        } else if let renderSlot = renderSlot as? OPXScreenControllerRenderSlot {
            logger.info("onUnbindSlot OPXScreenControllerRenderSlot. uniqueID:\(containerContext.uniqueID)")
            router.containerController.navigationController?.dismiss(animated: animated)
            return super.onUnbindSlot(renderSlot: renderSlot)
        } else if let renderSlot = renderSlot as? OPUniversalPushControllerRenderSlot {
            /// code from  375 line in this file and changed a little logic
            if let children = router.containerController.navigationController?.viewControllers {
                if let index = children.lastIndex(of: router.containerController) {
                    if index == children.count - 1, children.count - 2 >= 0, let lastSecondVC = children[children.count - 2] as? BDPBaseContainerController {
                        // 当前隐藏的小程序是顶层VC && 即将显示的VC 也是小程序
                        logger.info("onUnbindSlot backFromOtherMiniProgram. uniqueID:\(containerContext.uniqueID)")
                        lastSecondVC.backFromOtherMiniProgram = true
                    }
                } else {
                    logger.info("onUnbindSlot not found in navigationController. uniqueID:\(containerContext.uniqueID)")
                }
            } else {
                logger.info("onUnbindSlot navigationController.viewControllers is nil. uniqueID:\(containerContext.uniqueID)")
            }

            /// 检查通过模态返回时，是不是返回到了一个小程序上
            /// ⚠️小程序外面套了一个NC⚠️
            if let presentingViewController = router.containerController.navigationController?.presentingViewController,
               let presentingNavigationController = presentingViewController as? UINavigationController,
               let topVC = presentingNavigationController.topViewController as? BDPBaseContainerController {
                topVC.backFromOtherMiniProgram = true
            }

            /// 如果是使用了统一路由机制，那么需要使用GadgetNavigator进行路由
            let uniqueID = containerContext.uniqueID
            /// pop 的时候一定要检查他自己是否在NC中，而且自己还需要有parent
            guard router.containerController.navigationController != nil, router.containerController.parent != nil else {
                logger.info("onUnbindSlot router.containerController.navigationController or router.containerController.parent is nil. uniqueID:\(containerContext.uniqueID)")
                return super.onUnbindSlot(renderSlot: renderSlot)
            }
            GadgetNavigator.shared.pop(viewController: router.containerController, animated: animated, complete: {
                if let error = $0 {
                    logger.error("onUnbindSlot OPUniversalPushControllerRenderSlot. pop failed. errMsg: \(error.localizedDescription). uniqueID:\(uniqueID)")
                } else {
                    logger.info("onUnbindSlot OPUniversalPushControllerRenderSlot. pop success")
                }
            })
            return super.onUnbindSlot(renderSlot: renderSlot)
        }
        
        return false
    }
    
    //        - (void)closeAndReboot:(BOOL)reboot cleanWarmCache:(BOOL)cleanWarmCache code:(OPMonitorCode *)code
    //        {
    //            BDPLogTagInfo(BDPTag.gadget, @"closeAndReboot, id=%@, currentLoadResultType=%@, reboot=%@, cleanWarmCache=%@, code=%@", self.uniqueID, self.loadResultType, @(reboot), @(cleanWarmCache), code);
    //            if (code) {
    //                self.closeCode = code;
    //            }
    //            self.willReboot = reboot;
    //
    //            // 退出事件触发
    //            [self onApplicationExitWithRestoreStatus:YES];
    //
    //            BDPUniqueID *uniqueID = self.uniqueID;
    //
    //            NSURL *openURL = self.schema.originURL;
    //            //重启时添加标记位，方便部分打点区分场景
    //            if (reboot) {
    //                BDPSchemaCodecOptions *options = [BDPSchemaCodec schemaCodecOptionsFromURL:openURL error:nil];
    //                [options.customFields setValue:BDPLaunchTypeRestart forKey:BDPLaunchTypeKey];
    //                openURL = [BDPSchemaCodec schemaURLFromCodecOptions:options error:nil];
    //            }
    //            dispatch_block_t cleanUpBlk = ^{
    //                if (cleanWarmCache || reboot) {
    //                    [[BDPWarmBootManager sharedManager] cleanCacheWithUniqueID:uniqueID];
    //                }
    //                if (reboot) {
    //                    // fix: [SUITE-4106]更新弹窗点击不能自动重启
    //                    [[BDPTimorClient sharedClient] setEnableOpenURL:NO]; // 这里屏蔽掉其他openURL，防止中间用户不小心点击进入新的小程序造成黑屏。
    //                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //                        [[BDPTimorClient sharedClient] setEnableOpenURL:YES]; // 恢复保证能用openURL
    //                        [[BDPTimorClient sharedClient] openWithURL:openURL openType:self.openType];
    //                    });
    //                }
    //            };
    //
    //            BDPPlugin(routerPlugin, BDPRouterPluginDelegate);
    //            if ([BDPDeviceHelper isPadDevice] && [routerPlugin respondsToSelector:@selector(bdp_closeMiniParam:completion:)]) {
    //                [routerPlugin bdp_closeMiniParam:self completion:^(BOOL success) {
    //                    if (success) {
    //                        UIViewController *topMost = [BDPResponderHelper topViewControllerFor:[BDPResponderHelper topmostView]];
    //                        if ([topMost isKindOfClass:[BDPBaseContainerController class]]) {
    //                            ((BDPBaseContainerController *)topMost).backFromOtherMiniProgram = YES;
    //                        }
    //                        cleanUpBlk();
    //                        BDPLogInfo([NSString stringWithFormat:@"mp %@ closeAndReboot %@ cleanWarmCache %@ success", _uniqueID, @(reboot), @(cleanWarmCache)]);
    //                    } else {
    //                        BDPLogError([NSString stringWithFormat:@"mp %@ closeAndReboot %@ cleanWarmCache %@ fail", _uniqueID, @(reboot), @(cleanWarmCache)])
    //                    }
    //                }];
    //                return;
    //            }
    //
    //            if (self.navigationController.viewControllers.count > 1) {
    //                UIViewController *preViewController = self.navigationController.viewControllers[self.navigationController.viewControllers.count - 2];
    //                if ([preViewController isKindOfClass:[BDPBaseContainerController class]]) {
    //                    ((BDPBaseContainerController *)preViewController).backFromOtherMiniProgram = YES;
    //                }
    //
    //                [self.navigationController popViewControllerAnimated:YES];
    //                cleanUpBlk();
    //            } else {
    //                if ([self.presentingViewController isKindOfClass:[BDPBaseContainerController class]]) {
    //                    ((BDPBaseContainerController *)(self.presentingViewController)).backFromOtherMiniProgram = YES;
    //                }
    //
    //                [self dismissViewControllerAnimated:YES completion:cleanUpBlk];
    //            }
    //        }
    
    public override func supportDarkMode() -> Bool {
        return BDPTaskManager.shared()?.getTaskWith(containerContext.uniqueID)?.config?.darkmode ?? false
    // MARK: - OPGadgetContainerProtocol
    }
    
    public func addGadgetLifeCycleDelegate(delegate: OPGadgetContainerLifeCycleDelegate) {
        addLifeCycleDelegate(delegate: delegate)
    }
    
    // MARK: - OPGadgetLoadTaskDelegate

    public func componentLoadStart(task: OPGadgetLoadTask, component: OPComponentProtocol, jsPtah: String) {
        
    }
    
    public func onMetaLoadSuccess(model: BDPModel) {
        executeOnMainQueueAsync {
            self.router?.containerController.updateLoading(name: model.name, iconUrl: model.icon)
        }
    }
    
    public func didTaskSetuped(uniqueID: BDPUniqueID, task: BDPTask, common: BDPCommon) {
        guard let router = router else {
            onFail(error: GDMonitorCode.invalid_router.error())
            return
        }
        
        // 提早触发webview的预加载（重构）
        if let pageManager = task.pageManager {
            pageManager.preparePreloadAppPageIfNeed()
        } else {
            logger.warn("task.pageManager is nil. uniqueID:\(uniqueID)")
        }
        
        // bind vc（重构）
        task.containerVC = router.containerController
        
        if containerContext.visibility == .visible {
            common.isForeground = true
        }
        
        if containerContext.activeState == .active {
            common.isActive = true
        }
        
        logger.info("didTaskSetuped. uniqueID=\(uniqueID)")
        
        // TODO: 初始化 ToolBarView （重构）
        //        [self setupToolBarView];
        
        if let plugin = BDPTimorClient.shared().lifeCyclePlugin.sharedPlugin() as? BDPLifeCyclePluginDelegate {
            logger.info("bdp_beforeLaunch. uniqueID=\(uniqueID)")
            plugin.bdp_?(beforeLaunch: uniqueID)
        }
        
        do {
            try onAppLaunch(warmLaunch: false, task: task, common: common, router: router)
        } catch {
            onFail(error: (error as? OPError) ?? error.newOPError(monitorCode: OPSDKMonitorCode.unknown_error) )
            return
        }
        
        setupSubNavi(router: router)
        
        router.containerController.invokeAppTaskBlks()
        
        // TODO: 超时未ready的检查逻辑，改为通过 Task 超时来实现（重构）
        // 启动 Ready 超时，在包已经下载完成的场景下，需要删包（因为包可能出现问题）
        
        
        //         WeakSelf;
        //        NSInteger second = [BDPSettingsManager.sharedManager s_integerValueForKey:kBDPSABTestLoadMAXTime];
        //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((second > 0?second:CHECK_READY_DELAY) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //             StrongSelfIfNilReturn;
        //             if (common && !common.isReady) {
        //                 BDPMonitorWithCode(GDMonitorCodeLaunch.ready_timeout, self.uniqueID).flush();
        //                 BOOL isDebugMode = [BDPAppMetaUtils metaIsDebugModeForVersionType:common.model.uniqueID.versionType];
        //                 if (isDebugMode) {
        //                     // 小程序的vConsole由tma-core实现,保持隐藏loadingView是为了可以看到vConsole
        //                     [self hideLoadingView:YES];
        //                     [self forcedEnableMoreMenu:YES];
        //                     return;
        //                 } else {
        //                     if (second > 0) {
        //                         // Lark 上该 second 值配置为0，因此不会执行下面的逻辑
        //                         NSError *error = OPErrorWithMsg(GDMonitorCodeAppLoad.not_ready_in_time, @"%@ common is not ready in time", self.uniqueID);
        //                         [self handleLoadFailedWithCode:GDMonitorCodeAppLoad.not_ready_in_time error:error useAlert:NO];
        //                     }
        //                 }
        //                 if (self.appFileReader.createLoadStatus == BDPPkgFileLoadStatusDownloaded) { // 已下载才删. 弱网留着继续下
        //                     self.removePkgBitMask |= BDPRemovePkgFromTimeout; // 非DEBUG超时标记清理
        //                 }
        //             }
        //         });
    }
    
    public func onPackageLoadFailed(error: OPError) {
        // 包下载失败，无论如何都认为小程序运行失败
        executeOnMainQueueAsync {
            self.onFail(error: error)
        }
    }
    // MARK: - OPGadgetContainerRouterDelegate
    
    func containerControllerDidWarmLaunch(router: OPGadgetContainerRouterProtocol,
                                          task: BDPTask,
                                          common: BDPCommon) {
        do {
            try onAppLaunch(warmLaunch: true, task: task, common: common, router: router)
        } catch {
            logger.error("containerControllerDidWarmLaunch onAppLaunch error. uniqueID=\(containerContext.uniqueID), error message: \(error.localizedDescription)")
        }
        
    }
    
    func containerSizeDidChanged(old: CGSize, new: CGSize) {
        
    }
    
    func containerControllerDidDisappear(viewController: UIViewController) {
        logger.info("containerControllerDidDisappear")
        guard let currentRenderSlot = currentRenderSlot else {
            return
        }
        if viewController.parent == nil {
            // 从界面中移除
            _ = self.onUnbindSlot(renderSlot: currentRenderSlot)
        } else {
            // 不可见
            notifySlotHide()
        }
    }
    
    func containerControllerDidAppear(viewController: UIViewController) {
        logger.info("containerControllerDidAppear")
        guard let currentRenderSlot = currentRenderSlot else {
            return
        }
        notifySlotShow()
        
        if firstAppearFlag == false, let plugin = BDPTimorClient.shared().lifeCyclePlugin.sharedPlugin() as? BDPLifeCyclePluginDelegate,plugin.responds(to: #selector(BDPLifeCyclePluginDelegate.bdp_(onFirstAppear:))) {
            plugin.bdp_?(onFirstAppear: containerContext.uniqueID)
            firstAppearFlag = true
        }
    }
    // MARK: - OPGadgetContainerUpdaterDelegate
    
    func reloadFromUpdater() {
        logger.info("reloadFromUpdater")
        onReload(monitorCode: GDMonitorCode.about_restart)
    }
    
//}
//
//extension OPGadgetContainer {
    
    private func onAppLaunch(warmLaunch: Bool, task: BDPTask, common: BDPCommon, router: OPGadgetContainerRouterProtocol) throws {
        
        logger.info("onAppLaunch, uniqueID=\(containerContext.uniqueID)")
        
        let uniqueID = containerContext.uniqueID
        
        // onAppLaunch调用时机需要保证在setupTaskDone之后
        // 但需要在onAppEnterForeground/onAppEnterBackground之前
        
        // TODO: startPage 的适配处理逻辑不要放在这里，请放在合适的地方（重构）
        guard let schema = router.containerController.schema else {
            throw GDMonitorCode.schema_check_error.error(message: "schema should not be nil")
        }
        
        var launchParams = BDPApplicationManager.getLaunchOptionParams(schema, type: uniqueID.appType)
        
        // 小程序场景下需要对无startPage做特殊处理
        if BDPIsEmptyString(launchParams["path"] as? String) {
            if warmLaunch {
                launchParams["path"] = task.currentPage?.path
                launchParams["query"] = task.currentPage?.queryString
            } else {
                launchParams["path"] = task.config?.entryPagePath
                launchParams["query"] = ""
            }
        }
        
        let pagePath = launchParams["path"] as? String
        let status = BDPTabBarPageController.getTabBarVCStatus(with: task, forPagePath: pagePath)
        var tabBarStatus = ["tab_bar_ready": status.rawValue]
        var onAppLaunchParams = launchParams.merging(tabBarStatus){ (current, _) in current }
    
        // 核心目标是调用这一行，这种重要的调用，请以更加强调的方式进行管理（ 例如 AppRuntime.onAppLaunch 显式的写法）
        if let context = task.context {
            context.bdp_fireEvent("onAppLaunch", sourceID: NSNotFound, data: onAppLaunchParams)
        } else {
            logger.error("task.context is nil. uniqueID=\(containerContext.uniqueID)")
        }
        
        // TODO: 这段代码需要封装，不要放在这里（重构）
        /// 检查应用是否含有某个权限
        if let specifyAbility = schema.originQueryParams?[kBDPSchemaKeyCustomFieldRequestAbility] as? String,
           !BDPIsEmptyString(specifyAbility) {
            checkAppHasSepcifyAbility(specifyAbility: specifyAbility, common: common)
        }
    }
    
    private func checkAppHasSepcifyAbility(specifyAbility: String, common: BDPCommon) {
        logger.info("checkAppHasSepcifyAbility, uniqueID=\(containerContext.uniqueID), abilityName=\(specifyAbility)")
        
        var showNeedUpdateGadgetApp = false
        
        switch specifyAbility {
        case kBDPSchemaKeyAbilityMessageAction:
            if !common.model.abilityForMessageAction {
                /// 声明有Message Action，但是没有对应权限
                showNeedUpdateGadgetApp = true
            }
        case kBDPSchemaKeyAbilityChatAction:
            if !common.model.abilityForChatAction {
                /// 声明有Chat Action，但是没有对应权限
                showNeedUpdateGadgetApp = true
            }
        default:
            break
        }
        
        if showNeedUpdateGadgetApp {
            logger.info("showNeedUpdateGadgetApp")
            router?.containerController.showNeedUpdateGadgetApp()
        }
    }
    
    private func setupSubNavi(router: OPGadgetContainerRouter) {
        logger.info("setupSubNavi")
        // 如果窗体加载成功，则加入缓存
        // TODO: 优化这块代码（重构）
        if router.containerController.subNavi != nil {
            logger.info("excuteColdBootDone")
            router.containerController.excuteColdBootDone()
        } else {
            let subNavi = BDPNavigationController(rootViewController: router.containerController.childRootViewController(),
                                    barBackgroundHidden: false,
                                    containerContext: containerContext)
            if router.containerController.setupChildViewController(subNavi) {
                // TODO:（重构）
                router.containerController.bindSubNavi(subNavi)
                router.containerController.excuteColdBootDone()
            } else {
                logger.warn("setupChildViewController failed")
            }
        }
    }

    private func reportStart(data: OPContainerMountDataProtocol, warmLaunch: Bool) {
        guard let data = data as? OPGadgetContainerMountDataProtocol else {
            logger.warn("data invalid type.")
            return
        }
        if(!warmLaunch && !LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.disable.powerlog")){
            //冷启动 且 FG未关闭的情况下，记录小程序 功耗起点，背景见： https://bytedance.feishu.cn/wiki/wikcnCmvpVZJfCdnlRa5MzVtN7f
            BDPowerLogManager.beginEvent("op_gadget_run", params: ["app_id":containerContext.uniqueID.appID])
        }

        let isColdStart = warmLaunch ? 0 : 1

        var isXScreen = 0
        if BDPXScreenManager.isXScreenFGConfigEnable(), let _ = data.xScreenData {
            isXScreen = 1
        }
        
        // 用于applink启动成功率的归因清洗，目前的情况是，reload的流程也会上报热启动数据。但是此次操作并没有经过applink。不加以区分的话，会造成上报启动数量大于经过applink的数量,目前存在两种情况,一种可以通过判断containerContext.isReloading 还一种是直接来源于调用容器reload方法
        let isReloading = containerContext.isReloading ? 1 : 0
        let fromReload = data.fromReload ? 1: 0
        data.markFromReloadAsConsumed()
        let monitor = OPMonitor(kEventName_mp_app_launch_start).setUniqueID(containerContext.uniqueID).timing()
            .addCategoryValue(kEventKey_scene, String(data.scene.rawValue))
            .addCategoryValue("cpu_max", BDPCPUMonitor.cpuUsage())
            .addCategoryValue("memory_usage", BDPMemoryMonitor.currentMemoryUsageInBytes())
            .addCategoryValue("fps_min", BDPFPSMonitor.fps())
            .addCategoryValue("is_cold_start", isColdStart)
            .addCategoryValue("reloading", isReloading)
            .addCategoryValue("fromReload", fromReload)
            .addCategoryValue("from", data.channel)
            .addCategoryValue("applink_trace_id", data.applinkTraceId)
            .addCategoryValue("XScreen", isXScreen)
            .setPlatform([.tea, .slardar])
            .setBridgeFG()
        var startPath : String? = nil
        if let path = data.startPage, let url = URL(string: path) {
            _ = monitor.addCategoryValue("start_page_path", url.path)
            startPath = url.path
        }
        
        if isColdStart == 1 {
            BDPPerformanceProfileManager.sharedInstance().initForProfileManager()
            BDPPerformanceProfileManager.sharedInstance().uniqueID = containerContext.uniqueID
            BDPPerformanceProfileManager.sharedInstance().monitorLoadTimeline(withStart: .launch, uniqueId: containerContext.uniqueID, extra: nil)
        } else {
            BDPPerformanceProfileManager.sharedInstance().monitorLoadTimeline(withStart: .warmLaunch, uniqueId: containerContext.uniqueID, extra: nil)
        }
        // 增加预加载相关信息：https://bytedance.feishu.cn/docx/doxcnbxvKuo4Kj4zyoXy1QjcIUg
        addPreloadInfoAndUpdatePreGadget(monitor: monitor, startPath: startPath)
        
        if let packageModule = BDPModuleManager(of: containerContext.uniqueID.appType).resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol,
           let packageInfoManager = OPUnsafeObject(packageModule.packageInfoManager),
           packageInfoManager.queryCountOfPkgInfo(with: containerContext.uniqueID, readType: .normal) == 0 {
            // TODO: 这里有问题，值取出来不正确
            _ = monitor.addCategoryValue("first_launch", true)
        }
        monitor.flush()
    }


    /// 增加预加载相关信息，同时更新上一个打开小程序信息
    /// - Parameters:
    ///   - monitor: 当前monitor
    ///   - startPath: 打开小程序的第一个页面路径
    private func addPreloadInfoAndUpdatePreGadget(monitor: OPMonitor, startPath: String?) {

        if OPSDKFeatureGating.disablePreloadMonitorInfo() {
            return
        }

        //page preload and Pre Gadget Info
        let pagePreloadInfo = BDPAppPageFactory.sharedManager()?.pagePreloadAndPreGadgetInfo()
        monitor.addMap(pagePreloadInfo)

        //work prelaod
        let runtimePreloadInfo = BDPJSRuntimePreloadManager.shared()?.runtimePreloadInfo()
        monitor.addMap(runtimePreloadInfo)

        // 更新上一个打开小程序的信息
        BDPAppPageFactory.sharedManager()?.updatePreGadget(containerContext.uniqueID.appID, startPath:startPath)
    }
    
    private func configContainer(renderSlot: OPRenderSlotProtocol) {
        if renderSlot is OPChildControllerRenderSlot {
            // 强制隐藏导航栏和Tab栏
            containerContext.apprearenceConfig.forceNavigationBarHidden = true
            containerContext.apprearenceConfig.forceTabBarHidden = true
            containerContext.apprearenceConfig.showDefaultLoadingView = false
        } else if renderSlot is OPPushControllerRenderSlot {
            // 不用强制隐藏导航栏和Tab栏
            containerContext.apprearenceConfig.forceNavigationBarHidden = false
            containerContext.apprearenceConfig.forceTabBarHidden = false
            containerContext.apprearenceConfig.showDefaultLoadingView = true
        } else if renderSlot is OPPresentControllerRenderSlot {
            // 不用强制隐藏导航栏和Tab栏
            containerContext.apprearenceConfig.forceNavigationBarHidden = false
            containerContext.apprearenceConfig.forceTabBarHidden = false
            containerContext.apprearenceConfig.showDefaultLoadingView = true
        } else if renderSlot is OPXScreenControllerRenderSlot {
            // 不用强制隐藏导航栏和Tab栏
            containerContext.apprearenceConfig.forceNavigationBarHidden = false
            containerContext.apprearenceConfig.forceTabBarHidden = false
            containerContext.apprearenceConfig.showDefaultLoadingView = true
        } else if renderSlot is OPUniversalPushControllerRenderSlot {
            /// 不用强制隐藏导航栏和Tab栏
            containerContext.apprearenceConfig.forceNavigationBarHidden = false
            containerContext.apprearenceConfig.forceTabBarHidden = false
            containerContext.apprearenceConfig.showDefaultLoadingView = true
        } else {
            
        }
    }
//}
//
//// 监听状态变化的结果，并做出响应
//extension OPGadgetContainer: OPContainerLifeCycleDelegate {
    public func containerDidLoad(container: OPContainerProtocol) {
        logger.info("containerDidLoad. uniqueID:\(containerContext.uniqueID)")
        if let plugin = BDPTimorClient.shared().lifeCyclePlugin.sharedPlugin() as? BDPLifeCyclePluginDelegate {
            logger.info("bdp_onStart. uniqueID:\(containerContext.uniqueID)")
            plugin.bdp_?(onStart: containerContext.uniqueID)
        }
    }
    
    public func containerDidReady(container: OPContainerProtocol) {
        logger.info("containerDidReady. uniqueID:\(containerContext.uniqueID)")
        executeOnMainQueueAsync({
            self.router?.containerController.hideLoading()
        })
        
        if let plugin = BDPTimorClient.shared().lifeCyclePlugin.sharedPlugin() as? BDPLifeCyclePluginDelegate {
            logger.info("bdp_onLaunch. uniqueID:\(containerContext.uniqueID)")
            plugin.bdp_?(onLaunch: containerContext.uniqueID)
        }

        /// 异步探测沙箱数据并上报
        SandboxDetection.asyncDetectAndReportSandboxInfo(uniqueId: containerContext.uniqueID)
    }
    
    public func containerDidFail(container: OPContainerProtocol, error: OPError) {
        logger.info("containerDidFail. uniqueID:\(containerContext.uniqueID), error:\(error)")
        
        if let plugin = BDPTimorClient.shared().lifeCyclePlugin.sharedPlugin() as? BDPLifeCyclePluginDelegate {
            if error.monitorCode == OPSDKMonitorCode.cancel {
                logger.info("bdp_onCancel. uniqueID:\(containerContext.uniqueID)")
                plugin.bdp_?(onCancel: containerContext.uniqueID)
            } else {
                logger.info("bdp_onFailure. uniqueID:\(containerContext.uniqueID)")
                plugin.bdp_?(onFailure: containerContext.uniqueID, code: error.monitorCode, msg: error.monitorCode.message)
            }
        }
        
        if loadTask?.output?.shouldRemovePkg == true {
            // TODO: 应当清理包，待测试
            logger.info("containerDidFail shouldRemovePkg. uniqueID:\(containerContext.uniqueID)")
            let pkgName = loadTask?.output?.model?.pkgName
            BDPAppLoadManager.shareService().removeAllMetaAndData(with: containerContext.uniqueID, pkgName: pkgName)
        }

        // 接入错误恢复框架
        containerContext.handleError(with: error, scene: .gadgetFailToLoad)
    }
    
    public func containerDidUnload(container: OPContainerProtocol) {
        logger.info("containerDidUnload. uniqueID:\(containerContext.uniqueID)")

        // 开始执行小程序错误恢复框架需要执行的错误恢复重试逻辑
        // 开始执行错误恢复，先通知埋点
        GadgetRecoveryMonitor.current.notifyGadgetRecoveryRecoverying(uniqueID: containerContext.uniqueID)
        // 执行一系列需要在小程序退出时执行的清理操作
        self.cleanWarmCacheIfNeeded()
        self.cleanMetaPkgIfNeeded()
        self.resetJSSDKIfNeeded()
        // preloadClear必须在所有的清理工作执行完毕之后再执行
        // 以保证清理之后又新预加载的对象内容的来源是已经重置过的文件
        self.clearPreloadCacheIfNeed()
    }
    
    public func containerDidDestroy(container: OPContainerProtocol) {
        logger.info("containerDidDestroy. uniqueID:\(containerContext.uniqueID)")
        if let plugin = BDPTimorClient.shared().lifeCyclePlugin.sharedPlugin() as? BDPLifeCyclePluginDelegate {
            logger.info("bdp_onDestroy. uniqueID:\(containerContext.uniqueID)")
            plugin.bdp_?(onDestroy: containerContext.uniqueID)
        }
        //BDPSubPackageManager，释放对应appId的 readers
        BDPAppPagePrefetchManager.shared()?.releasePrefetcher(with: containerContext.uniqueID)
        BDPSubPackageManager.shared().cleanFileReaders(with: containerContext.uniqueID)
        if(BDPPerformanceProfileManager.sharedInstance().profileEnable){
            BDPPerformanceProfileManager.sharedInstance().endConnection()
        }
        //内部有FG判断； 不应该直接写在这，但上面的生命周期监听 在EMA pod，下方代码在TT pod，依赖上不对，用不了
        BDPPerformanceProfileManager.sharedInstance().removePerformanceEntries(for: containerContext.uniqueID)

    }
    
    public func containerDidShow(container: OPContainerProtocol) {
        logger.info("containerDidShow. uniqueID:\(containerContext.uniqueID)")
        // 兼容旧的 BDPCommon 的状态(这里不一定能取到 Common, 因此还需要在 Common 加载完成时再设一遍)
        if let common = BDPCommonManager.shared()?.getCommonWith(containerContext.uniqueID) {
            common.isForeground = true
        } else {
            logger.warn("containerDidShow common is nil. uniqueID:\(containerContext.uniqueID)")
        }
        
        let startPage = self.router?.containerController.startPage?.absoluteString
        if let plugin = BDPTimorClient.shared().lifeCyclePlugin.sharedPlugin() as? BDPLifeCyclePluginDelegate {
            logger.info("bdp_onShow. uniqueID:\(containerContext.uniqueID)")
            plugin.bdp_?(onShow: containerContext.uniqueID, startPage:startPage)
        }
        
        if self.containerContext.containerConfig.enableAutoDestroy {
            // 停止自动释放逻辑
            logger.info("stopTimerToReleaseView. uniqueID:\(containerContext.uniqueID)")
            BDPWarmBootManager.shared()?.stopTimerToReleaseView(with: containerContext.uniqueID)
        }

        // 小程序成功加载，通知自动恢复框架埋点，统计恢复成功次数
        GadgetRecoveryMonitor.current.notifyGadgetRecoveryLoadSuccess(uniqueID: containerContext.uniqueID)
    }
    
    public func containerDidHide(container: OPContainerProtocol) {
        logger.info("containerDidHide. uniqueID:\(containerContext.uniqueID)")
        // 兼容旧的 BDPCommon 的状态
        if let common = BDPCommonManager.shared()?.getCommonWith(containerContext.uniqueID) {
            common.isForeground = false
        } else {
            logger.warn("containerDidHide common is nil. uniqueID:\(containerContext.uniqueID)")
        }
        
        if let plugin = BDPTimorClient.shared().lifeCyclePlugin.sharedPlugin() as? BDPLifeCyclePluginDelegate {
            logger.info("bdp_onHide. uniqueID:\(containerContext.uniqueID)")
            plugin.bdp_?(onHide: containerContext.uniqueID)
        }
        
        // 需要延迟判断，因为除了用户手势操作以外，主端还会有一些在特殊情况下快速将VC移除并添加回去的特殊操作
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            // 不在界面栈中(可能通过手势退出)
            if let containerController = self.router?.containerController,
               containerController.parent == nil {
                
                logger.info("containerDidHide vc.parent is nil. uniqueID:\(self.containerContext.uniqueID)")
                containerController.onApplicationExit(withRestoreStatus: true)
                // 这边发送事件告诉其他AppController需要处理界面方向
                if (OPSDKFeatureGating.fixGadgetOrientationByPreviewsGadgetGestureExit()) {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kGadgetContainerDidHideByGesture"), object: containerController.appController)
                }

                if self.containerContext.mountState == .mounted {
                    logger.info("containerDidHide onUnmount. uniqueID:\(self.containerContext.uniqueID)")
                    self.onUnmount(monitorCode: OPSDKMonitorCode.cancel)
                    ///原下方判断是否触发回收的代码 因为左滑返回后，containerContext.mountState 还未 unmount，所以不会走，因此补充执行该逻
                    if let task = BDPTaskManager.shared()?.getTaskWith(self.containerContext.uniqueID), true == task.context?.isJSContextThreadForceStopped() {
                        // 需要清理热缓存
                        logger.info("containerDidHide onDestroy. uniqueID:\(self.containerContext.uniqueID)")
                        self.onDestroy(monitorCode: GDMonitorCode.js_running_thread_force_stopped)
                    } else {
                        if self.containerContext.containerConfig.enableAutoDestroy {
                            logger.info("startTimerToReleaseView. uniqueID:\(self.containerContext.uniqueID)")
                            BDPWarmBootManager.shared()?.startTimerToReleaseView(with: self.containerContext.uniqueID)
                        }
                    }
                }

                if LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.detectblankafterswipe.enable") {
                    /// 通过手势退出，也进行白屏检测 （下方的白屏检测，因为当时containerContext.mountState 还未 unmount，所以不会走，因此补充执行该逻辑）
                    containerController.detectBlankWebview({ [weak self] (cleanWarmCache, error) in
                        guard self != nil else {
                            logger.error("swipe detect blank screen error self dealloc")
                            return
                        }
                        if let error = error {
                            logger.error("swipe detect blank screen error do nothing， error message: \(error.localizedDescription)")
                            return
                        }
                        logger.info("swipe detectBlankWebview: cleanWarmCache \(cleanWarmCache)")
                    })
                } else {
                    logger.info("swipe without detectBlankWebview")
                }
            }
        }
        
        
        if containerContext.isReloading {
            // 注意：reloading 状态不走 onDestory 检查流程
            logger.info("container hide during reloading")
        } else if containerContext.mountState == .unmount {
            // unmount 后需要开始尝试自动清理逻辑
            if let task = BDPTaskManager.shared()?.getTaskWith(containerContext.uniqueID), true == task.context?.isJSContextThreadForceStopped() {
                // 需要清理热缓存
                logger.info("containerDidHide onDestroy. uniqueID:\(containerContext.uniqueID)")
                onDestroy(monitorCode: GDMonitorCode.js_running_thread_force_stopped)
            } else {
                if self.containerContext.containerConfig.enableAutoDestroy {
                    logger.info("startTimerToReleaseView. uniqueID:\(containerContext.uniqueID)")
                    BDPWarmBootManager.shared()?.startTimerToReleaseView(with: containerContext.uniqueID)
                }
            }
            
            // 白屏检测，如果白屏则清理热缓存
            router?.containerController.detectBlankWebview({ [weak self] (cleanWarmCache, error) in
                guard let self = self else {
                    return
                }
                if let error = error {
                    logger.error("detect blank screen error do nothing， error message: \(error.localizedDescription)")
                    return
                }
                if cleanWarmCache {
                    // 需要清理热缓存
                    logger.info("containerDidHide onDestroy. uniqueID:\(self.containerContext.uniqueID)")
                    self.onDestroy(monitorCode: GDMonitorCode.blank_webview)
                }
            })
        }
    }
    
    public func containerDidPause(container: OPContainerProtocol) {
        // 兼容旧的 BDPCommon 的状态
        if let common = BDPCommonManager.shared()?.getCommonWith(containerContext.uniqueID) {
            common.isActive = false
        }
    }
    
    public func containerDidResume(container: OPContainerProtocol) {
        // 兼容旧的 BDPCommon 的状态
        if let common = BDPCommonManager.shared()?.getCommonWith(containerContext.uniqueID) {
            common.isActive = true
        }
    }
    
    public func containerConfigDidLoad(container: OPContainerProtocol, config: OPProjectConfig) {
        
    }
//}
//
//extension OPGadgetContainer {
    /// 尝试将小程序的加载页面变为带有可重试错误的提示页面
    /// - Parameter tipInfo: 提示信息
    /// - Returns: 是否成功变换加载页面
    func tryChangeLoadingViewToFailRefreshState(tipInfo: String) -> Bool {
        // 正常的push打开小程序的情况
        if let containerController = router?.containerController, currentRenderSlot is OPUniversalPushControllerRenderSlot  {
            containerController.updateLoadingViewWithRecoverableRefresh(info: tipInfo, uniqueID: containerContext.uniqueID)
            return true
        } else if let renderSlot = currentRenderSlot as? OPChildControllerRenderSlot {
            guard let failedViewUIDelegate = renderSlot.failedViewUIDelegate else {
                return false
            }
            failedViewUIDelegate.showFailedView(with: tipInfo, context: containerContext)
            return true
        }

        return false
    }
    
    /// 加载统一错误页，如果错误页面没有对应的挂载则不进行操作
    /// - Parameter errorStyle: 错误页面样式
    /// - Returns: 是否成功加载错误页面
    func tryChangeLoadingViewToUnifyErrorState(errorStyle:UnifyExceptionStyle) -> Bool {
        // 正常的push打开小程序的情况
        if let containerController = router?.containerController, currentRenderSlot is OPUniversalPushControllerRenderSlot  {
            containerController.makeLoadingViewUnifyErrotState(errorStyle: errorStyle, uniqueID: containerContext.uniqueID)
            return true
        } else if let renderSlot = currentRenderSlot as? OPChildControllerRenderSlot {
            guard let failedViewUIDelegate = renderSlot.failedViewUIDelegate else {
                return false
            }
            failedViewUIDelegate.showFailedView(with: errorStyle.content, context: containerContext)
            return true
        }

        return false
    }
}
