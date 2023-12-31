//
//  OpenPlatformAPIHandlerImp.swift
//  LarkOpenPlatform
//
//  Created by zhysan on 2020/10/12.
//

import Foundation
import EENavigator
import LarkAppLinkSDK
import WebBrowser
import EEMicroAppSDK
import LarkMessengerInterface
import LarkLocalizations
import LarkUIKit
import LarkAccountInterface
import Swinject
import LarkRustClient
import RustPB
import RxSwift
import LKCommonsLogging
import LarkOPInterface
import JsSDK
import LarkSDKInterface
import Homeric
import LKCommonsTracker
import CookieManager
import LarkFeatureGating
import LarkSetting
import SuiteAppConfig
import OPFoundation
import LarkTab
import LarkNavigation
import LarkOpenPlatform
import LarkAI
import LarkGuide
import TTMicroApp
import EcosystemWeb
import LarkWebViewContainer
import ECOInfra
import LarkContainer
import WebKit
import LarkCloudScheme
import OPSDK
import SKBitable
import LarkSplitViewController
import LarkQuickLaunchBar
import LarkQuickLaunchInterface
import UniverseDesignToast

// swiftlint:disable all
private let logger = Logger.oplog(OpenPlatformAPIHandlerImp.self, category: "OpenPlatformAPIHandlerImp")

private let kOPAPIHandlerErrorDomain = "client.open_platform.api_handler"

final class OpenPlatformAPIHandlerImp {

    lazy var configDependency: ConfigDependency = {
        ConfigDependencyImp(resolver: self.resolver)
    }()
    
    @Provider var configService: ECOConfigService

    internal init(_ resolver: UserResolver) {
        self.resolver = resolver
    }

    // MARK: - private

    private let resolver: UserResolver

    func featureGeting(for key: String) -> Bool {
        LarkFeatureGating.shared.getFeatureBoolValue(for: key)
    }
    
    func settingsDictionaryValue(for key: String) -> [String: Any]? {
        configService.getDictionaryValue(for: key)
    }
}

