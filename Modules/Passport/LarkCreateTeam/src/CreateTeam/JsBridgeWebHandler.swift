//
//  JsBridgeWebHandler.swift
//  Pods
//
//  Created by quyiming@bytedance.com on 2019/7/23.
//
// swiftlint:disable all
import Foundation
import LarkContainer
import Swinject
import EENavigator
import WebBrowser
import LarkAccountInterface
import LarkMessengerInterface
import JsSDK
import LarkUIKit
import LarkWebViewContainer
import LarkOPInterface
import SuiteAppConfig
import WebKit
import LarkContact
import RxSwift
import LarkSetting
import LKCommonsLogging

fileprivate func openPlatformJSBHandlerUserResolver() -> UserResolver {
    // #TODOZJX
    let compatibleMode = FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.user_scope_compatible_disable")
    return Container.shared.getCurrentUserResolver(compatibleMode: !compatibleMode) // user:current
}

public struct JsBridgeWebBody: CodablePlainBody {
    public static let pattern: String = "//client/web/bridge"

    public let url: URL
    public var jsApis: [String]
    public var isInjectIgnorePageReady: Bool

    public init(url: URL, jsApis: [String] = [], isInjectIgnorePageReady: Bool = true) {
        self.url = url
        self.jsApis = jsApis
        self.isInjectIgnorePageReady = isInjectIgnorePageReady
    }
}

class JsBridgeWebHandler: TypedRouterHandler<JsBridgeWebBody> { // user:checked (navigator)
    private let resolver: Resolver

    static let logger = Logger.log(JsBridgeWebHandler.self, category: "LarkCreateTeam.JsBridgeWebHandler")

    @Provider static var appConfigService: AppConfigService // user:checked (global-resolve)

    @Provider static var dependency: PassportWebViewDependency

    init(resolver: Resolver) {
        self.resolver = resolver
        super.init()
    }

    static func createWebViewController(
        resolver: Resolver,
        url: URL,
        isInjectIgnorePageReady: Bool = true,
        jsApis: [String] = [],
        customUserAgent: String? = nil
    ) -> WebBrowser {
        var config = WebBrowserConfiguration(
            customUserAgent: customUserAgent,
            //未改动逻辑
            shouldNonPersistent: !appConfigService.feature(for: "sso").isOn,
            jsApiMethodScope: .none,
            webBizType: .passport,
            notUseUniteRoute: true //登录前webview不走统一路由拦截,请不要随意修改这个值. 可以联系passport
        )
        let controller = WebBrowser(url: url, configuration: config)
        dependency.enableLeftNaviButtonsRootVCOptObservable().subscribe {[weak controller] event in
            if let element = event.element {
                controller?.updateLeftNaviButtonsRootVCOpt(leftNaviButtonsRootVCOpt: element)
                Self.logger.info("update left navi Buttons on root vc: \(element)")
            }
        }
        registerPassportExtensionItems(browser: controller)
        let i = PassportAPIExtensionItem.buildPassportAPIExtensionItem(resolver: resolver, jsApis: jsApis)
        try? controller.register(item: i)
        let it = PassportSingleExtensionItem(browser: controller, resolve: resolver)
        it.jsSDKBuilder = i.jsSDKBuilder
        try? controller.register(singleItem: it)
        return controller
    }

