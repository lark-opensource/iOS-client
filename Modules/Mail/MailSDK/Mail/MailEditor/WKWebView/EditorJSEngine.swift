//
//  File.swift
//  MailSDK
//
//  Created by majx on 2019/6/18.
//

import Foundation
import RxSwift

protocol EditorJSEngine: AnyObject, EditorExecJSService {
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)
    func simulateJSMessage(_ msg: String, params: [String: Any])
    var isBusy: Bool { get set }
    var webView: MailNewBaseWebView { get }
    var webViewIdentity: String { get }
}

extension EditorJSEngine {
    func simulateJSMessage(_ msg: String, params: [String: Any]) { }
}
