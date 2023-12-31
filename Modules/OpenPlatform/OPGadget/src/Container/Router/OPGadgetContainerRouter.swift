//
//  OPGadgetContainerRouter.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/25.
//

import Foundation
import OPSDK
import TTMicroApp
import OPFoundation
import LarkFeatureGating
import LKCommonsLogging

fileprivate let logger = Logger.oplog(OPGadgetContainerRouter.self, category: "OPGadgetContainerRouter")

@objc protocol OPGadgetContainerRouterDelegate: AnyObject {
    
    func containerSizeDidChanged(old: CGSize, new: CGSize)
    
    func containerControllerDidAppear(viewController: UIViewController)
 
    func containerControllerDidDisappear(viewController: UIViewController)
    
    func containerControllerDidWarmLaunch(router: OPGadgetContainerRouterProtocol,
                                          task: BDPTask,
                                          common: BDPCommon)
}

@objc protocol OPGadgetContainerRouterProtocol: class, OPRouterProtocol {
    
    /// 当前的容器视图
    var containerController: OPGadgetContainerController { get }
    
    func navigateTo(parentNode: OPNodeProtocol, component: OPComponentProtocol, initData: OPComponentDataProtocol) throws
    
    func redirectTo(parentNode: OPNodeProtocol, component: OPComponentProtocol, initData: OPComponentDataProtocol) throws

    func switchTab(parentNode: OPNodeProtocol, component: OPComponentProtocol, initData: OPComponentDataProtocol) throws
    
    func navigateBack() throws
    
    func reLaunch(pageURL: String) throws
    
    func notifyCurrentPageAppLaunch()
    
    func notifyOnLoadApp(error: OPError?)
    
    func excuteWarmBoot(mountData: OPGadgetContainerMountDataProtocol)
}


@objcMembers class OPGadgetContainerRouter: NSObject, OPGadgetContainerRouterProtocol {
    
    private let containerContext: OPContainerContext
    
    var containerController: OPGadgetContainerController
    
    weak var delegate: OPGadgetContainerRouterDelegate?
    
    required init(containerContext: OPContainerContext) {
        self.containerContext = containerContext
        let launchParam = BDPTimorLaunchParam()
        
        do {
            let (url, _) = try OPGadgetSchemaAdapter.getSchema(containerContext: containerContext)
            launchParam.url = url
        } catch {
            // TODO: 日志+埋点
        }
        
        self.containerController = OPGadgetContainerController(launchParam: launchParam, containerContext: containerContext)
        
        super.init()
        
        self.containerController.delegate = self
    }
    
    func navigateTo(parentNode: OPNodeProtocol, component: OPComponentProtocol, initData: OPComponentDataProtocol) throws {
        
    }
    
    func redirectTo(parentNode: OPNodeProtocol, component: OPComponentProtocol, initData: OPComponentDataProtocol) throws {
        
    }
    
    func switchTab(parentNode: OPNodeProtocol, component: OPComponentProtocol, initData: OPComponentDataProtocol) throws {
        
    }
    
    func navigateBack() throws {
        
    }
    
    func reLaunch(pageURL: String) throws {
        containerController.appController?.routeManager?.reLaunch(pageURL)
    }
    
    func notifyCurrentPageAppLaunch() {
        // TODO: 这种字符串 onAppRoute 的调用方式需要优化
        
        // 这里因为时机问题，有概率导致 currentAppPageController 为空
        // 所以兜底放到下一个 runloop 再执行
        if let appPageCtrlr = currentAppPageController {
            appPageCtrlr.onAppRoute("appLaunch")
        } else {
            DispatchQueue.main.async {
                let monitor = OPMonitor(GDMonitorCodeLaunch.onapproute_downgrade)
                if let appPageCtrlr = self.currentAppPageController {
                    appPageCtrlr.onAppRoute("appLaunch")
                    monitor.setResultTypeSuccess()
                } else {
                    let opError = OPError.error(monitorCode: GDMonitorCodeLaunch.onapproute_downgrade_fail, message: "failed")
                    monitor.setResultTypeFail()
                        .setError(opError)
                }
                monitor.flush()
            }
        }
    }
    
    func notifyOnLoadApp(error: OPError?) {
        guard let appPage = currentAppPageController?.appPage else {
            return
        }
        
        let data = [
            "result": (error != nil) ? "fail" : "success",
            "errMsg": OPSafeObject(error?.monitorCode.message, "")
        ]
        
        // TODO: 这种 fireEvent 需要收敛到统一的 bridge 接口
        appPage.bdp_fireEvent("onLoadApp", sourceID: appPage.appPageID, data: data)
    }
    
    var currentComponent: OPComponentProtocol?
    
    func createComponent(fileReader: OPPackageReaderProtocol, containerContext: OPContainerContext) throws -> OPComponentProtocol {
        return OPGadgetComponent(fileReader: fileReader, context: containerContext)
    }
    
