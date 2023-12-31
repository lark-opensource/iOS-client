//
//  BDPWebView.swift
//  TTMicroApp
//
//  Created by 新竹路车神 on 2021/2/20.
//

import Foundation
import LarkWebViewContainer
import ECOProbe
import LKCommonsLogging
import ECOInfra
import LarkWebviewNativeComponent

private let log = Logger.oplog(BDPWebView.self, category: NSStringFromClass(BDPWebView.self))

private var bridgeKey: UInt = 0

extension LarkWebView {
    @objc open func setupNativeComponent() {
        // 继承覆写点
    }
}

extension BDPWebView {
    @objc public func setupCommonBridge() {
        lkwBridge.registerBridge()
        lkwBridge.disableMonitor = true
        lkwBridge.set(larkWebViewBridgeDelegate: self)
    }

    /// 发送消息（OC调用请不要传入nil，一旦发现传入nil，需要负crash责任，revert代码，写case study，做复盘）
    @objc public func sendAsyncEventIfFireeventReady(event: String, params: [AnyHashable: Any]) {
        if !isFireEventReady {  //  code from wanghaoyu
            let dic = [
                "event": event,
                "params": params
            ] as [String : Any]
            bwv_fireEventQueue.enqueue(dic)
            return
        }
        sendAsyncEvent(event: event, params: params)
    }
    @objc public func sendAsyncEvent(event: String, params: [AnyHashable: Any]) {
        let jsStr: String
        do {
            jsStr = try LarkWebViewBridge.buildCallBackJavaScriptString(
                callbackID: event,
                params: params,
                extra: nil,
                type: .continued
            )
        } catch {
            log.error("sendAsyncEvent failed, finalMap cannot trans to Data", error: error)
            return
        }
        evaluateJavaScript(jsStr)
    }
}

extension BDPWebView: LarkWebViewBridgeDelegate {
    public func invoke(with message: APIMessage, webview: LarkWebView, callback: APICallbackProtocol) {
        invokeApiName(message.apiName, data: (message.data as NSDictionary).decodeNativeBuffersIfNeed(), callbackID: message.callbackID, extra: message.extra, useNewBridge: true) { (res, status) in
            let response = res as? [String: Any] ?? [String: Any]()
            switch status {
            case .success:
                callback.callbackSuccess(param: response)
            case .userCancel:
                callback.callbackCancel(param: response)
            default:
                callback.callbackFailure(param: response)
            }
        }
    }
}

extension BDPWebView {
    @objc
    public func webviewWillAppear() {
        components?.allObjects.forEach { element in
            element.webviewWillAppear()
        }
    }
    
    @objc
    public func webviewDidAppear() {
        components?.allObjects.forEach { element in
            element.webviewDidAppear()
        }
    }
    
    @objc
    public func webviewWillDisappear() {
        components?.allObjects.forEach { element in
            element.webviewWillDisappear()
        }
    }
    
    @objc
    public func webviewDidDisappear() {
        components?.allObjects.forEach { element in
            element.webviewDidDisappear()
        }
    }
}

private var kBDPComponents: Void?
extension BDPWebView {
    // register
    open func registerLifeCycle(component: BDPWebViewLifeCycleProtocol) {
        if components == nil {
            components = NSHashTable(options: .weakMemory, capacity: 8)
        }
        components?.add(component)
    }
    open func unregisterLifeCycle(component: BDPWebViewLifeCycleProtocol) {
        components?.remove(component)
    }
    
    var components: NSHashTable<BDPWebViewLifeCycleProtocol>? {
        get {
            return (objc_getAssociatedObject(self, &kBDPComponents) as? NSHashTable<BDPWebViewLifeCycleProtocol>)
        }
        set {
            objc_setAssociatedObject(self, &kBDPComponents, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}

@objc
public protocol BDPWebViewLifeCycleProtocol: AnyObject {
    
    func webviewWillAppear()
    func webviewDidAppear()
    
    func webviewWillDisappear()
    func webviewDidDisappear()
}
