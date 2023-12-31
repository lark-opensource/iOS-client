//
//  Swizzing.swift
//  LarkUIExtensionWrapper
//
//  Created by 李晨 on 2020/3/10.
//

import UIKit
import Foundation

final class Swizzing {
    static func uiExtensionSwizzleMethod() {
        let swizzlingSet: [(AnyClass, Selector, Selector)] = [
            (UIView.self,
             #selector(UIView.didMoveToWindow),
             #selector(UIView.uiExtensionDidMoveToWindow))
        ]

        swizzlingSet.forEach { (value) in
            uiExtensionSwizzling(
                forClass: value.0,
                originalSelector: value.1,
                swizzledSelector: value.2
            )
        }
    }

    static func themeExtensionSwizzleMethod() {
        let swizzlingSet: [(AnyClass, Selector, Selector)] = [
            (UIWindow.self,
             #selector(UIWindow.traitCollectionDidChange(_:)),
             #selector(UIWindow.uiExtensionTraitCollectionDidChange))
        ]

        swizzlingSet.forEach { (value) in
            uiExtensionSwizzling(
                forClass: value.0,
                originalSelector: value.1,
                swizzledSelector: value.2
            )
        }
    }
}

extension UIView {
    @objc
    func uiExtensionDidMoveToWindow() {
        if self.ueDirtyTag {
            PropertyStore.shared.updateProperty(object: self)
        }
        self.uiExtensionDidMoveToWindow()
    }
}

extension UIWindow {
    @objc
    func uiExtensionTraitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        /// HOOK UIWindow,  监听皮肤切换
        /// 这里需要注意的是每次退到后台，系统会分别切换切换 亮色/暗色 一次， 回到前台之后如果皮肤发生变化再回调一次
        ThemeManager.shared.updateWhenTraitChange()
        self.uiExtensionTraitCollectionDidChange(previousTraitCollection)
    }
}

private func uiExtensionSwizzling(
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
