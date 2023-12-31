//
//  NormalWebAppLinkHandler.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/6/28.
//

import EENavigator
import LarkAppLinkSDK
import LarkNavigator
import LarkSetting
import LarkSplitViewController
import LarkUIKit
import LKCommonsLogging
import Swinject
import UniverseDesignToast
import WebBrowser
import ECOProbe
import ECOInfra
import LarkAccountInterface
import LarkOPInterface

//code from yinyuan.0 未进行任何逻辑修改，只是代码换了个位置
final class NormalWebAppLinkHandler {
    
    static let logger = Logger.ecosystemWebLog(NormalWebAppLinkHandler.self, category: "NormalWebAppLinkHandler")
    
    static func assemble(container: Container) {
        // AppLink 指定在应用内打开网页 https://bytedance.feishu.cn/docs/doccnlwjaY7h0KJC155Hq60wJrc#
        LarkAppLinkSDK.registerHandler(path: "/client/web_url/open", handler: {(applink: AppLink) in
            OPMonitor("applink_handler_start").setAppLink(applink).flush()
            NormalWebAppLinkHandler().handle(appLink: applink, container: container)
        })
    }
    
    /// 从Applink获取顶层View
    static func getHudContainerView(appLink: AppLink) -> UIView? {
        if let applinkContainer = appLink.context?.from()?.fromViewController?.view {
            return applinkContainer
        }
        if let topVCView = OPUserScope.userResolver().navigator.mainSceneWindow?.fromViewController?.view {
            return topVCView
        }
        if let window = OPUserScope.userResolver().navigator.mainSceneWindow {
            return window
        }
        return nil
    }
    
    /// 提示错误信息
    static func showFailureHud(tips: String, on: UIView?) {
        if let view = on {
            UDToast.showFailure(with: tips, on: view)
        } else {
            Self.logger.error("show \(tips) failed because no top view")
        }
    }

    func handle(appLink: AppLink, container: Container) {
        let hudContainerView = Self.getHudContainerView(appLink: appLink)

        guard let components = URLComponents(url: appLink.url, resolvingAgainstBaseURL: false) else {
            // applink 不合法，内部异常
            Self.logger.error("applink.url invalid: \(appLink.url)")
            Self.showFailureHud(tips: BundleI18n.EcosystemWeb.Lark_Legacy_UnknownErr, on: hudContainerView)
            return
        }

        let urlKeyName = "url"                  // url 参数名
        let encodeUrlKeyName = "lk_target_url_encode" // 加密后的 url 参数名
        let validSchemes = ["http", "https"]    // 合法的 scheme

        var urlStr = ""
        if let urlItem = components.queryItems?.first(where: { (item) -> Bool in
            item.name == urlKeyName
        }) {
            urlStr = urlItem.value ?? ""
        } else {
            // 没有 URL 参数
            guard FeatureGatingManager.shared.featureGatingValue(with: "openplatfrom.web.add_link_to_desk") else {// user:global
                Self.logger.info("FG openplatfrom.web.add_link_to_desk is false")
                Self.logger.error("The following parameters are missing in the link: \(urlKeyName). applink.url: \(appLink.url)")
                let text = BundleI18n.EcosystemWeb.Lark_OpenPlatform_ParamMissingMsg(urlKeyName)
                Self.showFailureHud(tips: text, on: hudContainerView)
                return
            }
                    
            guard let urlItem = components.queryItems?.first(where: { (item) -> Bool in
                item.name == encodeUrlKeyName
            }), let urlEncodeStr = urlItem.value else {
                // 没有 lk_target_url_encode 参数，解析失败
                Self.logger.error("The following parameters are missing in the link: \(urlKeyName)， \(encodeUrlKeyName). applink.url: \(appLink.url)")
                let text = BundleI18n.EcosystemWeb.Lark_OpenPlatform_ParamMissingMsg(urlKeyName) + "; " + BundleI18n.EcosystemWeb.Lark_OpenPlatform_ParamMissingMsg(encodeUrlKeyName)
                Self.showFailureHud(tips: text, on: hudContainerView)
                return
            }
            // 有 lk_target_url_encode 参数，对其进行对称解密
            let key = "Lark"
            let iv = OPAES256Utils.getIV("Lark", backup: "Lark")
            let currentDid = try? container.resolve(assert: DeviceService.self).deviceId
            Self.logger.info("encodedUrl string:\(urlEncodeStr)")
            urlStr = OPAES256Utils.decrypt(withContent: urlEncodeStr, key: key, iv: iv)
            if urlStr.contains("lk_target_did"),
               let url = URL(string: urlStr),
               let targetDid = url.queryParameters["lk_target_did"],
               currentDid == targetDid {
                let targetUrl = url.remove(name: "lk_target_did")
                urlStr = targetUrl.absoluteString
            } else {
                // URL 不合法
                Self.logger.error("url is invalid. applink.url: \(appLink.url), currentdid:\(String(describing: currentDid))")
                let text = BundleI18n.EcosystemWeb.OpenPlatform_Share_ParamWrongMsg(urlKeyName)
                Self.showFailureHud(tips: text, on: hudContainerView)
                return
            }
        }
        
        guard let url = URL(string: urlStr),
              let scheme = url.scheme,
              validSchemes.contains(scheme.lowercased()) else {
            // URL 不合法
            Self.logger.error("url is invalid. applink.url: \(appLink.url)")
            let text = BundleI18n.EcosystemWeb.OpenPlatform_Share_ParamWrongMsg(urlKeyName)
            Self.showFailureHud(tips: text, on: hudContainerView)
            return
        }

        guard let appLinkService = try? container.resolve(assert: AppLinkService.self) else {
            // 内部异常
            Self.logger.error("AppLinkService not found. applink.url: \(appLink.url)")
            let text = BundleI18n.EcosystemWeb.Lark_Legacy_UnknownErr
            Self.showFailureHud(tips: text, on: hudContainerView)
            return
        }

        guard !appLinkService.isAppLink(url) else {
            // 不支持嵌套打开 AppLink
            Self.logger.error("param url should not be a applink, applink.url: \(appLink.url)")
            let text = BundleI18n.EcosystemWeb.OpenPlatform_Share_ParamWrongMsg(urlKeyName)
            Self.showFailureHud(tips: text, on: hudContainerView)
            return
        }
        guard let from = appLink.context?.from() else {
            Self.logger.error("appLink.context?.from() is nil, applink.url: \(appLink.url)")
            return
        }
        
        OPMonitor("applink_handler_success").setAppLink(appLink).flush()
    
        var bodyUrl = url
        //仅在半屏模式FG打开情况下，有半屏参数mode=panel才去处理
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.applink.open_web_app_with_panel.enable")) {// user:global
            let modeKeyName = "mode"
            let panelStyleKeyName = "panel_style"
            if let modeValue = components.queryItems?.first(where: { $0.name == modeKeyName })?.value {
                if modeValue == "panel" {
                    bodyUrl = bodyUrl.append(name: modeKeyName, value: modeValue, forceNew: false)
                    Self.logger.info("bodyUrl append \(modeKeyName): \(modeValue)")
                    //如果有panel_style参数
                    if let panelStyleValue = components.queryItems?.first(where: { $0.name == panelStyleKeyName })?.value {
                        bodyUrl = bodyUrl.append(name: panelStyleKeyName, value: panelStyleValue, forceNew: false)
                        Self.logger.info("bodyUrl append \(panelStyleKeyName): \(panelStyleValue)")
                    }
                }
            }
        }
        
