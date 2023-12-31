//
//  JSBridgeManager.swift
//  LarkWebviewNativeComponent
//
//  Created by tefeng liu on 2020/10/30.
//

import Foundation
import LarkWebViewContainer

typealias JSBridgeHandler = (_ params: [String: Any], _ callback: APICallbackProtocol) -> Void

final class JSBridgeManager {
    var methodMap: [String: JSBridgeHandler] = [:]

    /// 因为组件依赖lkwebview，所以不抽象接口。
    weak var webview: LarkWebView?
}

// MARK: public interface
extension JSBridgeManager {

    /// 调用 Native -> JS
    /// - Parameters:
    ///   - event: 事件名
    ///   - params: 参数
    func fireEvent(event: String, params: [String: Any], id: String) {
        let name = "window.onLKNativeRenderComponentEvent && window.onLKNativeRenderComponentEvent"
        var data: [String: Any] = [:]
        data["id"] = id
        data["action"] = event
        data["params"] = params
        webview?.lkwBridge.evaluateJS(functionName: name, params: data)
    }

    /// 响应 JS -> Native 调用之前注册进去的方法
    /// - Parameters:
    ///   - method: 方法名
    ///   - params: 参数
    ///   - callback: 回调
    func handle(method: String, params: [String: Any], callback: APICallbackProtocol) {
        // 一些校验判断
        // 取出对应的handler
        guard let handler = methodMap[method] else {
            return
        }
        handler(params, callback)
    }


    /// 注册 JS -> Native 的响应方法
    /// - Parameters:
    ///   - methodName: 方法名字
    ///   - handler: callback
    func registerHandler(methodName: String, handler: @escaping JSBridgeHandler) {
        methodMap[methodName] = handler
    }
}
