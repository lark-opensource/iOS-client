import WebKit

private var ajaxFetchHookInjectedKey: UInt = 0
private var ajaxFetchHookInjectedValue = "injected"

extension LarkWebView {
    private func injectAjaxHook() {
        guard let hookJSString = larkWebViewDependency.ajaxFetchHookString() else {
            logger.lkwlog(level: .error, "injectAjaxHook failed, cannot get ajaxHookJSString from pkg manager", traceId: opTraceId())
            return
        }
        objc_setAssociatedObject(self, &ajaxFetchHookInjectedKey, ajaxFetchHookInjectedValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        ajaxFetchHookBridge.setAjaxFetchHook()
        let forMainFrameOnly: Bool
        if let iframe = LarkWebSettings.shared.offlineSettings?.ajax_hook.iframe {
            switch iframe {
            case .all:
                forMainFrameOnly = false
            case .none:
                forMainFrameOnly = true
            }
        } else {
            forMainFrameOnly = true
        }
        logger.lkwlog(level: .info, "will inject js code and ajax_hook.iframe is \(LarkWebSettings.shared.offlineSettings?.ajax_hook.iframe.rawValue) and forMainFrameOnly is \(forMainFrameOnly)", traceId: opTraceId())
        let userScript = WKUserScript(source: hookJSString, injectionTime: .atDocumentStart, forMainFrameOnly: forMainFrameOnly)
        configuration.userContentController.addUserScript(userScript)
    }
}

extension LarkWebView {
    public func setupAjaxHook() {
        guard !hasInjectedHookJS() else {
            logger.lkwlog(level: .info, "has injected hook js", traceId: opTraceId())
            return
        }
        injectAjaxHook()
    }
    
    private func hasInjectedHookJS() -> Bool {
        if let string = objc_getAssociatedObject(self, &ajaxFetchHookInjectedKey) as? String, string == ajaxFetchHookInjectedValue {
            return true
        } else {
            return false
        }
    }
}
