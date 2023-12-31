//
//  DemoWebBrowserAssembly.swift
//  LarkOpenPlatform
//
//  Created by zhysan on 2020/10/12.
//

#if canImport(WebBrowser)
import Foundation
import WebBrowser
import LarkAssembler
import Swinject
import LarkWebViewContainer
import LarkContainer
import ByteViewCommon
import LarkSetting
#if canImport(LarkOpenPlatform)
import LarkOpenPlatform
import EEMicroAppSDK
import EcosystemWeb
import JsSDK
#endif
#if canImport(LarkAI)
import LarkAI
#endif
#if canImport(SKBitable)
import SKBitable
#endif

final class DemoWebBrowserAssembly: LarkAssemblyInterface {
    func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)
        container.register(LarkWebViewQualityServiceProtocol.self) { _ in
            QualityService()
        }
        user.register(DemoWebHandler.self) {
            DemoWebHandler($0)
        }
        user.register(LarkWebViewProtocol.self) {
            try $0.resolve(assert: DemoWebHandler.self)
        }
        user.register(WebBrowserDependencyProtocol.self) {
            try $0.resolve(assert: DemoWebHandler.self)
        }
        #if canImport(LarkOpenPlatform)
        user.register(EcosyetemWebDependencyProtocol.self) {
            try $0.resolve(assert: DemoWebHandler.self)
        }
        #endif
        #if canImport(LarkAI)
        user.register(WebTranslateWebAPIRegister.self) { _ in
            WebTranslateWebAPIRegisterImpl()
        }
        #endif
    }
}

// swiftlint:disable all
private final class DemoWebHandler: WebBrowserDependencyProtocol, LarkWebViewProtocol {
    private let logger = Logger.getLogger("Demo")

    private let resolver: UserResolver
    init(_ resolver: UserResolver) {
        self.resolver = resolver
    }

    func setupAjaxFetchHook(webView: LarkWebView) {
        guard offlineEnable() else {
            logger.info("offline fg is closed, not setupAjaxHook")
            return
        }
        if LarkWebSettings.shared.offlineSettings?.ajax_hook.inject == .all {
            logger.info("ajax_hook.inject == .all")
            webView.setupAjaxHook()
        } else if LarkWebSettings.shared.offlineSettings?.ajax_hook.inject == .larkweb {
            logger.info("ajax_hook.inject == .larkweb")
            webView.setupAjaxHook()
        } else {
            logger.info("ajax_hook.inject is not all or larkweb")
        }
    }
    func offlineEnable() -> Bool {
        do {
            return try resolver.resolve(assert: FeatureGatingService.self).dynamicFeatureGatingValue(with: "openplatform.webapp.offline.enable")
        } catch {
            return false
        }
    }
}

#if canImport(LarkOpenPlatform)
extension DemoWebHandler {
    func errorpageHTML() -> String? {
        EMAAppEngine.current()?.componentResourceManager?.fetchResourceWithSepcificKey(componentName: "errorpage", resourceType: "html")
    }
    func webDetectPageHTML() -> String? {
        EMAAppEngine.current()?.componentResourceManager?.fetchResourceWithSepcificKey(componentName: "op_web_detect_page", resourceType: "html")
    }
    func ajaxFetchHookString() -> String? {
        EMAAppEngine.current()?.componentResourceManager?.fetchAjaxHookJS()
    }
    func appInfoForCurrentWebpage(browser: WebBrowser) -> WebAppInfo? {
        browser.appInfoForCurrentWebpage
    }
    func isWebAppForCurrentWebpage(browser: WebBrowser) -> Bool {
        browser.isWebAppForCurrentWebpage
    }
    func registerExtensionItemsForBitableHomePage(browser: WebBrowser) {
        browser.ecosystem_registerExtensionItemsForBitableHomePage()
    }
    func getLarkWebJsSDK(with api: WebBrowser, methodScope: JsAPIMethodScope) -> LarkWebJSSDK? {
        return JsSDKBuilder.jsSDKWithAllProvider(api: api, resolver: resolver, scope: methodScope)
    }
}

extension DemoWebHandler: EcosyetemWebDependencyProtocol {
    func getWebAppJsSDKWithAuthorization(appId: String, apiHost: WebBrowser) -> WebAppApiAuthJsSDKProtocol? {
        WebAppApiAuthJsSDK(appID: appId, apiHost: apiHost, resolver: resolver)
    }
    
    func getWebAppJsSDKWithoutAuthorization(apiHost: WebBrowser) -> WebAppApiNoAuthProtocol? {
        WebAppApiNoAuth(apiHost: apiHost)
    }

    func registerBusinessExtensions(browser: WebBrowser) {
        #if canImport(LarkAI)
        try? browser.register(item: WebTranslateExtensionItem(browser: browser))
        #endif
        #if canImport(SKBitable)
        try? browser.register(item: FormsExtensionItem())
        #endif
    }

    func generateWebAppLink(targetUrl: String, appId: String) -> URL? {
        return H5Applink.generateAppLink(targetUrl: targetUrl, appId: appId)
    }
    
    func generateCustomPathWebAppLink(targetUrl: String, appId: String) -> URL? {
        return H5Applink.generateCustomPathWebAppLink(targetUrl: targetUrl, appId: appId)
    }
    
    func shareH5(webVC: WebBrowser) {
    }
    
    func isOfflineMode(browser: WebBrowser) -> Bool {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.offline.v2")) {
            if browser.resolve(OfflineResourceExtensionItem.self) != nil {
                return true
            }
        }
        if browser.resolve(WebOfflineExtensionItem.self) != nil {
            return true
        }
        if browser.resolve(FallbackExtensionItem.self) != nil {
            return true
        }
        if browser.configuration.resourceInterceptConfiguration != nil {
            return true
        }
        if browser.configuration.offline {
            return true
        }
        return false
    }
}

#else
extension DemoWebHandler {
    func errorpageHTML() -> String? {
        nil
    }
    func webDetectPageHTML() -> String? {
        nil
    }
    func ajaxFetchHookString() -> String? {
        nil
    }
    func appInfoForCurrentWebpage(browser: WebBrowser) -> WebAppInfo? {
        nil
    }
    func isWebAppForCurrentWebpage(browser: WebBrowser) -> Bool {
        false
    }
    func registerExtensionItemsForBitableHomePage(browser: WebBrowser) {
    }
    func getLarkWebJsSDK(with api: WebBrowser, methodScope: JsAPIMethodScope) -> LarkWebJSSDK? {
        return nil
    }
}
#endif

#if canImport(LarkAI)
private final class WebTranslateWebAPIRegisterImpl: WebTranslateWebAPIRegister {
    #if canImport(LarkOpenPlatform)
    func registJSSDK(apiDict: [String: () -> LarkWebJSAPIHandler], jsSDK: LarkWebJSSDK) {
        JsSDKBuilder.registJSSDK(apiDict: apiDict, jsSDK: jsSDK)
    }
    func canEnableWebTranslate(_ context: WebBrowserMenuContext) -> Bool {
        !context.isOfflineMode
    }
    #else
    func registJSSDK(apiDict: [String: () -> LarkWebJSAPIHandler], jsSDK: LarkWebJSSDK) {
    }
    func canEnableWebTranslate(_ context: WebBrowserMenuContext) -> Bool {
        false
    }
    #endif
}
#endif

// swiftlint:enable all
#endif
