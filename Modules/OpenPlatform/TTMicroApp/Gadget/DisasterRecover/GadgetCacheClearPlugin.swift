//
//  GadgetCacheClearPlugin.swift
//  TTMicroApp
//
//  Created by justin on 2023/2/23.
//

import Foundation
import LKCommonsLogging
import LarkUIKit
import LarkFeatureGating
import UniverseDesignIcon
import OPSDK
import OPFoundation

private let logger = Logger.log(GadgetCacheClearPlugin.self, category: "GadgetMenu")

/// 小程序更多菜单中用于手动清除小程序缓存信息的按钮
public final class GadgetCacheClearPlugin: MenuPlugin {

    static var cacheclearMenuEnable: Bool {
        #if DEBUG
        return true
        #else
        return OPGadgetDRManager.shareManager.enableGadgetMenuDR()
        #endif
    }

    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext

    /// 从上下文中获取UniqueID的key
    private static let contextUniqueIDKey = "uniqueID"

    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        // 菜单插件按钮FG控制
        guard Self.cacheclearMenuEnable else {
            return nil
        }
        guard let appMenuContext = menuContext as? AppMenuContext else {
            logger.error("CacheClear plugin init failure because there is no appMenuContext")
            return nil
        }
        
        if appMenuContext.uniqueID.versionType == .preview  {
            logger.error("CacheClear plugin init failure because gadget versionType is preview")
            return nil
        }

        self.menuContext = appMenuContext
    }

    public static var pluginID: String {
        "GadgetCacheClearPlugin"
    }

    /// CacheClear的唯一标识符
    private let cacheclearIdentifier = "cacheclear"
    /// 插件的优先级，需要比关于菜单插件的优先级高
    private let cacheclearItemPriority: Float = 15

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
        let title = BDPI18n.openPlatform_CacheClear_Bttn ?? "Clear Cache"
        let image = UDIcon.getIconByKey(UDIconType.clearOutlined)
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let container = OPApplicationService.current.getContainer(uniuqeID: menuContext.uniqueID)
        let cacheClearMenuItem = MenuItemModel(
            title: title,
            imageModel: imageModle,
            itemIdentifier: cacheclearIdentifier,
            badgeNumber: badgeNumber,
            itemPriority: cacheclearItemPriority
        ) { [weak container, weak self] _ in
            guard container != nil else {
                logger.error("can not clear gadget cache because the contaienr does not exit or container has destroyed")
                return
            }
            
            // 产品埋点
            self?.itemActionReport(applicationID: self?.menuContext.uniqueID.appID, menuItemCode: .cacheClearButton)
            
            if let alertPlugin = BDPTimorClient.shared().alertPlugin.sharedPlugin() as? BDPAlertPluginDelegate {
                let appName = self?.getAppName()
                var content = BDPI18n.openPlatform_CacheClear_Dialog ?? "Clear cache, and exit \"{{app_name}}\"?"
                content = content.replacingOccurrences(of: "{{app_name}}", with: "\(appName ?? "")")
                
                let confirm = BDPI18n.determine ?? "OK"
                _ = alertPlugin.bdp_showAlert?(withTitle: "", content: content, confirm: confirm, from: nil, confirmCallback: {
                    OPGadgetDRManager.shareManager.menuCleanCacheForDR(self?.menuContext.uniqueID)
                }, showCancel: true)
            }
        }
        cacheClearMenuItem.menuItemCode = .cacheClearButton
        updater(cacheClearMenuItem)
    }
    
    
    /// 获取小程序appName
    /// - Returns: appName
    func getAppName() -> String {
        let uniqueID = self.menuContext.uniqueID
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            logger.error("CacheClearPlugin AppName is nil because common isn't exist")
            return ""
        }
        guard let model = OPUnsafeObject(common.model) else {
            logger.error("CacheClearPlugin AppName is nil because model isn't exist")
            return ""
        }
        
        guard let appName = OPUnsafeObject(model.name) else {
            logger.error("CacheClearPlugin AppName is nil because appName isn't exist")
            return ""
        }
        
        return appName
    }

}
