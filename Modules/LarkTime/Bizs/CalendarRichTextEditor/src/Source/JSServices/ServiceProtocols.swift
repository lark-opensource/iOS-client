//
//  ServiceProtocols.swift
//  RichTextEditor
//
//  Created by chenhuaguan on 2020/6/29.
//

import LarkWebViewContainer

protocol JSServiceHandler: APIHandlerProtocol {
    var handleServices: [JSService] { get }
    func handle(params: [String: Any], serviceName: String)
}

extension JSServiceHandler {
    func invoke(with message: APIMessage, context: Any, callback: APICallbackProtocol) {
        /// LarkWebView的callbackID获取兼容旧bridge方式
        var param = message.data
        param["callback"] = message.callbackID
        handle(params: param, serviceName: message.apiName)
    }

    var shouldInvokeInMainThread: Bool {
        true
    }
}
