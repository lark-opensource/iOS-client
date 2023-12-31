//
//  WebOfflineRouterHandler.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/11/17.
//

import ECOInfra
import ECOProbe
import EENavigator
import LKCommonsLogging
import WebBrowser
import LarkSetting
import LarkContainer
import LarkNavigator
import Swinject

final class WebOfflineRouterHandler: UserTypedRouterHandler {
    
    static let logger = Logger.ecosystemWebLog(WebOfflineRouterHandler.self, category: "WebOfflineRouterHandler")
    
    func handle(_ body: WebOfflineBody, req: EENavigator.Request, res: EENavigator.Response) {
        var configuration = WebBrowserConfiguration(webBrowserID: body.webBrowserID)
        let trace = OPTraceService.default().generateTrace()
        Self.logger.info("WebOfflineRouterHandler open web, traceId is \(trace.traceId ?? "")")
        OPMonitor(WebContainerMonitorEvent.containerStartHandle)
            .setWebAppID(body.webAppInfo.id)
            .setWebURL(body.url)
            .setWebBizType(configuration.webBizType)
            .setWebBrowserScene(WebBrowserScene.normal)
            .setWebBrowserOffline(true)
            .addCategoryValue("from", body.fromScene?.rawValue)
            .addCategoryValue("applink_trace_id", body.appLinkTrackId)
            .tracing(trace)
            .flush()
        configuration.initTrace = trace
        configuration.acceptWebMeta = true
        configuration.enableRedirectOptimization = true
        configuration.startHandleTime = Date().timeIntervalSince1970
        configuration.scene = WebBrowserScene.normal
        configuration.appId = body.webAppInfo.id
        configuration.offline = true
        
        let browser = WebBrowser(url: body.url, configuration: configuration)
        browser.resolver = resolver
        registerEcosystemWebNavigationBarExtensionItems(browser: browser)
        registerEcosystemWebExtensionItems(browser: browser, showProgress: true, useLarkWebPanel: false)
        registerWebAppExtensionItem(browser: browser, webAppInfo: body.webAppInfo)
        registerWebOfflineExtensionItems(browser: browser, appID: body.webAppInfo.id)
        res.end(resource: browser)
    }
}

func registerWebOfflineExtensionItems(browser: WebBrowser, appID: String) {
    do {
        guard ecosyetemWebDependency.offlineEnable() else {
            WebOfflineRouterHandler.logger.error("offline fg disable, not register WebOfflineExtensionItem")
            return
        }
        
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.offline.v2")) {// user:global
        try browser.register(item: OfflineResourceExtensionItem(appID: appID, browser: browser, delegate: OfflineResourcesTool.shared))
        } else {
        try browser.register(item: WebOfflineExtensionItem(appID: appID, browser: browser))
        }
        if !FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.web.leaveconfirm.disable")) {// user:global
        try browser.register(item: LeaveConfirmExtensionItem())
        }
    } catch {
        WebOfflineRouterHandler.logger.error("registerWebOfflineExtensionItems error", error: error)
    }
}
