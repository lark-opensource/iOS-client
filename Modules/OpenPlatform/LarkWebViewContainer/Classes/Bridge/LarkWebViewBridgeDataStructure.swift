//
//  LarkWebViewBridgeDataStructure.swift
//  WebView
//
//  Created by 新竹路车神 on 2020/8/26.
//

import LarkOPInterface
import WebKit

/// 网页的 APIHandler 父类 请不要直接使用，一定要继承并且override apiName 和 invoke （套件统一API框架上线后废弃该结构）
open class WebAPIHandler: APIHandlerProtocol {
    /// 是否主线程执行 默认否
    open var shouldInvokeInMainThread: Bool {
        assertionFailure(overrideMessage)
        return false
    }

    public init() {
    }

    public func invoke(with message: APIMessage, context: Any, callback: APICallbackProtocol) {
        guard let webview = context as? LarkWebView else {
            return
        }
        invoke(with: message, webview: webview, callback: callback)
    }

    /// API实现
    /// - Parameters:
    ///   - message: API 信息数据结构
    ///   - context: API 上下文
    ///   - apiCallback: 回调对象
    open func invoke(
        with message: APIMessage,
        webview: LarkWebView,
        callback: APICallbackProtocol
    ) {
        assertionFailure(overrideMessage)
    }
}
