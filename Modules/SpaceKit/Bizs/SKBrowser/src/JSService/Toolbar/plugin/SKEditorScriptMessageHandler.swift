//
//  SKEditorScriptMessageHandler.swift
//  SKBrowser
//
//  Created by LiXiaolin on 2020/8/25.
//  


import Foundation
import WebKit

class SKEditorScriptMessageHandler: NSObject, WKScriptMessageHandler {

    var docsJSMessageName = ""
    static let docsJSMethodName = "method"
    static let docsJSArgsName = "args"


    private var pluginRender: SKPluginRender?

    init(_ render: SKPluginRender?) {
        pluginRender = render
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == docsJSMessageName,
            let body = message.body as? [String: Any],
            let method = body[SKEditorScriptMessageHandler.docsJSMethodName] as? String,
            let agrs = body[SKEditorScriptMessageHandler.docsJSArgsName] as? [String: Any] else {
                return
        }
        pluginRender?.handleJs(message: method, agrs)
    }
}
