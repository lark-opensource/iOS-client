//
//  OPBlockWebWorker.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/3/28.
//

import Foundation
import WebBrowser
import OPSDK
import LarkWebViewContainer
import OPBlockInterface
import TTMicroApp
import LarkContainer

// block web 逻辑层：负责处理webview与native的双向通信
class OPBlockWebWorker: OPNode, OPWorkerProtocol {

    struct BlockAPIEvent {
        let name: String
        let params: [AnyHashable: Any]?
        let extra: [AnyHashable: Any]?
        let callback: OPEventCallbackBlock?
    }

    // native->js消息处理器
    private weak var messagePublisher: WebBrowser?

    // 一期不做runtime ready事件
    public internal(set) var isRuntimeReady: Bool = true
    // 在runtime ready缓存native像js发送的消息，待runtimeReady后统一发送
    public private(set) var eventBuffer: [BlockAPIEvent] = []

    // 复用component的context，内部可取meta等信息
    let context: OPComponentContext
    let userResolver: UserResolver

    // 可使用的native api
    private let useableApis: [String]
    private let apiBridge: OPBlockAPIBridge

    init(context: OPComponentContext, userResolver: UserResolver, messagePublisher: WebBrowser?) {
        self.context = context
        self.userResolver = userResolver
        self.messagePublisher = messagePublisher
        let componentUtils = BlockComponentUtils(
            blockWebComponentConfig: userResolver.settings.staticSetting(),
            apiConfig: userResolver.settings.staticSetting()
        )
        self.useableApis = componentUtils.usableAPIs(for: context.containerContext)
        self.apiBridge = OPBlockAPIBridge(containerContext: context.containerContext)
        super.init()
    }

    // 接收API调用：一般为js -> native
    func invokeAPI(name: String, params: [AnyHashable: Any]?, extra: [AnyHashable: Any]?, callback: @escaping OPEventCallbackBlock) throws {
        guard useableApis.contains(name) else {
            context.containerContext.trace?.error("can not handle api, not in settings",
                                                  additionalData: ["uniqueID": context.containerContext.uniqueID.fullString,
                                                                   "apiName": name])
            callback(OPEventResult(type: OPEventResultType.noHandler.rawValue))
            return
        }
        let eventContext = OPEventContext(userInfo: [:])
        let param = params as? [String: AnyHashable] ?? [:]
        let handled = sendEvent(eventName: name, params: param, callbackBlock: callback, context: eventContext)
        context.containerContext.trace?.info("invoke api handled: \(handled)",
                                             additionalData: ["uniqueID": context.containerContext.uniqueID.fullString,
                                                              "apiName": name])
    }

    func invokeAPIByAPIBridge(name: String, params: [AnyHashable: Any]?, extra: [AnyHashable: Any]?, callback: @escaping BDPJSBridgeCallback) {
        
        let params = params ?? [:]
        apiBridge.invokeApi(apiName: name, param: params) { (status, response) in
            callback(status, response)
        }
        context.containerContext.trace?.info("invoke api",
                                             additionalData: ["uniqueID": context.containerContext.uniqueID.fullString,
                                                              "apiName": name])
    }

    // 触发消息发送: 一般为native -> js
    func publishEvent(name: String, params: [AnyHashable: Any]?, extra: [AnyHashable: Any]?, callback: @escaping OPEventCallbackBlock) throws {
        if isRuntimeReady {
            let message = try LarkWebViewBridge.buildCallBackJavaScriptString(callbackID: name, params: params ?? [:], extra: extra, type: .continued)
            messagePublisher?.webview.evaluateJavaScript(message, completionHandler: { [weak self](result, error) in
                if let err = error {
                    self?.context.containerContext.trace?.error("publish event fail",
                                                                additionalData: ["apiName": name],
                                                                error: err)
                    let result = OPEventResult(type: OPEventResultType.fail.rawValue,
                                               data: nil,
                                               error: err.newOPError(monitorCode: OPSDKMonitorCode.unknown_error))
                    callback(result)
                } else {
                    self?.context.containerContext.trace?.info("publish event success",
                                                               additionalData: ["apiName": name])
                    callback(OPEventResult(type: OPEventResultType.success.rawValue, data: nil, error: nil))
                }
            })
        } else {
            assertionFailure("should not enter here")
            let event = BlockAPIEvent(name: name, params: params, extra: extra, callback: callback)
            eventBuffer.append(event)
        }
    }

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 show 事件, component 通知 worker
    /// worker 按需进行操作， 如开始API调用等
    func onShow() {

    }

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 hide 事件, component 通知 worker
    /// worker 按需进行操作， 如pending API调用等
    func onHide() {

    }

    /// Container 在 destroy 时，告诉 Component 要 destroy 了, component 通知 worker
    /// worker 按需进行操作， 如清除API队列等
    func onDestroy() {

    }

}

