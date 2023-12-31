//
//  WebCopyLinkMenuPlugin.swift
//  WebBrowser
//
//  Created by 刘洋 on 2021/3/3.
//

import LarkSetting
import LarkUIKit
import LKCommonsLogging
import OPSDK
import UIKit
import UniverseDesignIcon
import UniverseDesignToast
import WebBrowser
import LarkEMM
import OPFoundation

/// 日志
private let logger = Logger.ecosystemWebLog(WebCopyLinkMenuPlugin.self, category: NSStringFromClass(WebCopyLinkMenuPlugin.self))

/// 复制网页链接的菜单插件
/// 核心逻辑代码code form:  lichen
public final class WebCopyLinkMenuPlugin: MenuPlugin {
    /// 套件统一浏览器的菜单上下文
    private let menuContext: WebBrowserMenuContext

    /// 复制网页链接插件的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let copyLinkIdentifier = "copyLink"
    /// 插件的优先级
    private let copyLinkItemPriority: Float = 50


    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else {
            logger.info("WebCopyLinkMenuPlugin plugin init failure because there is no WebBrowserMenuContext")
            return nil
        }
        if webMenuContext.isOfflineMode {
            return nil
        }
        if webMenuContext.webBrowser?.browserURL?.scheme == "blob" {
            logger.info("OPWDownload WebCopyLinkMenuPlugin init failure because blob url scheme")
            return nil
        }
        self.menuContext = webMenuContext
        MenuItemModel.webBindButtonID(menuItemIdentifer: copyLinkIdentifier, buttonID: OPMenuItemMonitorCode.copyLinkButton.rawValue)
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        fetchMenuItemModel{
            item in
            handler.updateItemModels(for: [item])
        }
    }

    public static var pluginID: String {
        "WebCopyLinkMenuPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self]
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        guard menuContext.webBrowser?.browserURL != nil else { return }
        let disable = self.menuContext.disabled(menuIdentifier: copyLinkIdentifier)
        let title = disable ? BundleI18n.EcosystemWeb.OpenPlatform_MoreAppFcns_UnableToCopyLink : BundleI18n.EcosystemWeb.Lark_Legacy_WebCopyUri
        let image = UDIcon.getIconByKey(UDIconType.linkCopyOutlined)
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let copyLinkMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.copyLinkIdentifier, badgeNumber: badgeNumber, disable: disable, itemPriority: self.copyLinkItemPriority) {[weak self] _ in
            self?.copyLink()
        }
        updater(copyLinkMenuItem)
    }

    /// 复制链接
    private func copyLink() {
            // 这个 commit 只是因为 URL 可能为 optional，并没有修改任何业务逻辑，功能咨询请咨询原作者
        if let webVC = self.menuContext.webBrowser, let url = webVC.browserURL?.absoluteString {
            logger.info("copyLink menu tapped")
            let config = PasteboardConfig(token: OPSensitivityEntryToken.webCopyLinkMenuPluginCopyLink.psdaToken)
            SCPasteboard.general(config).string = url
            var onView: UIView = webVC.webView
            // 若网页容器端内下载场景, 则Toast显示在容器视图上
            if webVC.isDownloadPreviewMode() {
                onView = webVC.view
            }
            UDToast.showSuccess(with: BundleI18n.EcosystemWeb.Lark_Legacy_JssdkCopySuccess, on: onView)
            MenuItemModel.webReportClick(applicationID: webVC.appInfoForCurrentWebpage?.id, menuItemIdentifer: copyLinkIdentifier)
        } else {
            logger.error("copyLink fail, webVC is nil")
        }
    }
}
