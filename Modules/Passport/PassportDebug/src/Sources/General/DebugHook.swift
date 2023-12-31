//
//  DebugHook.swift
//  PassportDebug
//
//  Created by ByteDance on 2022/7/20.
//

import Foundation
import UIKit

extension UIWindow {
    @objc private func myDidAddSubview(_ subview: UIView) {
        myDidAddSubview(subview)
        EnvInfoManager.shared.makeEnvInfoViewTop()
    }
    
    static let hookDidAddSubview: Void = {
        swizzling(forClass: UIWindow.self, originalSelector: #selector(UIWindow.didAddSubview), swizzledSelector: #selector(UIWindow.myDidAddSubview))
    }()
    
}

fileprivate func swizzling(
    forClass: AnyClass,
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
