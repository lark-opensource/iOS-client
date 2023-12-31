//
//  WebBrowser+InternalWKNavigationDelegate.swift
//  WebBrowser
//
//  Created by yinyuan on 2021/11/3.
//

import SnapKit
import WebKit
import LarkSetting

/// 仅 WebBrowser 内部 first level code 可写在这里，其他逻辑请走 extension item 方式
extension WebBrowser {
    
    /// 内部逻辑务必回调 decisionHandler ，否则会阻塞网页加载
    func internalWebView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {
        if webDriveDownloadPreviewEnable() || Self.webDrivePreviewEnhancedEnable() {
            self.driveBrowser(self, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
        } else {
            decisionHandler(.allow)
        }
    }

    func internalWebView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        /// 下载能力插件处理, 内部逻辑务必回调 decisionHandler ，否则会阻塞网页加载
        if webDriveDownloadPreviewEnable() || Self.webDrivePreviewEnhancedEnable() {
            self.driveBrowser(self, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
        } else {
            DownloadExtensionItem().browser(self, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
        }
    }
    
    func internalWebView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        let needFixWebviewForDarkMode = (webView.superview == nil) || webView.isHidden == true
        guard enableDarkModeOptimization, needFixWebviewForDarkMode else { return }
        
        if webView.superview == nil {
            view.insertSubview(webview, at: 0)
            // 横屏safearea适配开关，默认不开，开启后走5.14.0之前逻辑
            if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.landscape.safearea.inset.disable")) { // user:global
                // 5.14.0之前逻辑,稳定后可删除
                webview.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            } else {
                // 5.14.0 及以后逻辑
                self.updateWebViewConstraint()
            }
        }
        
        if webView.isHidden == true {
            webView.isHidden = false
        }
    }
}
