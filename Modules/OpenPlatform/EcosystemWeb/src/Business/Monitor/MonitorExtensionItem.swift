//
//  MonitorExtensionItem.swift
//  WebBrowser
//
//  Created by yinyuan on 2022/4/27.
//

import ECOProbe
import LarkWebViewContainer
import LKCommonsLogging
import WebBrowser
import WebKit
import LarkSetting

private let logger = Logger.webBrowserLog(MonitorExtensionItem.self, category: "MonitorExtensionItem")

final public class MonitorExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "Monitor"
    public var lifecycleDelegate: WebBrowserLifeCycleProtocol? = MonitorWebBrowserLifeCycle()
    
//    public var navigationDelegate: WebBrowserNavigationProtocol? = MonitorWebBrowserNavigation()
    
    public var browserDelegate: WebBrowserProtocol? = MonitorWebBrowserDelegate()
    
    public init() {
        
    }
}

final public class MonitorWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    
    let webViewInspectorFixDisable: Bool = FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.inspector.didcreatefix.disable"))

    public func viewDidLoad(browser: WebBrowser) {
        if !webViewInspectorFixDisable {
            browser.webview.lkwb_monitor.setMonitorData(key: WebContainerMonitorEventKey.appID.rawValue, value: browser.appInfoForCurrentWebpage?.id)
            browser.webview.createTime = NSDate().timeIntervalSince1970
        }
        
        // 埋点：要求在网页容器 WebBrowserVC.view 创建完成时上报
        OPMonitor(.containerCreated, browser: browser).flush()
        
        //业务埋点, 时机对齐品质的.containerCreated
        OPMonitor(.h5ApplicationLaunch, browser: browser)
            .addCategoryValue("h5app_id", browser.configuration.appId ?? "")
            .addCategoryValue("h5app_url", browser.browserURL?.safeURLString ?? "")
            .setPlatform([.tea])
            .flush()
    }
    
    // 不可靠的通知，如果插件注册晚于webview创建会收不到这个通知，不推荐使用
    public func webviewDidCreated(_ browser: WebBrowser, webview: LarkWebView) {
        // webview 创建后需要立即绑定外部传入的 app_id
        if webViewInspectorFixDisable {
            webview.lkwb_monitor.setMonitorData(key: WebContainerMonitorEventKey.appID.rawValue, value: browser.appInfoForCurrentWebpage?.id)
            webview.createTime = NSDate().timeIntervalSince1970
        }
        
    }

    public func viewDidAppear(browser: WebBrowser, animated: Bool) {
        OPMonitor(.containerAppear, browser: browser)
            .tracing(browser.webview.trace)
            .flush()
    }
    
    
    public func viewWillDisappear(browser: WebBrowser, animated: Bool) {
        let webview:LarkWebView = browser.webview
        webview.disappearTime = NSDate().timeIntervalSince1970
        OPMonitor(.containerDisappear, browser: browser)
            .tracing(browser.webview.trace)
            .flush()
    }
    
    public func webBrowserDeinit(browser: WebBrowser) {
        let webview:LarkWebView = browser.webview
        var timeduration:TimeInterval = (webview.disappearTime - webview.createTime) * 1000
        OPMonitor(.containerDestroyed, browser: browser)
            .setBrowserDuration(timeduration)
            .setBrowserStage(browser.processStage)
            .tracing(browser.webview.trace)
            .flush()
    }
    
}

//final public class MonitorWebBrowserNavigation: WebBrowserNavigationProtocol {
//
//}

final public class MonitorWebBrowserDelegate: WebBrowserProtocol {
    
    public func browser(_ browser: WebBrowser, willLoadURL url: URL) {
        // 埋点：首次加载URL
        if browser.webview.url == nil && browser.webview.backForwardList.backList.isEmpty && browser.webview.backForwardList.forwardList.isEmpty && browser.webview.backForwardList.currentItem == nil {
            // 埋点：在首次加载 url 时上报
            var duration:TimeInterval = 0
            if let start = browser.configuration.startHandleTime {
                duration = Date().timeIntervalSince1970 - start
            }
            OPMonitor(.containerLoadPrepareDuration, browser: browser)
                .setWebURL(url)
                .setDuration(duration)
                .setWebAppID(browser.configuration.appId)
                .flush()
            
            OPMonitor(.containerFirstLoadUrl, browser: browser)
                .setWebURL(url)
                .setWebAppID(browser.configuration.appId)
                .flush()
        }
    }
}
