//
//  ServiceProtocols.swift
//  DocsSDK
//
//  Created by guotenghu on 2019/3/13.
//  

import Foundation

protocol EditorJSServiceHandler {
    var handleServices: [EditorJSService] { get }
    func handle(params: [String: Any], serviceName: String)
}

protocol EditorExecJSService: AnyObject {
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)
}
