//
//  OpenURLPlugin.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/15.
//

import Foundation
import LKCommonsLogging
import WebKit
import SKFoundation

class OpenURLPlugin: WAPlugin {
    
    override var pluginType: WAPluginType {
        .base
    }
    
    required init(host: WAPluginHost) {
        super.init(host: host)
        host.lifeCycleObserver.addListener(self)
    }
}

extension OpenURLPlugin: WAContainerLifeCycleListener {
    
    func container(_ container: WAContainer, decidePolicyForAction navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let webView = container.hostWebView else { return }
        Self.logger.info("webview open url decidePolicyFor \(navigationAction.navigationType), url:\(navigationAction.request.url?.safeURLString ?? "")")
        
        // iframe
        if let frame = navigationAction.targetFrame, frame.isMainFrame == false {
            decisionHandler(.allow)
            return
        }
        guard let naviUrl = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if let curUrl = webView.url, curUrl == naviUrl {
            decisionHandler(.allow)
            return
        }
        if let hostUrl = container.hostURL, hostUrl == naviUrl {
            decisionHandler(.allow)
            return
        }
        guard let hostVC = self.host?.container.hostVC else {
            Self.logger.error("navigateToUrl must have hostVC")
            decisionHandler(.cancel)
            return
        }
        Self.logger.info("navigateTo lark open")
        hostVC.openUrl(naviUrl)
        decisionHandler(.cancel)
    }
    
    func container(_ container: WAContainer, decidePolicyForResponse navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        Self.logger.info("recv navigationResponse")
        let shouldLoad: Bool = {
            guard let response = navigationResponse.response as? HTTPURLResponse else { return true }
            Self.logger.info("navigationResponse code:\(response.statusCode)")
            switch response.statusCode {
            case DocsNetworkError.HTTPStatusCode.MovedTemporarily.rawValue, DocsNetworkError.HTTPStatusCode.MovedPermanently.rawValue:
                //记录一下重定向，不要拦截
                if let redirectStr = response.allHeaderFields["Location"] as? String {
                    Self.logger.warn("recv \(response.statusCode), redirect to \(redirectStr)")
                }
                return true
            default:
                return true
            }
        }()

        let actionPolicy: WKNavigationResponsePolicy = shouldLoad ? .allow : .cancel
        decisionHandler(actionPolicy)
    }
    
    func container(_ container: WAContainer, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url else {
            Self.logger.error("get empty url")
            return nil
        }
        guard let hostVC = self.host?.container.hostVC else {
            Self.logger.error("openURL must have hostVC")
            return nil
        }
        Self.logger.error("intercept window.open for:\(url.safeURLString)")
        hostVC.openUrl(url)
        return nil
    }
}


