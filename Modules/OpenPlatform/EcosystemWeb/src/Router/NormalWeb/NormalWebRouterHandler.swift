//
//  NormalWebRouterHandler.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/6/28.
//

import CookieManager
import ECOInfra
import ECOProbe
import EENavigator
import LarkAccountInterface
import LarkUIKit
import LKCommonsLogging
import SuiteAppConfig
import Swinject
import WebBrowser
import AnimatedTabBar
import LarkSetting
import LarkNavigator
import LarkWebViewContainer
import LarkAppLinkSDK
import LarkOPInterface
import LarkQuickLaunchBar
import LarkQuickLaunchInterface
import LarkTab
import LarkTraitCollection

final class NormalWebRouterHandler: UserTypedRouterHandler {
    
    static let logger = Logger.ecosystemWebLog(NormalWebRouterHandler.self, category: "NormalWebRouterHandler")
    
    func handle(_ body: WebBody, req: Request, res: Response) {
        var bodyUrl = body.url
        
        //监控埋点参数配置，如果命中了H5AppLink再次router策略，并且context有新值才会被覆盖
        var fromScene = body.fromScene?.rawValue
        var applink_trace_id = body.appLinkTrackId
        var applink_from = body.appLinkFrom
        var webAppInfo = body.webAppInfo
        
        let enabledDisableUniteRouter = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.router.context.diableuniterouter"))// user:global
        var notUseUniteRoute = body.notUseUniteRoute
        if enabledDisableUniteRouter {
            if req.context["notUseUniteRoute"] != nil {
                // context 主动设置notUseUniteRoute策略
                notUseUniteRoute = req.context["notUseUniteRoute"] as? Bool ?? false
            }
        }
        
        var fromSceneInContext = WebBrowserFromScene.normal
        if let lkWebFrom = req.context["lk_web_from"] as? String, lkWebFrom == "webbrowser" {
            fromSceneInContext = WebBrowserFromScene.web
        } else if let launcherFrom = req.context["launcher_from"] as? String, !launcherFrom.isEmpty{
            var launcherFromDetail = "normal"
            switch launcherFrom {
            case "main":
                launcherFromDetail = "launcherFromMain"
            case "quick":
                launcherFromDetail = "launcherFromQuick"
            case "temporary":
                launcherFromDetail = "launcherFromTemporary"
            default:
                break
            }
            fromSceneInContext = resolveFromSceneWithContext(from: launcherFromDetail)
        } else {
            fromSceneInContext = resolveFromSceneWithContext(from: req.context["from"] as? String)
        }
        
        let fromSceneInContextReport = WebBrowserFromSceneReport.build(context: req.context)
        
        let fromMode = req.context["lk_web_mode"] as? String ?? ""
        
        if !FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.applink.routeragain.disable")) {// user:global
            if let from = (req.context["fromScene"] as? H5AppFromScene) {
                fromScene = from.rawValue
            }
            if let trackId = req.context["appLinkTrackId"]  {
                applink_trace_id = trackId as? String
            }
            if let applinkF = req.context["appLinkFrom"]  {
                applink_from = applinkF as? String
            }
            
            if let webInfo = req.context["webAppInfo"]  {
                webAppInfo = webInfo as? WebAppInfo
            }
        }
        if LarkWebSettings.lkwEncryptLogEnabel {
            var logContext = req.context
            logContext.removeValue(forKey: ContextKeys.body) // 打log时过滤body，body信息在初始化的时候已经脱敏打印了,不需要重复打印
            let contextString = String(describing: logContext)
            Self.logger.info("NormalWebRouterHandler recieve handle, body.url: \(bodyUrl.safeURLString), appid: \(String(describing: webAppInfo?.id)), name:\(String(describing: webAppInfo?.name)), context:\(contextString)")
        } else {
            let contextString = String(describing: req.context)
            Self.logger.info("NormalWebRouterHandler recieve handle, body.url: \(bodyUrl.safeURLString), appid: \(webAppInfo?.id), name:\(webAppInfo?.name), context:\(contextString)")
        }
        
