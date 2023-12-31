import ECOInfra
import ECOProbe
import EENavigator
import Foundation
import LarkFoundation
import LarkOPInterface
import LarkSetting
import LarkWebViewContainer
import LKCommonsLogging
import OPSDK
import OPWebApp
import TTMicroApp
import WebBrowser
import LarkContainer

private let errorDomain = "WebAppIntegratedErrorDomain"
private let invaildURLCode = -1
private let noMobileURL = -2
private let metaPkgInternal = -3
private let lowVersion = -4
private let onlineInvaildURLCode = -5
private let offlineInvaildURLCode = -6
private let onlineMetaPkgInternal = -7
private let offlineMetaPkgInternal = -8
private let hasNoFallbackURLs = -9
private let logger = Logger.ecosystemWebLog(WebAppIntegratedSoftwareDevelopmentKit.self, category: "WebAppIntegratedSoftwareDevelopmentKit")
/// 套件统一浏览器架构 3.0 - 网页容器的应用能力集成 Software Development Kit
public final class WebAppIntegratedSoftwareDevelopmentKit {
    @available(*, deprecated, message: "please use fetchWebAppBrowser")
    class public func createBrowser(
        with appID: String,
        webAppIntegratedConfiguration: WebAppIntegratedConfiguration = WebAppIntegratedConfiguration(),
        webBrowserConfiguration: WebBrowserConfiguration = WebBrowserConfiguration(),
        webAppIntegratedLoadDelegate: WebAppIntegratedLoadProtocol? = nil,
        resolver: Resolver?
    ) -> WebBrowser? {
        if appID.isEmpty {
            assertionFailure("appID is empty, 请不要传空字符串，不要传 nil（比如OC那边来的），请传入开放平台应用的 appID，⚠️⚠️⚠️⚠️⚠️本入口不接受如下场景的 appID 加载：1. appID 对应的主页 URL 是 Docs，AppLink，Mail 等在端内具备特殊能力的不使用 browser 渲染的网页，如果不按照要求盲目传入导致线上事故，revert 代码，写 case study，做复盘，承担事故责任")
            return nil
        }
        
        // 启动最早埋点(兜底)，可以选提前到更早时机
        var configuration = webBrowserConfiguration
        configuration.startHandleTime = Date().timeIntervalSince1970
        configuration.appId = appID
        if configuration.initTrace == nil {
            // 如果外部调用没有主动设置 initTrace，则认为这里就是最早的起点，并设置 initTrace，要在最早的时机调用(早于 init)
            let trace = OPTraceService.default().generateTrace()
            configuration.initTrace = trace
            
            var browserScene = WebBrowserScene.normal
            switch webAppIntegratedConfiguration.openWebAppIntegratedScene {
                case .maintab:
                browserScene = WebBrowserScene.mainTab
                case .workplacePortal:
                browserScene = WebBrowserScene.workplacePortal
                case .unknown:
                browserScene = WebBrowserScene.normal
            }
            
            logger.info("WebAppIntegratedSoftwareDevelopmentKit open web, traceId is \(trace.traceId ?? "")")
            OPMonitor(WebContainerMonitorEvent.containerStartHandle)
                .setWebAppID(appID)
                .setWebBizType(configuration.webBizType)
                .setWebBrowserScene(browserScene)
                .tracing(trace)
                .flush()
        }
        let browser = WebBrowser(configuration: configuration)
        browser.resolver = resolver
        if webAppIntegratedConfiguration.enableNavigationBarItems {
            registerEcosystemWebNavigationBarExtensionItems(browser: browser)
        }
        registerEcosystemWebExtensionItems(browser: browser, showProgress: true, useLarkWebPanel: false)
        registerWebAppExtensionItem(browser: browser, webAppInfo: WebAppInfo(id: appID))
        registerWebAppIntegratedLoadExtensionItem(
            browser: browser,
            appID: appID,
            webAppIntegratedConfiguration: webAppIntegratedConfiguration,
            webAppIntegratedLoadDelegate: webAppIntegratedLoadDelegate
        )
        return browser
    }
    class public func fetchWebAppBrowser(
        appID: String,
        initTrace: OPTrace?,
        startHandleTime: TimeInterval?,
        scene:WebBrowserScene = .normal,
        fromScene:WebBrowserFromScene = .normal,
        fromSceneReport:WebBrowserFromSceneReport = .normal,
        /// 外部指定要打开的path，如果传入了这个path，会替换获取到的url的path， 目前工作台applink跳转用
        startPath: String? = nil,
        /// 外部指定要打开的query，如果传入了这个query，会替换获取到的url的query， 目前工作台applink跳转用
        startQueryItems: [URLQueryItem]? = nil,
        completionHandler: @escaping (Result<WebBrowser, Error>) -> Void
    ) {
        var initTrace = initTrace
        var startTime = startHandleTime
        var browserScene = scene
        if initTrace == nil {
            // 如果外部调用没有主动设置 initTrace，则认为这里就是最早的起点，并设置 initTrace，要在最早的时机调用(早于 init)
            initTrace = OPTraceService.default().generateTrace()
            logger.info("WebAppIntegratedSoftwareDevelopmentKit open web, traceId(initTrace) is \(initTrace?.traceId ?? "none")")
            OPMonitor(WebContainerMonitorEvent.containerStartHandle)
                .setWebAppID(appID)
                .setWebBizType(.larkWeb)
                .setWebBrowserScene(browserScene)
                .tracing(initTrace)
                .flush()
            startTime = Date().timeIntervalSince1970
        }
        let instanceID = UUID().uuidString
        OPWebAppManager.sharedInstance.prepareWebApp(uniqueId: OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .webApp, instanceID: instanceID), previewToken: nil, supportOnline: true) { error, state, ext in
            DispatchQueue.main.async {
                if let error = error {
                    logger.error("prepareWebApp Error", error: error)
                    completionHandler(.failure(error))
                    return
                }
                switch state {
                case .meta:
                    guard let ext = ext else {
                        let e = NSError(domain: errorDomain, code: onlineMetaPkgInternal)
                        logger.error("ext is nil", error: e)
                        completionHandler(.failure(e))
                        return
                    }
                    if ext.offlineEnable {
                        //  离线模式，等包回调
                        return
                    }
                    guard let mobileUrl = ext.mobileUrl else {
                        let e = NSError(domain: errorDomain, code: noMobileURL)
                        logger.error("ext.mobileUrl is nil", error: e)
                        completionHandler(.failure(e))
                        return
                    }
                    guard var url = URL(string: mobileUrl) else {
                        let e = NSError(domain: errorDomain, code: onlineInvaildURLCode)
                        logger.error("ext.mobileUrl is not rfc url", error: e)
                        completionHandler(.failure(e))
                        return
                    }
                    
                    // 根据传入的startPath，替换url中的path，以跳转到指定的子路径
                    if let updatedUrl = url.replaceWebAppUrlIfNeeded(
                        with: startPath,
                        queryItems: startQueryItems,
                        webBrowserScene: scene
                    ) {
                        url = updatedUrl
                    }

                    var webBrowserConfiguration = WebBrowserConfiguration(downloadEnable: true)
                    webBrowserConfiguration.webBrowserID = instanceID
                    webBrowserConfiguration.initTrace = initTrace
                    webBrowserConfiguration.startHandleTime = startTime
                    webBrowserConfiguration.appId = appID
                    webBrowserConfiguration.scene = browserScene
                    webBrowserConfiguration.fromScene = fromScene
                    webBrowserConfiguration.fromSceneReport = fromSceneReport
                    completionHandler(.success(WebBrowser(url: url, configuration: webBrowserConfiguration)))
                case .pkg:
                    guard let ext = ext else {
                        let e = NSError(domain: errorDomain, code: offlineMetaPkgInternal)
                        logger.error("ext is nil", error: e)
                        completionHandler(.failure(e))
                        return
                    }
                    guard ext.offlineEnable else {
                        //  和包管理对接人沟通，在线也会走这个回调，要求在这里不要做判断，直接跳过
                        return
                    }
                    var offlineURLString = ext.vhost
                    if offlineURLString.starts(with: "https"), convert_https_to_http() {
                        offlineURLString = offlineURLString.replaceFirst(of: "https://", with: "http://")
                    }
                    if var path = ext.mainUrl {
                        if !path.starts(with: "/") {
                            //  避免后端不按照RFC规范传输
                            path = "/" + path
                        }
                        offlineURLString = offlineURLString + path
                    }
                    guard var offlineURL = URL(string: offlineURLString) else {
                        let e = NSError(domain: errorDomain, code: offlineInvaildURLCode)
                        logger.error("offlineURLString is not rfc url", error: e)
                        completionHandler(.failure(e))
                        return
                    }
                    // 根据传入的startPath，替换offlineURL中的path
                    if let updatedOfflineUrl = offlineURL.replaceWebAppUrlIfNeeded(
                        with: startPath,
                        queryItems: startQueryItems,
                        webBrowserScene: scene
                    ) {
                        offlineURL = updatedOfflineUrl
                    }
                    var fallbackUrls = [URL]()
                    if let fallbackUrlStrings = ext.fallbackUrls {
                        for urlString in fallbackUrlStrings {
                            var urlString = urlString
                            if var p = ext.mainUrl {
                                if !urlString.hasSuffix("/"), !p.starts(with: "/") {
                                    p = "/" + p
                                }
                                urlString = urlString + p
                            }
                            if var u = URL(string: urlString) {
                                // 根据传入的startPath，替换fallbackUrl中的path
                                if let updatedfallbackUrl = u.replaceWebAppUrlIfNeeded(
                                    with: startPath,
                                    queryItems: startQueryItems,
                                    webBrowserScene: scene
                                ) {
                                    u = updatedfallbackUrl
                                }
                                fallbackUrls.append(u)
                            }
                        }
                    }
                    let buildBrowserBlock = {
                        tryBuildBrowser(appID: appID, initTrace: initTrace, offlineURL: offlineURL, fallbackUrls: fallbackUrls, instanceID: instanceID, startHandleTime: startTime, scene:browserScene, fromScene: fromScene, completionHandler: completionHandler)
                    }
                    if let minLarkVersion = ext.minLarkVersion {
                        if !minLarkVersion.isEmpty {
                            let larkVersion = LarkFoundation.Utils.appVersion
                            if !larkVersion.isEmpty {
                                if BDPVersionManager.compareVersion(minLarkVersion, with: larkVersion) > 0 {
                                    completionHandler(.failure(NSError(domain: errorDomain, code: lowVersion)))
                                } else {
                                    buildBrowserBlock()
                                }
                            } else {
                                buildBrowserBlock()
                            }
                        } else {
                            buildBrowserBlock()
                        }
                    } else {
                        //  包管理侧要求策略：开发者没配置最小版本，可以打开
                        buildBrowserBlock()
                    }
                }
            }
        }
    }
}
private func tryBuildBrowser(appID: String, initTrace: OPTrace?, offlineURL: URL, fallbackUrls: [URL], instanceID: String, startHandleTime: TimeInterval?, scene: WebBrowserScene = .normal, fromScene: WebBrowserFromScene, completionHandler: @escaping (Result<WebBrowser, Error>) -> Void) {
    var webBrowserConfiguration = WebBrowserConfiguration(downloadEnable: true)
    webBrowserConfiguration.webBrowserID = instanceID
    webBrowserConfiguration.initTrace = initTrace
    webBrowserConfiguration.startHandleTime = startHandleTime
    webBrowserConfiguration.appId = appID
    webBrowserConfiguration.scene = scene
    webBrowserConfiguration.fromScene = fromScene
    webBrowserConfiguration.offline = true
    if #available(iOS 12.2, *), !offline_v2_useFallbackURLs(appID: appID) {
        //  iOS12.2以上且不使用fallback，直接加载离线资源
        //  Settings配置数组
        webBrowserConfiguration.resourceInterceptConfiguration = (offline_v2_schemes(), WebAppResourceIntercept())
        completionHandler(.success(WebBrowser(url: offlineURL, configuration: webBrowserConfiguration)))
        return
    }
    //  此FG只用于URLProtocol下线前，URLProtocol删除的时候删掉这行if以及else内的代码
    if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.offline.usefallback")) {// user:global
    if !fallbackUrls.isEmpty {
        var fallbackURLs = fallbackUrls
        let firstFallbackURL = fallbackURLs.removeFirst()
        let browser = WebBrowser(url: firstFallbackURL, configuration: webBrowserConfiguration)
        if !fallbackURLs.isEmpty {
            try? browser.register(item: FallbackExtensionItem(fallbackUrls: fallbackURLs))
        }
        completionHandler(.success(browser))
    } else {
        completionHandler(.failure(NSError(domain: errorDomain, code: hasNoFallbackURLs)))
    }
    } else {
        // URLProtocol删除的时候删掉这段代码
        let b = WebBrowser(url: offlineURL, configuration: webBrowserConfiguration)
        registerWebOfflineExtensionItems(browser: b, appID: appID)
        completionHandler(.success(b))
    }
}
public func offline_v2_useFallbackURLs(appID: String) -> Bool {
    guard let offline_v2 = LarkWebSettings.shared.settings?["offline_v2"] as? [String: Any] else {
        return false
    }
    guard let use_fallback = offline_v2["use_fallback"] as? Bool else {
        guard let fallback_appids = offline_v2["fallback_appids"] as? [String] else {
            return false
        }
        return fallback_appids.contains(appID)
    }
    return use_fallback
}
public func offline_v2_schemes() -> Set<String> {
    guard let offline_v2 = LarkWebSettings.shared.settings?["offline_v2"] as? [String: Any] else {
        return ["http"]
    }
    guard let schemes = offline_v2["schemes"] as? Set<String> else {
        return ["http"]
    }
    guard !schemes.isEmpty else {
        return ["http"]
    }
    return schemes
}
public func convert_https_to_http() -> Bool {
    guard let offline_v2 = LarkWebSettings.shared.settings?["offline_v2"] as? [String: Any] else {
        return false
    }
    guard let convert_https_to_http = offline_v2["convert_https_to_http"] as? Bool else {
        return false
    }
    return convert_https_to_http
}
extension String {
    func replaceFirst(of p: String, with r: String) -> String {
        if let range = range(of: p) {
            return replacingCharacters(in: range, with: r)
        } else {
            return self
        }
    }
}
@available(*, deprecated, message: "use fetchWebAppBrowser")
public struct WebAppIntegratedConfiguration {
    let openWebAppIntegratedScene: OpenWebAppIntegratedScene
    let enableNavigationBarItems: Bool
    let enableWebAppIntegratedLoadUI: Bool
    /// 外部指定要打开的path，如果传入了这个path，会替换获取到的url的path
    /// 目前工作台applink跳转用
    public var startPath: String?
    /// 外部指定要打开的query，如果传入了这个query，会替换获取到的url的query
    /// 目前工作台applink跳转用
    public var startQueryItems: [URLQueryItem]?
    
