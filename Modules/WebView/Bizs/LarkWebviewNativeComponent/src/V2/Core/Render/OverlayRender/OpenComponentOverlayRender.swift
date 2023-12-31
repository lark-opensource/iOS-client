//
//  OpenComponentOverlayRender.swift
//  OPPlugin
//
//  Created by yi on 2021/8/11.
//
// 非同层组件渲染处理类

import Foundation
import WebKit
import LKCommonsLogging
import ECOProbe
import LarkWebViewContainer

final class OpenComponentOverlayRender: OpenComponentRenderProtocol {
    static private let logger = Logger.oplog(OpenNativeComponentBridgeAPIHandler.self, category: "LarkWebviewNativeComponent")

    static func insertComponent(webView: LarkWebView, view: UIView, componentID: String, style: [String : Any]?, completion: @escaping (Bool)->Void) {
        
        let overlayManager = webView.op_nativeComponentManager().overlayManager
        
        guard !componentID.isEmpty else {
            // 没有传入则端上生成id
            Self.logger.error("OverlayRender, insertComponent param componentID is empty!")
            completion(false)
            return
        }
        var container: UIView
        if let fixed = style?["fixed"] as? Bool, fixed {
            container = webView
        } else {
            container = webView.scrollView
        }
        let success = overlayManager.insertComponentView(view: view, container: container, stringID: componentID)
        completion(success)
    }
    
    static func updateComponent(webView: LarkWebView, componentID: String, style: [String : Any]?) {
        // update 更新逻辑
        guard let fixed = style?["fixed"] as? Bool else {
            return
        }
        // 显式存在的时候再做变更
        var container: UIView
        if fixed {
            container = webView
        } else {
            container = webView.scrollView
        }
        let overlayManager = webView.op_nativeComponentManager().overlayManager
        guard let nativeView = overlayManager.findComponentView(stringID: componentID) else {
            // cannot find nativeView
            Self.logger.error("OverlayRender, updateComponent with \(componentID), but cannot find native view")
            return
        }
        if container != nativeView.superview {
            Self.logger.info("OverlayRender, updateComponent with \(componentID), superview is changed because of the fixed property is \(fixed)")
            container.addSubview(nativeView)
        }
    }

    static func removeComponent(webView: LarkWebView, componentID: String) -> Bool {
        return webView.op_nativeComponentManager().overlayManager.removeComponentView(stringID: componentID)
    }

    static func component(webView: LarkWebView, componentID: String) -> UIView? {
        return webView.op_nativeComponentManager().overlayManager.findComponentView(stringID: componentID)
    }
}
