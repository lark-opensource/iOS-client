//
//  OpenNativeBaseComponent.swift
//  TTMicroApp
//
//  Created by yi on 2021/8/4.
//
// iOS Native组件接入文档：https://bytedance.feishu.cn/docs/doccnYMmoEgR4hV1koieRp43b5b

import Foundation
import LKCommonsLogging
import LarkWebViewContainer
import ECOProbe
import LarkOpenAPIModel

/// for override
public protocol OpenNativeBaseComponentProtocol: AnyObject {
    
    func getNativeView(dealedData: [AnyHashable : Any], trace: OPTrace, webView: LarkWebView, callback: @escaping (OpenComponentInsertResponse) -> Void)
    
    func dispatchAction(methodName: String, data: [AnyHashable : Any], trace: OPTrace, webView: LarkWebView, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void)
}

// web组件基类
open class OpenNativeBaseComponent: NSObject, OpenNativeBaseComponentProtocol {
    public internal(set) var renderType: OpenNativeComponentRenderType = .native_component_sandwich
    public internal(set) var type = ""
    public weak var webView: LarkWebView? = nil
    public internal(set) var componentID = ""
    var identify = ""
    
    // 组件标签名字
    open class func nativeComponentName() -> String {
        return ""
    }

    //需要响应自定义手势的视图.
    //Note: 当触摸落在传入视图上时,会禁用WKContentView的手势. 可能会影响一些界面操作;
    open func respondCustomGestureViews() -> [UIView]? {
        return nil
    }

    // 组件插入接收
    // params：透传前端标签属性
    // 返回值：view
    open func insert(params: [AnyHashable: Any]) -> UIView? {
        return nil
    }
    
    open func insert(params: [AnyHashable: Any], trace: OPTrace) -> UIView? {
        return insert(params: params)
    }
    
    func insert(params: [AnyHashable: Any], trace: OPTrace, callback: @escaping (OpenComponentInsertResponse) -> Void) {
        if let view = insert(params: params, trace: trace) {
            callback(.success(view: view))
        } else {
            let error = OpenAPIError(errno: OpenNativeInfraErrnoInsert.internalError)
                    .setNativeComponentError(OpenNativeComponentBridgeAPIError.bizError)
            callback(.failure(error: error))
        }
    }
    
    open func viewDidInsert(success: Bool) { }

    // 组件更新
    // nativeView： 插入的视图
    // params：透传前端标签属性
    open func update(nativeView: UIView?, params: [AnyHashable: Any]) {

    }
    
    open func update(nativeView: UIView?, params: [AnyHashable: Any], trace: OPTrace) {
        return update(nativeView: nativeView, params: params)
    }

    // 组件删除
    open func delete() {
    }
    
    open func delete(trace: OPTrace?) {
        return delete()
    }

    // 发送事件到JS
    // event：事件名字
    // params：参数
    public func fireEvent(event: String, params: [AnyHashable : Any]) {

        var data: [String : Any] = [:]
        data["type"] = Self.nativeComponentName()
        data["data"] = params
        data["event"] = event
        data["id"] = identify
        data["renderID"] = componentID

        if let webView = webView {
            webView.op_nativeComponentBridge?.fireEvent(event: "nativeComponentAction", params: data)
        }
    }

    // 接收JS派发的消息
    // methodName： JS派发到native的事件名字
    // data：透传的数据
    open func dispatchAction(methodName: String, data: [AnyHashable: Any]) {

    }
    
    open func dispatchAction(methodName: String, data: [AnyHashable: Any], trace: OPTrace) {
        dispatchAction(methodName: methodName, data: data)
    }

    func setupWebView(view: LarkWebView) {
        webView = view
    }
    
    // MARK: OpenNativeBaseComponentProtocol
    
    open func getNativeView(dealedData: [AnyHashable : Any], trace: OPTrace, webView: LarkWebView, callback: @escaping (OpenComponentInsertResponse) -> Void) {
        insert(params: dealedData, trace: trace, callback: callback)
    }
    
    open func dispatchAction(methodName: String, data: [AnyHashable : Any], trace: OPTrace, webView: LarkWebView, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void) {
        dispatchAction(methodName: methodName, data: data, trace: trace)
        callback(.success(data: nil))
    }
}
