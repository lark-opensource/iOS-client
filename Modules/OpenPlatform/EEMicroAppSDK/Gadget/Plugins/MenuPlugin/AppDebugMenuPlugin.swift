//
//  AppDebugMenuPlugin.swift
//  EEMicroAppSDK
//
//  Created by 刘洋 on 2021/3/12.
//
import TTMicroApp
import LarkUIKit
import LKCommonsLogging
import OPSDK

/// 日志
private let logger = Logger.log(AppDebugMenuPlugin.self, category: "EEMicroApp")

/// 小程序设置的菜单插件
/// 核心代码code from：CosWhy
final class AppDebugMenuPlugin: MenuPlugin {

    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext

    /// debug的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let debugIdentifier = "debug"
    /// 插件的优先级
    private let debugItemPriority: Float = 10

    /// 从持久化存储中读取是否正在debug
    private let vConsoleKey = "vConsole"

    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let appMenuContext = menuContext as? AppMenuContext else {
            logger.error("debug plugin init failure because there is no appMenuContext")
            return nil
        }

        self.menuContext = appMenuContext
    }

    public static var pluginID: String {
        "AppDebugMenuPlugin"
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
        guard let context = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        let title = (context.isDebug ? BDPI18n.debug_close : BDPI18n.debug_open) ?? ""
        let image = UIImage.bdp_imageNamed("icon_more_panel_debug") ?? UIImage()
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let larkDebugMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.debugIdentifier, badgeNumber: badgeNumber, itemPriority: self.debugItemPriority) { [weak self] _ in
            self?.openDebug()
        }
        larkDebugMenuItem.menuItemCode = .larkDebugButton
        updater(larkDebugMenuItem)
    }

    /// 打开Debug页面
    private func openDebug() {
        guard let context = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        let uniqueID = self.menuContext.uniqueID
        let monitor: OPMonitor
        if context.isDebug {
            monitor = OPMonitor(ShellMonitorEvent.mp_debug_close_click).setMonitorCode(ShellMonitorCode.mp_debug_close_success)
        } else {
            monitor = OPMonitor(ShellMonitorEvent.mp_debug_open_click).setMonitorCode(ShellMonitorCode.mp_debug_open_success)
        }
        monitor.setUniqueID(uniqueID)
            .setResultTypeSuccess()
            .flush()

        // 产品埋点
        self.itemActionReport(applicationID: uniqueID.appID, menuItemCode: .appDebugButton)

        context.privateStorage.setObject(!context.isDebug, forKey: vConsoleKey)

        logger.info("OPApplicationService debug is working for \(!context.isDebug)")
        OPApplicationService.current.getContainer(uniuqeID: uniqueID)?.destroy(monitorCode: GDMonitorCode.debug_switch_dismiss)
    }

    /// 检查环境是否正确，是否显示设置
    /// - Returns: 设置所需要的必要信息
    private func checkEnvironmentIsReady() -> (isDebug: Bool, privateStorage: TMAKVStorage, task: BDPTask)? {
        let uniqueID = self.menuContext.uniqueID
        guard BDPAppMetaUtils.metaIsDebugMode(for: uniqueID.versionType) else {
            logger.info("debug can't show because app versionType isn't current")
            return nil
        }
        guard let task = BDPTaskManager.shared()?.getTaskWith(uniqueID) else {
            logger.error("debug can't show because task isn't exist")
            return nil
        }
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            logger.error("debug can't show because common isn't exist")
            return nil
        }
        guard let sandbox = common.sandbox else {
            logger.error("debug can't show because sandbox isn't exist")
            return nil
        }
        guard let privateStorage = sandbox.privateStorage else {
            logger.error("debug can't show because privateStorage isn't exist")
            return nil
        }
        let isDebug: Bool
        if let shouldDebug = privateStorage.object(forKey: vConsoleKey) as? NSString {
            isDebug = shouldDebug.integerValue != 0
        } else if let shouldDebug = privateStorage.object(forKey: vConsoleKey) as? NSNumber {
            isDebug = shouldDebug.boolValue
        } else {
            isDebug = false
        }
        return (isDebug, privateStorage, task)
    }

}
