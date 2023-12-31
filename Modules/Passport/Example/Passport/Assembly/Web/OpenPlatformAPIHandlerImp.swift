//
//  OpenPlatformAPIHandlerImp.swift
//  LarkOpenPlatform
//
//  Created by zhysan on 2020/10/12.
//

import Foundation
import EENavigator
import LarkAppLinkSDK
import LarkWebViewController
import LarkLocalizations
import LarkUIKit
import LarkAccountInterface
import EEImageService
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

// swiftlint:disable all
private let logger = Logger.oplog(OpenPlatformAPIHandlerImp.self, category: "OpenPlatformAPIHandlerImp")

private let kOPAPIHandlerErrorDomain = "client.open_platform.api_handler"

class OpenPlatformAPIHandlerImp {

    lazy var configDependency: ConfigDependency = {
        ConfigDependencyImp(resolver: self.resolver)
    }()

    internal init(_ resolver: Resolver) {
        self.resolver = resolver
    }

    // MARK: - private

    private let resolver: Resolver

    /// 通过 avatar key 从 Rust 层同步获取 avatar URL，不要在主线程调用
    private func getAvatarURL(_ key: String) -> String {
        let service = resolver.resolve(RustService.self)!

        var request = Media_V1_GetResourceUrlsRequest()
        request.key = key

        var param = Media_V1_AvatarFsUnitParams()
        param.sizeType = .small
        request.avatarFsUnitParams = param

        do {
            let response: Media_V1_GetResourceUrlsResponse = try service.sendSyncRequest(request)
            if let str = response.urls.first {
                return str
            }
            logger.error("nil avatar url! key: \(key)")
        } catch {
            logger.error("avatar url fetch failed, key: \(key), err: \(error)")
        }
        return ""
    }
    
    func featureGeting(for key: String) -> Bool {
        LarkFeatureGating.shared.getFeatureBoolValue(for: key)
    }
}

extension OpenPlatformAPIHandlerImp: WebBrowserDependencyProtocol {
    /// TODO 需要适配
    func close(_ viewController: UIViewController?) -> Bool {
        return true
    }

    func collectPlugins() -> [WebPlugin] {
        return []
    }
    func isTabState(_ tab: Tab?) -> Bool {
        return false
    }

    func registJSSDK(apiDict: [String : () -> LarkWebJSAPIHandler], jsSDK: LarkWebJSSDK) {
        JsSDKBuilder.registJSSDK(apiDict: apiDict, jsSDK: jsSDK)
    }

    func getLarkWebJsSDK(with api: WebBrowser, methodScope: JsAPIMethodScope) -> LarkWebJSSDK? {
        let sdk = JsSDKBuilder.jsSDKWithAllProvider(api: api, resolver: resolver, scope: methodScope)
        (sdk as? JsSDKImpl)?.authSessionDelegate = api
        return sdk
    }
    
    func registerExtensionItemsForBitableHomePage(browser: WebBrowser) {
    }

    /// 是否是一方网页
    /// - Parameter url: 网页的URL
    /// - Returns: 结果
    func isInternalWeb(with url: URL) -> Bool {
        // 目前只有Pano接入，需要补充的话，发版补充，参考 https://bytedance.feishu.cn/docs/doccnW3E184DDXMAN0YoP7BbuLb
        if isPano(url: url) {
            return true
        }
        // 如果要其他的业务也能用，需要开发
        return false
    }

    //  是否是Pano的URL 此处会有Lark依赖，为了保障Lark依赖项挂掉还能跑，按照上面文档的约定：对内从宽，对外从严
    private func isPano(url: URL) -> Bool {
        guard let hosts = DomainSettingManager.shared.currentSetting[.pano] else {
            logger.error("get AppConfiguration.settings has no pano hosts, please contact AppConfiguration owner")
            return true
        }
        guard !hosts.isEmpty else {
            //  pano一定配置了域名的，如果这里挂掉了，需要return true
            logger.error("get AppConfiguration.settings pano hosts is empty, please contact AppConfiguration owner")
            return true
        }
        guard let urlHost = url.host else {
            //  如果传过来的URLhost都没有，明显URL不对，不应该返回true
            logger.error("url.host is nil")
            return false
        }
        //  遍历hosts数组，如果有一个相等，return true
        let value = hosts.contains(urlHost)
        return value
    }

