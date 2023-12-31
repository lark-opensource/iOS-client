//
//  WebBrowserView+SSR.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/6/6.
//  


import Foundation
import LarkWebViewContainer
import SKFoundation
import SKUIKit
import SKCommon
import SKResource
import SpaceInterface
import SKInfra
import LarkContainer

extension WebBrowserView {
    
    /// 尝试使用独立WebView渲染SSR（唯一入口）
    func tryRenderSSRWebView(data: [String: Any]?) -> Bool {
        guard self.webLoader?.canRenderCacheInSSRWebView() ?? false else {
            DocsLogger.info("[ssr] tryRenderSSRWebView cancel, fg/ab/setting miss", component: LogComponents.ssrWebView)
            return false
        }
        
        guard self.ssrWebContainer?.hasSSRData != true else {
            spaceAssertionFailure() //不应该多次调用
            DocsLogger.info("[ssr] ssr webview has show", component: LogComponents.ssrWebView)
            return true
        }
        DocsLogger.info("[ssr] show ssr webview", component: LogComponents.ssrWebView)
        self.ssrWebContainer?.removeFromSuperview()
        let ssrWebView = SSRWebViewContainer(hostView: self)
        ssrWebView.delegate = self
        self.ssrWebContainer = ssrWebView
        editorWrapperView.insertSubview(ssrWebView, aboveSubview: self.webView)
        
        ssrWebView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        if let data = data {
            if !ssrWebView.render(ssr: data) {
                hideSSRWebViewIfNeed()
                return false
            }
            return true
        } else if DocHtmlCacheFetchManager.fetchSSRBeforeRenderEnable() {
            //没有SSR，看下是否正在下载中，或者看下是否已经下载完成
            DocsLogger.info("\(LogComponents.fetchSSR)[ssr] show ssr webview without data, try use SSRWebview",
                            component: LogComponents.ssrWebView)
            
            guard let docsInfo = docsInfo else {
                DocsLogger.info("\(LogComponents.fetchSSR)[ssr] show ssr webview docsInfo is nil", component: LogComponents.ssrWebView)
                return false
            }
            
            //使用真实文档token
            let token = docsInfo.token
            let type = docsInfo.inherentType
            
            if let manager = try? Container.shared.getCurrentUserResolver().resolve(type: DocHtmlCacheFetchManager.self) {
                DocsLogger.info("\(LogComponents.fetchSSR)[ssr] show ssr webview begin get html cache",
                                component: LogComponents.ssrWebView)
                manager.getDocHtmlCache(realToken: token, realType: type) { data, _ in
                    
                    DispatchQueue.main.async {
                        DocsLogger.info("\(LogComponents.fetchSSR)[ssr] fetch SSR callback，token:\(token.encryptToken)",
                                        component: LogComponents.ssrWebView)
                        guard let record = data, let cacheHtml = record.payload else {
                            DocsLogger.info("\(LogComponents.fetchSSR)[ssr] fetch SSR callback payload is nil，data：\(String(describing: data)), token:\(token)", component: LogComponents.ssrWebView)
                            return
                        }
                        //处理成data进行render
                        guard let cacheData = self.webLoader?.handleCachedHtml(cacheHtml, record: record) else {
                            DocsLogger.info("\(LogComponents.fetchSSR)[ssr] handleCachedHtml is nil, token:\(token.encryptToken)",
                                            component: LogComponents.ssrWebView)
                            return
                        }
                        if !ssrWebView.render(ssr: cacheData) {
                            DocsLogger.info("\(LogComponents.fetchSSR)[ssr] render fail, token:\(token.encryptToken)",
                                            component: LogComponents.ssrWebView)
                            self.hideSSRWebViewIfNeed()
                            return
                        }
                        DocsLogger.info("\(LogComponents.fetchSSR)[ssr] render success, token:\(token.encryptToken)",
                                        component: LogComponents.ssrWebView)
                    }
                    
                }
                return true
            }
            return false
        }
        return false
    }
    
    func hideSSRWebViewIfNeed(forceClose: Bool = false) {
        if self.ssrWebContainer == nil {
            return
        }
        DocsLogger.info("[ssr] hide ssr webview", component: LogComponents.ssrWebView)
        if forceClose || OpenAPI.docs.enableKeepSSRWebViewTest == false {
            self.ssrWebContainer?.removeFromSuperview()
            self.ssrWebContainer = nil
        }
    }
}

extension WebBrowserView: SSRWebViewContainerDelegate {
    public func onRequestCloseSSRWebView() {
        self.hideSSRWebViewIfNeed(forceClose: true)
    }
    
    public func onRequestHideSSRLoading() {
        loadingDelegate?.updateLoadStatus(.success, oldStatus: nil)
    }
}
