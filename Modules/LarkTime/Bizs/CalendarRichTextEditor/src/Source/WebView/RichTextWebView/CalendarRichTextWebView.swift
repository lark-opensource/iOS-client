//
//  CalendarRichTextWebView.swift
//  CalendarRichTextEditor
//
//  Created by Rico on 2021/2/20.
//

import UIKit
import Foundation
import WebKit
import LarkWebViewContainer

@objc protocol CLDInputAccessory {
    var realInputAccessoryView: UIView? { get set }
    var realInputView: UIView? { get set }
}

protocol CLDWebViewContextMenu {
    var items: [UIMenuItem] { get set }
}

protocol WebDelegate: AnyObject {
    /// request header
    var webRequestHeaders: [String: String] { get }
}

// MARK: - RichTextWebView Implementation
extension RichTextWebView {

    public var cldContextMenu: CLDWebViewContextMenu {
        get { return self.contextMenu }
        set {
            if let menu = newValue as? ContextMenu {
                self.contextMenu = menu
            }
        }
    }

    public var cldActionHelper: _ActionHelper {
        self._actionHelper
    }

    func safeSendMethod(selector: Selector!) {
        interceptSelector(selector)
        if responds(to: selector) {
            perform(selector, with: nil)
        } else if let contentV = contentView, contentV.responds(to: selector) {
            contentV.perform(selector, with: nil)
        }
        if sel_isEqual(selector, #selector(selectAll(_:))) {
            Logger.debug("调用了全选")
        }
    }

    // 某些方法需要在 webview 扩展它的行为，在此处拦截
    private func interceptSelector(_ selector: Selector) {
        if sel_isEqual(selector, #selector(selectAll(_:))) {
            let jsStr = "window.lark.biz.util.onSelectAll()"
            evaluateJavaScript(jsStr) { (_, error) in
                if let err = error {
                    Logger.error("webview select all fail", extraInfo: ["str": jsStr], error: err, component: nil)
                }
            }
        }
    }

    public func setCLDResponderDelegate(_ delegate: DocsWebViewResponderDelegate?) {
        self.responderDelegate = delegate
    }

    public func setCLDWebDelegate(_ delegate: WebDelegate?) {
        self.rtWebViewDelegate = delegate
    }

    public func setCLDGestureDelegate(_ delegate: WKWebViewGestureDelegate?) {
        self.gestureDelegate = delegate
    }

    public var cldWebViewInputAccessory: CLDInputAccessory {
        return self.inputAccessory
    }
}

extension LarkWebView.LKWInputAccessory: CLDInputAccessory { }