    func canOpen(url: URL) -> Bool {
        guard let scheme = url.scheme else { return false }
        if var schemeConfig = resolver.resolve(UserGeneralSettings.self)?.schemeConfig {
            return schemeConfig.schemeHandleList.contains(where: { $0.caseInsensitiveCompare(scheme) == .orderedSame }) || url.absoluteString.contains("itunes.apple.com")
        }
        return false
    }

    func openURL(_ url: URL,
                 options: [UIApplication.OpenExternalURLOptionsKey: Any],
                 completionHandler completion: ((Bool) -> Void)?) {
        if let downloadSiteList = resolver.resolve(UserGeneralSettings.self)?.schemeConfig.schemeDownloadSiteList,
           !downloadSiteList.isEmpty {
            UIApplication.shared.open(url, options: options) { (success) in
                if !success {
                    if let scheme = url.scheme,
                       let downloadSiteString = downloadSiteList[scheme],
                       let downloadSite = URL(string: downloadSiteString) {
                        UIApplication.shared.open(downloadSite)
                    }
                }
                completion?(success)
                Tracker.post(TeaEvent(Homeric.APPLINK_FEISHU_OPEN_OTHERAPP_RESULT,
                                      params: ["schema": url.scheme ?? "",
                                               "result": success ? "success" : "fail"]))
            }
        } else {
            UIApplication.shared.open(url, options: options, completionHandler: completion)
        }
    }

    /// 获取网页应用带Api授权机制的JSSDK
    /// - Parameters:
    ///   - appId: 应用ID
    ///   - apiHost: api实现方
    func getWebAppJsSDKWithAuthorization(appId: String, apiHost: WebBrowser) -> WebAppApiAuthJsSDKProtocol? {
        nil
    }

    /// 获取网页应用不带Api授权机制的JSSDK
    /// - Parameters:
    ///   - apiHost: api实现方
    func getWebAppJsSDKWithoutAuthorization(apiHost: WebBrowser) -> WebAppApiNoAuthProtocol? {
        nil
    }

    func loadWebCacheService(bizName: String?) -> WebCacheDependency? {
        return WebCacheDependencyImp(resolver: resolver, bizName: bizName)
    }

    func auditEnterH5App(_ appID: String) {
        if let auditService = resolver.resolve(OPAppAuditService.self) {
            auditService.auditEnterApp(appID)
        }
    }
    
    //  Onboarding相关
    /// 是否需要引导
    /// - Parameter key: 引导key
    func checkShouldShowGuide(key: String) -> Bool {
        return false
    }
    
    /// 完成引导
    /// - Parameter guideKey: 引导Key
    func didShowedGuide(guideKey: String) {
    }
}

class LoginDependencyImp: LoginDependency {
    func registerUnloginRouterWhitelist(_ pattern: String) {
        UnloginWhitelistRegistry.registerUnloginWhitelist(pattern)
    }

    func handleSSOSDKUrl(_ url: URL) -> Bool {
        AccountServiceAdapter.shared.handleSSOSDKUrl(url)
    }

    func plantCookie() {
        CookieManager.shared.plantCookie(
            token: AccountServiceAdapter.shared.currentAccessToken
        )
    }
}

class ConfigDependencyImp: ConfigDependency {

    private let resolver: Resolver
    private lazy var disposeBag: DisposeBag = { DisposeBag() }()

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    var secLinkWhitelist: [String] {
        [
            ".*\\.feishu\\.cn$",
            "^feishu\\.cn$",
            ".*\\.larksuite\\.com$",
            ".*\\.feishu-pre\\.cn$",
            ".*\\.larksuite-pre\\.com$",
            "^larksuite\\.help$",
            "^getfeishu\\.cn$",
            "ct\\.ctrip\\.com$",
            "wx\\.tenpay\\.com",
            "tanna\\.kundou\\.cn"
        ]
    }

    var suiteSecurityLink: String? {
        DomainSettingManager.shared.currentSetting[.suiteSecurityLink]?.first
    }

    func isSecurityUrl(_ url: String, result: @escaping (Bool) -> Void) {
        result(true)
    }

    func featureSwitchOn(for feature: FeatureSwitchKey) -> Bool { false }

    func featureGeting(for key: String) -> Bool {
        LarkFeatureGating.shared.getFeatureBoolValue(for: key)
    }
}
// swiftlint:enable all
