//
//  MenuBadgeType.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/1/29.
//

import Foundation

/// Badge显示的风格，这是为了兼容OC，实际效果等价于关联类型的枚举
public final class MenuBadgeType: NSObject {
    /// Badge显示的风格
    let type: BadgeType

    /// 初始化显示风格
    /// - Parameter type: 指定的显示风格
    private init(type: BadgeType) {
        self.type = type
        super.init()
    }

    /// 初始化显示dotSmall的风格
    @objc
    static public func initWithDotSmallStyle() -> MenuBadgeType {
        .init(type: .dotSmall)
    }

    /// 初始化显示dotLarge的风格
    @objc
    static public func initWithDotLargeStyle() -> MenuBadgeType {
        .init(type: .dotLarge)
    }

    /// 初始化显示数字的风格
    /// - Parameters:
    ///   - maxNumber: 数字红点的最大数字
    @objc
    static public func initWithNumberStyle(maxNumber: UInt) -> MenuBadgeType {
        .init(type: .number(maxNumber: maxNumber))
    }

    /// 初始化显示数字的风格，数字最大值取决于内部默认实现
    @objc
    static public func initWithNumberStyle() -> MenuBadgeType {
        .init(type: .number(maxNumber: nil))
    }

    /// 初始化显示数字的风格，数字最大值取决于内部默认实现
    @objc
    static public func initWithNoneStyle() -> MenuBadgeType {
        .init(type: .none)
    }
}

extension MenuBadgeType {
    /// LarkMenu显示的Badge风格类型
    enum BadgeType {
        /// 数字类型
        /// 表示显示的数字最大为多少，超过其的数字会变为...显示
        /// - Note: 不能超过Int.max，否则会出现意想不到的问题
        case number(maxNumber: UInt?)

        /// Lark统一红点，外面有圈圈
        case dotLarge

        /// Lark统一红点，外面无圈圈，比较小
        case dotSmall

        /// 不显示Badge
        case none
    }

}