extension OpenPlatformAPIHandlerImp: WebBrowserDependencyProtocol, EcosyetemWebDependencyProtocol, LarkWebViewProtocol {
    public func errorpageHTML() -> String? {
        EMAAppEngine.current()?.componentResourceManager?.fetchResourceWithSepcificKey(componentName: "errorpage", resourceType: "html")
    }
    public func webDetectPageHTML() -> String? {
            EMAAppEngine.current()?.componentResourceManager?.fetchResourceWithSepcificKey(componentName: "op_web_detect_page", resourceType: "html")
        }
    public func ajaxFetchHookString() -> String? {
        EMAAppEngine.current()?.componentResourceManager?.fetchAjaxHookJS()
    }
    public func offlineEnable() -> Bool {
        OPSDKFeatureGating.isWebappOfflineEnable()
    }
    public func setupAjaxFetchHook(webView: LarkWebView) {
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
    public func networkClient() -> ECONetworkClientProtocol {
        Injected<ECONetworkClientProtocol>(name: ECONetworkChannel.rust.rawValue, arguments: OperationQueue(), DefaultRequestSetting).wrappedValue
    }
    func appInfoForCurrentWebpage(browser: WebBrowser) -> WebAppInfo? {
        browser.appInfoForCurrentWebpage
    }
    func isWebAppForCurrentWebpage(browser: WebBrowser) -> Bool {
        browser.isWebAppForCurrentWebpage
    }
    func registerBusinessExtensions(browser: WebBrowser) {
        try? browser.register(item: WebTranslateExtensionItem(browser: browser))
        try? browser.register(item: FormsExtensionItem())
    }
    
    func registerExtensionItemsForBitableHomePage(browser: WebBrowser) {
        browser.ecosystem_registerExtensionItemsForBitableHomePage()
    }
    
    func generateWebAppLink(targetUrl: String, appId: String) -> URL? {
        return H5Applink.generateAppLink(targetUrl: targetUrl, appId: appId)
    }
    
    func generateCustomPathWebAppLink(targetUrl: String, appId: String) -> URL? {
        return H5Applink.generateCustomPathWebAppLink(targetUrl: targetUrl, appId: appId)
    }
    
    
    func isTabState(_ tab: Tab?) -> Bool {
        guard let navigationService = self.resolver.resolve(NavigationService.self),
              let tab = tab else {
            return false
        }
        if navigationService.checkInTabs(for: tab) {
            return true
        }
        return false
    }
    func getLarkWebJsSDK(with api: WebBrowser, methodScope: JsAPIMethodScope) -> LarkWebJSSDK? {
        let sdk = JsSDKBuilder.jsSDKWithAllProvider(api: api, resolver: resolver, scope: methodScope)
        return sdk
    }

    func canOpen(url: URL) -> Bool { CloudSchemeManager.shared.canOpen(url: url) }

    func openURL(_ url: URL,
                 options: [UIApplication.OpenExternalURLOptionsKey: Any],
                 completionHandler completion: ((Bool) -> Void)?) {
        CloudSchemeManager.shared.open(url, options: options, completionHandler: completion)
    }

    /// 获取网页应用带Api授权机制的JSSDK
    /// - Parameters:
    ///   - appId: 应用ID
    ///   - apiHost: api实现方
    func getWebAppJsSDKWithAuthorization(appId: String, apiHost: WebBrowser) -> WebAppApiAuthJsSDKProtocol? {
        WebAppApiAuthJsSDK(appID: appId, apiHost: apiHost, resolver: resolver)
    }

    /// 获取网页应用不带Api授权机制的JSSDK
    /// - Parameters:
    ///   - apiHost: api实现方
    func getWebAppJsSDKWithoutAuthorization(apiHost: WebBrowser) -> WebAppApiNoAuthProtocol? {
        WebAppApiNoAuth(apiHost: apiHost)
    }

    func auditEnterH5App(_ appID: String) {
        if let auditService = resolver.resolve(OPAppAuditService.self) {
            auditService.auditEnterApp(appID)
        }
    }

    func asyncDetectAndReportH5AppSandbox(_ appId: String) {
        SandboxDetection.asyncDetectAndReportH5SandboxInfo(appId: appId)
    }

    //  Onboarding相关
    /// 是否需要引导
    /// - Parameter key: 引导key
    func checkShouldShowGuide(key: String) -> Bool {
        guard let newGuideService = resolver.resolve(NewGuideService.self) else {
            let msg = "has no NewGuideService, please contact ug team"
            assertionFailure(msg)
            logger.error(msg)
            return false
        }
        return newGuideService.checkShouldShowGuide(key: key)
    }

    /// 完成引导
    /// - Parameter guideKey: 引导Key
    func didShowedGuide(guideKey: String) {
        guard let newGuideService = resolver.resolve(NewGuideService.self) else {
            let msg = "has no NewGuideService, please contact ug team"
            assertionFailure(msg)
            logger.error(msg)
            return
        }
        newGuideService.didShowedGuide(guideKey: guideKey)
    }
    
    func shareH5(webVC: WebBrowser) {
        ShareLegacy.shareH5(target: WebVCTarget(webVC: webVC))
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
    // openAPI唤起My AI分会话，不实现，暂时注释掉，具体方法已经下沉到 WebBrowser
//    func launchMyAI(browser: WebBrowser) {
//        if let launchBarItem = browser.resolve(WebLaunchBarExtensionItem.self), let launchBarService = resolver.resolve(MyAIQuickLaunchBarService.self), launchBarService.isAIServiceEnable.value {
//            launchBarItem.luanchMyAI()
//        } else {
//            UDToast.showTips(with: BundleI18n.LarkOpenPlatform.OpenPlatform_Worker_FeatureUnavailable, on: browser.view, delay: 2.0)
//        }
//    }
}

extension OpenPlatformAPIHandlerImp {
    func close(_ viewController: UIViewController?) -> Bool {
        guard let vc = viewController else {
            return true
        }
        guard let nav = vc.navigationController else {
            // present
            vc.dismiss(animated: true, completion: nil)
            return true
        }
        guard let topvc = nav.topViewController else {
            logger.warn("nav top vc is nil, nav: \(nav), vcs: \(nav.viewControllers)")
            return false
        }
        guard topvc == vc || topvc.children.contains(vc) else {
            logger.warn("web vc is not at the top level, topvc: \(nav.viewControllers)")
            return false
        }
        // zhysan todo: iPad 兼容性验证
        //  iPad兼容 @lixiaorui
        if nav.viewControllers.count == 1 {
            if let split = nav.larkSplitViewController,
               nav === split.viewController(for: .secondary) {
                // if split detail pop last, show default detail page
//                Navigator.shared.showDetail(LKSplitViewController2.DefaultDetailController(), wrap: LkNavigationController.self)
                if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
                    Navigator.shared.showDetail(LKSplitViewController2.DefaultDetailController(), from: fromVC)
                } else {
                    logger.error("OpenPlatformAPIHandlerImp close can not show vc because no fromViewController")
                }
            } else {
                // nav has only one vc, so no more vc to pop, go dismiss
                nav.dismiss(animated: true, completion: nil)
            }
        } else {
            nav.popViewController(animated: true)
        }
        return true
    }

    func canOpen(_ url: URL) -> Bool {
        let param = Navigator.shared.response(for: url, test: true).parameters
        if param["_canOpenInDocs"] as? Bool == true {
            return true
        }
        if param["_canOpenInMicroApp"] as? Bool == true {
            return true
        }
        if param[AppLinkAssembly.KEY_CAN_OPEN_APP_LINK] as? Bool == true {
            return true
        }
        return false
    }

    func open(_ url: URL) {
        if !canOpen(url) {
            logger.warn("open url not support: \(url)")
            return
        }
        // iPad 兜底适配
        if let from = OPNavigatorHelper.topmostNav(window: OPWindowHelper.fincMainSceneWindow()) {
            Navigator.shared.push(url, from: from)
        } else {
            logger.error("open url failed because can not find from")
        }
    }

    func larkCookies() -> [HTTPCookie] {
        LarkCookieManager.shared.buildLarkCookies(session: AccountServiceAdapter.shared.currentAccessToken, domains: nil).map { $1 }.flatMap { $0 }
    }
}

final class LoginDependencyImp: LoginDependency {
    func registerUnloginRouterWhitelist(_ pattern: String) {
        UnloginWhitelistRegistry.registerUnloginWhitelist(pattern)
    }

