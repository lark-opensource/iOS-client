//
//  LarkWebView+InputAccessory.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/29.
//
//  自定义键盘

import Foundation

@objc extension LarkWebView {
    // InputAccessoryView
    private static var inputAccessoryViewKey: UInt8 = 0
    override open var inputAccessoryView: UIView? {
        if let view = objc_getAssociatedObject(self, &LarkWebView.inputAccessoryViewKey) as? UIView {
            return view
        } else {
            return super.inputAccessoryView
        }
    }

    // InputView
    private static var inputViewKey: UInt8 = 0
    override open var inputView: UIView? {
        if let view = objc_getAssociatedObject(self, &LarkWebView.inputViewKey) as? UIView {
            return view
        } else {
            return super.inputView
        }
    }
}

@objc extension LarkWebView {
    private static var inputAccessoryKey: UInt8 = 0
    /// toolbar for keyboard (inputAccessoryView)
    public var inputAccessory: LKWInputAccessory {
        get {
            guard let value = objc_getAssociatedObject(self, &LarkWebView.inputAccessoryKey) as? LKWInputAccessory else {
                let obj = LKWInputAccessory(target: self)
                self.inputAccessory = obj
                return obj
            }
            return value
        }
        set {
            objc_setAssociatedObject(self, &LarkWebView.inputAccessoryKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc
    public final class LKWInputAccessory: NSObject {
        // wkwebView -> contextMenu -> weak wkwebView
        fileprivate weak var target: LarkWebView?

        override private init() {
            super.init()
        }

        public init(target: LarkWebView) {
            self.target = target
            super.init()

            if #available(iOS 13.0, *) {
                // Seems like iOS 13 don't needs method swizlling anymore, still need continuous observation to prove this assumption.
            } else {
                // add method
                let inputAccessorySel = #selector(getter: inputAccessoryView)
                let inputViewSel = #selector(getter: inputView)
                guard let contentView = target.contentView,
                    let nickClass = target.contentViewNickClass,
                    let inputAccessMethod = class_getInstanceMethod(LarkWebView.self, inputAccessorySel),
                    let inputViewMethod = class_getInstanceMethod(LarkWebView.self, inputViewSel) else {
                        assertionFailure()
                        return
                }
                // inputView
                if class_addMethod(nickClass.self, inputViewSel, method_getImplementation(inputViewMethod), method_getTypeEncoding(inputViewMethod)) {
                } else {
                    class_replaceMethod(nickClass.self, inputViewSel, method_getImplementation(inputViewMethod), method_getTypeEncoding(inputViewMethod))
                }
                // inputAccesssoryView
                if class_addMethod(nickClass.self, inputAccessorySel, method_getImplementation(inputAccessMethod), method_getTypeEncoding(inputAccessMethod)) {
                } else {
                    class_replaceMethod(nickClass.self, inputAccessorySel, method_getImplementation(inputAccessMethod), method_getTypeEncoding(inputAccessMethod))
                }
                object_setClass(contentView, nickClass)
            }
        }
        /// inputAccessoryView
        @objc
        public var realInputAccessoryView: UIView? {
            get {
                guard let webView = self.target else { return nil }
                return objc_getAssociatedObject(webView, &LarkWebView.inputAccessoryViewKey) as? UIView
            }
            set {
                if let webView = self.target {
                    objc_setAssociatedObject(webView, &LarkWebView.inputAccessoryViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    webView.reloadInputViews()
                }
                self.target?.contentView?.reloadInputViews()
            }
        }
        /// inputView
        @objc
        public var realInputView: UIView? {
            get {
                guard let webView = self.target else { return nil }
                return objc_getAssociatedObject(webView, &LarkWebView.inputViewKey) as? UIView
            }
            set {
                if let webView = self.target {
                    objc_setAssociatedObject(webView, &LarkWebView.inputViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    webView.reloadInputViews()
                }
                self.target?.contentView?.reloadInputViews()
            }
        }
    }
}
