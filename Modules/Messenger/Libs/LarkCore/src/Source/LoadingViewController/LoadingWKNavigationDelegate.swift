//
//  Temp.swift
//  LarkWeb
//
//  Created by CharlieSu on 3/29/20.
//

import Foundation
import WebKit

@objc
public protocol LoadingWKNavigationDelegate: NSObjectProtocol {
    @objc
    optional func loadingWebview(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)

    @objc
    optional func loadingWebview(_ webView: WKWebView, didFinish navigation: WKNavigation!)

    @objc
    optional func loadingWebview(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void)

    @objc
    optional func loadingWebview(_ webView: WKWebView, decidePolicyResFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void)

    @objc
    optional func loadingWebview(_ webView: WKWebView, didCommit navigation: WKNavigation!)

    @objc
    optional func loadingWebview(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!)

    @objc
    optional func loadingWebview(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error)

    @objc
    optional func loadingWebview(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error)

    @objc
    optional func loadingWebview(_ webView: WKWebView,
                                 didReceive challenge: URLAuthenticationChallenge,
                                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void)

    @objc
    optional func loadingWebviewWebviewWebContentProcessDidTerminate(_ webView: WKWebView)
}
