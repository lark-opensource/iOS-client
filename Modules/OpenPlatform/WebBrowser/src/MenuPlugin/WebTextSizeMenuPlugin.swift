//
//  WebTextSizeMenuPlugin.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/6/8.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import LarkSetting
import UniverseDesignIcon
import LarkGuide
import LarkStorage

public final class WebTextSizeMenuPlugin: MenuPlugin {
    private static let logger = Logger.webBrowserLog(WebTextSizeMenuPlugin.self, category: "WebTextSizeMenuPlugin")
    private static let textSizeBadgeKey = "op_webbrowser_textsize_badge"
    
    private let menuContext: WebBrowserMenuContext
    
    /// 插件唯一标识符, 还需要在SetupLarkBadgeTask文件中的BadgeImpl结构体注册, 否则会导致Crash
    private let textSizeId = "WebTextSize"
    
    private let textSizePriority: Float = 5
    
    private let kvStore: KVStore = {
        return KVStores.in(space: .global, domain: Domain.biz.webApp).udkv()
    }()
    
    public static let featureEnabled: Bool = {
        if Display.pad {
            return false
        }
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.moremenu.text_size.enable"))// user:global
    }()
    
    public static var pluginID: String {
        NSStringFromClass(WebTextSizeMenuPlugin.self)
    }
    
    public static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self]
    }
    
    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard Self.featureEnabled else {
            Self.logger.info("[WebTextSize] WebTextSizeMenuPlugin init failure because fg is false or pad device")
            return nil
        }
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else {
            Self.logger.info("[WebTextSize] WebTextSizeMenuPlugin init failure because there was no WebBrowserMenuContext")
            return nil
        }
        guard webMenuContext.webBrowser?.isDownloadPreviewMode() == false else {
            Self.logger.info("[WebTextSize] OPWDownload WebTextSizeMenuPlugin init failure because download preview mode")
            return nil
        }
        self.menuContext = webMenuContext
        MenuItemModel.webBindButtonID(menuItemIdentifer: textSizeId, buttonID: "2025")
    }
    
    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        guard menuContext.webBrowser?.isDownloadPreviewMode() == false else {
            return
        }
        fetchMenuItemModel { item in
            handler.updateItemModels(for: [item])
        }
    }
    
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        let title = BundleI18n.WebBrowser.OpenPlatform_WebAppSettings_ChangeFontSize
        let image = UDIcon.textAaOutlined
        let imageModel = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let number: UInt = showTextSizeBadge() ? 1 : 0
        let menuItem = MenuItemModel(title: title, imageModel: imageModel, itemIdentifier: textSizeId, badgeNumber: number, itemPriority: textSizePriority) { [weak self] _ in
            guard let self = self else { return }
            self.showTextSizePanel()
            self.didShowedTextSizeBadge()
        }
        updater(menuItem)
    }
    
    private func didShowedTextSizeBadge() {
        kvStore.set(true, forKey: Self.textSizeBadgeKey)
    }
    
    private func showTextSizeBadge() -> Bool {
        return !kvStore.bool(forKey: Self.textSizeBadgeKey)
    }
    
    private func showTextSizePanel() {
        guard let browser = menuContext.webBrowser else {
            return
        }
        let controller = WebTextSizeController(from: browser)
        controller.showPanel(animated: true)
    }
}
