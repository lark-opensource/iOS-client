//
//  LarkWebView+Render Properties.swift
//  LarkWebViewContainer
//
//  Created by tefeng liu on 2020/9/17.
//

import Foundation

/// render object info
@objcMembers
public final class NativeRenderObj: NSObject {
    public var viewId: String = ""
    public var nativeView: UIView?

    // MARK: weak referrence
    public weak var webview: LarkWebView?
    weak var scrollView: UIScrollView?
}

// MARK: private properties
private var kRenderObjs: Void?
private var kTouchActionGestureRecognizer: Void?
private var kCurrentHittestView: Void?

extension LarkWebView {
    var renderObjs: [String: NativeRenderObj] {
        get {
            return (objc_getAssociatedObject(self, &kRenderObjs) as? [String: NativeRenderObj]) ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &kRenderObjs, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    var touchActionGestureRecognizer: UIGestureRecognizer? {
        get {
            if let res = (objc_getAssociatedObject(self, &kTouchActionGestureRecognizer) as? UIGestureRecognizer) {
                return res
            }

            if let contentView = findWebContentView(webview: self), let gestures = contentView.gestureRecognizers {
                for ges in gestures {
                    if let targetClass = NSClassFromString("WKTouchActionGestureRecognizer"),
                       ges.isKind(of: targetClass) {
                        self.touchActionGestureRecognizer = ges
                        return ges
                    }
                }
            }
            return nil;
        }
        set {
            objc_setAssociatedObject(self, &kTouchActionGestureRecognizer, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    var currentHittestView: UIView? {
        get {
            return (objc_getAssociatedObject(self, &kCurrentHittestView) as? UIView)
        }
        set {
            objc_setAssociatedObject(self, &kCurrentHittestView, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}
