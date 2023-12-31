//
//  AppShortCutMenuPlugin.swift
//  EEMicroAppSDK
//
//  Created by XingJinhao on 2021/11/29.
//

import Foundation
import TTMicroApp
import Swinject
import LarkUIKit
import LKCommonsLogging
import OPSDK
import UniverseDesignIcon
import UIKit
import EEMicroAppSDK
import LarkAppConfig
import LarkSetting
import RustPB
import WebBrowser
import LarkFeatureGating
import ECOInfra
import UniverseDesignToast
import EENavigator
import LarkAccountInterface

private typealias OpenDomainSettings = InitSettingKey
/// 日志
private let logger = Logger.log(AppShortCutMenuPlugin.self, category: "LarkOpenPlatform")

/// 小程序添加到桌面快捷方式的菜单plugin
final class AppShortCutMenuPlugin: MenuPlugin {
    
    /// Swinject的对象
    private let resolver: Resolver

    /// 小程序的菜单上下文
    private let menuContext: MenuContext
    
    /// 从上下文中获取Resolver的key
    static let providerContextResloveKey = "resolver"
    
    /// plugin唯一标识
    private let shortCutIdentifier = "shortCut"
    
    /// 插件的优先级
    private let shortCutItemPriority: Float = 75
    
    public init?(menuContext: MenuContext, pluginContext: MenuPluginContext) {
        guard LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.add.shortcut.enable") else {// user:global
            logger.info("shortCut plugin init failure because FG is false")
            return nil
        }
        guard let resolver = pluginContext.parameters[AppShortCutMenuPlugin.providerContextResloveKey] as? Resolver else {
            logger.error("shortCut plugin init failure because there is no resolver")
            return nil
        }
        self.resolver = resolver
        self.menuContext = menuContext
        if !FeatureGatingManager.shared.featureGatingValue(with: "openplatfrom.web.add_link_to_desk") {// user:global
            /// 只对网页/小程序应用开启添加到桌面能力，不对普通网页开启
            logger.info("FG openplatfrom.web.add_link_to_desk is false")
            guard self.fetchUniqueID(from: menuContext) != nil else {
                logger.error("commonApp plugin init failure because there is no uniqueID")
                return nil
            }
        }
        MenuItemModel.webBindButtonID(menuItemIdentifer: shortCutIdentifier, buttonID: OPMenuItemMonitorCode.addDesktopButton.rawValue)
    }
    
    public static var pluginID: String {
        "AppShortCutMenuPlugin"
    }

    public static var enableMenuContexts: [MenuContext.Type] {
        [WebBrowserMenuContext.self, AppMenuContext.self]
    }

    public func pluginDidLoad(handler: MenuPluginOperationHandler) {
        self.fetchMenuItemModel(updater: {
            item in
            handler.updateItemModels(for: [item])
        })
    }

    /// 获取菜单数据模型
    /// - Parameter updater: 更新菜单选项的回调
    private func fetchMenuItemModel(updater: @escaping (MenuItemModelProtocol) -> ()) {
        if !FeatureGatingManager.shared.featureGatingValue(with: "openplatfrom.web.add_link_to_desk") {// user:global
            /// 只对网页/小程序应用开启添加到桌面能力，不对普通网页开启
            logger.info("FG openplatfrom.web.add_link_to_desk is false")
            guard let _ = checkEnvironmentIsReady() else {
                logger.error("fetch menuItemModel failure because there is no uniqueID")
                return
            }
        }
        let title = BundleI18n.OpenPlatformShare.OpenPlatform_AddAppHome_AddBttn
        let image = UDIcon.getIconByKey(UDIconType.cellphoneOutlined)
        let badgeNumber: UInt = 0
        let imageModle = MenuItemImageModel(normalForIPhonePanel: image, normalForIPadPopover: image)
        let shortCutMenuItem = MenuItemModel(title: title, imageModel: imageModle, itemIdentifier: self.shortCutIdentifier, badgeNumber: badgeNumber, itemPriority: self.shortCutItemPriority) { [weak self] _ in
            self?.addToDeskShortCut()
        }
        shortCutMenuItem.menuItemCode = .addDesktopButton
        updater(shortCutMenuItem)
    }
    
    private func fetchUniqueID(from menuContext: MenuContext) -> BDPUniqueID? {
        if let appMenuContext = menuContext as? AppMenuContext {
            let uniqueID = appMenuContext.uniqueID
            return uniqueID
        } else if let webMenuContext = menuContext as? WebBrowserMenuContext {
            guard let appID = webMenuContext.webBrowser?.appInfoForCurrentWebpage?.id, !appID.isEmpty else {
                logger.error("fetchUniqueID failure because there is no appID")
                return nil
            }
            let uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .webApp)
            return uniqueID
        } else {
            logger.error("fetchUniqueID failure because there is no AppMenuContext or WebBrowserMenuContext")
            return nil
        }
    }
    
    private func generateShortCutUrl(from uniqueID: BDPUniqueID) -> URL? {
        /// 从settings中获取跳转引导页url配置
        let settings = (try? resolver.resolve(assert: AppConfiguration.self))?.settings ?? [:]// user:global
        let configService: ECOConfigService = ECOConfig.service()
        guard let navBaseUrl = configService.getDictionaryValue(for: "gadget_shortcut_navigatorUrl")?["navigatorDomain"] as? String,
              let appLinkDomain = settings[OpenDomainSettings.mpApplink]?.first else {
            logger.error("can't add shortCut because component of url is nil")
            return nil
        }
        guard let appType = uniqueID.appType.toDeskShortCutName() else {
            logger.error("can't add shortCut because appType is not supported")
            return nil
        }
        let currentLanguage = NSLocale.current.languageIdentifier
        
        var navigatorUrl = URLComponents.init(string: navBaseUrl)
        navigatorUrl?.queryItems = [
            URLQueryItem(name: "appId", value: uniqueID.appID),
            URLQueryItem(name: "appType", value: appType),
            URLQueryItem(name: "lang", value: currentLanguage),
            URLQueryItem(name: "domain", value: appLinkDomain)
        ]
        
        return navigatorUrl?.url
    }
    
    private func generateWebShortCutUrl(from url: URL, with title: String?) -> URL? {
        /// 从settings中获取跳转引导页url配置
        let settings = (try? resolver.resolve(assert: AppConfiguration.self))?.settings ?? [:]// user:global
        let configService: ECOConfigService = ECOConfig.service()
        guard let navBaseUrl = configService.getDictionaryValue(for: "gadget_shortcut_navigatorUrl")?["navigatorDomain"] as? String,
              let appLinkDomain = settings[OpenDomainSettings.mpApplink]?.first else {
            logger.error("can't add shortCut because component of url is nil")
            return nil
        }
        guard let deviceId = (try? resolver.resolve(assert: DeviceService.self))?.deviceId, let targetUrl = url.append(name: "lk_target_did", value: deviceId) as URL? else {
            logger.error("can't add shortCut because component of url is nil")
            return nil
        }
        let appType = "web"
        let currentLanguage = NSLocale.current.languageIdentifier
        // 对url进行对称加密
        let key = "Lark"
        let iv = OPAES256Utils.getIV("Lark", backup: "Lark")
        let encodedUrl = OPAES256Utils.encrypt(withContent: targetUrl.absoluteString, key: key, iv: iv)
        logger.info("encodedUrl string:\(encodedUrl)")
        // 对title进行前15个字符的截取
        var titleBeginning = title ?? ""
        if titleBeginning.count > 15 {
            let index = titleBeginning.index(titleBeginning.startIndex, offsetBy: 15)
            titleBeginning = String(titleBeginning[..<index])
        }
        var navigatorUrl = URLComponents.init(string: navBaseUrl)
        navigatorUrl?.queryItems = [
            URLQueryItem(name: "lk_target_url_encode", value: encodedUrl),
            URLQueryItem(name: "title_encode", value: titleBeginning),
            URLQueryItem(name: "appType", value: appType),
            URLQueryItem(name: "lang", value: currentLanguage),
            URLQueryItem(name: "domain", value: appLinkDomain)
        ]
        
        return navigatorUrl?.url
    }
    
    private func getFirstUrl(of browser: WebBrowser?) -> URL? {
        if let backListFirst = browser?.webview.backForwardList.backList.first {
            return backListFirst.url
        }
        return browser?.webview.backForwardList.currentItem?.url
    }

    /// 将小程序/普通网页/网页应用添加到桌面快捷方式
    private func addToDeskShortCut() {
        if let webMenuContext = self.menuContext as? WebBrowserMenuContext {
            // 网页容器环境
            if webMenuContext.webBrowser?.addFirstLinkToDesk == true {
                // 添加容器首页配置开启
                logger.info("For this browser, add_fisrt_link_to_desk is true")
                if let appID = webMenuContext.webBrowser?.appInfoForFirstWebpage?.id, !appID.isEmpty {
                    // 容器鉴权缓存的首个appInfo存在，根据应用身份生成跳转引导页url
                    let uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .webApp)
                    guard let url = generateShortCutUrl(from: uniqueID) else {
                        showFailedToast()
                        logger.error("can't add shortCut because navigatorUrl of first auth is invalid")
                        return
                    }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    // 产品埋点
                    MenuItemModel.webReportClick(applicationID: uniqueID.appID, menuItemIdentifer: shortCutIdentifier)
                } else {
                    // 容器鉴权缓存记录不存在，根据容器首页url生成跳转引导页url
                    guard let firstUrl = getFirstUrl(of: webMenuContext.webBrowser) else {
                        showFailedToast()
                        logger.error("can't add shortCut because Url of first page is nil")
                        return
                    }
                    let firstTitle = ""
                    guard let url = generateWebShortCutUrl(from: firstUrl, with: firstTitle) else {
                        showFailedToast()
                        logger.error("can't add shortCut because navigatorUrl of first page is invalid")
                        return
                    }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    // 产品埋点
                    MenuItemModel.webReportClick(applicationID: nil, menuItemIdentifer: shortCutIdentifier)
                }
            } else {
                // 添加容器首页配置关闭
                logger.info("For this browser, add_fisrt_link_to_desk is false")
                if let uniqueID = checkEnvironmentIsReady() {
                    // 当前页面有应用身份，则根据应用身份生成跳转引导页url
                    guard let url = generateShortCutUrl(from: uniqueID) else {
                        showFailedToast()
                        logger.error("can't add shortCut because navigatorUrl is invalid")
                        return
                    }
                    // 添加到桌面插件点击埋点，此埋点仅能上报用户点击按钮的行为，无法判断是否成功添加到桌面
                    OPMonitor(ShellMonitorEvent.mp_add_desktop_icon_click)
                        .setUniqueID(uniqueID)
                        .addCategoryValue("trigger_by", "user")
                        .setMonitorCode(ShellMonitorCode.mp_add_desktop_icon_click)
                        .setResultTypeSuccess()
                        .flush()
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    // 产品埋点
                    MenuItemModel.webReportClick(applicationID: uniqueID.appID, menuItemIdentifer: shortCutIdentifier)
                } else {
                    // 当前页面为普通网页，则根据当前页面url生成跳转引导页url
                    guard let currentUrl = webMenuContext.webBrowser?.webview.url else {
                        showFailedToast()
                        logger.error("can't add shortCut because Url of current page is nil")
                        return
                    }
                    let currentTitle = webMenuContext.webBrowser?.webview.title
                    guard let url = generateWebShortCutUrl(from: currentUrl, with: currentTitle) else {
                        showFailedToast()
                        logger.error("can't add shortCut because navigatorUrl of current page is invalid")
                        return
                    }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    // 产品埋点
                    MenuItemModel.webReportClick(applicationID: nil, menuItemIdentifer: shortCutIdentifier)
                }
            }
        } else {
            // 小程序环境
            guard let uniqueID = checkEnvironmentIsReady() else {
                showFailedToast()
                logger.error("can't add shortCut because uniqueID is nil")
                return
            }
            guard let url = generateShortCutUrl(from: uniqueID) else {
                showFailedToast()
                logger.error("can't add shortCut because navigatorUrl is invalid")
                return
            }
            // 添加到桌面插件点击埋点，此埋点仅能上报用户点击按钮的行为，无法判断是否成功添加到桌面
            OPMonitor(ShellMonitorEvent.mp_add_desktop_icon_click)
                .setUniqueID(uniqueID)
                .addCategoryValue("trigger_by", "user")
                .setMonitorCode(ShellMonitorCode.mp_add_desktop_icon_click)
                .setResultTypeSuccess()
                .flush()
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            // 产品埋点
            self.itemActionReport(applicationID: uniqueID.appID, menuItemCode: .addDesktopButton)
        }
    }

    /// 检查环境是否正确，是否显示设置
    /// - Returns: 设置所需要的必要信息
    private func checkEnvironmentIsReady() -> BDPUniqueID? {
        guard let uniqueID = self.fetchUniqueID(from: self.menuContext) else {
            return nil
        }
        return uniqueID
    }

    /// 添加失败时显示toast
    private func showFailedToast() {
        let message = BundleI18n.OpenPlatformShare.OpenPlatform_AddAppHome_AddFailedToast
        let config = UDToastConfig(toastType: .error, text: message, operation: nil)
        guard let mainSceneWindow = Navigator.shared.mainSceneWindow else {// user:global
            return
        }
        UDToast.showToast(with: config, on: mainSceneWindow)
    }

}

extension OPAppType {
    fileprivate func toDeskShortCutName() -> String? {
        switch self {
        case .gadget:
            return "mini_program"
        case .webApp:
            return "web_app"
        case .block:
            assertionFailure("not supported appType")
        case .unknown:
            assertionFailure("not supported appType")
        case .widget:
            assertionFailure("not supported appType")
        default:
            assertionFailure("not supported appType")
        }
        return nil
    }
}