    public init(
        openWebAppIntegratedScene: OpenWebAppIntegratedScene = .unknown,
        enableNavigationBarItems: Bool = true,
        enableWebAppIntegratedLoadUI: Bool = true
    ) {
        self.openWebAppIntegratedScene = openWebAppIntegratedScene
        self.enableNavigationBarItems = enableNavigationBarItems
        self.enableWebAppIntegratedLoadUI = enableWebAppIntegratedLoadUI
    }
}
@available(*, deprecated, message: "use fetchWebAppBrowser")
public enum OpenWebAppIntegratedScene: Int {
    case unknown = -1
    case maintab = 0
    case workplacePortal = 1
}

extension URL {
    func replaceWebAppUrlIfNeeded(
        with path: String?,
        queryItems: [URLQueryItem]?,
        webBrowserScene: WebBrowserScene
    ) -> URL? {
        /// 只有工作台场景才需要对 url 做特殊处理
        guard webBrowserScene == .workplacePortal else {
            return nil
        }
        return replaceWebAppUrlFromSceneIfNeeded(with: path, queryItems: queryItems)
    }
    
    @available(*, deprecated, message: "use fetchWebAppBrowser")
    func replaceWebAppUrlIfNeeded(
        with path: String?,
        queryItems: [URLQueryItem]?,
        openWebAppIntegratedScene: OpenWebAppIntegratedScene
    ) -> URL? {
        /// 只有工作台场景才需要对 url 做特殊处理
        guard openWebAppIntegratedScene == .workplacePortal else {
            return nil
        }
        return replaceWebAppUrlFromSceneIfNeeded(with: path, queryItems: queryItems)
    }
    
    private func replaceWebAppUrlFromSceneIfNeeded(
        with path: String?,
        queryItems: [URLQueryItem]?
    ) -> URL? {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        if path == nil && queryItems == nil {
            return nil
        }
        if let p = path {
            urlComponents.path = p
        }
        /// 如果用户配置了网页门户的applink子路径，query为空代表用户需要跳转的子路径不带query
        urlComponents.queryItems = queryItems
        return urlComponents.url
    }
}
