//
//  WebSearchMenuPlugin.swift
//  WebBrowser
//
//  Created by zhaojingxin on 2023/10/27.
//

import LarkUIKit
import LKCommonsLogging
import UniverseDesignIcon
import LarkSetting

public final class WebSearchMenuPlugin: MenuPlugin {
    
    public static let menuIdentifier = "WebSearchIdentifier"
    
    private static let logger = Logger.webBrowserLog(WebSearchMenuPlugin.self, category: "WebSearchMenuPlugin")
    
    private let menuContext: WebBrowserMenuContext
    
    public static var pluginID: String {
        NSStringFromClass(WebSearchMenuPlugin.self)
    }
    
    public static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self]
    }
    
    private let menuPriority: Float
    
    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else {
            Self.logger.info("menuContext is not WebBrowserMenuContext")
            return nil
        }
        
        guard webMenuContext.webBrowser?.resolve(WebSearchExtensionItem.self) != nil else {
            Self.logger.info("web browser search disabled")
            return nil
        }
        
        do {
            let config = try SettingManager.shared.setting(with: .make(userKeyLiteral: "opWebSearchConfig"))
            menuPriority = config["menu_priority"] as? Float ?? 28
        } catch {
            menuPriority = 28
        }
        
        self.menuContext = webMenuContext
        MenuItemModel.webBindButtonID(menuItemIdentifer: Self.menuIdentifier, buttonID: "2027")
    }
    
    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        fetchMenuItemModel { item in
            handler.updateItemModels(for: [item])
        }
    }
    
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        let title = BundleI18n.WebBrowser.LittleApp_MoreFeat_FindOnPageBttn
        let image = UDIcon.lookupOutlined
        let imageModel = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let menuItem = MenuItemModel(title: title, imageModel: imageModel, itemIdentifier: Self.menuIdentifier, badgeNumber: 0, itemPriority: menuPriority) { [weak self] _ in
            guard let self, let webBrowser = self.menuContext.webBrowser,
            let searchExtensionItem = webBrowser.resolve(WebSearchExtensionItem.self) else {
                return
            }
            
            searchExtensionItem.enterSearch(.mouse)
            
            MenuItemModel.webReportClick(applicationID: webBrowser.currrentWebpageAppID(), menuItemIdentifer: Self.menuIdentifier)
        }
        updater(menuItem)
    }
}