        let params = bodyUrl.lf.queryDictionary
        let panelConfig = PanelBrowserConfig(params: params)
        var fromAppOutSide = false //是否App外部唤起
        if let appLinkFrom = applink_from, let applinkFromType = AppLinkFrom(rawValue: appLinkFrom) {
            fromAppOutSide = (applinkFromType == .app)
        }
        
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        let isLandscape = statusBarOrientation == .landscapeLeft || statusBarOrientation == .landscapeRight //是否横屏
        let enablePanel = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.applink.open_web_app_with_panel.enable"))// user:global
        //全屏(默认)效果
        var isPopUpAnimation = false
        var isNavLeftClose = false
        if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.popupopen.disable")) {
            if let lkAnimationMode = body.lkAnimationMode {
                isPopUpAnimation = lkAnimationMode == "1"
            }
            if let lkNavigationMode = body.lkNavigationMode {
                isNavLeftClose = isPopUpAnimation && lkNavigationMode == "1"
            }
        }
        let ipadPopUpFixEnable = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.ipad.popup.fix.enable"))// user:global
        
        //非ipad && 非横屏 && 非外部唤起 && 开关开 && 参数合法，才可以使用半屏，否则全屏。
        let useLarkWebPanel = !Display.pad &&
                              !isLandscape &&
                              !fromAppOutSide &&
                              enablePanel &&
                              panelConfig.usePanel()
        let bizType: LarkWebViewBizType = useLarkWebPanel == true ? .larkWebPanel : .larkWeb
        var isCollapsed: Bool = false
        if let trait = req.from.fromViewController?.rootWindow()?.traitCollection , let size = req.from.fromViewController?.rootWindow()?.bounds.size {
            let newtrait =  TraitCollectionKit.customTraitCollection(trait, size)
            isCollapsed = newtrait.horizontalSizeClass == .compact
        }
        
        var scene: WebBrowserScene = .normal
        if(useLarkWebPanel) {
            //update
            scene = WebBrowserScene.panel
        } else  if let myAIQuickLaunchbarService = try? resolver.resolve(assert: LarkOpenPlatformMyAIService.self), myAIQuickLaunchbarService.isTemporaryEnabled(), Display.pad, !isCollapsed {
            let workplaceTemporaryTabEnable = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.workplace.temporary.enable"))
            
            let handleShowTemporaryEnable = !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.handle.showtemporary.disable"))
            if handleShowTemporaryEnable, let showTemporary = req.context["showTemporary"] as? Bool {
                //context包含showTemporary有值的处理
                scene = showTemporary == true ? .temporaryTab : .normal
            } else {
                //context包含showTemporary没有值 or disbale FG开启，走旧逻辑
                if fromSceneInContext == .web, fromMode == WebBrowserScene.normal.rawValue {
                    // 在web容器里通过window.open 或者 openschema打开，需要延续之前的模式
                    scene = .normal
                } else if (fromSceneInContext == .workplace || fromSceneInContext == .workplacePortal) && !workplaceTemporaryTabEnable {
                    // 7.0 版本工作台还没有做全屏适配，仍然使用push方式打开
                    scene = .normal
                } else {
                    // 其余场景使用标签页打开
                    if ipadPopUpFixEnable {
                        if !isPopUpAnimation {
                            scene = .temporaryTab
                        }
                    } else {
                        scene = .temporaryTab
                    }
                }
            }
        }
        // 兼容 ipad 多scene场景，不需要在标签页打开，直接返回browser即可. pad的路由就是这么带劲
        if let fromWebScene = req.context["fromWebMultiScene"] as? Bool, fromWebScene == true {
            scene = .normal
        } else if body.fromWebMultiScene == true {
            scene = .normal
        }
        
        var feedId = "" //feed场景需要
        if let feedInfo = req.context["feedInfo"] as? [String: Any] {
            if let appID = feedInfo["appID"] as? String {
                feedId = appID
            }
        }
        
        let trace = OPTraceService.default().generateTrace()
        Self.logger.info("NormalWebRouterHandler open web, traceId:\(trace.traceId ?? ""), usePanel:\(useLarkWebPanel), isCollapsed:\(isCollapsed), scene:\(scene.rawValue ?? "")")
        OPMonitor(WebContainerMonitorEvent.containerStartHandle)
            .setWebAppID(webAppInfo?.id)
            .setWebURL(bodyUrl)
            .setWebBizType(bizType)
            .setWebBrowserScene(scene)
            .addCategoryValue("from", fromScene)
            .addCategoryValue("applink_trace_id", applink_trace_id)
            .tracing(trace)
            .flush()
        //  代码放在这里有待讨论，是之前离职的passport同学的遗留代码，仅保持原逻辑不动
        if let userService = try? resolver.resolve(assert: PassportUserService.self), let token = userService.user.sessionKey {
            LarkCookieManager.shared.plantCookie(
                token: token
            )
        }
        
        // 用于 window.open 的时候传递 referer
        var originRefererURL: URL?
        if let from = req.context["from"] as? String, let fromURL = URL(string: from) {
            if let scheme = fromURL.scheme?.lowercased(), ["http", "https"].contains(scheme) {
                originRefererURL = fromURL
            }
        }
        
        let webBrowserID = req.context[webBrowserIDKey] as? String ?? UUID().uuidString
        let shouldNonPersistent: Bool
        if let appConfigService = try? resolver.resolve(assert: AppConfigService.self) {
            shouldNonPersistent = !appConfigService.feature(for: "sso").isOn
        } else {
            shouldNonPersistent = false
        }
        var webViewConfig = WebBrowserConfiguration(
            customUserAgent: nil,
            /// 精简模式下sso为false，shouldNonPersistent应传true，需取反
            //未改动逻辑
            shouldNonPersistent: shouldNonPersistent,
            originRefererURL: originRefererURL,
            webBrowserID: webBrowserID,
            downloadEnable: true    // 开启文件下载能力
        )
        if enabledDisableUniteRouter {
            webViewConfig = WebBrowserConfiguration(
                customUserAgent: nil,
                /// 精简模式下sso为false，shouldNonPersistent应传true，需取反
                //未改动逻辑
                shouldNonPersistent: shouldNonPersistent,
                originRefererURL: originRefererURL,
                webBrowserID: webBrowserID,
                notUseUniteRoute: notUseUniteRoute,
                downloadEnable: true    // 开启文件下载能力
            )
        }
        webViewConfig.acceptWebMeta = true
        webViewConfig.enableRedirectOptimization = true
        webViewConfig.initTrace = trace
        webViewConfig.startHandleTime = Date().timeIntervalSince1970
        webViewConfig.scene = scene
        webViewConfig.webBizType = bizType
        webViewConfig.appId = webAppInfo?.id
        webViewConfig.fromScene = fromSceneInContext
        webViewConfig.fromSceneReport = fromSceneInContextReport
        if isNavLeftClose {
            webViewConfig.isLaunchBarEnable = false
        }
        let browser = getBrowser(resolver: resolver, url: bodyUrl, req: req, context: req.context, configuration: webViewConfig, isCollapsed: isCollapsed)
        browser.resolver = resolver
        browser.feedId = feedId
        tryFixDifferentNavipush(browser: browser, req: req,isCollapsed: isCollapsed)
        if useLarkWebPanel {
            if !browser.isReuseBrowser {
                registerEcosystemWebMetaExtension(for: browser)
                registerEcosystemWebExtensionItems(browser: browser, showProgress: false, useLarkWebPanel: true)
                registerWebAppExtensionItem(browser: browser, webAppInfo: webAppInfo)
                ecosyetemWebDependency.registerBusinessExtensions(browser: browser)
            }
            let panelBrowserVC = PanelBrowserViewContainer(contentViewController: browser, style: panelConfig.panelStyle, appId: webAppInfo?.id ?? "", resolver: resolver)
            panelBrowserVC.show(from: req.from.fromViewController)
            res.end(resource: nil)
        } else {
            if !browser.isReuseBrowser {
                registerEcosystemWebMetaExtension(for: browser)
                registerEcosystemWebNavigationBarExtensionItems(browser: browser, isNavLeftClose: isNavLeftClose)
                registerEcosystemWebExtensionItems(browser: browser, showProgress: true, isNavLeftClose: isNavLeftClose, useLarkWebPanel: false)
                registerWebAppExtensionItem(browser: browser, webAppInfo: webAppInfo)
                ecosyetemWebDependency.registerBusinessExtensions(browser: browser)
            }
            if (isPopUpAnimation) {
                //present效果
                if let from = req.from.fromViewController {
                    browser.isFormSheet = true
                    Navigator.shared.present(browser,
                                             wrap: LkNavigationController.self,
                                             from: from,
                                             prepare: { $0.modalPresentationStyle = .formSheet })
                }
                res.end(resource: nil)
            } else {
                if let myaiQuickLaunchbarService = try? resolver.resolve(assert: LarkOpenPlatformMyAIService.self), scene == .temporaryTab {
                    // ipad 临时区域打开, tabContainableIdentifier 是从冷启动后点击临时区域传递过来的标识，方便定位数据和刷新数据信息
                    if req.context[NavigationKeys.uniqueid] != nil {
                        browser.tabContainableIdentifier = req.context[NavigationKeys.uniqueid] as? String ?? ""
                    }
                    myaiQuickLaunchbarService.showTabVC(browser)
                    Self.logger.info("showTabVC with url: \(browser.browserURL?.safeURLString), traceId:\(trace.traceId)")
                    res.end(resource: nil)
                } else {
                    //push效果
                    res.end(resource: browser)
                }
            }
        }
    }
    
    
    func resolveFromSceneWithContext(from: String?) -> WebBrowserFromScene {
        guard let from = from else {
            return WebBrowserFromScene.normal
        }
        return WebBrowserFromScene(rawValue: from)
    }
    
    func getBrowser(resolver: Resolver, url: URL?, req: Request, context: [String: Any], configuration: WebBrowserConfiguration, isCollapsed: Bool) -> WebBrowser {
        if let webAppKeepAliveService = try? resolver.resolve(assert: WebAppKeepAliveService.self), webAppKeepAliveService.isWebAppKeepAliveEnable()  {
            let temporaryUniququeId = context[NavigationKeys.uniqueid] as? String
            let identifier = webAppKeepAliveService.createKeepAliveIdentifier(fromScene: configuration.fromScene, scene: configuration.scene, appId: configuration.appId, url: url, isCollapsed: isCollapsed, tabContainableIdentifier: temporaryUniququeId)
            let scene  = webAppKeepAliveService.createKeepAliveScene(fromScene: configuration.fromScene, scene: configuration.scene, appId: configuration.appId, url: url, isCollapsed: isCollapsed, tabContainableIdentifier: temporaryUniququeId)
            Self.logger.info("keepalive start router fromScene\(configuration.fromScene), scene:\(configuration.scene), appid:\(configuration.appId), isCollapsed:\(isCollapsed), url:\(url?.safeURLString)")
            LKWSecurityLogUtils.webSafeAESURL(identifier, msg: "keepalive try get cacche for identifier")
            if !identifier.isEmpty {
                if let cacheWebAppBrowser = webAppKeepAliveService.getWebAppBrowser(identifier: identifier, scene: scene, tabContainableIdentifier:temporaryUniququeId) {
                    let hasCustomURL = context["lk_web_customurl"] as? Bool ?? false
                    if let url = url, url.absoluteString != cacheWebAppBrowser.webview.url?.absoluteString, hasCustomURL, temporaryUniququeId.isEmpty {
                        // url不等价并且applink中有自定path或者targeturl
                        cacheWebAppBrowser.loadURL(url)
                        Self.logger.info("keepalive browser:\(identifier) load when has lk_web_customurl")
                    }
                    cacheWebAppBrowser.isReuseBrowser = true
                    Self.logger.info("keepalive get cache browser:\(identifier)")
                    req.context[ContextKeys.checkPushSafety] = true
                    if req.context[NavigationKeys.uniqueid] != nil {
                        cacheWebAppBrowser.tabContainableIdentifier = req.context[NavigationKeys.uniqueid] as? String ?? ""
                    }
                    return cacheWebAppBrowser
                } else {
                    let browser = WebBrowser(url: url, configuration: configuration)
                    browser.pageScene = scene
                    browser.initIsCollapsed = isCollapsed
                    if req.context[NavigationKeys.uniqueid] != nil {
                        browser.tabContainableIdentifier = req.context[NavigationKeys.uniqueid] as? String ?? ""
                    }
                    Self.logger.info("keepalive browser:\(identifier) should add to cache")
                    return browser
                }
            } else {
                Self.logger.info("keepalive router to normal")
                return WebBrowser(url: url, configuration: configuration)
            }
        } else {
            Self.logger.info("keepalive fg close hit normal router")
            return WebBrowser(url: url, configuration: configuration)
        }
    }
    
    func tryFixDifferentNavipush(browser:WebBrowser, req: Request, isCollapsed: Bool){
        if let keepAliveService = try? resolver.resolve(assert: WebAppKeepAliveService.self), keepAliveService.isWebAppKeepAliveEnable() {
            // 保活开启并且iPad c和iPhone保活 未关闭时，需要走fix逻辑
            func tryFixDifferentNavipushInnerFunc(){
                if let navi = browser.navigationController, let near = req.from.fromViewController?.nearestNavigation, navi != near {
                    // 拿到的vc已经有navigationController，说明之前已经出现在某个导航里了
                    var currentViewControlers = navi.viewControllers
                    Self.logger.info("keepalive borwser has navi and diff with nearestNavigation, counts:\(currentViewControlers.count)")
                    // 从原来的导航里把当前browser 删掉
                    var hitVCInStack = false
                    currentViewControlers.removeAll {
                        if $0 == browser {
                            Self.logger.info("keepalive try fix push hit stack")
                            hitVCInStack = true
                            return true
                        }
                        return false
                    }
                    // 原来导航里确实存在将要push的vc，才做重新赋值的操作，否则什么都不做
                    if hitVCInStack {
                        Self.logger.info("keepalive try fix push set new viewControllers, counts:\(currentViewControlers.count)")
                        navi.viewControllers = currentViewControlers
                    }
                }
            }
            if Display.phone, !keepAliveService.isWebAppKeepAliveIPhoneDisable() {
                tryFixDifferentNavipushInnerFunc()
            } else if Display.pad, isCollapsed, !keepAliveService.isWebAppKeepAliveIPhoneDisable() {
                tryFixDifferentNavipushInnerFunc()
            }
            
        }
        
    }
}

