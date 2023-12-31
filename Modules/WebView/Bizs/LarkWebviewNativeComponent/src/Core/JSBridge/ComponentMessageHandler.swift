//
//  ComponentMessageHandler.swift
//  LarkWebviewNativeComponent
//
//  Created by tefeng liu on 2020/10/30.
//

import Foundation
import LarkWebViewContainer

final class ComponentMessageHandler: APIHandlerProtocol {
    /// 承载网页的视图控制器
    private weak var webview: LarkWebView?

    init(webview: LarkWebView?) {
        self.webview = webview
    }

    var shouldInvokeInMainThread: Bool {
        return true
    }

    func invoke(with message: APIMessage, context: Any, callback: APICallbackProtocol) {
        guard let method = message.data["methodName"] as? String else {
            lkAssertionFailure("没有方法名")
            return
        }

        guard let params = message.data["data"] as? [String: Any] else {
            lkAssertionFailure("没有参数")
            return
        }

        webview?.componetBridge.handle(method: method, params: params, callback: callback)
    }
}

