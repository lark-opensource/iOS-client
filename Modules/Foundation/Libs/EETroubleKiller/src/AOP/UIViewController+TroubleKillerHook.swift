//
//  UIViewController+Hook.swift
//  EETroubleKiller
//
//  Created by Meng on 2019/5/13.
//

import Foundation
import UIKit

extension UIViewController {

    @objc
    static func troubleKillerSwizzleMethod() {
        let originalSelector = #selector(viewDidAppear(_:))
        let swizzledSelector = #selector(troubleKillerSwizzledViewDidAppear(_:))
        swizzling(
            forClass: UIViewController.self,
            originalSelector: originalSelector,
            swizzledSelector: swizzledSelector
        )
    }

    @objc
    func troubleKillerSwizzledViewDidAppear(_ animated: Bool) {
        troubleKillerSwizzledViewDidAppear(animated)
        guard TroubleKiller.config.enable else { return }
        let domainKey = (self as? DomainProtocol)?.domainKey ?? [:]
        TroubleKiller.pet.triggerAppear(target: self, domainKey: domainKey)
    }

}

private func swizzling(
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
