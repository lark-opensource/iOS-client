//
//  UIFont+Extensions+Hook.swift
//  LarkFont
//
//  Created by 白镜吾 on 2023/3/20.
//

import UIKit
import UniverseDesignFont

/// 此处 LarkFont 的作用为，systemFont 和 LarkFont 进行交换，当关了 Swizzle FG 时不影响 直接替换的业务。
internal extension LarkFont {
    /// 替换 systemFont(ofSize:)
    @objc
    static func customFont(ofSize size: CGFloat) -> UIFont {
        return UDFont.systemFont(ofSize: size)
    }

    /// 替换 systemFont(ofSize:weight:)
    @objc
    static func customFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return UDFont.systemFont(ofSize: size, weight: weight)
    }

    /// 替换 boldSystemFont(ofSize:)
    @objc
    static func boldCustomFont(ofSize size: CGFloat) -> UIFont {
        return UDFont.boldSystemFont(ofSize: size)
    }

    @objc
    static func italicSystemFont(ofSize size: CGFloat) -> UIFont {
        return UDFont.italicSystemFont(ofSize: size)
    }

    // convenience methods to change to mono digit
    @objc
    static func monospacedDigitCustomFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return UDFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
    }
}
