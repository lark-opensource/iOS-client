//
//  InlineAIShowContentJSService.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/5/11.
//

import Foundation
import LarkWebViewContainer

class InlineAIShowContentJSService: InlineAIJSServiceProtocol {
    
    var callback: APICallbackProtocol?
    
    weak var webView: InlineAIWebView?

    weak var delegate: AIWebAPIHandlerDelegate?

    var cacheParams: [String: Any]?

    var handleServices: [InlineAIJSService] {
        return [.renderContent,.renderComplete]
    }
    
    init(webView: InlineAIWebView?, delegate: AIWebAPIHandlerDelegate?) {
        self.webView = webView
        self.delegate = delegate
    }

    func handle(params: [String : Any], serviceName: InlineAIJSService, callback: LarkWebViewContainer.APICallbackProtocol?) {
        LarkInlineAILogger.info("[web] InlineAIShowContentJSService handle \(serviceName)")
        if serviceName == InlineAIJSService.renderContent {
            self.callback = callback
            if let cache = cacheParams {
                LarkInlineAILogger.warn("[web] callback using cache now")
                callJSCallback(cache)
                self.cacheParams = nil
            }
        } else if serviceName == InlineAIJSService.renderComplete {
            LarkInlineAILogger.info("[web] renderComplete: \(params)")
            let contentHeight = params["contentHeight"] as? CGFloat
            self.webView?.contentDidRenderComplete(contentHeight: contentHeight)
        }
    }
    
    func showContent(content: String, extra: [String: Any]?, theme: String, conversationId: String, taskId: String, isFinish: Bool) {
        var param: [String: Any] = ["content": content,
                     "conversationId": conversationId,
                     "taskId": taskId,
                     "theme": theme]
        if let contentExtra = extra, !contentExtra.isEmpty {
            param["contentExtra"] = contentExtra
        }
        if isFinish {
            param["status"] = "finish"
        }
        if let bgColor = webView?.customBackgroundColor {
            param["bgColor"] = bgColor.hexString
        }
        LarkInlineAILogger.info("[web] deliver content to js contentLen: \(content.count)")
        LarkInlineAILogger.debug("[web] deliver content \(param)")
        callJSCallback(param)
    }
    
    private func callJSCallback(_ params: [String: Any]) {
        if callback == nil {
            cacheParams = params
            LarkInlineAILogger.warn("[web] callJSCallback callback is nil")
        } else {
            LarkInlineAILogger.info("[web] deliver content to js")
        }
        callback?.callbackSuccess(param: params)
    }
}
