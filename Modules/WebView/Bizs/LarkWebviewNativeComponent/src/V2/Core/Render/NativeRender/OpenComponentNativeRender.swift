//
//  OpenComponentNativeRender.swift
//  OPPlugin
//
//  Created by yi on 2021/8/11.
//
// 同层组件渲染处理类

import Foundation
import WebKit
import LarkWebViewContainer
import LKCommonsLogging
import ECOProbe

final class OpenComponentNativeRender: OpenComponentRenderProtocol {

    static func updateComponent(webView: LarkWebView, componentID: String, style: [String : Any]?) {
        
    }

    static private let logger = Logger.oplog(OpenNativeComponentBridgeAPIHandler.self, category: "LarkWebviewNativeComponent")

    static func insertComponent(webView: LarkWebView, view: UIView, componentID: String, style: [String : Any]?, completion: @escaping (Bool) -> Void) {
        webView.insertComponent(view: view, atIndex: componentID, completion: completion)
    }

    static func removeComponent(webView: LarkWebView, componentID: String) -> Bool {
        return webView.removeComponent(index: componentID)
    }

    static func component(webView: LarkWebView, componentID: String) -> UIView? {
        let nativeView = webView.component(fromIndex: componentID)
        return nativeView
    }
}
