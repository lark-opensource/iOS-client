//
//  OpenNativeComponentBridge.swift
//  LarkWebviewNativeComponent
//
//  Created by yi on 2021/9/1.
//
// 组件bridge
// bridge方案：https://bytedance.feishu.cn/docs/doccnmS6nsemMXwTNM1tMIKQTGe

import Foundation
import LarkWebViewContainer
import LKCommonsLogging
import ECOProbe
import LarkOpenAPIModel

// api处理
typealias OpenNativeComponentBridgeHandler = (_ params: [AnyHashable: Any], _ trace: OPTrace, _ callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>, OpenNativeComponentRenderType?) -> Void) -> Void

final class OpenNativeComponentBridge: NSObject {
    static private let logger = Logger.oplog(OpenNativeComponentBridgeAPIHandler.self, category: "NativeComponent")
    weak var webView: LarkWebView?
    var handleMap: [String: OpenNativeComponentBridgeHandler] = [:]
    
    var appID: String?

    // 注册API处理
    func registerHandler(methodName: String, handler: @escaping OpenNativeComponentBridgeHandler) {
        handleMap[methodName] = handler
    }

    // 接收JS消息
    func handle(message: String, params: [AnyHashable: Any], trace: OPTrace, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>, OpenNativeComponentRenderType?) -> Void) {
        guard let handler = handleMap[message] else {
            trace.error("Bridge, handle fail, message not register, message \(message)")
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeError.noHandler)
            callback(.failure(error: error), nil)
            return
        }
        handler(params, trace, callback)
    }

    // 发送事件到JS
    func fireEvent(event: String, params: [AnyHashable: Any]) {
        guard let webView = webView else {
            Self.logger.error("Bridge, fireEvent fail, webView is nil, event \(event)")
            return
        }
        var data = params
        if let encodeData = data as? NSDictionary {
            data = encodeData.encodeNativeBuffersIfNeed()
        }
        let jsStr: String
        do {
            jsStr = try LarkWebViewBridge.buildCallBackJavaScriptString(
                callbackID: event,
                params: data,
                extra: nil,
                type: .continued
            )
        } catch {
            Self.logger.error("Bridge, fireEvent fail, LarkWebViewBridge buildCallBackJavaScriptString error, event \(event)", error: error)
            return
        }
        webView.evaluateJavaScript(jsStr) { (res, error) in
            if let error = error {
                Self.logger.error("Bridge, fireEvent fail, webView evaluateJavaScript error, event \(event)", error: error)
            }
        }
    }
}
