//
//  AppSettingMenuPlugin.swift
//  EEMicroApp
//
//  Created by 刘洋 on 2021/3/12.
//

import TTMicroApp
import LarkUIKit
import LKCommonsLogging
import OPSDK
import UniverseDesignIcon

/// 日志
private let logger = Logger.log(AppSettingMenuPlugin.self, category: "EEMicroApp")

/// 小程序设置的菜单插件
/// 核心代码code from： houziyou
final class AppSettingMenuPlugin: MenuPlugin {

    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext

    /// 设置的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let settingIdentifier = "setting"
    /// 插件的优先级
    private let settingItemPriority: Float = 40

    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let appMenuContext = menuContext as? AppMenuContext else {
            logger.error("setting plugin init failure because there is no appMenuContext")
            return nil
        }

        self.menuContext = appMenuContext
    }
    
    public static var pluginID: String {
        "AppSettingMenuPlugin"
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
        let title = BDPI18n.settings ?? ""
        let image = UDIcon.getIconByKey(UDIconType.settingOutlined)
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let settingsMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.settingIdentifier, badgeNumber: badgeNumber, itemPriority: self.settingItemPriority) { [weak self] _ in
            self?.openSetting()
        }
        updater(settingsMenuItem)
    }

    /// 打开设置页面
    private func openSetting() {
        guard let context = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        let uniqueID = self.menuContext.uniqueID
        OPMonitor(ShellMonitorEvent.mp_settings_btn_click)
            .setUniqueID(uniqueID)
            .setMonitorCode(ShellMonitorCode.open_settings_success)
            .setResultTypeSuccess()
            .flush()
        logger.info("setting success open")
        context.subNavi.pushViewController(BDPPermissionController(authProvider: context.auth), animated: true)
    }

    /// 检查环境是否正确，是否显示设置
    /// - Returns: 设置所需要的必要信息
    private func checkEnvironmentIsReady() -> (subNavi: BDPNavigationController, auth: BDPAuthorization)? {
        #if !DEBUG
        logger.info("setting can't show because release environment")
        return nil
        #endif
        let uniqueID = self.menuContext.uniqueID
        guard EMASandBoxHelper.gadgetDebug() else {
            logger.error("setting can't show because you haven't debug access")
            return nil
        }
        guard let task = BDPTaskManager.shared()?.getTaskWith(uniqueID) else {
            logger.error("setting can't show because task isn't exist")
            return nil
        }
        guard let containerVC = task.containerVC as? BDPBaseContainerController else {
            logger.error("setting can't show because containerVC isn't exist")
            return nil
        }
        guard let subNavi = containerVC.subNavi else {
            logger.error("setting can't show because subNavi isn't exist")
            return nil
        }
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            logger.error("setting can't show because common isn't exist")
            return nil
        }
        guard let auth = common.auth else {
            logger.error("setting can't show because auth isn't exist")
            return nil
        }
        return (subNavi, auth)
    }

}