func registerEcosystemWebMetaExtension(for browser: WebBrowser) {
    guard browser.configuration.acceptWebMeta else {
        NormalWebRouterHandler.logger.error("registerEcosystemWebMetaExtension error because acceptWebMeta is false")
        return
    }
    do {
        try browser.register(item: WebMetaExtensionItem(browser: browser))
        let orientationExtensionItem = WebMetaOrientationExtensionItem(browser: browser)
        if Display.phone {
            try browser.register(item: orientationExtensionItem)
        }
        try browser.register(item: WebMetaSafeAreaExtensionItem(browser: browser))
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.meta.meta_hidemenuitems")) ||
            WebMetaMoreMenuConfigExtensionItem.isWebShareLinkEnabled() {// user:global
            try browser.register(item: WebMetaMoreMenuConfigExtensionItem(browser: browser))
        }
        if WebMetaSlideToCloseExtensionItem.isSlideToCloseEnabled() {
            try browser.register(item: WebMetaSlideToCloseExtensionItem(browser: browser))
        }
        if WebMetaBackForwardGesturesExtensionItem.allowBackForwardGesEnable() {
            try browser.register(item: WebMetaBackForwardGesturesExtensionItem(browser: browser))
        }
        if WebMetaNavigationBarExtensionItem.isShowNavigationBarEnabled() ||
            WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled() ||
            WebMetaNavigationBarExtensionItem.isHideNavBarItemsEnabled() {
            try browser.register(item: WebMetaNavigationBarExtensionItem(browser: browser))
        }
        if WebMetaLaunchBarExtensionItem.isShowLaunchBarEnabled() {
            try browser.register(item: WebMetaLaunchBarExtensionItem(browser: browser))
        }
    } catch {
        NormalWebRouterHandler.logger.error("registerEcosystemWebMetaExtension error", error: error)
    }
}

