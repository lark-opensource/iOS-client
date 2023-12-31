//
//  LarkWebView+Extensions.swift
//  WebBrowser
//
//  Created by houjihu on 2020/10/2.
//

import ECOInfra
import LarkLocalizations
import LKCommonsLogging
import WebKit
import LarkSetting

// code from houzhiyou，等window.open彻底实现之后就可以删了这个函数。and houzhiyou'code from lichen
extension URLRequest {
    /// 设置request的Referer
    /// fix https://jira.bytedance.com/browse/SUITE-13006
    /// 需求背景：
    /// 我们非常关注 webview 对 window.open window.close window.location.href=XXX window.location.replace window.history window.referer window.opener window.parent 等API的支持和表现，
    /// 希望在android 和 ios下表现一致，实在不能做到一致给我们个文档，说明下webview的处理逻辑也行。
    /// OA集成了几个分散的系统，系统间会有互相打开和跳转的逻辑，对提高大佬儿们的审批效率意义重大，辛苦lark的同学出一套解决方案
    /// 需求经办人：@qihongye
    func lwvc_fixReferer(referer: String?) -> URLRequest {
        var request = self
        let refererKey = "Referer"
        if request.allHTTPHeaderFields?[refererKey] == nil, let referer = referer {
            request.setValue(referer, forHTTPHeaderField: refererKey)
            WebBrowser.logger.info("refererecoSafeURL: \(URL(string: referer)?.safeURLString)")
        }
        return request
    }
    
    func lwvc_setTimeoutInterval() -> URLRequest {
        var request = self
        guard FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.web.load_no_response_timeout.enable") else {// user:global
            return request
        }
        guard let interval = ErrorPageWebBrowserNavigation.pendingTime else {
            return request
        }
        request.timeoutInterval = interval
        WebBrowser.logger.info("lwvc_setTimeoutInterval pendingTime: \(interval)")
        return request
    }
}

public extension WKWebView {
    /// 同时兼容loadFileURL和loadRequest
    func lwvc_loadRequest(_ urlRequest: URLRequest, prevUrl: URL? = nil) {
        WebBrowser.logger.info("load urlRequest: \(urlRequest.url?.safeURLString), prevURL: \(prevUrl?.safeURLString)")
        var urlRequest = urlRequest.lwvc_fixReferer(referer: prevUrl?.absoluteString).lwvc_setTimeoutInterval()
        if let url = urlRequest.url,
            url.isFileURL {
            loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            return
        }
        #if DEBUG || BETA || ALPHA
        WebBrowserDebugItem.enbaleAddHeaderIfInDebugEnvironment(request: &urlRequest)
        #endif
        load(urlRequest)
    }
}

public extension UIView {
    /// 视图是否可见
    /// - Returns: 是否可见
    func isVisible() -> Bool {
        guard let window = window else {
            return false
        }
        guard !window.isHidden, !isHidden else {
            return false
        }
        return alpha > 0
    }
}
