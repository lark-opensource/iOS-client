//
//  LarkWebViewCache.swift
//  LarkWebViewContainer
//
//  Created by houjihu on 2020/8/13.
//

import Foundation
import LKCommonsLogging
import WebKit
import ECOProbe
import ECOInfra

/// WebView缓存池，SDK内部默认
class SubPoolManager: NSObject {
    let maxRenderTimes = 5
    let maxReloadTimes = 10
    let logger = Logger.lkwlog(LarkWebView.self, category: "SubPoolManager")

    /// 重用的webview队列
    private var webviewQueue: WebViewQueue
    private let trace: OPTrace

    let config: LarkWebViewConfig
    let poolConfig: LarkWebviewPoolConfig
    var isTemplateReadyConfig: Bool {
        return poolConfig is LarkWebviewFileTemplatePoolConfig || poolConfig is LarkWebviewRequestTemplatePoolConfig
    }

    var getWebViewCallbacks = [GetWebViewCallback]()
    /// Init your sub pool with a webview config and pool config
    /// - parameter webviewConfig: The config that use to create webview
    /// - parameter poolConfig: The config that defines how the pool works
    required init(config: LarkWebViewConfig, poolConfig: LarkWebviewPoolConfig) {
        self.config = config
        self.poolConfig = poolConfig
        self.webviewQueue = WebViewQueue(capacity: poolConfig.capacity)
        self.trace = OPTraceService.default().generateTrace()
        super.init()
        webviewQueue.delegate = self
        fillupIfNeeded()
    }

    /// create a new webview
    fileprivate func createWebView() -> LarkWebView {
        let webview = LarkWebView(frame: .zero, config: config, parentTrace: self.trace)
        return webview
    }

    /// Get a webview from the pool
    /// - returns: A larkwebview instance
    func dequeueWebView() -> LarkWebView {
        let webview = webviewQueue.getItem() ?? createWebView()
        updateWebviewUsageStatus(webview)
        return webview
    }

    /// Get a template ready webview from the pool
    /// - parameter completion: this block will be called once the webview is ready
    func dequeueTemplateReadyWebView(completion: @escaping GetWebViewCallback) {
        if let readyWebview = webviewQueue.getTemplateReadyItem() {
            updateWebviewUsageStatus(readyWebview)
            completion(readyWebview)
        } else {
            getWebViewCallbacks.append(completion)
        }
    }

    /// Reclaim the webview into the pool
    /// - parameter webview: The webview instance you want to reclaim
    func reclaim(webview: LarkWebView) {
        guard webview.renderTimes < maxRenderTimes else {
            return
        }
        // reset the delegate to self in order to monitor navigation error and process terminate
        webview.navigationDelegate = self
        if isTemplateReadyConfig {
            webview.isTemplateReady = false
            webview.reload()
        }
        webviewQueue.append(item: webview)
        webview.prepare(initTrace: webview.config.initTrace, parent: self.trace)
    }

    /// update the webview's status everytimes it' been used
    func updateWebviewUsageStatus(_ webview: LarkWebView) {
        webview.renderTimes += 1
        webview.navigationDelegate = nil
    }

    /// Fill the pool with one single webview instance when it's empty
    func fillupIfNeeded() {
        guard webviewQueue.isEmpty else { return }
        logger.info("fillup pool")
        let webview = createWebView()
        webview.navigationDelegate = self
        if let templatePoolConfig = poolConfig as? LarkWebviewRequestTemplatePoolConfig {
            webview.load(templatePoolConfig.request)
        } else if let templatePoolConfig = poolConfig as? LarkWebviewFileTemplatePoolConfig {
            webview.loadFileURL(templatePoolConfig.fileURL, allowingReadAccessTo: templatePoolConfig.readAccessURL)
        }
        webviewQueue.append(item: webview)
    }
}

extension SubPoolManager: OPTraceContextProtocol {
    public func opTrace() -> OPTrace? {
        return self.trace
    }
}

extension SubPoolManager: WebViewQueueDelegate {
    func queueDidBecomeEmpty() {
        fillupIfNeeded()
    }
}

extension SubPoolManager: WKNavigationDelegate {
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        guard let larkWebView = webView as? LarkWebView else {
            OPError.error(monitorCode: PoolMonitorCode.webviewTypeError, message: "current class \(type(of: webView).description())")
            return
        }
        OPMonitor(.wbPoolTerminate, webview: larkWebView).flush()
        // must remove the webview from the queue, because it's broken and unusable
        webviewQueue.remove(item: larkWebView)
        larkWebView.isTemplateReady = false
        larkWebView.reloadTimes += 1
        if larkWebView.reloadTimes < maxReloadTimes {
            larkWebView.reload()
        }
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard let larkWebView = webView as? LarkWebView else {
            OPError.error(monitorCode: PoolMonitorCode.webviewTypeError, message: "current class \(type(of: webView).description())")
            return
        }
        OPMonitor(.wbPoolDidFail, webview: larkWebView).flush()
        webviewQueue.remove(item: larkWebView)
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard let larkWebView = webView as? LarkWebView else {
            OPError.error(monitorCode: PoolMonitorCode.webviewTypeError, message: "current class \(type(of: webView).description())")
            return
        }
        OPMonitor(.wbPoolDidFailProvisionalNavigation, webview: larkWebView).flush()
        webviewQueue.remove(item: larkWebView)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let larkWebView = webView as? LarkWebView else {
            OPError.error(monitorCode: PoolMonitorCode.webviewTypeError, message: "current class \(type(of: webView).description())")
            return
        }
        OPMonitor(.wbPoolFinishLoad, webview: larkWebView).flush()
        larkWebView.isTemplateReady = true
        if getWebViewCallbacks.isEmpty {
            webviewQueue.append(item: larkWebView)
        } else {
            let callback = getWebViewCallbacks.removeFirst()
            callback(larkWebView)
        }
    }
}