func registerEcosystemWebNavigationBarExtensionItems(browser: WebBrowser, isNavLeftClose: Bool = false) {
    do {
        try browser.register(item: NavigationBarStyleExtensionItem())
        try browser.register(item: NavigationBarMiddleExtensionItem())
        if (isNavLeftClose) {
            try browser.register(item: ModalNavigationBarLeftExtensionItem(browser: browser))
            
        } else {
            try browser.register(item: NavigationBarLeftExtensionItem(browser: browser))
        }
        
    } catch {
        NormalWebRouterHandler.logger.error("registerEcosystemWebNavigationBarExtensionItems error", error: error)
    }
}

func registerEcosystemWebExtensionItems(browser: WebBrowser, showProgress: Bool, isNavLeftClose: Bool = false, useLarkWebPanel: Bool) {
    do {
        try browser.register(item: MonitorExtensionItem())
        try browser.register(item: MemoryLeakExtensionItem())
        try browser.register(item: TerminateReloadExtensionItem(browser: browser))
        if (showProgress) {
            try browser.register(item: ProgressViewExtensionItem())
        }
        try browser.register(item: ErrorPageExtensionItem())
        try browser.register(item: WebInspectorExtensionItem(browser: browser))
        if OPUserScope.userResolver().fg.staticFeatureGatingValue(with: "openplatform.browser.remote.debug.client_enable") {
            try browser.register(item: WebOnlineInspectorExtensionItem(browser: browser))
        }
        try browser.register(item: UniteRouterExtensionItem())
        try browser.register(item: MediaExtensionItem())
        try browser.register(item: EcosystemAPIExtensionItem())
        try browser.register(singleItem: EcosystemWebSingleExtensionItem())
        if !isNavLeftClose {
            try browser.register(item: WebMenuExtensionItem(browser: browser))
            try browser.register(item: NavigationBarRightExtensionItem(browser: browser))
        }

        try browser.register(item: WebLaunchBarExtensionItem(browser: browser))
        try browser.register(item: WebInlineAIExtensionItem(browser: browser))
        try browser.register(item: NativeComponentExtensionItem())
        if Display.pad {
            try browser.register(item: PadExtensionItem(browser: browser))
        }
        try browser.register(item: WebMetaLegacyExtensionItem())
        if !FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.web.leaveconfirm.disable")) {// user:global
        try browser.register(item: LeaveConfirmExtensionItem())
        }
        if WebBrowser.isDynamicNetStatusEnabled() {
            try browser.register(item: NetStatusExtenstionItem(browser: browser))
        }
        if WebTextSizeMenuPlugin.featureEnabled {
            try browser.register(item: WebTextSizeExtensionItem(browser: browser))
        }
        if !useLarkWebPanel, !isNavLeftClose, browser.configuration.scene != .workplacePortal {
            registerWebSearchExtensionItem(browser: browser)
        }
    } catch {
        NormalWebRouterHandler.logger.error("registerEcosystemWebExtensionItems error", error: error)
    }
}

