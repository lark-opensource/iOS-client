//
//  OfflineResourceExtensionItem.swift
//  WebBrowser
//
//  Created by yinyuan on 2022/1/17.
//
import LarkWebViewContainer
import LKCommonsLogging
import WebKit

private let logger = Logger.webBrowserLog(OfflineResourceExtensionItem.self, category: "OfflineResourceExtensionItem")

public protocol OfflineResourceProtocol: AnyObject {

    /// 是否需要拦截请求
    /// - Returns: 是否拦截
    func browserCanIntercept(browser: WebBrowser, request: URLRequest) -> Bool

    /// 返回请求资源
    func browserFetchResources(browser: WebBrowser, request: URLRequest, completionHandler: @escaping (Result<(URLResponse, Data), Error>) -> Void)
}

/// 当且仅当离线包FG开启的时候可以注册这个item
final public class OfflineResourceExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "OfflineResource"
    let browserID: String

    fileprivate weak var browser: WebBrowser?
    
    var timer: Timer?
    let appID: String
    //  https://bytedance.feishu.cn/docx/doxcnaKWKrvl3CmebTX52byWPwh
    let fullWindow: Bool
    
    public private(set) weak var delegate: OfflineResourceProtocol?
    
    public init(appID: String, browser: WebBrowser, delegate: OfflineResourceProtocol) {
        self.appID = appID
        self.browser = browser
        self.delegate = delegate
        self.browserID = browser.configuration.webBrowserID
//        if !ecosyetemWebDependency.offlineEnable() {
//            let msg = "offline fg closed, should not register this extension item"
//            logger.error(msg)
//            assertionFailure(msg)
//        }
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
            logger.info("ajax_hook.inject == .larkweb_offline, setupAjaxHook in OfflineResourceExtensionItem init")
            browser.webview.setupAjaxHook()
        }
    }
    
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = OfflineResourceWebBrowserLifeCycle(browserID: browserID, item: self)
    
    public lazy var navigationDelegate: WebBrowserNavigationProtocol? = OfflineResourceWebBrowserNavigation(browserID: browserID, item: self)
    
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
            OfflineResourceURLProtocolManager.shared.stopOffline(with: self.browserID)
        })
    }
    
    func cancelTimer() {
        logger.info("cancel offline enable/disable timer")
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        OfflineResourceURLProtocolManager.shared.stopOffline(with: browserID)
        cancelTimer()
    }
    
}

final public class OfflineResourceWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    
    let browserID: String
    
    weak var item: OfflineResourceExtensionItem?
    
    init(browserID: String, item: OfflineResourceExtensionItem) {
        self.browserID = browserID
        self.item = item
        if item.fullWindow, let browser = item.browser {
            OfflineResourceURLProtocolManager.shared.startOffline(with: browser)
            item.startTimer()
        }
    }

    public func webBrowserDeinit(browser: WebBrowser) {
        logger.info("webBrowserDeinit and stop Offline Intercept")
        OfflineResourceURLProtocolManager.shared.stopOffline(with: browserID)
        //WebBrowser 包管理内存清理操作
//        let uniqueID = OPAppUniqueID(appID: self.item?.appID ?? "",
//                                     identifier: nil,
//                                     versionType: .current,
//                                     appType: .webApp,
//                                     instanceID: browser.configuration.webBrowserID)
//        OPWebAppManager.sharedInstance.cleanWebAppInMemory(uniqueID: uniqueID)
        item?.cancelTimer()
    }
}

final public class OfflineResourceWebBrowserNavigation: WebBrowserNavigationProtocol {
    
    let browserID: String
    
    weak var item: OfflineResourceExtensionItem?
    
    init(browserID: String, item: OfflineResourceExtensionItem?) {
        self.browserID = browserID
        self.item = item
    }
    
    public func browser(_ browser: WebBrowser, decidePolicyFor navigationAction: WKNavigationAction) -> WKNavigationActionPolicy {
        let startDate = Date()
        let isOfflineResources = item?.delegate?.browserCanIntercept(browser: browser, request: navigationAction.request)
        let costTime = Date().timeIntervalSince(startDate)
        logger.info("decidePolicyFor navigationAction, pkgmanager.canIntercept cost time is \(costTime), isOfflineResources: \(isOfflineResources)")
        if isOfflineResources == true {
            if item?.fullWindow == true {
                logger.info("fullWindow is true, just register urlprotocol in init")
            } else {
                OfflineResourceURLProtocolManager.shared.startOffline(with: browser)
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
                OfflineResourceURLProtocolManager.shared.stopOffline(with: browserID)
                item?.cancelTimer()
            }
        }
    }

    public func browser(_ browser: WebBrowser, didFinish navigation: WKNavigation!) {
        logger.info("didFinish navigation")
        if item?.fullWindow == true {
            logger.info("fullWindow is true, just unregister urlprotocol in deinit")
        } else {
            OfflineResourceURLProtocolManager.shared.stopOffline(with: browserID)
            item?.cancelTimer()
        }
    }

    public func browser(_ browser: WebBrowser, didFail navigation: WKNavigation!, withError error: Error) {
        logger.info("didFail navigation")
        if WKNavigationDelegateFailFix.isFatalWebError(error: error) {
            if item?.fullWindow == true {
                logger.info("fullWindow is true, just unregister urlprotocol in deinit")
            } else {
                OfflineResourceURLProtocolManager.shared.stopOffline(with: browserID)
                item?.cancelTimer()
            }
        }
    }
    
    public func browserWebContentProcessDidTerminate(_ browser: WebBrowser) {
        logger.info("browserWebContentProcessDidTerminate")
        if item?.fullWindow == true {
            logger.info("fullWindow is true, just unregister urlprotocol in deinit")
        } else {
            OfflineResourceURLProtocolManager.shared.stopOffline(with: browserID)
            item?.cancelTimer()
        }
    }
}
