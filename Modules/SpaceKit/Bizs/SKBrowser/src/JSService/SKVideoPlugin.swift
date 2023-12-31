//
//  SKVideoPlugin.swift
//  SpaceKit
//
//  Created by maxiao on 2019/6/11.
//

import UIKit
import WebKit
import SKCommon
import SKFoundation

extension DocsJSService {
    static let SKVideoStyle = DocsJSService(rawValue: "biz.util.setStyle")
}

///////////////////////////////////////////////////////////////////////////
protocol SKVideoHandlerDelegate: AnyObject {
    func videoHandlerDidReceivedCallback(_ callback: String,
                                         _ handler: SKVideoHandler)
}

class SKVideoHandler: JSServiceHandler {

    weak var delegate: SKVideoHandlerDelegate?

    var handleServices: [DocsJSService] {
        return [.SKVideoStyle]
    }

    func handle(params: [String: Any],
                serviceName: String) {
        guard let callback = params["callback"] as? String else { return }
        delegate?.videoHandlerDidReceivedCallback(callback, self)
    }
}

///////////////////////////////////////////////////////////////////////////
public final class SKVideoPlugin {

    private let readyHandler: SKNotifyReadyJsHandler = SKNotifyReadyJsHandler()
    private let videoHandler: SKVideoHandler = SKVideoHandler()
    private var jsManager: JSServicesManager = JSServicesManager()
    private var readyToRender: Bool = false
    private var styleInfoDic: [String: Any]?
    private var callbackName: String?
    private weak var jsEngine: SKExecJSFuncService?

    public init(jsEngine: SKExecJSFuncService) {
        self.jsEngine = jsEngine
        readyHandler.delegate = self
        videoHandler.delegate = self
        jsManager.register(handler: readyHandler)
        jsManager.register(handler: videoHandler)
    }

    public func register(_ handler: JSServiceHandler) {
        jsManager.register(handler: handler)
    }

    public func handleJs(message: String,
                         _ params: [String: Any]) {
        jsManager.handle(message: message, params)
    }

    public func setStyle(_ backgroundColor: String,
                         _ textColor: String) {
        styleInfoDic = ["background": "#\(backgroundColor)", "color": "#\(textColor)"]
        if readyToRender {
            callJsToRender()
        }
    }

    private func callJsToRender() {
        guard let style1nfo = styleInfoDic, let ca11backName = callbackName else { return }

        jsEngine?.callFunction(DocsJSCallBack(ca11backName), params: style1nfo, completion: nil)

    }

}

extension SKVideoPlugin: SKNotifyReadyJsDelegate {
    func hasUpdateJsReady(_ ready: Bool,
                          handler: SKNotifyReadyJsHandler) {
        self.readyToRender = ready
        callJsToRender()
    }
}

extension SKVideoPlugin: SKVideoHandlerDelegate {
    func videoHandlerDidReceivedCallback(_ callback: String,
                                         _ handler: SKVideoHandler) {
        callbackName = callback
    }
}

///////////////////////////////////////////////////////////////////////////
public final class SKVideoScriptHandler: NSObject, WKScriptMessageHandler {

    public static let docsJSMessageName = "invoke"
    public static let docsJSMethodName  = "method"
    public static let docsJSArgsName    = "args"

    private var plugin: SKVideoPlugin?

    public init(_ render: SKVideoPlugin?) {
        self.plugin = render
    }

    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        guard message.name == SKVideoScriptHandler.docsJSMessageName,
            let body = message.body as? [String: Any],
            let method = body[SKVideoScriptHandler.docsJSMethodName] as? String,
            let agrs = body[SKVideoScriptHandler.docsJSArgsName] as? [String: Any] else {
                spaceAssertionFailure("参数不完整")
                return
        }
        plugin?.handleJs(message: method, agrs)
    }
}
