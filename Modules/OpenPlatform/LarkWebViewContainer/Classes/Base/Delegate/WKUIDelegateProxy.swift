//
//  WKUIDelegateProxy.swift
//  LarkWebViewContainer
//
//  Created by houjihu on 2020/9/14.
//

import LarkSetting
import LKCommonsLogging
import WebKit

/// SDK内部的uiDelegate，会调用外部设置的delegate实现.
/// 针对此对象内没有实现的方法，会通过消息派发直接转发到外部设置的delegate
@objcMembers
public final class WKUIDelegateProxy: BaseDelegateProxy, WKUIDelegate {
    /// SDK外部设置的uiDelegate
    var internUIDelegate: WKUIDelegate? {
        get {
            return self.internDelegate as? WKUIDelegate
        }
        set {
            self.internDelegate = newValue
        }
    }

    /// write WKUIDelegate method implementation below, and call internUIDelegate method...
}

extension WKUIDelegateProxy {
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        if prompt == "__LKWebViewAjaxFetchHookStatus__" {
            if ajaxFetchHookFG {
                completionHandler("__LKWebViewAjaxFetchHookStatus_Enable__")
            } else {
                completionHandler(nil)
            }
            return
        }
        // 提供前端的FG通道，各业务方如果有诉求，请开启promptFGSystemEnable，并且前端调用 prompt('__featureGatingValue__', key)
        if let web = webView as? LarkWebView, web.config.promptFGSystemEnable, prompt == "__featureGatingValue__" {
            let fg = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: defaultText ?? ""))// user:global
            logger.lkwlog(level: .info, "front call fg, key is \(defaultText) and return value is \(fg)", traceId: web.opTraceId())
            if fg {
                completionHandler("true")
            } else {
                completionHandler("false")
            }
            return
        }
        if internUIDelegate?.webView?(webView, runJavaScriptTextInputPanelWithPrompt: prompt, defaultText: defaultText, initiatedByFrame: frame, completionHandler: completionHandler) == nil {
            logger.info("not impl prompt")
            completionHandler(nil)
        }
    }
}