    override func handle(_ body: JsBridgeWebBody, req: EENavigator.Request, res: Response) {
        let controller = JsBridgeWebHandler.createWebViewController(resolver: resolver, url: body.url, isInjectIgnorePageReady: body.isInjectIgnorePageReady, jsApis: body.jsApis)
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *) {
            // 禁用下拉手势
            controller.isModalInPresentation = true
        }
        #endif
        res.end(resource: controller)
    }

    // 除了 Dynamic 和 Passport 以外 handler，对应原始 getApiDict
    static func clientHandlerDict(api: WebBrowser, resolver: UserResolver) -> JsAPIHandlerDict {
        return [
            BaseJsAPIHandlerProvider(api: api, resolver: resolver),
            CommonJsAPIHandlerProvider(api: api, resolver: resolver),
            BizJsAPIHandlerProvider(resolver: resolver),
            DeviceJsAPIHandlerProvider()
        ].handlers()
    }
}
//  把passport和browser的耦合接开，未修改逻辑，这里的代码是passport调用API的代码
final public class PassportAPIExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "PassportAPI"
    private var resolver: Resolver?
    public var jsSDKBuilder: ((WebBrowser) -> LarkWebJSSDK)?
    public init(resolver: Resolver?) {
        self.resolver = resolver
    }
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = PassportAPIWebBrowserLifeCycle(item: self)
    func setupOldBridge(browser: WebBrowser) {
        let h = PassportOldScriptMessageHandler(controller: browser, resolver: resolver)
        h.jsSDKBuilder = jsSDKBuilder
        browser.webview.configuration.userContentController.add(h, name: "invoke")
    }

    public static func buildAccountSecurityCenterAPIExtensionItem(resolver: Resolver) -> PassportAPIExtensionItem {
        let i = PassportAPIExtensionItem(resolver: resolver)
        i.jsSDKBuilder = { (api) -> LarkWebJSSDK in
            var resApiDict: [String: () -> LarkWebJSAPIHandler] = [
                "biz.passport.firstPartyMFA": { PassportFirstPartyMFAHandler(resolver: resolver) },
                "biz.passport.checkMFAStatus": { PassportCheckStatusMFAHandler(resolver: resolver) }
            ]
            resApiDict.merge(generateSCSResApiDict(resolver: resolver)) { current, _ in current }
            let apiDict = allHandlerProviders(api: api, resolver: openPlatformJSBHandlerUserResolver()).handlers()
            for (k, v) in apiDict {
                resApiDict[k] = v
            }
            return JsSDKBuilder.initJsSDK(api, resolver: openPlatformJSBHandlerUserResolver(), handlerDict: resApiDict)
        }
        return i
    }

    public static func generateSCSResApiDict(resolver: Resolver) -> [String: () -> LarkWebJSAPIHandler] {
        let service = try? resolver.resolve(assert: AppLockSettingDependency.self)
        guard (service?.enableAppLockSettingsV2).isTrue else {
            return [:]
        }
        return ["biz.scs.isLockScreenProtectionEnabled": { AppLockSettingStatusHandler(resolver: resolver) }]
    }

    public static func buildPassportAPIExtensionItem(resolver: Resolver, jsApis: [String] = []) -> PassportAPIExtensionItem {
        let i = PassportAPIExtensionItem(resolver: resolver)
        i.jsSDKBuilder = { (api) -> LarkWebJSSDK in
            var resApiDict: [String: () -> LarkWebJSAPIHandler] = [
                "biz.account.setClose": { SetCloseHandler() },
                "biz.account.hideNavigationBack": { HideNavigationBackHandler() },
                "biz.account.openLink": { BaseJsAPIHandlerProvider.makeOpenWebLinkHandler(openLinkBlock: { (url, vc, _) in
                    var navi = NaviParams()
                    navi.forcePush = true
                    Navigator.shared.push(body: SimpleWebBody(url: url), naviParams: navi, from: vc) // user:checked (navigator)
                }) },
                "biz.account.log": { LogHandler() },
                "biz.account.appInfo": { AppInfoHandler() },
                "biz.account.ka_info": { PassportConfigHandler() },
                "biz.account.h5_login_result": { PassportLoginResultHandler() },
                "device.base.getSystemInfo": { GetSystemInfoHandler(openPlatform: resolver.resolve(OpenPlatformService.self)!) },
                "biz.account.switch_idp": { PassportSwitchIdpHandler() },
                "biz.account.vpn_auth_user": { PassportUserVpnAuthHandler() },
                "biz.passport.authorizedOperation": { PassportAuthorizedOperationHandler() },
                "biz.passport.set_lang": { PassportSetLanguageHandler() },
                "biz.passport.get_lang": { PassportGetLanguageHandler() },
                "biz.passport.startFaceIdentify": { PassportBioAuthHandler() },
                "biz.passport.request_network": { PassportNativeHttpRequestHandler() },
                "biz.passport.get_remote_register_info": { PassportGetStepInfoHandler() },
                "biz.passport.join_by_scan": { PassportJoinByScanHandler() },
                "passport.redirect_to_saas_login": {PassportRedirectToSaasHandler() }
            ]
            let userResolver = openPlatformJSBHandlerUserResolver()
            if !jsApis.isEmpty {
                let apiDict = JsBridgeWebHandler.clientHandlerDict(api: api, resolver: userResolver)
                for (k, v) in apiDict {
                    if jsApis.contains(k) {
                        resApiDict[k] = v
                    }
                }
            }
            return JsSDKBuilder.initJsSDK(api, resolver: userResolver, handlerDict: resApiDict)
        }
        return i
    }
}
final public class PassportAPIWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: PassportAPIExtensionItem?
    init(item: PassportAPIExtensionItem) {
        self.item = item
    }
    public func viewDidLoad(browser: WebBrowser) {
        item?.setupOldBridge(browser: browser)
    }
}
class PassportOldScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak private var controller: WebBrowser?
    private var resolver: Resolver?
    var jsSDKBuilder: ((WebBrowser) -> LarkWebJSSDK)?
    lazy var jsSDK: LarkWebJSSDK? = { [weak self] in
        guard let `self` = self else { return nil }
        guard let browser = self.controller else { return nil }
        guard let resolve = self.resolver else { return nil }
        var jsSdk: LarkWebJSSDK?
        if let builder = self.jsSDKBuilder {
            jsSdk = builder(browser)
        } else {
            let resolver = openPlatformJSBHandlerUserResolver()
            jsSdk = JsSDKBuilder.initJsSDK(
                browser,
                resolver: resolver,
                handlerProviders: allHandlerProviders(api: browser, resolver: resolver),
                scope: browser.configuration.jsApiMethodScope
            )
        }
        return jsSdk
    }()
    init(controller: WebBrowser?, resolver: Resolver?) {
        self.resolver = resolver
        self.controller = controller
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let params = message.body as? [String: Any] else { return }
        guard let method = params["method"] as? String else { return }
        guard let args = params["args"] as? [String: Any] else { return }
        if Thread.isMainThread {
            jsSDK?.invoke(method: method, args: args)
        } else {
            DispatchQueue.main.async {
                self.jsSDK?.invoke(method: method, args: args)
            }
        }
    }
}
final public class PassportSingleExtensionItem: WebBrowserExtensionSingleItemProtocol {
    weak var browser: WebBrowser?
    private var resolver: Resolver?
    public var jsSDKBuilder: ((WebBrowser) -> LarkWebJSSDK)?
    public init(browser: WebBrowser?, resolve: Resolver?) {
        self.browser = browser
        self.resolver = resolve
    }
    public lazy var callAPIDelegate: WebBrowserCallAPIProtocol? = {
        let a = PassportCallAPI(item: self, browser: browser, resolve: resolver)
        a.jsSDKBuilder = jsSDKBuilder
        return a
    }()
}
final class PassportCallAPI: WebBrowserCallAPIProtocol {
    weak var browser: WebBrowser?
    private var resolver: Resolver?
    var jsSDKBuilder: ((WebBrowser) -> LarkWebJSSDK)?
    lazy var jsSDK: LarkWebJSSDK? = { [weak self] in
        guard let `self` = self else { return nil }
        guard let browser = self.browser else { return nil }
        guard let resolve = self.resolver else { return nil }
        var jsSdk: LarkWebJSSDK?
        if let builder = self.jsSDKBuilder {
            jsSdk = builder(browser)
        } else {
            let resolver = openPlatformJSBHandlerUserResolver()
            jsSdk = JsSDKBuilder.initJsSDK(
                browser,
                resolver: resolver,
                handlerProviders: allHandlerProviders(api: browser, resolver: resolver),
                scope: browser.configuration.jsApiMethodScope
            )
        }
        return jsSdk
    }()
    private weak var item: PassportSingleExtensionItem?
    init(item: PassportSingleExtensionItem?, browser: WebBrowser?, resolve: Resolver?) {
        self.item = item
        self.browser = browser
        self.resolver = resolve
    }
    public func recieveAPICall(webBrowser: WebBrowser, message: APIMessage, callback: APICallbackProtocol) {
        jsSDK?.invoke(apiName: message.apiName, data: message.data, callbackID: message.callbackID)
    }
}
func allHandlerProviders(api: WebBrowser, resolver: UserResolver) -> [JsAPIHandlerProvider] {
    return [
        BaseJsAPIHandlerProvider(api: api, resolver: resolver),
        CommonJsAPIHandlerProvider(api: api, resolver: resolver),
        BizJsAPIHandlerProvider(resolver: resolver),
        DeviceJsAPIHandlerProvider(),
        DynamicJsAPIHandlerProvider(api: api, resolver: resolver),
        PassportJsAPIHandlerProvider(resolver: resolver)
    ]
}

