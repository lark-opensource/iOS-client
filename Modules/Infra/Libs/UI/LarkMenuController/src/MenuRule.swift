//
//  MenuRule.swift
//  LarkMenuController
//
//  Created by kangsiwan on 2021/12/20.
//

import UIKit
import Foundation

// 每条规则的优先级
public struct MenuRulePriority: Hashable, Equatable {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let low = MenuRulePriority(rawValue: 100)
    public static let normal = MenuRulePriority(rawValue: 300)
    public static let high = MenuRulePriority(rawValue: 500)
}
// 布局面板的规则协议
// 可以制定具体的规则，遵守此协议。业务方使用时，可以指定多个规则制成数组，底层就会根据数据布局好menu
public protocol MenuLayoutRule {
    var priority: MenuRulePriority { get set }
    func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool
    func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat?
}

public protocol MenuLayoutAnimation {
    func appearLayout(rect: CGRect, info: MenuLayoutInfo) -> CGRect
    func disappearLayout(rect: CGRect, info: MenuLayoutInfo) -> CGRect
}

// MARK: X轴方向的规则
// x轴方向：屏幕居中
public struct XMiddleRule: MenuLayoutRule {
    public var priority: MenuRulePriority
    private let compact: CGFloat
    public init(priority: MenuRulePriority = .low, compact: CGFloat = 500) {
        self.priority = priority
        self.compact = compact
    }
    public func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool {
        if info.menuVC.view.bounds.width <= compact {
            return true
        }
        return false
    }
    public func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        return info.menuVC.view.frame.width / 2 - info.menuSize.width / 2
    }
}

// x轴方向：根据手指居中
public struct XFollowGestureRule: MenuLayoutRule {
    public var priority: MenuRulePriority
    private let multiple: CGFloat
    private let offset: CGFloat
    public init(priority: MenuRulePriority = .normal, multiple: CGFloat = 1.3, offset: CGFloat = 0) {
        self.priority = priority
        self.multiple = multiple
        self.offset = offset
    }
    public func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool {
        if info.transformTrigerLocation() != nil, info.menuSize.width * multiple <= info.menuVC.view.bounds.width {
            return true
        }
        return false
    }
    public func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        if let location = info.transformTrigerLocation() {
            return location.x - info.menuSize.width / 2 + offset
        }
        return nil
    }
}

// MARK: Y轴方向的规则
// y轴方向：根据屏幕居中
public struct YMiddleRule: MenuLayoutRule {
    public var priority: MenuRulePriority
    public init(priority: MenuRulePriority = .low) {
        self.priority = priority
    }
    public func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool {
        return true
    }
    public func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        return info.menuVC.view.frame.height / 2 - info.menuSize.height / 2
    }
}

// y轴方向：点击位置在屏幕下侧在上面显示，点击位置在屏幕上侧在下面显示
public struct YScreenSideRule: MenuLayoutRule {
    public var priority: MenuRulePriority
    let offset: CGFloat
    public init(priority: MenuRulePriority = .normal, offset: CGFloat = 0) {
        self.priority = priority
        self.offset = offset
    }
    public func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool {
        if info.transformTrigerLocation() != nil {
            return true
        }
        return false
    }

    public func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        guard let location = info.transformTrigerLocation() else {
            return nil
        }
        if location.y < info.menuVC.view.frame.height / 2 {
            return location.y + offset
        } else {
            return location.y - info.menuSize.height - offset
        }
    }
}

// y轴方向：根据手指居中
public struct YFollowGestureRule: MenuLayoutRule {
    public var priority: MenuRulePriority
    private let offset: CGFloat
    public init(priority: MenuRulePriority = .normal, offset: CGFloat = 0) {
        self.priority = priority
        self.offset = offset
    }
    public func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool {
        if info.transformTrigerLocation() != nil {
            return true
        }
        return false
    }
    public func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        guard let location = info.transformTrigerLocation() else {
            return nil
        }
        return location.y - info.menuSize.height / 2 + offset
    }
}
// MARK: 动画方法
public struct YTranslateAnimationRule: MenuLayoutAnimation {

    let offset: CGFloat
    public init(offset: CGFloat = 0) {
        self.offset = offset
    }
    public func appearLayout(rect: CGRect, info: MenuLayoutInfo) -> CGRect {
        var rect = rect
        if let location = info.transformTrigerLocation() {
            if location.y > rect.centerY {
                rect.origin.y += min(offset, location.y - rect.centerY)
            } else {
                rect.origin.y -= min(offset, rect.centerY - location.y)
            }
        }
        return rect
    }
    public func disappearLayout(rect: CGRect, info: MenuLayoutInfo) -> CGRect {
        return rect
    }
}
