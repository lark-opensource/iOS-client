//
//  Swizzing.swift
//  LarkLandscape
//
//  Created by 李晨 on 2020/2/26.
//

import Foundation

func lo_swizzling(
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
