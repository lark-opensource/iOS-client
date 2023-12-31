//
//  MailNewWebView.swift
//  MailSDK
//
//  Created by Ryan on 2020/11/2.
//

import UIKit
import LarkWebViewContainer

protocol TemplateReadyDelegate: AnyObject {
    var isReady: Bool { get set }
    var responderDelegate: EditorWebViewResponderDelegate? { get set }
}

class MailNewWebView: LarkWebView, TemplateReadyDelegate {
    var isReady = false
    private var observation: NSKeyValueObservation?
    override var inputAccessoryView: UIView? {
        return nil
    }
    var disableScroll: Bool = false {
        didSet {
            if let ob = observation {
                ob.invalidate()
            }
            if disableScroll {
                MailLogger.info("[NewWebView] addobserve")
                self.observation = self.scrollView.observe(\.contentOffset, options: NSKeyValueObservingOptions.init(rawValue: 3)) { (scrollView, change) in
                    if let new = change.newValue,
                       let old = change.oldValue,
                        new.y != old.y {
                        if new.y > 0 {
                            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                        }
                    }
                }
            }
        }
    }
    weak var responderDelegate: EditorWebViewResponderDelegate?
    override var canBecomeFirstResponder: Bool {
        return responderDelegate?.editorWebViewShouldBecomeFirstResponder(self) ?? true
    }

    override var canResignFirstResponder: Bool {
        return responderDelegate?.editorWebViewShouldResignFirstResponder(self) ?? true
    }

    override func becomeFirstResponder() -> Bool {
        // warning: 不知道为何有时候没点到 WebView，也会成为第一响应者，导致其他的TextFiled失效
        responderDelegate?.editorWebViewWillBecomeFirstResponder(self)
        let res = super.becomeFirstResponder()
        responderDelegate?.editorWebViewDidBecomeFirstResponder(self)
        return res
    }

    override func resignFirstResponder() -> Bool {
        responderDelegate?.editorWebViewWillResignFirstResponder(self)
        let res = super.resignFirstResponder()
        responderDelegate?.editorWebViewDidResignFirstResponder(self)
        return res
    }

    deinit {
        MailLogger.info("[NewWebView] deinit")
        if let ob = observation {
            ob.invalidate()
        }
    }
}

