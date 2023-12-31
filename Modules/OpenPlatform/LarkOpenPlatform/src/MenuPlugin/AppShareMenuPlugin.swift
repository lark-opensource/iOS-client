//
//  AppShareMenuPlugin.swift
//  LarkOpenPlatform
//
//  Created by 刘洋 on 2021/3/11.
//

import TTMicroApp
import LarkUIKit
import LKCommonsLogging
import OPSDK
import OPFoundation
import ECOProbe
import UniverseDesignIcon
import LarkFeatureGating

/// 小程序分享的菜单插件
/// 核心逻辑代码code form:  刘相鑫
final class AppShareMenuPlugin: MenuPlugin {
    
    static let logger = Logger.log(AppShareMenuPlugin.self, category: "LarkOpenPlatform")
    
    @FeatureGating("openplatform.gadget.share_app_msg_apath.disable")
    var shareAppMsgAPathDisabled: Bool

    /// 小程序的菜单上下文
    private let menuContext: AppMenuContext

    /// 分享的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let shareIdentifier = "share"
    /// 插件的优先级
    private let shareItemPriority: Float = 90

    init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard let appMenuContext = menuContext as? AppMenuContext else {
            Self.logger.error("AppShareMenuPlugin:share plugin init failure because there is no AppMenuContext")
            return nil
        }

        self.menuContext = appMenuContext
    }

    static var pluginID: String {
        "AppShareMenuPlugin"
    }

    static var enableMenuContexts: [MenuContext.Type] {
        [AppMenuContext.self]
    }

    func pluginDidLoad(handler: MenuPluginOperationHandler) {
        fetchMenuItemModel{
            handler.updateItemModels(for: [$0])
        }
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        guard let _ = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }
        let title = BundleI18n.OpenPlatformShare.Lark_Legacy_Share
        let image = UDIcon.getIconByKey(UDIconType.shareOutlined)
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let shareMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.shareIdentifier, badgeNumber: badgeNumber, itemPriority: self.shareItemPriority) { [weak self] _ in
            Self.logger.warn("AppShareMenuPlugin:share click")
            self?.share()
        }
        shareMenuItem.menuItemCode = .shareButton
        updater(shareMenuItem)
    }

    /// 分享
    private func share() {
        guard let context = checkEnvironmentIsReady() else {
            // checkEnvironmentIsReady方法中已经打日志了
            return
        }

        let sharedManager = context.share
        let page = context.page
        var path = page.bap_path
        if !shareAppMsgAPathDisabled {
            path = page.bap_absolutePathString
        }

        var webViewUrlStr = ""
        for view in page.subviews {
            if let bdpViewComponent = view as? BDPWebViewComponent, !bdpViewComponent.isHidden {
                webViewUrlStr = bdpViewComponent.bwc_openInOuterBrowserURL.absoluteString
                break
            }
        }
        Self.logger.warn("share webViewUrlStr equal to empty string")
        var fireParams: [String: String] = [:]
        fireParams["path"] = BDPSafeString(path)
        fireParams["webViewUrl"] = BDPSafeString(webViewUrlStr)
        sharedManager.engine = context.engine
        sharedManager.shareChannelParams = fireParams

        sharedManager.setShareEntry(.toolBar)
        sharedManager.engine.bdp_fireEvent("onShareAppMessage", sourceID: NSNotFound, data: fireParams)
        Self.logger.info("share success")
        
        // 产品埋点：分享链路 https://bytedance.feishu.cn/sheets/shtcnxrXP8G9GjHbZ7qE9FGAG0b?sheet=196nOL
        self.itemActionReport(applicationID: context.engine.uniqueID.appID, menuItemCode: .shareButton)
    }

    /// 检查环境是否正确，是否显示分享
    /// - Returns: 分享所需要的必要信息
    private func checkEnvironmentIsReady() -> (page: BDPAppPage, share: BDPShareManager, engine: OPMicroAppJSRuntimeProtocol)? {
        guard BDPTimorClient.shared().sharePlugin.sharedPlugin() != nil else {
            Self.logger.error("share can't show because sharedPlugin isn't exist")
            return nil
        }
        guard let task = BDPTaskManager.shared()?.getTaskWith(menuContext.uniqueID) else {
            Self.logger.error("share can't show because task isn't exist")
            return nil
        }
        guard let currentPagePath = task.currentPage?.path else {
            Self.logger.error("share can't show because currentPagePath isn't exist")
            return nil
        }
        guard let pageConfig = task.config?.getPageConfig(byPath: currentPagePath) else {
            Self.logger.error("share can't show because pageConfig isn't exist")
            return nil
        }
        guard !pageConfig.isHideShareMenu else {
            Self.logger.error("share can't show because isHideShareMenu is true")
            return nil
        }
        guard let common = BDPCommonManager.shared()?.getCommonWith(menuContext.uniqueID) else {
            Self.logger.error("share can't show because common isn't exist")
            return nil
        }
        guard let model = OPUnsafeObject(common.model) else {
            Self.logger.error("share can't show because model isn't exist")
            return nil
        }
        guard model.shareLevel != .black else {
            Self.logger.error("share can't show because shareLevel is black")
            return nil
        }
        guard let engine = task.context else {
            Self.logger.error("share can't show because engine isn't exist")
            return nil
        }
        guard let currentPage = task.currentPage else {
            Self.logger.error("share can't show because currentPage isn't exist")
            return nil
        }
        guard let pageManager = task.pageManager else {
            Self.logger.error("share can't show because pageManager isn't exist")
            return nil
        }
        guard let sharedManager = BDPShareManager.shared() else {
            Self.logger.error("share can't show because sharedManager isn't exist")
            return nil
        }
        // 注意这里调用了OC的函数，不能相信它
        guard let appPage = OPUnsafeObject(pageManager.appPage(withPath: currentPage.path)) else {
            Self.logger.error("share can't show because appPage isn't exist")
            return nil
        }
        // 关于元组的奇怪的问题：元组中如果有一个参数声明为nonnull但实际是nil(因为来自了不可靠的OC代码)，将会导致其他的正常参数永远不被释放，从而导致内存泄漏
        return (appPage, sharedManager, engine)
    }
}
