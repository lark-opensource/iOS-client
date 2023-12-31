import ECOInfra
import LarkContainer
import LarkWebViewContainer
import LarkSetting
import LKCommonsLogging
import WebBrowser
import WebKit
import OPWebApp
import OPSDK
import OPFoundation

private let logger = Logger.ecosystemWebLog(WebOfflineExtensionItem.self, category: "WebOfflineExtensionItem")

/// 当且仅当离线包FG开启的时候可以注册这个item
@available(*, deprecated, message: "do not use it")
final public class WebOfflineExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "WebOffline"
    let uuid = UUID().uuidString
    
    var timer: Timer?
    let appID: String
    //  https://bytedance.feishu.cn/docx/doxcnaKWKrvl3CmebTX52byWPwh
    let fullWindow: Bool
    
    init(appID: String, browser: WebBrowser) {
        self.appID = appID
        if !ecosyetemWebDependency.offlineEnable() {
            let msg = "offline fg closed, should not register this extension item"
            logger.error(msg)
            assertionFailure(msg)
        }
        if let appids = LarkWebSettings.shared.offlineSettings?.fullWindowInterceptAppIDs {
            if appids.contains("*") {
                logger.info("fullWindowInterceptAppIDs contains *, fullWindow set true")
                fullWindow = true
            } else if appids.contains(appID) {
                logger.info("fullWindowInterceptAppIDs contains \(appID), fullWindow set true")
                fullWindow = true
            } else {
                logger.info("fullWindowInterceptAppIDs not contains \(appID), fullWindow set false")
                fullWindow = false
            }
        } else {
            logger.info("fullWindowInterceptAppIDs is nil, fullWindow set false")
            fullWindow = false
        }
        if LarkWebSettings.shared.offlineSettings?.ajax_hook.inject == .larkweb_offline {
            logger.info("ajax_hook.inject == .larkweb_offline, setupAjaxHook in WebOfflineExtensionItem init")
            browser.webview.setupAjaxHook()
        }
    }
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = WebOfflineWebBrowserLifeCycle(uuid: uuid, item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = WebOfflineWebBrowserNavigation(uuid: uuid, item: self)
    
    func startTimer() {
        if fullWindow == true {
            logger.info("fullWindow is true, need no timer")
            return
        }
        logger.info("start offline enable/disable timer")
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        let timeout: TimeInterval = 60
        timer = Timer(timeInterval: timeout, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            logger.info("offline enable/disable timer timeout")
            WebOfflineURLProtocolManager.shared.stopOffline(with: self.uuid)
        })
    }
    
    func cancelTimer() {
        logger.info("cancel offline enable/disable timer")
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        cancelTimer()
    }
    
}

final public class WebOfflineWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    
    let uuid: String
    
    weak var item: WebOfflineExtensionItem?
    
    init(uuid: String, item: WebOfflineExtensionItem) {
        self.uuid = uuid
        self.item = item
        if item.fullWindow {
            WebOfflineURLProtocolManager.shared.startOffline(with: uuid)
        }
    }

    public func webBrowserDeinit(browser: WebBrowser) {
        logger.info("webBrowserDeinit and stop Offline Intercept")
        WebOfflineURLProtocolManager.shared.stopOffline(with: uuid)
        //WebBrowser 包管理内存清理操作
        let uniqueID = OPAppUniqueID(appID: self.item?.appID ?? "",
                                     identifier: nil,
                                     versionType: .current,
                                     appType: .webApp,
                                     instanceID: browser.configuration.webBrowserID)
        OPWebAppManager.sharedInstance.cleanWebAppInMemory(uniqueID: uniqueID)
        item?.cancelTimer()
    }
}

final public class WebOfflineWebBrowserNavigation: WebBrowserNavigationProtocol {
    
    let uuid: String
    
    weak var item: WebOfflineExtensionItem?
    
    init(uuid: String, item: WebOfflineExtensionItem?) {
        self.uuid = uuid
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, decidePolicyFor navigationAction: WKNavigationAction) -> WKNavigationActionPolicy {
        let startDate = Date()
        let isOfflineResources = OfflineResourcesTool.canIntercept(with: navigationAction.request)
        let costTime = Date().timeIntervalSince(startDate)
        logger.info("decidePolicyFor navigationAction, pkgmanager.canIntercept cost time is \(costTime), isOfflineResources: \(isOfflineResources)")
        if isOfflineResources {
            if item?.fullWindow == true {
                logger.info("fullWindow is true, just register urlprotocol in init")
            } else {
            WebOfflineURLProtocolManager.shared.startOffline(with: uuid)
            item?.startTimer()
            }
        }
        return .allow
    }

    public func browser(_ browser: WebBrowser, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        logger.info("didFailProvisionalNavigation")
        if WKNavigationDelegateFailFix.isFatalWebError(error: error) {
            if item?.fullWindow == true {
                logger.info("fullWindow is true, just unregister urlprotocol in deinit")
            } else {
            WebOfflineURLProtocolManager.shared.stopOffline(with: uuid)
            item?.cancelTimer()
            }
        }
    }

    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        logger.info("didFinish navigation")
        if item?.fullWindow == true {
            logger.info("fullWindow is true, just unregister urlprotocol in deinit")
        } else {
        WebOfflineURLProtocolManager.shared.stopOffline(with: uuid)
        item?.cancelTimer()
        }
    }

    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        logger.info("didFail navigation")
        if WKNavigationDelegateFailFix.isFatalWebError(error: error) {
            if item?.fullWindow == true {
                logger.info("fullWindow is true, just unregister urlprotocol in deinit")
            } else {
            WebOfflineURLProtocolManager.shared.stopOffline(with: uuid)
            item?.cancelTimer()
            }
        }
    }
    
    public func browserWebContentProcessDidTerminate(_ browser: WebBrowser) {
        logger.info("browserWebContentProcessDidTerminate")
        if item?.fullWindow == true {
            logger.info("fullWindow is true, just unregister urlprotocol in deinit")
        } else {
        WebOfflineURLProtocolManager.shared.stopOffline(with: uuid)
        item?.cancelTimer()
        }
    }
}

extension WebBrowserMenuContext {
    public var isOfflineMode: Bool {
        guard let browser = webBrowser else { return false }
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.offline.v2")) {// user:global
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
