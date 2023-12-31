//
//  RichTextContextDefine.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/12.
//

import UIKit
import Foundation

protocol RichTextViewDisplayConfig: AnyObject {
    func setContextMenus(items: [UIMenuItem])

    func updateContentHeight(_ height: CGFloat)

    func pushOnpasteAutoAuth(_ authInfo: [Bool])
}

protocol RichTextViewJSEngine: AnyObject {
    func callFunction(_ function: JSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?)
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)
    func fetchServiceInstance<H: JSServiceHandler>(_ service: H.Type) -> H?
    func simulateJSMessage(_ msg: String, params: [String: Any])
    func jsContextDidReady()
    var isBusy: Bool { get set }
    var webView: RichTextWebView { get }
    var webViewIdentity: String { get }
}

extension RichTextViewJSEngine {
    func fetchServiceInstance<H: JSServiceHandler>(_ service: H.Type) -> H? { return nil }
    func simulateJSMessage(_ msg: String, params: [String: Any]) { }
}

protocol RichTextViewUIResponse: AnyObject {
    @discardableResult
    func becomeFirst(trigger: String) -> Bool
    @discardableResult
    func becomeFirst() -> Bool
    func setTrigger(trigger: String)
    func addKeyboardResponder(_ responder: UIResponder)
    @discardableResult
    func resign() -> Bool
    var inputAccessory: UIView? { get set }
}

protocol RichTextViewBridgeConfig: AnyObject {
    func setJSBridge(_ bridge: String, for jsName: String)
}
