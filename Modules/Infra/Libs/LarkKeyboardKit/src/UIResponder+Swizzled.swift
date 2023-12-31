//
//  UIResponder+Swizzled.swift
//  KeyboardKit
//
//  Created by 李晨 on 2019/10/17.
//

import UIKit
import Foundation

extension UIResponder {
    @objc
    static func kk_swizzleMethod() {
        let swizzlingSet: [(Selector, Selector)] = [
            (#selector(becomeFirstResponder), #selector(kk_swizzledBecomeFirstResponder)),
            (#selector(resignFirstResponder), #selector(kk_swizzledResignFirstResponder))
        ]

        swizzlingSet.forEach { (value) in
            let originalSelector = value.0
            let swizzledSelector = value.1
            kk_swizzling(
                forClass: UIResponder.self,
                originalSelector: originalSelector,
                swizzledSelector: swizzledSelector
            )
        }
    }

    @objc
    func kk_swizzledBecomeFirstResponder() -> Bool {
        KeyboardKit.shared.tempFirstRespnder = self
        let result = self.kk_swizzledBecomeFirstResponder()
        KeyboardKit.shared.tempFirstRespnder = nil
        if result {
            KeyboardKit.shared.update(firstResponder: self)
        }
        return result
    }

    @objc
    func kk_swizzledResignFirstResponder() -> Bool {
        let result = self.kk_swizzledResignFirstResponder()
        if result && KeyboardKit.shared.firstResponder == self {
            KeyboardKit.shared.update(firstResponder: nil)
        }
        return result
    }

    static func kk_swizzling(
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

}