    func unload() {
        
        /*
         主导航小程序的内存回收单独管理，解决问题 https://meego.feishu.cn/larksuite/issue/detail/6896964?parentUrl=%2Flarksuite%2FissueView%2Fj1ZvyBxbrF
         被T出登陆，又重新验证登陆场景下，主导航小程序(第一个tab)被重新构建的时序为
         1.重新加载tabgadget控制器，重新构建小程序(已经使用新的用户数据，数据不会窜)
         2.主端将1中创建的控制器设置为首tab的控制器
         3.原来的首tab主导航小程序开始析构，被触发小程序onDestroy->unload->BDPWarmBootManager.cleanCache
         4.将正在构建的1的容器的属性开始销毁
         5.新的容器启动失败
         
         理论上，普通小程序也可能会有此问题，但是人工操作下难以触发
         此改动可能会有内存泄漏的风险，如新登陆的账号和老账号并不一致，没有重新构建相同uniqueID的小程序，那么common和task会被一直持有
         
         开启enableTabGadgetUpdate后,通过appid的主导航小程序的uniqueID会发生变化，可以参与普通内存管理
        */
        if !OPSDKFeatureGating.enableTabGadgetUpdate() && LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.fix_tab_gadget_load_fail") {
            if let scene = containerContext.firstMountData?.scene {
                if scene != .mainTab && scene != .convenientTab {
                    BDPWarmBootManager.shared()?.cleanCache(with: containerController.uniqueID)
                }
            }
        } else {
            BDPWarmBootManager.shared()?.cleanCache(with: containerController.uniqueID)
        }
    }
    
    func excuteWarmBoot(mountData: OPGadgetContainerMountDataProtocol) {
        
        // TODO: 补充日志
        
        let uniqueID = containerController.uniqueID
        
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID), let task = BDPTaskManager.shared()?.getTaskWith(uniqueID) else {
            return
        }
        
        common.isReaderOff = false // 阅读器修改回标志
        
        BDPWarmBootManager.shared()?.stopTimerToReleaseView(with: uniqueID)
        
        do {
            let (_, schema) = try OPGadgetSchemaAdapter.getSchema(containerContext: containerContext)
            updateSchema(schema: schema, common: common, task: task)
        } catch {
            // TODO: 日志，埋点
        }
        
        // TODO: 这里有问题，excuteWarmBoot并不代表一定在前台（重构）
        common.isForeground = true
        
        // 热启动fixStartPageIfNeed调用两次导致redirect重复问题修复，方案1在外部去除重复调用，方案2在fixStartPageIfNeed内部处理。优先下面的方案1
        let enableFixStartPageIssueFromEntry = LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.enable_fix_startpage_entry")
        // 打开开关则不调用fixStartPageIfNeed
        if !enableFixStartPageIssueFromEntry {
            OPGadgetLoadTask.fixStartPageIfNeed(warmLaunch: true, router: self, task: task, common: common)
        }
        
        // TODO: 这里有问题，excuteWarmBoot并不代表一定活跃（重构）
        common.isActive = true
        
        delegate?.containerControllerDidWarmLaunch(router: self, task: task, common: common)

        
        // reLaunch到startPage
        reLaunchStartPageIfNeed(task: task,mountData: mountData)
        
        // 经产品确认，只要带着start_page，启动后当前页面非首页，即需要展示"返回首页"
        if containerController.startPage != nil {
            containerController.appController?.routeManager?.showGoHomeButtonIfNeed()
        }

        containerController.appController?.layoutAnchorShareButton()
        
        // TODO: 搜索上报，似乎没什么用，删掉
        //            [self.searchReporter evnetWarmBootLoadDetail];
    }
}

extension OPGadgetContainerRouter: OPGadgetContainerControllerDelegate {
    
    func containerControllerDidAppear(viewController: UIViewController) {
        delegate?.containerControllerDidAppear(viewController: viewController)
    }
    
    func containerControllerDidDisappear(viewController: UIViewController) {
        delegate?.containerControllerDidDisappear(viewController: viewController)
    }
    
}

extension OPGadgetContainerRouter {
    
    private var currentAppPageController: BDPAppPageController? {
        return containerController.appController?.currentAppPage()
    }
    
    private func reLaunchStartPageIfNeed(task: BDPTask, mountData: OPGadgetContainerMountDataProtocol) {
        if let startPage = containerController.startPage, !startPage.isEqual(toPage: task.currentPage) {
            do {
                try reLaunch(pageURL: startPage.absoluteString)
            } catch {
                // TODO:
            }
        } else {
            // 仅当 path 不同时进入该逻辑
            if EMAFeatureGating.boolValue(forKey: "openplatform.gadget.relaunch") {
                // 这里去执行链接中relaunch参数的逻辑
                if let startPage = mountData.startPage, startPage.count > 0 && mountData.relaunchWhileLaunching {
                    if EMAFeatureGating.boolValue(forKey: "openplatform.gadget.relaunch.startpage.compat") {
                        do {
                            try reLaunch(pageURL: startPage)
                        } catch {
                            // TODO:
                            logger.error("applink reLaunch error accured \(startPage)")
                        }
                    } else {
                        if let config = task.config,config.containsPage(startPage) {
                            do {
                                try reLaunch(pageURL: startPage)
                            } catch {
                                // TODO:
                                logger.error("applink reLaunch error accured \(startPage)")
                            }
                        }
                    }
                }
            }
        }
        
        // TODO: 似乎对Lark没什么用的调用，放在这里位置也不对，待优化
        containerController.appController?.setupBottomBarIfNeed()

    }
    
    private func updateSchema(schema: BDPSchema, common: BDPCommon, task: BDPTask) {
        containerController.schema = schema
        common.schema = schema
        
        containerController.startPage = BDPAppPageURL(urlString: schema.startPage)
        containerController.sourceStartPage = containerController.startPage // 热启动 赋值原始startPage
        OPGadgetLoadTask.fixStartPageIfNeed(warmLaunch: true, router: self, task: task, common: common)
    }
    
}
