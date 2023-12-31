//
//  OpenNativeComponentBridgeAPIHandler.swift
//  LarkWebviewNativeComponent
//
//  Created by yi on 2021/9/1.
//
// 通用组件API 逻辑处理
// 协议文档：https://bytedance.feishu.cn/docs/doccnHzc6L0voW0kLfAp5WYdq5e

import Foundation
import LarkWebViewContainer
import LKCommonsLogging
import ECOProbe
import LarkOpenAPIModel
import ECOInfra

final class OpenNativeComponentBridgeAPIHandler: NSObject {

    weak var webView: LarkWebView?
    
    func insertNativeComponent(params: [AnyHashable: Any], trace: OPTrace, callback:  @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>, OpenNativeComponentRenderType?) -> Void) {
        guard let (page, componentID, type) = preCheck(params: params, trace: trace, callback: callback) else {
            return
        }
        
        let identify = params["id"] as? String ?? ""
        let data: [AnyHashable: Any] = params["data"] as? [AnyHashable: Any] ?? [:]
        let tag = params["tag"] as? String ?? ""
        
        let renderType: OpenNativeComponentRenderType
        if let finalRenderTypeString = params["finalRenderType"] as? String {
            trace.info("origin finalRenderType: \(finalRenderTypeString)")
            renderType = finalRenderType(of: finalRenderTypeString)
        } else {
            trace.info("no origin finalRenderType")
            renderType = .native_component_sandwich
        }
        
        trace.info("BridgeAPIHandler insertNativeComponent invoke, type \(type) componentID \(componentID) identify \(identify) renderType: \(renderType.rawValue), tag: \(tag)")
        
        OpenNativeComponentInterceptor.classType(type, webView: webView)?.receivedJSInsertEvent(with: componentID, params: params, error: nil)

        page.op_nativeComponentManager().insertComponent(webView: page, type: type, componentID: componentID, identify: identify, renderType: renderType, data: data, trace: trace) { response in
            callback(response, renderType)
        }
    }

    func updateNativeComponent(params: [AnyHashable: Any], trace: OPTrace, callback:  @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>, OpenNativeComponentRenderType?) -> Void) {
        guard let (page, componentID, type) = preCheck(params: params, trace: trace, callback: callback) else {
            return
        }
        
        let identify = params["id"] as? String ?? ""
        let data: [AnyHashable: Any] = params["data"] as? [AnyHashable: Any] ?? [:]
        trace.info("BridgeAPIHandler updateNativeComponent invoke, type \(type) componentID \(componentID) identify \(identify)")
        
        let result = page.op_nativeComponentManager().updateComponent(webView: page, componentID: componentID, data: data, trace: trace)
        if !result {
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.updateComponentFail)
            callback(.failure(error: error), nil)
        } else {
            callback(.success(data: nil), nil)
        }
    }

    func deleteNativeComponent(params: [AnyHashable: Any], trace: OPTrace, callback:  @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>, OpenNativeComponentRenderType?) -> Void) {
        guard let (page, componentID, type) = preCheck(params: params, trace: trace, callback: callback) else {
            return
        }
        let identify = params["id"] as? String ?? ""
        trace.info("BridgeAPIHandler deleteNativeComponent invoke, type \(type) componentID \(componentID) identify \(identify)")

        let result = page.op_nativeComponentManager().removeComponent(webView: page, componentID: componentID, trace: trace)
        if result {
            callback(.success(data: nil), nil)
        } else {
            trace.error("BridgeAPIHandler deleteNativeComponent fail, removeComponent fail, type \(type) componentID \(componentID) identify \(identify)")
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.removeComponentFail)
            callback(.failure(error: error), nil)
        }
    }

    // 组件事件派发
    func nativeComponentDispatchAction(params: [AnyHashable: Any], trace: OPTrace, callback:  @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>, OpenNativeComponentRenderType?) -> Void) {
        guard let (page, componentID, type) = preCheck(params: params, trace: trace, callback: callback) else {
            return
        }
        let identify = params["id"] as? String ?? ""
        let data: [AnyHashable: Any] = params["data"] as? [AnyHashable: Any] ?? [:]
        let method = params["method"] as? String ?? ""
        trace.info("BridgeAPIHandler nativeComponentDispatchAction invoke, type \(type) componentID \(componentID) identify \(identify) method \(method)")

        page.op_nativeComponentManager().nativeComponentDispatchAction(webView: page, componentID: componentID, method: method, data: data, trace: trace, webview: page) { response in
            callback(response, nil)
        }
    }

    // 注册同层协议处理
    func registerHandlers(bridge: OpenNativeComponentBridge, view: LarkWebView) {
        webView = view
        bridge.registerHandler(methodName: OpenNativeAPIName.insertNativeComponent.rawValue) { params, trace, callback in
            self.insertNativeComponent(params: params, trace: trace, callback: callback)
        }
        bridge.registerHandler(methodName: OpenNativeAPIName.updateNativeComponentAttribute.rawValue) { params, trace, callback in
            self.updateNativeComponent(params: params, trace: trace, callback: callback)
        }
        bridge.registerHandler(methodName: OpenNativeAPIName.deleteNativeComponent.rawValue) { params, trace, callback in
            self.deleteNativeComponent(params: params, trace: trace, callback: callback)
        }
        bridge.registerHandler(methodName: OpenNativeAPIName.nativeComponentDispatchAction.rawValue) { params, trace, callback in
            self.nativeComponentDispatchAction(params: params, trace: trace, callback: callback)
        }
    }
}

extension OpenNativeComponentBridgeAPIHandler {
    fileprivate func preCheck(params: [AnyHashable: Any], trace: OPTrace, callback:  @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>, OpenNativeComponentRenderType?) -> Void) -> (LarkWebView, String, String)? {
        guard let page = webView else {
            trace.error("BridgeAPIHandler fail, webView is nil")
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.noWebView)
            callback(.failure(error: error), nil)
            return nil
        }
        guard let componentID = params["renderID"] as? String, let type = params["type"] as? String else {
            trace.error("BridgeAPIHandler fail, renderID or type is nil")
            let error = OpenAPIError(errno: OpenNativeInfraErrnoCommon.internalError)
                .setNativeComponentError(OpenNativeComponentBridgeAPIError.noTypeOrIDParams)
            callback(.failure(error: error), nil)
            return nil
        }
        return (page, componentID, type)
    }
}

/// 默认使用旧同层方案(递归图层查找对应background-color的方案)
fileprivate func finalRenderType(of string: String) -> OpenNativeComponentRenderType {
    guard let type = OpenNativeComponentRenderType(rawValue: string) else {
        return .native_component_sandwich
    }
    return type
}