    func handleSSOSDKUrl(_ url: URL) -> Bool {
        let userResolver = Container.shared.getCurrentUserResolver()
        guard let service = try? userResolver.resolve(assert: PassportAuthorizationService.self) else {
            return false
        }
        return service.handleSSOSDKUrl(url)
    }

    func plantCookie() {
        LarkCookieManager.shared.plantCookie(
            token: AccountServiceAdapter.shared.currentAccessToken
        )
    }
}

final class ConfigDependencyImp: ConfigDependency {

    private let resolver: Resolver
    private lazy var disposeBag: DisposeBag = { DisposeBag() }()

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    var secLinkWhitelist: [String] {
        if let setting = resolver.resolve(UserGeneralSettings.self) {
            return setting.dominManagePolicyConfig.secLinkWhitelist
        }
        return []
    }

    var suiteSecurityLink: String? {
        DomainSettingManager.shared.currentSetting[.suiteSecurityLink]?.first
    }

    func isSecurityUrl(_ url: String, result: @escaping (Bool) -> Void) {
        resolver.resolve(UrlAPI.self)!.judgeSecureLink(target: url, scene: "messenger").map { (res) -> Bool in
            res.isSafe
        }.subscribe { (isSafe) in
            result(isSafe)
        } onError: { (error) in
            logger.error("judge isSecurityUrl error: \(error)")
            result(false)
        }.disposed(by: disposeBag)

    }

    func featureSwitchOn(for feature: FeatureSwitchKey) -> Bool {
        resolver.resolve(AppConfigService.self)!.feature(for: feature.rawValue).isOn
    }

    func featureGeting(for key: String) -> Bool {
        LarkFeatureGating.shared.getFeatureBoolValue(for: key)
    }
}
// swiftlint:enable all
