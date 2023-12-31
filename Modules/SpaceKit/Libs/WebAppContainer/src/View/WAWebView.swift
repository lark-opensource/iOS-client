//
//  WAWebView.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/10/23.
//

import Foundation
import LarkWebViewContainer
import EENavigator
import LKCommonsLogging
import SKFoundation

class WAWebView: LarkWebView {
    static let logger = Logger.log(WAWebView.self, category: WALogger.TAG)
    
    private static let interceptSchemes: Set<String> = ["http", "https"] //TODO: config this
    weak var interceptor: WAResourceInterceptor?
    weak var container: WAContainer? {
        didSet {
            interceptor?.dataDelegate = container?.hostOfflineManager
        }
    }
    
    convenience init(
        frame: CGRect,
        configuration: WKWebViewConfiguration,
        vConsoleEnable: Bool = false,
        interceptEnable: Bool = true,
        bizType: LarkWebViewBizType = LarkWebViewBizType.unknown,
        disableClearBridgeContext: Bool = false
    ) {
        let config = LarkWebViewConfigBuilder()
            .setWebViewConfig(configuration)
            .setDisableClearBridgeContext(disableClearBridgeContext)
            .build(
                bizType: bizType,
                isAutoSyncCookie: true,
                vConsoleEnable: vConsoleEnable,
                promptFGSystemEnable: false
            )
        let interceptor = WAResourceInterceptor()
        if interceptEnable {
            config.webViewConfig.registerIntercept(schemes: Self.interceptSchemes, delegate: interceptor)
        }
        self.init(frame: frame, config: config, parentTrace: nil, webviewDelegate: nil)
        self.scrollView.keyboardDismissMode = .interactive
        self.navigationDelegate = self
        self.uiDelegate = self
        self.webviewDelegate = self
        self.interceptor = interceptor
    }
}


extension WAWebView: LarkWebViewDelegate {
    @objc public func buildCustomUserAgent() -> String? {
        let ua = WAHttpDefine.defaultWebViewUA
        return ua
    }
}

extension WAWebView: WKNavigationDelegate {
    
    //WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        Self.logger.info("webview decidePolicyFor actionType:\(navigationAction.navigationType)",tag: LogTag.open.rawValue)
        guard let container else { return }
        container.lifeCycleObserver.container(container, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Self.logger.info("webview didStartProvisionalNavigation",tag: LogTag.open.rawValue)
        guard let container else { return }
        container.lifeCycleObserver.container(container, didStartProvisionalNavigation: navigation)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { 
        Self.logger.error("webview didFailProvisionalNavigation",tag: LogTag.open.rawValue, error: error)
        guard let container else { return }
        container.lifeCycleObserver.container(container, didFailProvisionalNavigation: navigation, withError: error)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { 
        Self.logger.info("webview didCommit", tag: LogTag.open.rawValue)
        guard let container else { return }
        container.lifeCycleObserver.container(container, didCommit: navigation)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { 
        Self.logger.info("webview didFinish", tag: LogTag.open.rawValue)
        guard let container else { return }
        container.lifeCycleObserver.container(container, didFinish: navigation)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { 
        Self.logger.error("webview didFail",tag: LogTag.open.rawValue, error: error)
        guard let container else { return }
        container.lifeCycleObserver.container(container, didFail: navigation, withError: error)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) { 
        Self.logger.warn("webview didReceiveServerRedirectForProvisionalNavigation", tag: LogTag.open.rawValue)
        guard let container else { return }
        container.lifeCycleObserver.container(container, didReceiveServerRedirectForProvisionalNavigation: navigation)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) { 
        Self.logger.info("webview decidePolicyFor Rsp",tag: LogTag.open.rawValue)
        guard let container else { return }
        container.lifeCycleObserver.container(container,
                                        decidePolicyFor: navigationResponse,
                                        decisionHandler: decisionHandler)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        Self.logger.error("webview DidTerminate",tag: LogTag.open.rawValue)
        guard let container else { return }
        container.lifeCycleObserver.containerWebContentProcessDidTerminate(container)
    }
}

extension WAWebView: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let container else { return nil}
        return container.lifeCycleObserver.container(container,
                                               createWebViewWith: configuration,
                                               for: navigationAction,
                                               windowFeatures: windowFeatures)
    }
}
