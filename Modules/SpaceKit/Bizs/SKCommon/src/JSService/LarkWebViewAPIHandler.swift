//
//  LarkWebViewAPIHandler.swift
//  SKUIKit
//
//  Created by lijuyou on 2020/10/14.
//  临时适配LarkWebView新Bridge，通过转发方式转发到旧Bridge，等到旧WebView删除后，再一起重构Bridge，实现新的Bridge Handler


import Foundation
import LarkWebViewContainer
import SKFoundation

public final class LarkWebViewAPIHandler: WebAPIHandler {

    weak var jsServiceManager: JSServicesManager?
    public private(set) var lastCallTime: TimeInterval = 0.0 //上次WebView调用时间截

    public override var shouldInvokeInMainThread: Bool {
        false
    }

    public init(jsServiceManager: JSServicesManager?) {
        self.jsServiceManager = jsServiceManager
    }

    public override func invoke(with message: APIMessage, webview: LarkWebView, callback: APICallbackProtocol) {
        guard let jsServiceManager = jsServiceManager else {
            DocsLogger.error("APIHandler's jsServiceManager is nil")
            return
        }
        jsServiceManager.handle(message: message.apiName, message.data, callback: callback)
        
        let method = message.apiName
        let params = message.data
        let webViewId = "\(ObjectIdentifier(webview))"
        let currentUrl = webview.url
        lastCallTime = Date().timeIntervalSince1970
        PowerConsumptionExtendedStatistic.trackJSCall(method: method, params: params, webViewId: webViewId, currentUrl: currentUrl)
    }
    
    deinit {
        DocsLogger.info("LarkWebViewAPIHandler deinit")
    }
}
