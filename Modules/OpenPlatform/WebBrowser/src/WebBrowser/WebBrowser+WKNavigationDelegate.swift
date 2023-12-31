//
//  WebBrowser+WKNavigationDelegate.swift
//  WebBrowser
//
//  Created by 新竹路车神 on 2020/10/2.
//

import ECOInfra
import LarkOPInterface
import LarkSetting
import WebKit
import ZeroTrust
import LarkWebViewContainer

extension WebBrowser: WKNavigationDelegate {
    /// decide
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        Self.logger.lkwlog(level: .info, "decidePolicyFor navigationAction, navigationAction.request.url.safeURLString:\(navigationAction.request.url?.safeURLString)", traceId: traceId(from: webView))
        var decision: WKNavigationActionPolicy = .allow
        extensionManager.items.forEach {
            let startTime = Date().timeIntervalSince1970
            if let dec = $0.navigationDelegate?.browser(self, decidePolicyFor: navigationAction) {
                if dec != .allow {
                    decision = dec
                }
            }
            self.recordExtensionItemTimeConsumingIn(phase: .navigationPolicy, duration: Date().timeIntervalSince1970 - startTime, itemName: $0.itemName)
        }
        switch decision {
        case .cancel:
            decisionHandler(decision)
        case .allow:
            // 继续交给内部异步逻辑处理，内部逻辑务必回调 decisionHandler ，否则会阻塞网页加载
            internalWebView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
        case .download:
            decisionHandler(decision)
        @unknown default:
            decisionHandler(decision)
        }
    }

    /// decide action
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        Self.logger.lkwlog(level: .info, "decidePolicyFor navigationResponse, navigationResponse.response.url.safeURLString:\(navigationResponse.response.url?.safeURLString)", traceId: traceId(from: webView))
        var decision: WKNavigationResponsePolicy = .allow
        extensionManager.items.forEach {
            let startTime = Date().timeIntervalSince1970
            if let dec = $0.navigationDelegate?.browser(self, decidePolicyFor: navigationResponse) {
                if dec != .allow {
                    decision = dec
                }
            }
            self.recordExtensionItemTimeConsumingIn(phase: .navigationResponse, duration: Date().timeIntervalSince1970 - startTime, itemName: $0.itemName)
        }
        switch decision {
        case .cancel:
            decisionHandler(decision)
        case .allow:
            // 继续交给内部异步逻辑处理，内部逻辑务必回调 decisionHandler ，否则会阻塞网页加载
            internalWebView(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
        case .download:
            decisionHandler(decision)
        @unknown default:
            decisionHandler(decision)
        }
    }

    ///  begin to receive web content   走到这里，webkit会生成一个webpage对象 
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        Self.logger.lkwlog(level: .info, "didCommit navigation, webView.url.safeURLString:\(webView.url?.safeURLString)", traceId: traceId(from: webView))
        internalWebView(webView, didCommit: navigation)
        extensionManager.items.forEach {
            let startTime = Date().timeIntervalSince1970
            $0.navigationDelegate?.browser(self, didCommit: navigation)
            self.recordExtensionItemTimeConsumingIn(phase: .webCommit, duration: Date().timeIntervalSince1970 - startTime, itemName: $0.itemName)
        }
    }

    /// start
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Self.logger.lkwlog(level: .info, "didStartProvisionalNavigation navigation, webview.url.safeURLString:\(webView.url?.safeURLString)", traceId: traceId(from: webView))
        processStage = .HasStartedURL
        extensionManager.items.forEach {
            let startTime = Date().timeIntervalSince1970
            $0.navigationDelegate?.browser(self, didStartProvisionalNavigation: navigation)
            self.recordExtensionItemTimeConsumingIn(phase: .navigationStart, duration: Date().timeIntervalSince1970 - startTime, itemName: $0.itemName)
        }
    }

    /// start failed
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Self.logger.lkwlog(level: .error, "didFailProvisionalNavigation navigation", traceId: traceId(from: webView), error: error)
        processStage = .HasFailedURL
        extensionManager.items.forEach {
            $0.navigationDelegate?.browser(self, didFailProvisionalNavigation: navigation, withError: error)
        }
    }

    /// finish
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Self.logger.lkwlog(level: .info, "didFinish navigation, webview.url.safeURLString:\(webView.url?.safeURLString)", traceId: traceId(from: webView))
        processStage = .HasFinishedURL
        extensionManager.items.forEach {
            $0.navigationDelegate?.browser(self, didFinish: navigation)
        }
    }

    /// nav failed
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Self.logger.lkwlog(level: .error, "didFail navigation", traceId: traceId(from: webView), error: error)
        processStage = .HasFailedURL
        extensionManager.items.forEach {
            $0.navigationDelegate?.browser(self, didFail: navigation, withError: error)
        }
    }

    /// recieve server redirect
    public func webView(_ webView: WKWebView,
                        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        Self.logger.lkwlog(level: .info, "didReceiveServerRedirectForProvisionalNavigation navigation, webview.url.safeURLString:\(webView.url?.safeURLString)", traceId: traceId(from: webView))
        extensionManager.items.forEach {
            let startTime = Date().timeIntervalSince1970
            $0.navigationDelegate?.browser(self, didReceiveServerRedirectForProvisionalNavigation: navigation)
            self.recordExtensionItemTimeConsumingIn(phase: .webRedirect, duration: Date().timeIntervalSince1970 - startTime, itemName: $0.itemName)
        }
    }

    /// web terminate
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        Self.logger.lkwlog(level: .error, "webViewWebContentProcessDidTerminate, webview address: \(webview), displayURL.safeURLString: \(browserURL?.safeURLString)", traceId: traceId(from: webView))
        processStage = .DidTerminate
        extensionManager.items.forEach {
            $0.navigationDelegate?.browserWebContentProcessDidTerminate(self)
        }
    }

    /// 认证挑战 技术对接人：kongkaikai
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let startTime = Date().timeIntervalSince1970
        let traceId = traceId(from: webView)
        defer {
            self.recordBrowserTimeConsumingIn(phase: .webChallenge, duration: Date().timeIntervalSince1970 - startTime)
        }
        Self.logger.lkwlog(level: .info, "didReceive challenge, webview.url.safeURLString:\(webView.url?.safeURLString)", traceId: traceId)
        // check fg and method
        guard FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: ZeroTrustConfig.zeroTrustFeatureGatingKey)),// user:global
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate else {
            Self.logger.lkwlog(level: .error, "ZeroTrust: not open fg.", traceId: traceId)
            completionHandler(.performDefaultHandling, nil)
            return
        }
        // check host
        guard let urlString = webView.url?.absoluteString,
              let hosts = ZeroTrustConfig.fixedSupportHost,
              hosts.contains(where: { urlString.contains($0) }) else {
            Self.logger.lkwlog(level: .error, "ZeroTrust: no matched host.", traceId: traceId)
            completionHandler(.performDefaultHandling, nil)
            return
        }
        var error: Error?
        // check cert
        guard let security = CertTool.read(with: ZeroTrustConfig.fixedSaveP12Label, error: &error) else {
            challenge.sender?.cancel(challenge)
            Self.logger.lkwlog(level: .error, "ZeroTrust: read cert faile.", traceId: traceId)
            completionHandler(.rejectProtectionSpace, .none)
            return
        }
        completionHandler(
            .useCredential,
            URLCredential(
                identity: security.0,
                certificates: security.1,
                persistence: .permanent
            )
        )
    }
    
    func traceId(from webView: WKWebView) -> String? {
        guard let webview = webView as? LarkWebView else {
            return nil
        }
        return webview.opTraceId()
    }
}
