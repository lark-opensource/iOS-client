//
//  AppMenuCompactHeaderPlugin.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/3/15.
//

import LarkUIKit
import LKCommonsLogging

/// 日志
private let logger = Logger.log(AppMenuCompactHeaderPlugin.self, category: "TTMicroApp")

@objc
/// 小程序菜单头部插件，现在用于ipad设备
public final class AppMenuCompactHeaderPlugin: NSObject, MenuPlugin {

    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext

    /// 菜单的操作句柄，不应该强持有
    private weak var menuHandler: MenuPluginOperationHandler?

    /// 权限视图，需要抢持有，因为它会有时候从界面消失
    private var header: AppMenuCompactAdditionView?
    
    public required init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let appMenuContext = menuContext as? AppMenuContext else {
            logger.error("AppMenuCompactHeaderPlugin plugin init failure because there is no AppMenuContext")
            return nil
        }
        guard Display.pad else {
            logger.error("AppMenuCompactHeaderPlugin plugin init failure because there isn't ipad")
            return nil
        }

        self.menuContext = appMenuContext
    }

    @objc
    public static var pluginID: String {
        "AppMenuCompactHeaderPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [AppMenuContext.self]
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        self.menuHandler = handler
        fetchMenuCompactAdditionView()
    }

    public func menuDidHide() {
        // 及时释放UIView
        self.header = nil
    }

    /// 获取菜单附加视图
    private func fetchMenuCompactAdditionView() {
        guard let _ = self.checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        let header = AppMenuCompactAdditionView()
        header.delegate = self
        header.privacyActionDelegate = self
        self.header = header
        header.startNotifier()
    }

    /// 检查环境是否正确，是否显示设置
    /// - Returns: 反馈所需要的必要信息
    private func checkEnvironmentIsReady() -> (subNavi: BDPNavigationController, auth: BDPAuthorization)? {
        let uniqueID = self.menuContext.uniqueID
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            logger.error("AppMenuCompactHeaderPlugin can't show/work because common isn't exist")
            return nil
        }
        guard let task = BDPTaskManager.shared()?.getTaskWith(uniqueID) else {
            logger.error("AppMenuCompactHeaderPlugin can't show/work because task isn't exist")
            return nil
        }
        guard let containerVC = task.containerVC as? BDPBaseContainerController else {
            logger.error("AppMenuCompactHeaderPlugin can't show/work because containerVC isn't exist")
            return nil
        }
        guard let subNavi = containerVC.subNavi else {
            logger.error("AppMenuCompactHeaderPlugin can't show/work because subNavi isn't exist")
            return nil
        }
        guard let auth = common.auth else {
            logger.error("AppMenuCompactHeaderPlugin can't show/work because auth isn't exist")
            return nil
        }
        return (subNavi, auth)
    }

}

extension AppMenuCompactHeaderPlugin: AlternateAnimatorDelegate {
    public func animationWillStart(for view: UIView) {
        guard let handler = self.menuHandler, let header = self.header else {
            return
        }
        let additionView = MenuAdditionView(customView: header)
        handler.updatePanelFooter(for: additionView)
    }

    public func animationDidEnd(for view: UIView) {
        guard let handler = self.menuHandler, let _ = self.header else {
            return
        }
        handler.updatePanelFooter(for: nil)
    }

    public func animationDidAddSubView(for targetView: UIView, subview: UIView) {
        guard let handler = self.menuHandler, let header = self.header else {
            return
        }
        subview.snp.makeConstraints{
            make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        let additionView = MenuAdditionView(customView: header)
        handler.updatePanelFooter(for: additionView)
    }

    public func animationDidRemoveSubView(for targetView: UIView, subview: UIView) {
        guard let handler = self.menuHandler, let header = self.header else {
            return
        }
        let additionView = MenuAdditionView(customView: header)
        handler.updatePanelFooter(for: additionView)
    }
}

extension AppMenuCompactHeaderPlugin: AppMenuPrivacyDelegate {
    public func action(for type: BDPMorePanelPrivacyType) {
        guard let handler = self.menuHandler else {
            logger.error("AppMenuCompactHeaderPlugin can't action because handler isn't exist")
            return
        }
        guard let context = self.checkEnvironmentIsReady() else {
            logger.error("AppMenuCompactHeaderPlugin can't action because context isn't exist")
            return
        }
        handler.hide(animation: true) {
            switch type {
            case .location, .microphone:
                context.subNavi.pushViewController(BDPPermissionController(authProvider: context.auth), animated: true)
            default:
                break
            }
        }
    }
}