func registerWebAppExtensionItem(browser: WebBrowser, webAppInfo: WebAppInfo?) {
    do {
        try browser.register(item: WebAppExtensionItem(browser: browser, webAppInfo: webAppInfo))
    } catch {
        NormalWebRouterHandler.logger.error("registerWebAppExtensionItem error", error: error)
    }
}

func registerWebAppIntegratedLoadExtensionItem(
    browser: WebBrowser,
    appID: String,
    webAppIntegratedConfiguration: WebAppIntegratedConfiguration,
    webAppIntegratedLoadDelegate: WebAppIntegratedLoadProtocol?
) {
    do {
        try browser.register(item: WebAppIntegratedLoadExtensionItem(
            appID: appID,
            webAppIntegratedConfiguration: webAppIntegratedConfiguration,
            webAppIntegratedLoadDelegate: webAppIntegratedLoadDelegate
        ))
    } catch {
        NormalWebRouterHandler.logger.error("registerWebAppIntegratedLoadExtensionItem error", error: error)
    }
}

func registerWebSearchExtensionItem(browser: WebBrowser) {
    do {
        if let searchItem = WebSearchExtensionItem(browser: browser) {
            try browser.register(item: searchItem)
        }
    } catch {
        NormalWebRouterHandler.logger.error("registerWebSearchExtensionItem error", error: error)
    }
}
