//
//  SKEditorLKWebViewHandler.swift
//  SKBrowser
//
//  Created by zoujie on 2021/6/2.
//  


import Foundation
import SKCommon
import LarkWebViewContainer
import SKFoundation

public final class SKEditorLKWebViewHandler: WebAPIHandler {

    weak var render: SKPluginRender?

    public override var shouldInvokeInMainThread: Bool {
        false
    }

    public init(render: SKPluginRender?) {
        self.render = render
    }

    public override func invoke(with message: APIMessage, webview: LarkWebView, callback: APICallbackProtocol) {
        guard let render = render else {
            DocsLogger.error("APIHandler's render is nil")
            return
        }
        render.handleJs(message: message.apiName, message.data, callback: callback)
    }
}