        let appLinkContext = appLink.context ?? [:]
        if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.weburlopen.supportdoc.disable")) {
            //处理用web_url/open协议打开云文档的场景
            if let dependency = try? container.resolve(assert: OpenPlatformService.self), dependency.canOpenDocs(url: bodyUrl.absoluteString) {
                if Display.pad, let from = appLinkContext["from"] as? String, WebBrowserFromScene(rawValue: from) == .feed, let openType = appLinkContext[ContextKeys.openType] as? EENavigator.OpenType, openType == .showDetail, let fromVC = appLinkContext.from()?.fromViewController as? UIViewController {
                    OPUserScope.userResolver().navigator.showDetailOrPush(bodyUrl, context:appLinkContext, wrap: LkNavigationController.self, from: fromVC)
                } else {
                    OPUserScope.userResolver().navigator.push(bodyUrl, context:appLinkContext, from: from)
                }
                Self.logger.info("retriveRealUrl Doc url: \(bodyUrl)")
                return
            }
        }
        
        var body = WebBody(url: bodyUrl)
        if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.popupopen.disable")) {// user:global
            //解析lk_animation_mode&lk_navigation_mode
            if let lkAnimationModeValue = components.queryItems?.first(where: { $0.name == "lk_animation_mode" })?.value {
                body.lkAnimationMode = lkAnimationModeValue
            }
            if let lkNavigationMode = components.queryItems?.first(where: { $0.name == "lk_navigation_mode" })?.value {
                body.lkNavigationMode = lkNavigationMode
            }
        }
        
        body.fromScene = .web_url_applink
        body.appLinkFrom = appLink.from.rawValue ?? ""
        body.appLinkTrackId = appLink.traceId
        if Display.pad, let fromVC = appLink.context?.from()?.fromViewController, fromVC is DefaultDetailVC {
            OPUserScope.userResolver().navigator.showDetailOrPush(body: body, context:appLinkContext, wrap: LkNavigationController.self, from: fromVC)
        } else {
            //支持网页进Feed需求iPad场景处理
            if Display.pad, let from = appLinkContext["from"] as? String, WebBrowserFromScene(rawValue: from) == .feed, let fromVC = appLinkContext.from()?.fromViewController as? UIViewController {
                OPUserScope.userResolver().navigator.showDetailOrPush(body: body, context:appLinkContext, wrap: LkNavigationController.self, from: fromVC)
            } else {
                OPUserScope.userResolver().navigator.push(body: body, context:appLinkContext, from: from)
    //            Navigator.shared.push(body: body, from: from)
            }
        }
    }
}

