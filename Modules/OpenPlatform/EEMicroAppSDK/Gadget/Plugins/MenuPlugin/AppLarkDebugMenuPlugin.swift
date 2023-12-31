//
//  AppLarkDebugMenuPlugin.swift
//  EEMicroApp
//
//  Created by 刘洋 on 2021/3/12.
//

import TTMicroApp
import LarkUIKit
import LKCommonsLogging
import OPSDK

/// 日志
private let logger = Logger.log(AppLarkDebugMenuPlugin.self, category: "EEMicroApp")

/// 小程序设置的菜单插件
/// 核心代码code from：yiqingzheng
final class AppLarkDebugMenuPlugin: MenuPlugin {

    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext

    /// larkDebug的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let larkDebugIdentifier = "larkDebug"
    /// 插件的优先级
    private let larkDebugItemPriority: Float = 5

    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let appMenuContext = menuContext as? AppMenuContext else {
            logger.error("larkDebug plugin init failure because there is no appMenuContext")
            return nil
        }

        self.menuContext = appMenuContext
    }

    public static var pluginID: String {
        "AppLarkDebugMenuPlugin"
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
        var title = "Debug"
        if OPDebugFeatureGating.debugAvailable() {
            if OPDebugWindow.debugStarted(withWindow: context.window) {
                title = "关闭Debug"
            } else {
                title = "开启Debug"
            }
        }
        let image = UIImage.ema_imageNamed("icon_more_panel_engineer") ?? UIImage()
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let larkDebugMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.larkDebugIdentifier, badgeNumber: badgeNumber, itemPriority: self.larkDebugItemPriority) { [weak self] _ in
            self?.openLarkDebug()
        }
        larkDebugMenuItem.menuItemCode = .larkDebugButton
        updater(larkDebugMenuItem)
        
        // 测试多页Menu的代码
//        #if DEBUG
//        for index in 0..<20 {
//            addTestIcon(identifier: "Test\(index)", updater: updater)
//        }
//        #endif
    }
    
//    #if DEBUG
//    private func addTestIcon(identifier: String, updater: @escaping (MenuItemModelProtocol) -> ()) {
//        let image = UIImage.bdp_imageNamed("icon_more_panel_engineer") ?? UIImage()
//        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
//        let larkDebugMenuItem = MenuItemModel(
//            title: identifier,
//            imageModel: imageModle,
//            itemIdentifier: identifier,
//            badgeNumber: 0,
//            itemPriority: 0
//        ) { _ in
//
//        }
//        updater(larkDebugMenuItem)
//    }
//    #endif

    /// 打开LarkDebug页面
    private func openLarkDebug() {
        guard let context = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        
        // 产品埋点
        self.itemActionReport(applicationID: menuContext.uniqueID.appID, menuItemCode: .larkDebugButton)

        guard OPDebugFeatureGating.debugAvailable() else {
            logger.info("larkDebug open success with EMADebug model")
            OPNavigatorHelper.topmostNav(searchSubViews: false, window: context.window)?.pushViewController(EMADebugViewController(common: context.common), animated: true)
            return
        }
        if OPDebugWindow.debugStarted(withWindow: context.window) {
            logger.info("larkDebug close success with OPDebug model")
            OPDebugWindow.closeDebug(withWindow: context.window)
        } else {
            logger.info("larkDebug open success with OPDebug model")
            OPDebugWindow.startDebug(withWindow: context.window)
        }
    }

    /// 检查环境是否正确，是否显示设置
    /// - Returns: 设置所需要的必要信息
    private func checkEnvironmentIsReady() -> (common: BDPCommon, window: UIWindow)? {
        let uniqueID = self.menuContext.uniqueID
        guard let enable = EMADebugUtil.sharedInstance()?.enable, enable else {
            logger.info("larkDebug can't show because enable is false")
            return nil
        }
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            logger.error("larkDebug can't show because common isn't exist")
            return nil
        }
        guard let window = uniqueID.window else {
            logger.error("larkDebug can't show because window isn't exist")
            return nil
        }
        return (common, window)
    }

}
