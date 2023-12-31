//
//  GadgetReloadMenuPlugin.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import LarkUIKit
import OPSDK
import TTMicroApp
import LKCommonsLogging
import LarkFeatureGating
import UniverseDesignIcon
import OPFoundation

private let logger = Logger.log(GadgetReloadMenuPlugin.self, category: "GadgetMenu")

/// 小程序更多菜单中用于手动刷新小程序的按钮
public final class GadgetReloadMenuPlugin: MenuPlugin {

    /// 菜单插件使用应用受FG控制，预计4.6版本下线
    static let fgKey = "openplatform.gadget.menu_reload.enable"

    static var reloadMenuEnable: Bool {
        #if DEBUG
        return true
        #else
        return LarkFeatureGating.shared.getFeatureBoolValue(for: Self.fgKey)
        #endif
    }

    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext

    /// 从上下文中获取UniqueID的key
    private static let contextUniqueIDKey = "uniqueID"

    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        // 菜单插件按钮FG控制，预计4.6版本下线
        guard Self.reloadMenuEnable else {
            return nil
        }
        guard let appMenuContext = menuContext as? AppMenuContext else {
            logger.error("larkDebug plugin init failure because there is no appMenuContext")
            return nil
        }

        self.menuContext = appMenuContext
    }

    public static var pluginID: String {
        "GadgetReloadMenuPlugin"
    }

    /// gadgetReload的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let reloadIdentifier = "reload"
    /// 插件的优先级，需要比关于菜单插件的优先级高
    private let reloadItemPriority: Float = 25

    public func menuWillShow(handler: MenuPluginOperationHandler) {
        fetchMenuItemModel{
            handler.updateItemModels(for: [$0])
        }
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [AppMenuContext.self]
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        let title = BDPI18n.openPlatform_GadgetErr_ReEnterAppTtl ?? "reload application"
        let image = UDIcon.getIconByKey(UDIconType.refreshOutlined)
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let container = OPApplicationService.current.getContainer(uniuqeID: menuContext.uniqueID)
        let reloadMenuItem = MenuItemModel(
            title: title,
            imageModel: imageModle,
            itemIdentifier: reloadIdentifier,
            badgeNumber: badgeNumber,
            itemPriority: reloadItemPriority
        ) { [weak container, weak self] _ in
            guard let container = container else {
                logger.error("can not reload gadget because the contaienr does not exit or container has destroyed")
                return
            }

            // 产品埋点
            self?.itemActionReport(applicationID: self?.menuContext.uniqueID.appID, menuItemCode: .relaunchButton)

            container.containerContext.handleError(with: .error(monitorCode: GDMonitorCode.gadget_menu_reload), scene: .gadgetReloadManually)
        }
        reloadMenuItem.menuItemCode = .relaunchButton
        updater(reloadMenuItem)
    }

}
