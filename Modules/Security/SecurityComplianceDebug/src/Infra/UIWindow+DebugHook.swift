//
//  UIWindow+DebugHook.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/28.
//

import Foundation

extension UIWindow {
    @objc private func SCDebugDidAddSubview(_ subview: UIView) {
        SCDebugDidAddSubview(subview)
        SecurityComplianeDebugFloatView.floatViewTags.forEach {
            guard let view = viewWithTag($0) else { return }
            view.superview?.bringSubviewToFront(view)
        }
    }

    static let hookDidAddSubview: Void = {
        swizzling(forClass: UIWindow.self, originalSelector: #selector(UIWindow.didAddSubview), swizzledSelector: #selector(UIWindow.SCDebugDidAddSubview))
    }()

}

fileprivate func swizzling(forClass: AnyClass,
                           originalSelector: Selector,
                           swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
            return
        }
        if class_addMethod(
            forClass,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        ) {
            class_replaceMethod(
                forClass,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
}
