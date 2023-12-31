//
//  MenuBadgeNumber.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/5.
//

import Foundation

/// 统一菜单的badge数字表示类型，实际上是UInt?类型，为了兼容OC类型
public final class MenuBadgeNumber: NSObject {
    let number: Number

    /// Badge的数字，如果没有Badge则会返回0
    public var badgeNumber: UInt {
        switch number {
        case .number(let count):
            return count
        default:
            return 0
        }
    }

    /// 初始化为数字类型
    /// - Parameter number: badge的数字
    @objc
    public init(number: UInt) {
        self.number = .number(count: number)
        super.init()
    }

    /// 初始化为无数字类型
    @objc
    override public init() {
        self.number = .none
        super.init()
    }
}

extension MenuBadgeNumber {
    /// 数字类型
    enum Number {
        /// 数字
        case number(count: UInt)
        /// 没有数字
        case none
    }
}
