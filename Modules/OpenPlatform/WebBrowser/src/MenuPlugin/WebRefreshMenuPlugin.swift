//
//  WebRefreshMenuPlugin.swift
//  WebBrowser
//
//  Created by 刘洋 on 2021/3/3.
//

import LarkSetting
import LarkUIKit
import LKCommonsLogging
import UniverseDesignIcon

/// 日志
private let logger = Logger.webBrowserLog(WebRefreshMenuPlugin.self, category: NSStringFromClass(WebRefreshMenuPlugin.self))

/// 刷新网页的菜单插件
/// 核心逻辑代码code form:  lichen
public final class WebRefreshMenuPlugin: MenuPlugin {

    /// 套件统一浏览器的菜单上下文
    private let menuContext: WebBrowserMenuContext
    /// 插件的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let refreshIdentifier = "refresh"
    /// 插件的优先级
    private let refreshItemPriority: Float = 40

    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else {
            logger.info("WebRefreshMenuPlugin init failure because there is no WebBrowserMenuContext")
            return nil
        }
        guard webMenuContext.webBrowser?.isDownloadPreviewMode() == false else {
            logger.info("OPWDownload WebRefreshMenuPlugin init failure because download preview mode")
            return nil
        }
        if webMenuContext.webBrowser?.browserURL?.scheme == "blob" {
            logger.info("OPWDownload WebRefreshMenuPlugin init failure because blob url scheme")
            return nil
        }
        self.menuContext = webMenuContext
        
        MenuItemModel.webBindButtonID(menuItemIdentifer: refreshIdentifier, buttonID: "2015")
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        guard menuContext.webBrowser?.isDownloadPreviewMode() == false else { return }
        fetchMenuItemModel{
            item in
            handler.updateItemModels(for: [item])
        }
    }

    public static var pluginID: String {
        "WebRefreshMenuPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self]
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        let title = BundleI18n.WebBrowser.Lark_Legacy_WebRefresh
        let image = UDIcon.refreshOutlined
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let refreshMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.refreshIdentifier, badgeNumber: badgeNumber, itemPriority: self.refreshItemPriority) {[weak self] _ in
            self?.refresh()
        }
        updater(refreshMenuItem)
    }

    /// 刷新网页
    private func refresh() {
        guard let browser = menuContext.webBrowser else {
            logger.error("refresh fail, menuContext.webBrowser is nil")
            return
        }
        browser.reload()
        MenuItemModel.webReportClick(applicationID: browser.currrentWebpageAppID(), menuItemIdentifer: refreshIdentifier)
    }
}
