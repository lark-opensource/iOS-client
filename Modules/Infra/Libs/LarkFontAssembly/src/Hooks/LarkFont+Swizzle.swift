//
//  FontSwizzleKit.swift
//  LarkFont
//
//  Created by 白镜吾 on 2023/3/20.
//

import UIKit
import UniverseDesignFont

public extension LarkFont {
    static var hadSwizzled: Bool = false

    // 交换 systemMethod <-> LarkFontMethod
    @objc
    static func swizzleIfNeeded() {
        guard #available(iOS 12.0, *) else { return }
        if !LarkFont.hadSwizzled {
            LarkFont.swizzleFocus()
            LarkFont.hadSwizzled = true
        }
    }

    static func swizzleFocus() {
        guard #available(iOS 12.0, *) else { return }
        LarkFont.hadSwizzled = false
        let swizzlingList: [(Selector, Selector)] = [
            (#selector(UIFont.systemFont(ofSize:)), #selector(LarkFont.customFont(ofSize:))),
            (#selector(UIFont.systemFont(ofSize:weight:)), #selector(LarkFont.customFont(ofSize:weight:))),
            (#selector(UIFont.boldSystemFont(ofSize:)), #selector(LarkFont.boldCustomFont(ofSize:))),
            (#selector(UIFont.italicSystemFont(ofSize:)), #selector(LarkFont.italicSystemFont(ofSize:))),
            (#selector(UIFont.monospacedDigitSystemFont(ofSize:weight:)), #selector(LarkFont.monospacedDigitCustomFont(ofSize:weight:)))
        ]

        swizzlingList.forEach { value in
            let originalSelector = value.0
            let swizzledSelector = value.1
            LarkFont.swizzling(forClass: UIFont.self, originalSelector: originalSelector, swizzledSelector: swizzledSelector)
        }
    }

    private static func swizzling(forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
        guard let originalMethod = class_getClassMethod(forClass, originalSelector),
              let swizzledMethod = class_getClassMethod(LarkFont.self, swizzledSelector) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