public func registerPassportExtensionItems(browser: WebBrowser) {
    do {
        try browser.register(item: MemoryLeakExtensionItem())
        try browser.register(item: TerminateReloadExtensionItem(browser: browser))
        try browser.register(item: ProgressViewExtensionItem())
        try browser.register(item: NativeFailViewExtensionItem(browser: browser))
        try browser.register(item: NavigationBarStyleExtensionItem())
        try browser.register(item: NavigationBarMiddleExtensionItem())
        try browser.register(item: NavigationBarLeftExtensionItem(browser: browser))
        try browser.register(item: UniteRouterExtensionItem())
    } catch {
        assertionFailure("\(error)")
    }
}
// swiftlint:enable all

public class PassportCallAPIImpl: ExternalCallAPIDependencyProtocol {
    public var resolver: Swinject.Resolver?
    public func getCallAPI(webBrowser: WebBrowser) -> WebBrowserCallAPIProtocol {
        let passportCallAPI = PassportCallAPI(item: nil, browser: webBrowser, resolve: self.resolver)
        if let resolver = resolver {
            passportCallAPI.jsSDKBuilder = PassportAPIExtensionItem.buildPassportAPIExtensionItem(resolver: resolver).jsSDKBuilder
        }
        return passportCallAPI

    }

    public var supportHandlerList: [String] = ["biz.account.setClose",
                                        "biz.account.hideNavigationBack",
                                        "biz.account.openLink",
                                        "biz.account.ka_info",
                                        "biz.passport.request_network",
                                        "biz.passport.get_remote_register_info",
                                        "biz.passport.join_by_scan",
                                        "biz.passport.get_lang",
                                        "biz.passport.set_lang"]
    init(resolver: Resolver) {
        self.resolver = resolver
    }
}
