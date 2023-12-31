//
//  NativeRenderHook.swift
//  LarkWebViewContainer
//
//  Created by tefeng liu on 2020/9/17.
//

import Foundation
import UIKit
import ECOInfra

private var kScrollViewRenderObj: Void?
private var kScrollViewDeallocator: Void?
private var kContentSizeObservation: Void?
private var kWebViewFirstResponderKey: Void?

// MARK: hook for uiscrollview. for fix
extension UIScrollView {
    var lkwContentSizeObservation: NSKeyValueObservation? {
        get {
            return (objc_getAssociatedObject(self, &kContentSizeObservation) as? NSKeyValueObservation)
        }
        set {
            objc_setAssociatedObject(self, &kContentSizeObservation, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}

// MARK: hook
private var kNativeRenderFindViewCallback: Void?

extension LarkWebView {
    typealias NativeRenderFindViewCallback = (UIView) -> UIView?

    // 查找注入同层元素的callback
    var nativeRenderFindViewCallback: NativeRenderFindViewCallback? {
        get {
            return objc_getAssociatedObject(self, &kNativeRenderFindViewCallback) as? NativeRenderFindViewCallback
        }

        set {
            objc_setAssociatedObject(self,
                                     &kNativeRenderFindViewCallback,
                                     newValue,
                                     .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    var firstResponderFixSetting: Bool {
        get {
            return objc_getAssociatedObject(self, &kWebViewFirstResponderKey) as? Bool ?? false
        }
        
        set {
            objc_setAssociatedObject(self, &kWebViewFirstResponderKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    func lkw_hook() {
        firstResponderFixSetting = LarkWebViewNativeComponentSettings.hitTestFirstResponderFix()
        
        lkw_swizzleInstanceClassIsa(#selector(hitTest(_:with:)), withHookInstanceMethod: #selector(lkw_hitTest(_:with:)))
        lkw_swizzleInstanceClassIsa(#selector(becomeFirstResponder), withHookInstanceMethod: #selector(lkw_becomeFirstResponder))
    }

    // 查找同层元素view
    @objc public func findNativeView(view: UIView) -> UIView? {
        var nativeObj: NativeRenderObj?
        for temp in self.renderObjs.values {
            if temp.scrollView == view && view == temp.nativeView?.superview {
                nativeObj = temp
                break
            }
        }
        return nativeObj?.nativeView
    }
    
    // 查找同层元素view(新方案)
    private func findNativeViewSync(view: UIView) -> UIView? {
        for temp in fixRenderSyncObjs.values {
            if temp.scrollView == view && view == temp.nativeView?.superview {
                return temp.nativeView
            }
        }
        return nil
    }
    
    /// 搜索native view的通用方法，先按旧同层逻辑搜索，如果没有搜索到再按同步同层逻辑搜索
    private func findNativeViewGeneralMethod(view: UIView) -> UIView? {
        if let nativeView = findNativeView(view: view) {
            return nativeView
        } else {
            let nativeView = findNativeViewSync(view: view)
            return nativeView
        }
    }
    
    // 查找同层元素view(view可以为nil)
    func findNativeViewFromRenderObjs(view: UIView?) -> UIView? {
        if let view = view {
            return findNativeViewGeneralMethod(view: view)
        }
        return nil
    }
    
    // 注入查找同层元素的callback
    @objc public func registerNativeRenderFindViewCallback(_ block: ((UIView) -> UIView?)?) {
        self.nativeRenderFindViewCallback = block
    }

    @objc
    func lkw_hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if #available(iOS 13.0, *) {
            // if iOS 13. wk gesture should be enable
            self.touchActionGestureRecognizer?.isEnabled = true
        }

        let view = lkw_hitTest(point, with: event)
        if view != nil && !view!.isKind(of: UIScrollView.self) {
            self.currentHittestView = nil
            return view
        } else if view != nil && view!.isKind(of: UITextView.self) {
            self.currentHittestView = view
            return view
        }

        var nativeView = findNativeViewFromRenderObjs(view: view)
        if nativeView == nil, let view = view {
            // 如果renderObjs 没有命中同层view，则从注入callback中查找
            nativeView = self.nativeRenderFindViewCallback?(view)
        }
        if let nativeView = nativeView {
            let pt = convert(point, to: nativeView)
            let ret = nativeView.hitTest(pt, with: event)
            // disable WKTouchActionGestureRecognizer
            if #available(iOS 13.0, *) {
                self.touchActionGestureRecognizer?.isEnabled = false
            }
            currentHittestView = ret
            return ret ?? view
        }
        currentHittestView = nil
        return view
    }

    @objc
    func lkw_becomeFirstResponder() -> Bool {
        if firstResponderFixSetting {
            if let hitView = currentHittestView, hitView.isFirstResponder {
                return false
            }
        } else {
        if currentHittestView != nil {
            return false
        }
        }
        return lkw_becomeFirstResponder()
    }
}
