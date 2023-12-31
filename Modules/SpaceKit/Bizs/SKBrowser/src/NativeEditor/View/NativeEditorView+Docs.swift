//
//  NativeEditorView+Docs.swift
//  SKBrowser
//
//  Created by lijuyou on 2021/7/13.
//  


import SKFoundation
import SKUIKit
import SKCommon
import SKEditor

public protocol DocsNativeEditorViewProtocol: DocsEditorViewProtocol {
    func getContentScrollView() -> UIScrollView
}

extension NativeEditorView {
    private static var responderDelegateKey: UInt8 = 0
    private static var editorDelegateKey: UInt8 = 0
    private static var gestureDelegateKey: UInt8 = 0

    public var responderDelegate: DocsEditorViewResponderDelegate? {
        get {
            let value = objc_getAssociatedObject(self, &NativeEditorView.responderDelegateKey) as? DocsEditorViewResponderDelegate
            return value
        }
        set {
            objc_setAssociatedObject(self, &NativeEditorView.responderDelegateKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }

    public var editorDelegate: EditorConfigDelegate? {
        get {
            let value = objc_getAssociatedObject(self, &NativeEditorView.editorDelegateKey) as? EditorConfigDelegate
            return value
        }
        set {
            objc_setAssociatedObject(self, &NativeEditorView.editorDelegateKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }

    public var gestureDelegate: EditorViewGestureDelegate? {
        get {
            let value = objc_getAssociatedObject(self, &NativeEditorView.gestureDelegateKey) as? EditorViewGestureDelegate
            return value
        }
        set {
            objc_setAssociatedObject(self, &NativeEditorView.gestureDelegateKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

extension NativeEditorView: DocsNativeEditorViewProtocol {

    public func getContentScrollView() -> UIScrollView {
        self.contentScrollView
    }

    public var editorViewType: EditorViewType {
        .native
    }

    public var skEditorViewInputAccessory: SKInputAccessory {
        self.inputAccessory
    }

    public func becomeFirst() -> Bool {
        spaceAssertionFailure("待实现")
        return true
    }

    public func resign() -> Bool {
        return self.endEditing(true)
    }

    public func setSKResponderDelegate(_ delegate: DocsEditorViewResponderDelegate?) {
        self.responderDelegate = delegate
    }

    public func setSKEditorConfigDelegate(_ delegate: EditorConfigDelegate?) {
        self.editorDelegate = delegate
    }

    public func setSKGestureDelegate(_ delegate: EditorViewGestureDelegate?) {
        self.gestureDelegate = delegate
    }
}

extension NativeEditorView: EditorViewDelegate {
    public func onEditorFirstResponderStatusCahnged(_ status: EditorFirstResponderStatus) {
        switch status {
        case .willBecomeFirstResponder:
            self.responderDelegate?.docsEditorViewWillBecomeFirstResponder(self)
        case .becomeFirstResponder:
            self.responderDelegate?.docsEditorViewDidBecomeFirstResponder(self)
        case .willResignFirstResponder:
            self.responderDelegate?.docsEditorViewWillResignFirstResponder(self)
        case .resignFirstResponder:
            self.responderDelegate?.docsEditorViewDidResignFirstResponder(self)
        @unknown default:
            break
        }
    }
}

@objc extension NativeEditorView.InputAccessory: SKInputAccessory {

}
