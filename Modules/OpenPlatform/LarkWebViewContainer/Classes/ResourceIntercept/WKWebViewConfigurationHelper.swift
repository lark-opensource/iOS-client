import WebKit
extension WKWebViewConfiguration {
    public func registerIntercept(schemes: Set<String>, delegate: WKResourceInterceptProtocol) {
        guard Thread.isMainThread else {
            assertionFailure("call in main thread")
            return
        }
        WKWebView.schemeHandlerSupport(schemes: schemes)
        let resourceInterceptWKURLSchemeHandler = ResourceInterceptWKURLSchemeHandler(delegate: delegate)
        for scheme in schemes {
            setURLSchemeHandler(resourceInterceptWKURLSchemeHandler, forURLScheme: scheme)
        }
        let userScript = WKUserScript(source: delegate.jssdk, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)
        userContentController.add(SchemeHandlerHelperScriptMessageHandler(), name: schemeHandlerHelperHandlerName)
    }
}
