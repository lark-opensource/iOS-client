//
//  OpenNativeComponentMessageHandler.swift
//  LarkWebviewNativeComponent
//
//  Created by yi on 2021/9/1.
//
// 组件bridge 消息接收

import Foundation
import LarkWebViewContainer
import LKCommonsLogging
import ECOProbe

final class OpenNativeComponentMessageHandler: WebAPIHandler {

    public override var shouldInvokeInMainThread: Bool {
        true
    }
    weak var bridge: OpenNativeComponentBridge?

    public init(bridge: OpenNativeComponentBridge?) {
        self.bridge = bridge
    }

    public override func invoke(with message: APIMessage, webview: LarkWebView, callback: APICallbackProtocol) {
        let params = message.data
        let componentID = params["renderID"] as? String ?? ""
        let type = params["type"] as? String ?? ""
        let identify = params["id"] as? String ?? ""
        let method = params["method"] as? String ?? ""
        let renderType = params["finalRenderType"] as? String ?? ""
        var componentHide = false
        if let bizData = params["data"] as? [AnyHashable: Any], let style = bizData["style"] as? [AnyHashable: Any] {
            let hide = style["hide"] as? Bool ?? false
            let invisible = style["invisible"] as? Bool ?? false
            componentHide = hide || invisible
        }
        let trace = OPTraceService.default().generateTrace(withParent: webview.trace, bizName: message.apiName)
        OPMonitor(name: "op_api_invoke",
                  code:  OPMonitorCode(domain: "client.open_platform.api.common",
                                       code: 10002,
                                       level: OPMonitorLevelNormal,
                                       message: "native_receive_invoke"))
        .addCategoryValue("api_name", message.apiName)
        .addCategoryValue("is_native_component", 1)
        .addCategoryValue("native_component_type", type)
        .addCategoryValue("native_component_method", method)
        .addCategoryValue("render_type", renderType)
        .addCategoryValue("app_id", bridge?.appID)
        .addCategoryValue("native_component_hide", componentHide)
        .tracing(trace)
        .flush()
        let callbackInvoke = OPMonitor(name: "op_api_invoke",
                                       code: OPMonitorCode(domain: "client.open_platform.api.common",
                                                           code: 10003,
                                                           level: OPMonitorLevelNormal,
                                                           message: "native_callback_invoke"))
            .addCategoryValue("api_name", message.apiName)
            .addCategoryValue("is_native_component", 1)
            .addCategoryValue("native_component_type", type)
            .addCategoryValue("native_component_method", method)
            .addCategoryValue("native_component_hide", componentHide)
            .tracing(trace)
            .timing()
        trace.info("MessageHandler, invoke start, message \(message.apiName) type \(type) componentID \(componentID) identify \(identify) method \(method)")

        if let bridge = bridge {
            bridge.handle(message: message.apiName, params: message.data, trace: trace) { response, renderType in
                switch response {
                case let .success(data: data):
                    callback.callbackSuccess(param: data?.toJSONDict() ?? [:])
                    callbackInvoke
                        .addCategoryValue("renderType", renderType?.rawValue)
                        .setResultTypeSuccess()
                        .timing()
                        .flush()
                    trace.info("MessageHandler, invoke success, message \(message.apiName) type \(type) componentID \(componentID) identify \(identify) method \(method)")
                    trace.finish()
                case let .failure(error: error):
                    callback.callbackFailure(param: error.errnoInfo)
                    callbackInvoke
                        .addCategoryValue("renderType", renderType?.rawValue)
                        .addCategoryValue("innerMsg", error.monitorMsg)
                        .addCategoryValue("innerCode", error.innerCode)
                        .setResultTypeFail()
                        .timing()
                        .flush()
                    trace.error("MessageHandler, invoke fail, innerMsg \(error.monitorMsg ?? ""), innerCode \(error.innerCode ?? 0), message \(message.apiName) type \(type) componentID \(componentID) identify \(identify) method \(method)")
                    trace.finish()
                }
            }
        } else {
            callback.callbackFailure(param: [:])
            callbackInvoke
                .addCategoryValue("innerMsg", OpenNativeComponentMessageError.noBridge.innerErrorMsg)
                .addCategoryValue("innerCode", OpenNativeComponentMessageError.noBridge.innerCode)
                .setResultTypeFail()
                .timing()
                .flush()
            trace.error("MessageHandler, invoke fail, bridge is nil, message \(message.apiName) type \(type) componentID \(componentID) identify \(identify) method \(method)")
            trace.finish()
            return
        }
    }
}
