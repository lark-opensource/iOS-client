//
//  MailBaseWebViewAble.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/11/9.
//

import Foundation
import WebKit

class BaseWebViewWeakRef {
    weak var superContainer: UIView?
}

protocol MailBaseWebViewAble: AnyObject {
    var weakRef: BaseWebViewWeakRef { get }
    var identifier: String? { get set }
    /// 用closure形式，避免retain
    var modelProvider: (() -> MailWebviewJavaScriptDelegate?)? { get set }

    func isCrashBlank() -> Bool
    func initJSBridge()
    func deinitJSBridge()
}

private var kWeakRef: Void?
extension MailBaseWebViewAble {
    var weakRef: BaseWebViewWeakRef {
        if let manager = objc_getAssociatedObject(self, &kWeakRef) as? BaseWebViewWeakRef {
            return manager
        } else {
            let manager = BaseWebViewWeakRef()
            objc_setAssociatedObject(self, &kWeakRef, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return manager
        }
    }
}

// MARK: - JS Methods 快捷方法
extension WKWebView {
    /// 获取焦点（弹起键盘）
    func focus() {
        focusAtEditor()
    }

    /// 获取焦点（弹起键盘）
    func focusAtEditor() {
        let jsStr = "window.command.focus()"
        self.evaluateJavaScript(jsStr, completionHandler: nil)
    }

    /// focus at editor begin
    func focusAtEditorBegin() {
        let jsStr = "window.command.focusAtEditorBegin()"
        self.evaluateJavaScript(jsStr, completionHandler: nil)
    }

    /// 失去焦点
    func blur() {
        //let jsStr = "var selection = window.getSelection();" +
                   // "selection.removeAllRanges();"
        let jsStr = "window.command.blur()"
        self.evaluateJavaScript(jsStr, completionHandler: nil)
    }
    
    func focusAtSelectionEnd() {
        let js = "window.command.focusAtSelectionEnd()"
        self.evaluateJavaScript(js, completionHandler: nil)
    }
}
