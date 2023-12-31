//
//  OPDebugWindowGadgetController.swift
//  OPSDK
//
//  Created by 尹清正 on 2021/2/3.
//

import UIKit
import OPGadget
import LarkOPInterface
import LKCommonsLogging
import OPSDK

fileprivate let logger = Logger.oplog(OPDebugWindowGadgetController.self, category: "OPDebugWindowGadgetController")

/// 用于承载Debugger调试小程序运行的ViewController
class OPDebugWindowGadgetController: UIViewController {

    /// 存储当前正在运行的小程序的container
    public private(set) weak var container: OPContainerProtocol?

    /// 监听小程序是否拥有回退能力的变化
    private var canGoBackObservation: NSKeyValueObservation?
    /// 用于存储控制小程序pages的navigationController
    private weak var gadgetPageNavigator: UINavigationController?

    override func viewDidLoad() {
        setupDebuggerGadget()
    }

    /// 将Debugger小程序加载运行进该Controller
    private func setupDebuggerGadget() {
        // 获取调试小程序的uniqueID
        guard let debuggerAppID = EMAAppEngine.current()?.onlineConfig?.debuggerAppID() else {
            logger.error("Can not get debuggerAppID from the only config data of currentAppEngine")
            return
        }
        let uniqueID = OPAppUniqueID(appID: debuggerAppID, identifier: debuggerAppID, versionType: .current, appType: .gadget, instanceID: "\(hashValue)")
        // 获取appID对应的Application应用
        let application = OPApplicationService.current.getApplication(appID: uniqueID.appID) ?? OPApplicationService.current.createApplication(appID: uniqueID.appID)
        // 获取uniqueID对应的Container容器
        let container = application.getContainer(uniqueID: uniqueID) ?? application.createContainer(
            uniqueID: uniqueID,
            containerConfig: OPGadgetContainerConfig(previewToken: nil, enableAutoDestroy: false)
        )
        // 创建renderSlot
        let renderSlot = OPChildControllerRenderSlot(parentViewController: self, defaultHidden: false)
        renderSlot.delegate = self
        // 监听小程序容器的生命周期
        container.addLifeCycleDelegate(delegate: self)
        // 挂载数据到container之上，开始加载小程序
        container.mount(
            data: OPGadgetContainerMountData(scene: .micro_app, startPage: "pages/index/index",relaunchWhileLaunching: false),
            renderSlot: renderSlot)
        // 临时保存当前的运行的小程序容器
        self.container = container
    }

    /// 调用该方法使小程序页面回退
    @objc func pageGoBack() {
        gadgetPageNavigator?.popViewController(animated: true)
    }
}

// MARK: - OPRenderSlotDelegate

extension OPDebugWindowGadgetController: OPRenderSlotDelegate {
    public func onRenderAttatched(renderSlot: OPRenderSlotProtocol) {

    }

    public func onRenderRemoved(renderSlot: OPRenderSlotProtocol) {

    }

    public func currentViewControllerForPresent() -> UIViewController? {
        return self
    }

    public func currentNavigationControllerForPush() -> UINavigationController? {
        return self.navigationController
    }
}

// MARK: - OPContainerLifeCycleDelegate

extension OPDebugWindowGadgetController: OPContainerLifeCycleDelegate {

    public func containerDidLoad(container: OPContainerProtocol) {

    }

    public func containerDidReady(container: OPContainerProtocol) {
        /// container ready之后查找用于控制小程序pages的navigationController
        for childVC in children {
            if let container = childVC as? BDPAppContainerController {
                gadgetPageNavigator = container.appController?.currentAppPage()?.navigationController
            }
        }
        /// 借助task的能力，来监听小程序页面的变化，从而可以在合适的时机添加或者清除导航控制器左上角的返回按钮
        let task = BDPTaskManager.shared()?.getTaskWith(container.containerContext.uniqueID)
        canGoBackObservation = task?.observe(\.currentPage, changeHandler: { [weak self] (task, change) in
            let canGoBack = (self?.gadgetPageNavigator?.viewControllers.count ?? 0) > 1
            self?.parent?.navigationItem.leftBarButtonItem = canGoBack
                ? .init(title: "返回", style: .plain, target: self, action: #selector(self?.pageGoBack))
                : nil
        })
    }

    public func containerDidFail(container: OPContainerProtocol, error: OPError) {
        // 在加载调试小程序容器时如果发生错误(大概率是因为session过期或没有调试小程序的访问权限)，对调试方案进行降级
        OPDebugFeatureGating.downgrade = true
        // 并且在出现问题时及时关闭不能正常运行的调试窗口
        OPDebugWindow.closeDebug(withWindow: self.view.window)
    }

    public func containerDidUnload(container: OPContainerProtocol) {
        OPDebugWindow.closeDebug(withWindow: self.view.window)
    }

    public func containerDidDestroy(container: OPContainerProtocol) {
        OPDebugWindow.closeDebug(withWindow: self.view.window)
    }

    public func containerDidShow(container: OPContainerProtocol) {

    }

    public func containerDidHide(container: OPContainerProtocol) {
        OPDebugWindow.closeDebug(withWindow: self.view.window)
    }

    public func containerDidPause(container: OPContainerProtocol) {

    }

    public func containerDidResume(container: OPContainerProtocol) {
        
    }

    func containerConfigDidLoad(container: OPSDK.OPContainerProtocol, config: OPSDK.OPProjectConfig) {

    }
}
