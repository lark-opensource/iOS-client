//
//  AppAboutMenuPlugin.swift
//  LarkOpenPlatform
//
//  Created by 刘洋 on 2021/3/2.
//

import LarkUIKit
import EENavigator
import LarkMessengerInterface
import LarkOPInterface
import EEMicroAppSDK
import OPSDK
import LKCommonsLogging
import TTMicroApp
import WebBrowser
import EcosystemWeb
import UniverseDesignIcon
import LarkSetting

/// 日志
private let logger = Logger.log(AppAboutMenuPlugin.self, category: "LarkOpenPlatform")

/// 关于的菜单插件
/// 网页应用核心代码code form:  wangxiaohua
/// 小程序核心代码code form：yinyuan.0
final class AppAboutMenuPlugin: MenuPlugin {
    /// 菜单上下文
    private let menuContext: MenuContext

    /// 关于插件的唯一标识符，注意也需要在SetupLarkBadgeTask文件中的BadgeImpl结构体中做相应的注册，因为这是LarkBadge组件必要的步骤，否则会直接导致crash
    private let aboutItemIdentifier = "about"
    /// 插件的优先级
    private let aboutItemPriority: Float = 20

    init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        self.menuContext = menuContext
        /// 在这里要校验是否可以获取uniqueID，这个是这个插件能初始化的必要条件
        guard self.fetchUniqueIDAndAppVersion(from: menuContext).uniqueID != nil else {
            logger.error("AppAboutMenuPlugin init failure because there is no uniqueID")
            return nil
        }
        MenuItemModel.webBindButtonID(menuItemIdentifer: aboutItemIdentifier, buttonID: OPMenuItemMonitorCode.aboutButton.rawValue)
    }

    /// 根据菜单上下文获取uniqueID和appVersion
    /// - Parameter menuContext: 菜单上下文
    /// - Returns: uniqueID和appVersion
    private func fetchUniqueIDAndAppVersion(from menuContext: MenuContext) -> (uniqueID: OPAppUniqueID?, appVersion: String?) {
        if let appMenuContext = menuContext as? AppMenuContext {
            let uniqueID = appMenuContext.uniqueID
            if let common = BDPCommonManager.shared()?.getCommonWith(uniqueID),
               let model = OPUnsafeObject(common.model),
               let appVersion = model.version {
                return (uniqueID, appVersion)
            } else {
                // 如果没有版本号，那么就使用空字符串,因为老逻辑是这个样子
                return (uniqueID, "")
            }
        } else if let webMenuContext = menuContext as? WebBrowserMenuContext {
            guard let appID = webMenuContext.webBrowser?.appInfoForCurrentWebpage?.id, !appID.isEmpty else {
                logger.error("fetchUniqueIDAndAppVersion failure because there is no appID")
                return (nil, nil)
            }
            let uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .webApp)
            return (uniqueID, nil)
        } else {
            logger.error("fetchUniqueIDAndAppVersion failure because there is no AppMenuContext or WebBrowserMenuContext")
            return (nil, nil)
        }
    }

    func pluginDidLoad(handler: MenuPluginOperationHandler) {
        self.fetchMenuItemModel(updater: {
            item in
            handler.updateItemModels(for: [item])
        })
    }

    static var pluginID: String {
        "AppAboutMenuPlugin"
    }

    static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self, AppMenuContext.self]
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        let title = BundleI18n.About.Lark_AppCenter_H5AboutPageName
        let image = UDIcon.getIconByKey(UDIconType.infoOutlined)
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let aboutMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.aboutItemIdentifier, badgeNumber: badgeNumber, itemPriority: self.aboutItemPriority) { [weak self] _ in
            self?.openAbout()
        }
        aboutMenuItem.menuItemCode = .aboutButton
        updater(aboutMenuItem)
    }

    // 打开关于
    private func openAbout() {
        var appSettingBody: AppSettingBody?
        let uniqueIDAndAppVersion = self.fetchUniqueIDAndAppVersion(from: self.menuContext)
        guard let uniqueID = uniqueIDAndAppVersion.uniqueID else {
            logger.error("about can't open because there is no uniqueID")
            return
        }
        let appID = uniqueID.appID
        if uniqueID.appType == .webApp {
            appSettingBody = AppSettingBody(appId: appID, scene: .H5)
            MenuItemModel.webReportClick(applicationID: appID, menuItemIdentifer: aboutItemIdentifier)
        } else if uniqueID.appType == .gadget {
            // 如果是小程序使用关于，那么需要设置好app版本号
            guard let appVersion = uniqueIDAndAppVersion.appVersion else {
                logger.error("about can't open because there is no appVersion")
                return
            }
            let params = [
                "version": appVersion
            ]
            appSettingBody = AppSettingBody(
                appId: appID,
                params: params,
                scene: .MiniApp
            )

            // 产品埋点
            self.itemActionReport(applicationID: appID, menuItemCode: .aboutButton)
        } else {
            logger.error("about can't open in \(uniqueID.appType)")
        }
        guard let body = appSettingBody else {
            logger.error("about can't open because there is no appSettingBody")
            return
        }
        let navigator = OPUserScope.userResolver().navigator
        let temporaryMenuPush = OPUserScope.userResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.temporary.menu.push"))
        if temporaryMenuPush {
            if let webMenuContext = menuContext as? WebBrowserMenuContext, let from = webMenuContext.webBrowser {
                navigator.push(body: body, from: from)
            } else if let fromVC = OPNavigatorHelper.topMostVC(window: uniqueID.window) ?? navigator.mainSceneWindow?.fromViewController {
                logger.info("about page is pushed")
                navigator.push(body: body, from: fromVC)
            } else {
                logger.error("about page can not push vc because no fromViewController")
            }
        } else {
            if let webMenuContext = menuContext as? WebBrowserMenuContext, let from = webMenuContext.webBrowser {
                navigator.push(body: body, from: from)
            }
            if let fromVC = OPNavigatorHelper.topMostVC(window: uniqueID.window) ?? navigator.mainSceneWindow?.fromViewController {
                logger.info("about page is pushed")
                navigator.push(body: body, from: fromVC)
            } else {
                logger.error("about page can not push vc because no fromViewController")
            }
        }
        
    }
}

