//
//  LarkWebView+KeyboardDisplay.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/29.
//
// 在UIWebView中，有一个属性keyboardDisplayRequiresUserAction，设置为NO时就可以在页面刚加载时直接弹出键盘；
// 在WKWebView中，是没有这个属性的，如果要实现类似的功能，就必须替换WKWebView中相应的方法.
// https://stackoverflow.com/questions/32449870/programmatically-focus-on-a-form-in-a-webview-wkwebview

import Foundation

public extension LarkWebView {
    /// 允许自动弹出键盘
    class func allowDisplayingKeyboardWithoutUserAction() {
        guard let wkContentViewClass: AnyClass = NSClassFromString("WKContentView") else { return }
        if #available(iOS 13.0, *) {
            let sel = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:activityStateChanges:userObject:")
            guard let method = class_getInstanceMethod(wkContentViewClass, sel) else { return }
            typealias WkWebviewKeyboardFunctionType = @convention(c)(AnyObject, Selector, UnsafeRawPointer, Bool, Bool, UnsafeMutablePointer<AnyObject>, UnsafeRawPointer) -> Void
            let originalImp = unsafeBitCast(method_getImplementation(method), to: WkWebviewKeyboardFunctionType.self)
            let block: @convention(block) (AnyObject, UnsafeRawPointer, Bool, Bool, UnsafeMutablePointer<AnyObject>, UnsafeRawPointer) -> Void = { sself, arg0, arg1, arg2, arg3, arg4 in
                originalImp(sself, sel, arg0, true, arg2, arg3, arg4)
            }
            let imp = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
            method_setImplementation(method, imp)
        } else if #available(iOS 12.2.0, *) {
            let sel = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
            guard let method = class_getInstanceMethod(wkContentViewClass, sel) else { return }
            typealias WkWebviewKeyboardFunctionType = @convention(c)(AnyObject, Selector, UnsafeRawPointer, Bool, Bool, Bool, UnsafeRawPointer) -> Void
            let originalImp = unsafeBitCast(method_getImplementation(method), to: WkWebviewKeyboardFunctionType.self)
            let block: @convention(block) (AnyObject, UnsafeRawPointer, Bool, Bool, Bool, UnsafeRawPointer) -> Void = { sself, arg0, arg1, arg2, arg3, arg4 in
                originalImp(sself, sel, arg0, true, arg2, arg3, arg4)
            }
            let imp = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
            method_setImplementation(method, imp)
        } else if #available(iOS 11.3.0, *) {
            let sel = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
            guard let method = class_getInstanceMethod(wkContentViewClass, sel) else { return }
            typealias WkWebviewKeyboardFunctionType = @convention(c)(AnyObject, Selector, UnsafeRawPointer, Bool, Bool, Bool, UnsafeRawPointer) -> Void
            let originalImp = unsafeBitCast(method_getImplementation(method), to: WkWebviewKeyboardFunctionType.self)
            let block: @convention(block) (AnyObject, UnsafeRawPointer, Bool, Bool, Bool, UnsafeRawPointer) -> Void = { sself, arg0, arg1, arg2, arg3, arg4 in
                originalImp(sself, sel, arg0, true, arg2, arg3, arg4)
            }
            let imp = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
            method_setImplementation(method, imp)
        } else {
            let sel = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:")
            guard let method = class_getInstanceMethod(wkContentViewClass, sel) else { return }
            typealias WkWebviewKeyboardFunctionType = @convention(c)(AnyObject, Selector, UnsafeRawPointer, Bool, Bool, UnsafeRawPointer) -> Void
            let originalImp = unsafeBitCast(method_getImplementation(method), to: WkWebviewKeyboardFunctionType.self)
            let block : @convention(block) (AnyObject, UnsafeRawPointer, Bool, Bool, UnsafeRawPointer) -> Void = { sself, arg0, arg1, arg2, arg3 in
                originalImp(sself, sel, arg0, true, arg2, arg3)
            }
            let imp = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
            method_setImplementation(method, imp)
        }
    }
}
