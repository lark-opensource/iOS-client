//
//  SelfAware.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/11.
//

import UIKit
import Foundation

extension UIViewController {
    @objc
    static func swizzleMethod() {
        let originalSelector = #selector(present(_:animated:completion:))
        let swizzledSelector = #selector(swizzledPresent(_:animated:completion:))
        swizzling(
            forClass: UIViewController.self,
            originalSelector: originalSelector,
            swizzledSelector: swizzledSelector
        )
    }

    @objc
    func swizzledPresent(
        _ viewController: UIViewController,
        animated: Bool,
        completion: (() -> Void)? = nil) {

        viewController.presenter = self
        self.presentee = viewController
        swizzledPresent(viewController, animated: animated, completion: completion)
    }
}

public func swizzling(
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
