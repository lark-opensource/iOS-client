//
//  WeChatMomentsShareMenuPlugin.swift
//  Lark
//
//  Created by bytedance on 2021/3/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import LarkUIKit
import WebBrowser
import LKCommonsLogging
import LarkSnsShare
import LarkContainer
import ECOProbe
import LarkReleaseConfig
import LarkOpenPlatform
import EcosystemWeb
import OPSDK
import UniverseDesignIcon
/// 日志
private let logger = Logger.oplog(WeChatMomentsShareMenuPlugin.self, category: "WeChatShare")
final class WeChatMomentsShareMenuPlugin: MenuPlugin {
    static var pluginID: String {
        "WeChatMomentsShareMenuPlugin"
    }

    static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self]
    }

    /// 套件统一浏览器的菜单上下文
    private let menuContext: WebBrowserMenuContext

    private static let webWeChatShareIdentifier = "shareToWeChatMoments"

    private static let webWeChatSharePriority: Float = 400

    private static var shareId: String {
        return "lark.op.wx_timeline"
    }

    @InjectedLazy private var snsShareService: LarkShareService

    init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        if !LarkShareConfig.isShareSupport(type: .moments) {
            return nil
        }
        guard let webMenuContext = menuContext as? WebBrowserMenuContext else {
            return nil
        }
        if webMenuContext.isOfflineMode {
            return nil
        }
        guard webMenuContext.webBrowser?.isDownloadPreviewMode() == false else {
            logger.info("OPWDownload WeChatMomentsShareMenuPlugin init failure because download preview mode")
            return nil
        }
        if webMenuContext.webBrowser?.browserURL?.scheme == "blob" {
            logger.info("OPWDownload WeChatMomentsShareMenuPlugin init failure because blob url scheme")
            return nil
        }
        self.menuContext = webMenuContext
        MenuItemModel.webBindButtonID(menuItemIdentifer: Self.webWeChatShareIdentifier, buttonID: OPMenuItemMonitorCode.shareToWechatMomentButton.rawValue)
    }

    func pluginDidLoad(handler: MenuPluginOperationHandler) {
        guard menuContext.webBrowser?.newFailingURL == nil else { return }
        guard menuContext.webBrowser?.isDownloadPreviewMode() == false else { return }
        fetchMenuItemModel { handler.updateItemModels(for: [$0]) }
    }

    private func shareToWeChatMoments() {
        guard let webBrowser = self.menuContext.webBrowser else {
            logger.error("wechat moments share failed, webBrowser is nil")
            return
        }
        ShareH5Helper.share(service: snsShareService,
                            traceId: Self.shareId,
                            webBrowser: webBrowser) {
            logger.info("wechat moments share successed")
        } failedHandler: { (error) in
            logger.error("wechat moments share failed")
        }
        MenuItemModel.webReportClick(applicationID: webBrowser.appInfoForCurrentWebpage?.id, menuItemIdentifer: Self.webWeChatShareIdentifier)
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> Void) {
        let title = LarkOpenPlatform.BundleI18n.OpenPlatformShare.OpenPlatform_Share_WeChat_Moments
        let image = UDIcon.getIconByKey(UDIconType.wechatFriendColorful)
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image, renderMode: .alwaysOriginal)
        let action: MenuItemModel.MenuItemAction = { _ in
            OPMonitor(LarkShareConfig.mini_sharecard_moments_send)
                .addMetricValue("app_id", self.menuContext.webBrowser?.appInfoForCurrentWebpage?.id ?? "")
                .addMetricValue("share_type", "url")
                .setPlatform([.tea, .slardar])
                .flush()
            self.shareToWeChatMoments()
        }
        let shareMenuItem = MenuItemModel(title: title,
                                          imageModel: imageModle,
                                          itemIdentifier: Self.webWeChatShareIdentifier,
                                          badgeNumber: 0,
                                          itemPriority: Self.webWeChatSharePriority,
                                          action: action)
        updater(shareMenuItem)
    }

}
