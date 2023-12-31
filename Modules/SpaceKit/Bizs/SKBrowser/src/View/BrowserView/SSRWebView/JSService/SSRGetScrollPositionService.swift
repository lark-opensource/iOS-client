//
//  SSRGetScrollPositionService.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/5/24.
//  


import Foundation
import SKFoundation
import SKCommon
import SKInfra
import LarkWebViewContainer

public final class SSRGetScrollPositionService: BaseJSService {
    
}

extension SSRGetScrollPositionService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilGetSSRScrollPosition]
    }

    public func handle(params: [String: Any], serviceName: String) {
        spaceAssertionFailure()
    }
    
    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        switch serviceName {
        case DocsJSService.utilGetSSRScrollPosition.rawValue:
            getSSRScrollPosition(callback: callback)
        default:
            spaceAssertionFailure()
        }
    }
    
    func getSSRScrollPosition(callback: APICallbackProtocol?) {
        guard let browserView = self.ui as? WebBrowserView,
        let webview = browserView.ssrWebContainer?.webView else {
            spaceAssertionFailure()
            return
        }
        DocsLogger.info("[ssr] getSSRScrollPosition")
        webview.evaluateJavaScript("javascript:getSSRScrollPos()") { [weak self] result, error in
            guard self != nil else { return }
            if let error = error {
                DocsLogger.error("[ssr] getSSRScrollPos failed with error", error: error)
                return
            }
            guard let data = result as? [String: Any] else {
                DocsLogger.error("[ssr] getSSRScrollPos parse data failed")
                return
            }
            DocsLogger.info("[ssr] getSSRScrollPos with result", extraInfo: ["result": data])
            callback?.callbackSuccess(param: ["result": data])
        }
    }
    
    
    /// 获取SSR滚动位置
    ///   通过promt方式调用，必须保证每个执行路径都有callback调用返回
    /// - Parameters:
    static func getSSRScrollPositionSync(_ browserView: WebBrowserView, callback: @escaping (([String: Any]?) -> Void)) {
        guard OpenAPI.docs.enableSSRWebView else {
            callback(nil)
            return
        }
        guard let webview = browserView.ssrWebContainer?.webView else {
            spaceAssertionFailure()
            DocsLogger.error("[ssr] getSSRScrollPos by webview is nil", component: LogComponents.ssrWebView)
            callback(nil)
            return
        }
        
        // 增加超时时间控制，如果超时没返回，则直接回调nil
        var isTimeout = false
        let timeout: Int = SettingConfig.ssrWebviewConfig?.promtTimeout ?? 100
        DocsLogger.info("[ssr] getSSRScrollPositionSync, timeout:\(timeout)", component: LogComponents.ssrWebView)
        let dispatchWorkItem = DispatchWorkItem {
            isTimeout = true
            DocsLogger.error("[ssr] getSSRScrollPos timeout", component: LogComponents.ssrWebView)
            callback(nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(timeout), execute: dispatchWorkItem)
        
        webview.evaluateJavaScript("javascript:getSSRScrollPos()") { result, error in
            dispatchWorkItem.cancel()
            guard isTimeout == false else {
                // 超时处理过了，不用重复处理
                DocsLogger.error("[ssr] eval getSSRScrollPos is timeout", component: LogComponents.ssrWebView)
                return
            }
            if let error = error {
                DocsLogger.error("[ssr] getSSRScrollPos failed with error", error: error, component: LogComponents.ssrWebView)
                callback(nil)
                return
            }
            guard let data = result as? [String: Any] else {
                DocsLogger.error("[ssr] getSSRScrollPos parse data failed", component: LogComponents.ssrWebView)
                callback(nil)
                return
            }
            DocsLogger.info("[ssr] getSSRScrollPos with result", extraInfo: ["result": data], component: LogComponents.ssrWebView)
            callback(data)
        }
    }
}
