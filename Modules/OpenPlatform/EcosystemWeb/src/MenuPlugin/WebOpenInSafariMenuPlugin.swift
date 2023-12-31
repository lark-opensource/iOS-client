//
//  WebOpenInSafariMenuPlugin.swift
//  WebBrowser
//
//  Created by 刘洋 on 2021/3/3.
//

import LarkSetting
import LarkUIKit
import LKCommonsLogging
import OPSDK
import UniverseDesignIcon
import WebBrowser
import UniverseDesignToast
import LarkCache

/// 日志
private let logger = Logger.ecosystemWebLog(WebOpenInSafariMenuPlugin.self, category: NSStringFromClass(WebOpenInSafariMenuPlugin.self))

/// 打开Safari的菜单插件
/// 核心逻辑代码code form:  lichen
public final class WebOpenInSafariMenuPlugin: MenuPlugin {
    /// 套件统一浏览器的菜单上下文
    private let menuContext: WebBrowserMenuContext
    /// 插件唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let openInSafariIdentifier = "openInSafari"
    /// 插件的优先级
    private let openInSafariItemPriority: Float = 30

    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else {
            logger.info("WebOpenInSafariMenuPlugin init failure because there is no WebBrowserMenuContext")
            return nil
        }
        if webMenuContext.isOfflineMode {
            return nil
        }
        if webMenuContext.webBrowser?.browserURL?.scheme == "blob" {
            logger.info("OPWDownload WebOpenInSafariMenuPlugin init failure because blob url scheme")
            return nil
        }
        self.menuContext = webMenuContext
        MenuItemModel.webBindButtonID(menuItemIdentifer: openInSafariIdentifier, buttonID: OPMenuItemMonitorCode.openBrowserButton.rawValue)
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        fetchMenuItemModel{
            item in
            handler.updateItemModels(for: [item])
        }
    }

    public static var pluginID: String {
        "WebOpenInSafariMenuPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self]
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        guard let url = menuContext.webBrowser?.browserURL?.absoluteString else { return }
        let disable = self.menuContext.disabled(menuIdentifier: openInSafariIdentifier)
        let title = disable ? BundleI18n.EcosystemWeb.OpenPlatform_MoreAppFcns_UnableToOpenInBr : BundleI18n.EcosystemWeb.Lark_Legacy_WebBrowseOpen
        let image = UDIcon.browserMacOutlined
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let openInSafariMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.openInSafariIdentifier, badgeNumber: badgeNumber, disable: disable, itemPriority: self.openInSafariItemPriority) {[weak self] _ in
            if let view = self?.menuContext.webBrowser?.view,
               self?.menuContext.webBrowser?.isDownloadPreviewMode() == true,
               FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.download.file_cipher.enable")),// user:global
               LarkCache.isCryptoEnable() {
                UDToast.showFailure(with: BundleI18n.EcosystemWeb.Mail_FileCantShareOrOpenViaThirdPartyApp_Toast, on: view)
            } else {
            self?.openInSafari()
            }
        }
        updater(openInSafariMenuItem)
    }

    /// 打开Safari
    private func openInSafari() {
        if let webVC = self.menuContext.webBrowser {
            if let url = webVC.browserURL {
            // code from yinyuan.0
            UIApplication.shared.open(url) { (result) in
                logger.info("open in safari result is \(result)")
            }
            } else {
                logger.error("open in safari fail, url is nil")
            }
            MenuItemModel.webReportClick(applicationID: webVC.appInfoForCurrentWebpage?.id, menuItemIdentifer: openInSafariIdentifier)
        } else {
            logger.error("open in safari fail, webVC is nil")
        }
    }
}

