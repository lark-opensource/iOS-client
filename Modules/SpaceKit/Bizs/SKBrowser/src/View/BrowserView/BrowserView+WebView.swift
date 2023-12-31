//
//  BrowserView+WebView.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/10/15.
//  


import SKFoundation
import WebKit
import SKUIKit
import SKCommon
import LarkWebviewNativeComponent
import LarkWebViewContainer

extension WebBrowserView {

    /// 创建WebView
    class func makeDefaultWebView(
        webViewConfiguration: WKWebViewConfiguration? = nil,
        bizType: LarkWebViewBizType = LarkWebViewBizType.docs,
        disableClearBridgeContext: Bool = false
    ) -> DocsWebViewProtocol {
        
        let webViewConfig: WKWebViewConfiguration
        
        if let webViewConfiguration = webViewConfiguration {
            webViewConfig = webViewConfiguration
        } else {
        webViewConfig = WKWebViewConfiguration()
        // 注入是否支持同层渲染接口，前端通过是否支持同层渲染判断是否降级。
        webViewConfig.lnc_injectJSNativeComponentConfig()
        webViewConfig.websiteDataStore = WKWebsiteDataStore.default()
        webViewConfig.allowsInlineMediaPlayback = true
        webViewConfig.setURLSchemeHandler(DocSourceSchemeHandler(), forURLScheme: DocSourceURLProtocolService.scheme)
        webViewConfig.setURLSchemeHandler(NativeRequestSchemeHandler(), forURLScheme: "nativerequest")
        }
        var vConsoleEnable = false
        #if BETA || ALPHA || DEBUG
        vConsoleEnable = DocsDebugConstant.isVconsoleEnable
        #endif
        let webView: DocsWebViewProtocol = DocsWebViewV2(
            frame: .zero,
            configuration: webViewConfig,
            vConsoleEnable: vConsoleEnable,
            disableClearBridgeContext: disableClearBridgeContext
        )
        webView.tryFixDarkModeWhitePage()
        DocsLogger.info("[webview] create \(type(of: webView).description())")
        if UserScopeNoChangeFG.LJY.enableResetWKProcessPool {
            DocsLogger.info("[webview] create with pool:\(ObjectIdentifier(webView.configuration.processPool))")
        }

        webView.skEditorViewInputAccessory.realInputAccessoryView = nil
        return webView
    }

    func registerBridge() {
        if let lkWebView = self.webView as? DocsWebViewV2 {
            //DocsWebViewV2
            let bridge = lkWebView.lkwBridge
            bridge.registerBridge()
            let commonHandler = LarkWebViewAPIHandler(jsServiceManager: self.jsServiceManager)
            self.jsServiceManager.lkwBridge = bridge
            self.jsServiceManager.lkwAPIHandler = commonHandler
            LarkNativeComponent.enableNativeComponent(webView: lkWebView, components: [DriveFileBlockComponent.self])
        } else {
            //DocsWebView
            // self -> webView -> ... -> message handler -> leakAvoider -> [weak] delegate -> self
            //  ↘ ----------------------------------------- ↗
            let name = "invoke"
            self.scriptMessageHandlerNames.insert(name)
            self.webView.configuration.userContentController.add(self.leakAvoider, name: name)
        }
    }

    func unRegisterBridge() {
        if let lkWebView = self.webView as? DocsWebViewV2 {
            //DocsWebViewV2
            lkWebView.lkwBridge.unregisterBridge()
        } else {
            //DocsWebView
            self.scriptMessageHandlerNames.forEach { (name) in
                self.webView.configuration.userContentController.removeScriptMessageHandler(forName: name)
            }
        }
    }

    func isLarkWebView() -> Bool {
        return self.webView.isKind(of: DocsWebViewV2.self)
    }
}


// MARK: - WKScriptMessageHandler
extension WebBrowserView: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "invoke", let body = message.body as? [String: Any],
            let method = body["method"] as? String,
            let agrs = body["args"] as? [String: Any] else {
                spaceAssertionFailure()
                DocsLogger.severe("cannot handle js request", error: nil, component: nil)
                return
        }
        let strlength = String(describing: body).lengthOfBytes(using: .utf8)
        if strlength > 1024 * 1024 * 2 {
            DocsLogger.info("WKScriptMessage length over max")
        }
        jsServiceManager.handle(message: method, agrs)
    }
}
