//
//  WebShareMenuPlugin.swift
//  Lark
//
//  Created by 刘洋 on 2021/3/3.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//
// swiftlint:disable all
import LarkUIKit
import EENavigator
import Foundation
import LKCommonsLogging
import LarkContainer
import LarkFeatureGating
import LarkMessengerInterface
import LarkOPInterface
import RoundedHUD
import RxSwift
import Swinject
import WebBrowser
import LarkReleaseConfig
import WebKit
import LarkOpenPlatform
import ECOProbe
import EcosystemWeb
import OPSDK
import UniverseDesignIcon

/// 日志
private let logger = Logger.log(WebShareMenuPlugin.self, category: "LarkAppCenter")
/// 分享的菜单插件
/// 核心逻辑代码code form:  lichen
final class WebShareMenuPlugin: MenuPlugin {

    /// Swinject的对象
    private var resolver: Resolver
    /// 套件统一浏览器的菜单上下文
    private let menuContext: WebBrowserMenuContext

    /// 从上下文中获取Resolver的key
    static let providerContextResloveKey = "resolver"
    /// 分享的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let webAndWebAppShareIdentifier = "share"
    /// 插件的优先级
    private let webAndWebAppShareItemPriority: Float = 999

    init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let resolver = pluginContext.parameters[WebShareMenuPlugin.providerContextResloveKey] as? Resolver else {
            return nil
        }
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else {
            return nil
        }
        if webMenuContext.isOfflineMode {
            return nil
        }
        guard webMenuContext.webBrowser?.isDownloadPreviewMode() == false else {
            logger.info("OPWDownload WebShareMenuPlugin init failure because download preview mode")
            return nil
        }
        if webMenuContext.webBrowser?.browserURL?.scheme == "blob" {
            logger.info("OPWDownload WebShareMenuPlugin init failure because blob url scheme")
            return nil
        }
        self.resolver = resolver
        self.menuContext = webMenuContext
        MenuItemModel.webBindButtonID(menuItemIdentifer: webAndWebAppShareIdentifier, buttonID: OPMenuItemMonitorCode.shareButton.rawValue)
    }

    func pluginDidLoad(handler: MenuPluginOperationHandler) {
        guard menuContext.webBrowser?.newFailingURL == nil else { return }
        guard menuContext.webBrowser?.isDownloadPreviewMode() == false else { return }
        fetchMenuItemModel{
            item in
            handler.updateItemModels(for: [item])
        }
    }

    static var pluginID: String {
        "WebShareMenuPlugin"
    }

    static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self]
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        // menuContext.disabled中有fg,关闭后disable直接返回false，回退至线上逻辑
        let disable = self.menuContext.disabled(menuIdentifier: webAndWebAppShareIdentifier)
        let title = disable ? BundleI18n.LarkOpenPlatform.OpenPlatform_MoreAppFcns_UnableToFwd : LarkOpenPlatform.BundleI18n.OpenPlatformShare.OpenPlatform_Share_Chat
        let image = UDIcon.getIconByKey(UDIconType.forwardOutlined).ud.withTintColor(UIColor.ud.iconN1)
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let badgeNumber: UInt = 0
        let shareMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: webAndWebAppShareIdentifier, badgeNumber: badgeNumber, disable: disable, itemPriority: webAndWebAppShareItemPriority) {[weak self] _ in
            self?.openShare()
        }
        updater(shareMenuItem)
    }

    private func openShare() {
        guard let webBrowser = self.menuContext.webBrowser else {
            logger.info("when open share, not find webBorwser")
            let shareErrorEvent = OPMonitor("op_h5_share_result")
                .setMonitorCode(WAMonitorCodeRuntime.share_error)
                .setResultTypeFail()
            shareErrorEvent
                .setErrorMessage("OPWeb: appcenter share faild because vc is not OPWebViewController with url is nil")
                .flush()
            return
        }
        logger.info("[ShareH5]: start shareH5 from LarkWebViewController")

        OPMonitor("openplatform_web_container_menu_click")
            .addCategoryValue("application_id", webBrowser.appInfoForCurrentWebpage?.id ?? "none")
            .addCategoryValue("identify_status", webBrowser.isWebAppForCurrentWebpage ? "web_app": "web")
            .addCategoryValue("scene_type", "none")
            .addCategoryValue("solution_id", "none")
            .addCategoryValue("click", "button")
            .addCategoryValue("target", "none")
            .addCategoryValue("button_id", OPMenuItemMonitorCode.shareButton.rawValue)
            .setPlatform(.tea)
            .flush()
        ShareLegacy.shareH5(target: WebVCTarget(webVC: webBrowser))
    }
    
}
// swiftlint:enable all
