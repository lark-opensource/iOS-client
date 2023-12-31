//
//  AppHomeMenuPlugin.swift
//  EEMicroApp
//
//  Created by 刘洋 on 2021/3/12.
//

import TTMicroApp
import LarkUIKit
import LKCommonsLogging
import OPSDK
import ECOInfra
import UniverseDesignIcon

/// 日志
private let logger = Logger.log(AppHomeMenuPlugin.self, category: "EEMicroApp")

/// 小程序返回主页的菜单插件
/// 核心逻辑代码code form:  CosWhy
final class AppHomeMenuPlugin: MenuPlugin {

    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext
    
    /// 主页的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let homeIdentifier = "goHome"
    /// 插件的优先级
    private let homeItemPriority: Float = 50

    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let appMenuContext = menuContext as? AppMenuContext else {
            logger.error("home plugin init failure because there is no appMenuContext")
            return nil
        }

        self.menuContext = appMenuContext
    }

    public static var pluginID: String {
        "AppHomeMenuPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [AppMenuContext.self]
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        fetchMenuItemModel{
            handler.updateItemModels(for: [$0])
        }
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        guard let _ = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        let title = BDPI18n.back_home ?? ""
        let image = UDIcon.getIconByKey(UDIconType.homeOutlined)
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let homeMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.homeIdentifier, badgeNumber: badgeNumber, itemPriority: self.homeItemPriority) { [weak self] _ in
            self?.backHome()
        }
        homeMenuItem.menuItemCode = .gohomeButton
        updater(homeMenuItem)
    }

    /// 返回主页
    private func backHome() {
        guard let context = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        let uniqueID = self.menuContext.uniqueID
        OPMonitor(ShellMonitorEvent.mp_home_btn_click)
            .setUniqueID(uniqueID)
            .setMonitorCode(ShellMonitorCode.back_home_success)
            .setResultTypeSuccess()
            .flush()

        // 产品埋点
        self.itemActionReport(applicationID: uniqueID.appID, menuItemCode: .gohomeButton)

        logger.info("home success open")
        context.routeManager.goHome()
        context.task.showGoHomeButton = false
    }

    /// 检查环境是否正确，是否显示设置
    /// - Returns: 返回主页所需要的必要信息
    private func checkEnvironmentIsReady() -> (task: BDPTask, routeManager: BDPAppRouteManager)? {
        let uniqueID = self.menuContext.uniqueID
        guard let task = BDPTaskManager.shared()?.getTaskWith(uniqueID) else {
            logger.error("home can't show because task isn't exist")
            return nil
        }
        guard task.showGoHomeButton else {
            logger.error("home can't show because showGoHomeButton is failure")
            return nil
        }
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            logger.error("home can't show because common isn't exist")
            return nil
        }
        guard let model = OPUnsafeObject(common.model) else {
            logger.error("home can't show because model isn't exist")
            return nil
        }
        guard BDPIsEmptyString(model.webURL) else {
            logger.error("home can't show because this is h5")
            return nil
        }
        guard let containerVC = task.containerVC as? BDPAppContainerController else {
            logger.error("home can't show because containerVC isn't exist")
            return nil
        }
        guard let appController = containerVC.appController else {
            logger.error("home can't show because appController isn't exist")
            return nil
        }
        guard let routeManager = appController.routeManager else {
            logger.error("home can't show because routeManager isn't exist")
            return nil
        }
        return (task, routeManager)
    }

}
