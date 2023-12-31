//
//  LarkWebViewSecLinkServiceProtocol.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/10.
//

import Foundation
import WebKit

/// 套件统一WebView安全🔗检测服务
@objc public protocol LarkWebViewSecLinkServiceProtocol {
    func webView(_ webView: LarkWebView, decidePolicyFor navigationResponse: WKNavigationResponse)

    func webView(_ webView: LarkWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void)

    func webViewDidFinish(url: URL?)

    func webViewDidFailProvisionalNavigation(error: Error, url: URL?)

    func webViewDidFail(error: Error, url: URL?)
    
    func seclinkPrecheck(url:URL, checkReuslt:@escaping (Bool) -> Swift.Void)
}
