//
//  SKPluginRender.swift
//  SpacePlugin
//
//  Created by Webster on 2019/5/15.
//

import Foundation
import WebKit
import SKCommon
import LarkWebViewContainer

public protocol SKExecJSService: AnyObject {
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)
}

public final class SKPluginRender {
    private let readyHandler: SKNotifyReadyJsHandler = SKNotifyReadyJsHandler()
    private var jsManager: JSServicesManager = JSServicesManager()
    private var readyToRender: Bool = false
    private var renderInfo: String?
    private weak var jsEngine: SKExecJSService?
    
    public init(jsEngine: SKExecJSService) {
        self.jsEngine = jsEngine
        readyHandler.delegate = self
        jsManager.register(handler: readyHandler)
    }
    public func register(_ handler: JSServiceHandler) {
        jsManager.register(handler: handler)
    }

    public func unRegister(handlers toRemove: [JSServiceHandler]) {
        jsManager.unRegister(handlers: toRemove)
    }
    
    public func handleJs(message: String, _ params: [String: Any], callback: APICallbackProtocol? = nil) {
        jsManager.handle(message: message, params, callback: callback)
    }

    public func render(_ info: String) {
        renderInfo = info
        if readyToRender {
            callJsToRender()
        }
    }

    private func callJsToRender() {
        guard let realInfo = renderInfo else { return }
        let renderStr = DocsJSCallBack.windowRender.rawValue + "('\(realInfo)')"
        jsEngine?.evaluateJavaScript(renderStr, completionHandler: nil)
    }
}

extension SKPluginRender: SKNotifyReadyJsDelegate {
    func hasUpdateJsReady(_ ready: Bool, handler: SKNotifyReadyJsHandler) {
        self.readyToRender = ready
        callJsToRender()
    }
}
