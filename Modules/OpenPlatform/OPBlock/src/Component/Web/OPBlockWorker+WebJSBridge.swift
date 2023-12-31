//
//  OPBlockWorker+WebJSBridge.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/3/31.
//

import Foundation
import WebBrowser
import LarkWebViewContainer
import OPSDK
import LarkOPInterface
import TTMicroApp

// 实现WebBrowserCallAPIProtocol，提供web -> native API通信
// 实现OPBaseBridgeDelegate， 提供native -> web 通信
extension OPBlockWebWorker: WebBrowserCallAPIProtocol {

    private var apiSetting: OPBlockAPISetting? {
        return try? userResolver.resolve(assert: OPBlockAPISetting.self)
    }

    /// 收到API调用
    /// - Parameters:
    ///   - webBrowser: The browser invoking the delegate method.
    ///   - message: API 数据结构
    ///   - callback: 回调对象
    func recieveAPICall(webBrowser: WebBrowser,
                        message: APIMessage,
                        callback: APICallbackProtocol) {
        context.containerContext.trace?.info("receive web api", additionalData: [
            "apiName": message.apiName,
            "url": webBrowser.webview.url?.safeURLString ?? "nil"
        ])
        let useAPIPlugin = apiSetting?.useAPIPlugin(
            host: context.containerContext.uniqueID.host,
            blockTypeId: context.containerContext.uniqueID.identifier,
            apiName: message.apiName
        ) ?? false
        if useAPIPlugin {
            useAPIPluginInvokeAPI(webBrowser: webBrowser, message: message, callback: callback)
            return
        }
        
        do {
            try invokeAPI(name: message.apiName, params: message.data, extra: message.extra) { [weak context] result in
                context?.containerContext.trace?.info("invoke api result", additionalData: [
                    "apiName": message.apiName,
                    "url": webBrowser.webview.url?.safeURLString ?? "nil",
                    "result": result.type
                ])
                let param = OPBlockComponent.callbackData(name: message.apiName, result: result) as? [String: Any] ?? [:]
                if let resultType = OPEventResultType(rawValue: result.type) {
                    switch resultType {
                    case .success:
                        callback.callbackSuccess(param: param)
                    case .fail:
                        callback.callbackFailure(param: param, extra: nil, error: result.error)
                    case .cancel:
                        callback.callbackCancel(param: param, extra: nil, error: result.error)
                    case .noHandler:
                        callback.callbackFailure(param: param, extra: nil, error: result.error)
                    }
                } else {
                    callback.callbackFailure(param: [:], extra: nil, error: OPError.error(monitorCode: OPSDKMonitorCode.unknown_error))
                }
            }
        } catch {
            context.containerContext.trace?.error("try invoke api fail",
                                                  additionalData: ["apiName": message.apiName],
                                                  error: error)
            callback.callbackFailure(param: [:], extra: nil, error: error.newOPError(monitorCode: OPSDKMonitorCode.unknown_error))
        }
    }
    
    func useAPIPluginInvokeAPI(webBrowser: WebBrowser,
                               message: APIMessage,
                               callback: APICallbackProtocol) {
        invokeAPIByAPIBridge(name: message.apiName,
                             params: message.data,
                             extra: message.extra) { [weak context] (status, response) in
            context?.containerContext.trace?.info("invoke api result", additionalData: ["apiName": message.apiName,
                                                                                        "url": webBrowser.webview.url?.safeURLString ?? "nil",
                                                                                        "result": BDPErrorMessageForStatus(status)])
            let param = OPBlockComponent.callbackData(name: message.apiName, status: status, response: response) as? [String: Any] ?? [:]
            let errMsg = response?["errMsg"] as? String ?? ""
            switch status {
            case .success:
                callback.callbackSuccess(param: param)
            case .failed:
                callback.callbackFailure(param: param, extra: nil, error: OPError.error(monitorCode: OWMonitorCodeApi.fail, message: errMsg))
            case .userCancel:
                callback.callbackCancel(param: param, extra: nil, error: OPError.error(monitorCode: OWMonitorCodeApi.cancel, message: errMsg))
            case .noHandler:
                callback.callbackFailure(param: param, extra: nil, error: OPError.error(monitorCode: OWMonitorCodeApi.no_handler, message: errMsg))
            default:
                // 其余情况先收敛到Fail
                callback.callbackFailure(param: [:], extra: nil, error: OPError.error(monitorCode: OPSDKMonitorCode.unknown_error))
            }
        }
    }
 
    /// OPBaseBridgeDelegate: 向js发消息
    func sendEventToBridge(
        eventName: String,
        params: [AnyHashable : Any]?,
        callback: OPBridgeCallback?) throws {
            context.containerContext.trace?.info("native publish event to web",
                                                 additionalData: ["event": eventName])
            callback?(nil)
            // 一期不支持native 向 js发消息
//            try publishEvent(name: eventName, params: params, extra: nil) { result in
//                callback?(nil)
//            }
    }
    
}
