//
//  BaseMenuLayout.swift
//  LarkMenuController
//
//  Created by kangsiwan on 2021/12/22.
//

import UIKit
import Foundation

// MARK: 可以直接使用的Layout
// 带动画的Layout，动画为平移。水平方向会跟随手指，竖直方向会根据在点击的位置在屏幕上或者下出现面板
public final class AnimationMenuLayout: CommonMenuLayout {
    init() {
        let xLayoutRules: [MenuLayoutRule] = [XFollowGestureRule()]
        let yLayoutRules: [MenuLayoutRule] = [YScreenSideRule(), YMiddleRule()]
        super.init(xLayoutRules: xLayoutRules, yLayoutRules: yLayoutRules)
        self.animationRule = YTranslateAnimationRule()
    }
}

// 可以替换SimpleMenuLayout
// 水平方向会跟随手指，竖直方向会根据在点击的位置在屏幕上或者下出现面板。
// 没有动画
public final class TheSimpleMenuLayout: CommonMenuLayout {
    public var offset: CGFloat = 20
    init() {
        super.init(xLayoutRules: [XFollowGestureRule(), XMiddleRule()], yLayoutRules: [YScreenSideRule(offset: offset), YMiddleRule()])
    }

    public override func menuUpdateLayout(info: MenuLayoutInfo, downward: Bool, offset: CGPoint) -> CGRect {
        if let origin = info.origin {
            let originX = origin.origin.x + offset.x
            var originY: CGFloat = origin.origin.y + (downward ? offset.y : (origin.height - info.menuSize.height + offset.y))
            return CGRect(origin: CGPoint(x: originX, y: originY), size: info.menuSize)
        } else {
            return super.menuLayout(info: info)
        }
    }
}

// MARK: CommonMenuLayout
// 想定义一个Layout，最好继承自Common，并指定水平和竖直方向需要遵守的规则。
// Menu已经定义了一些通用规则在MenuRule文件中。如果这些规则不满足使用的需要，也可以自定义规则。规则需要满足MenuLayoutRule协议
// 规则的执行顺序会根据他的优先级决定
open class CommonMenuLayout: BaseMenuLayout {
    open var xLayoutRules: [MenuLayoutRule] {
        set {
            _xLayoutRules = sortByRulePriority(rules: newValue)
        }
        get {
            return _xLayoutRules
        }
    }
    open var yLayoutRules: [MenuLayoutRule] {
        set {
            _yLayoutRules = sortByRulePriority(rules: newValue)
        }
        get {
            return _yLayoutRules
        }
    }
    private var _xLayoutRules: [MenuLayoutRule] = []
    private var _yLayoutRules: [MenuLayoutRule] = []
    public init(xLayoutRules: [MenuLayoutRule], yLayoutRules: [MenuLayoutRule]) {
        super.init()
        self.xLayoutRules = xLayoutRules
        self.yLayoutRules = yLayoutRules
    }

    // MARK: override
    open override func menuLayout(info: MenuLayoutInfo) -> CGRect {
        let x = calculateCoordinateValue(with: _xLayoutRules, info: info, layout: self) ?? defaultXLayout(info: info)
        let y = calculateCoordinateValue(with: _yLayoutRules, info: info, layout: self) ?? defaultYLayout(info: info)
        return CGRect(origin: CGPoint(x: x, y: y), size: info.menuSize)
    }

    open override func menuUpdateLayout(info: MenuLayoutInfo, downward: Bool, offset: CGPoint) -> CGRect {
        let rect = menuLayout(info: info)
        let x = rect.origin.x + offset.x
        let y = rect.origin.y + (downward ? offset.y : -offset.y)
        return CGRect(origin: CGPoint(x: x, y: y), size: info.menuSize)
    }

    // 计算坐标系的值
    open func calculateCoordinateValue(with ruleArray: [MenuLayoutRule], info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        for rule in ruleArray {
            if rule.canUseCondition(info: info, layout: layout),
               let value = rule.ruleImplement(info: info, layout: layout) {
                return value
            }
        }
        return nil
    }

    // MARK: x轴的方法
    // 在屏幕中间
    open func defaultXLayout(info: MenuLayoutInfo) -> CGFloat {
        let xPos = info.menuVC.view.frame.width / 2 - info.menuSize.width / 2
        return xPos
    }

    // MARK: y轴的方法
    // 在屏幕中间
    open func defaultYLayout(info: MenuLayoutInfo) -> CGFloat {
        return info.menuVC.view.frame.height / 2 - info.menuSize.height / 2
    }

    // MARK: private
    private func sortByRulePriority(rules: [MenuLayoutRule]) -> [MenuLayoutRule] {
        let array = rules.sorted { r1, r2 in
            r1.priority.rawValue > r2.priority.rawValue
        }
        return array
    }
}

// MARK: BaseMenuLayout
// 遵守MenuBarLayout协议，并用来设置安全区域、动画等基础能力
// 子类想设置动画，直接给animationRule赋值，base会在appear和disappear中会优先判断是否有动画，有动画会执行动画
open class BaseMenuLayout: MenuBarLayout {
    // MARK: open 属性
    // 系统的安全区域是否生效，默认生效
    open var isUseSystemSafeArea: Bool = true
    open var insets: UIEdgeInsets = UIEdgeInsets.zero
    open var animationRule: MenuLayoutAnimation?

    // MARK: 遵守协议
    // 非必要的情况不要重写下面的协议方法，因为协议方法会加防护
    open func calculate(info: MenuLayoutInfo) -> CGRect {
        return transform(rect: menuLayout(info: info), info: info)
    }

    open func calculateAppear(info: MenuLayoutInfo) -> CGRect {
        let rect = calculate(info: info)
        return transform(rect: menuAppearLayout(rect: rect, info: info), info: info)
    }

    open func calculateDisappear(info: MenuLayoutInfo) -> CGRect {
        if let rect = info.origin {
            return transform(rect: menuDisappearLayout(rect: rect, info: info), info: info)
        } else {
            assertionFailure()
            return .zero
        }
    }

    open func calculateUpdate(info: MenuLayoutInfo, downward: Bool, offset: CGPoint) -> CGRect {
        return transform(rect: menuUpdateLayout(info: info, downward: downward, offset: offset), info: info)
    }
    // MARK: open 方法
    // 可以重写下面的四个方法
    open func menuLayout(info: MenuLayoutInfo) -> CGRect {
        assertionFailure("不能直接使用BaseMenuLayout的menuLayout方法，需要重写此方法")
        return .zero
    }

    open func menuAppearLayout(rect: CGRect, info: MenuLayoutInfo) -> CGRect {
        if let animationRule = animationRule {
            return animationRule.appearLayout(rect: rect, info: info)
        }
        return rect
    }

    open func menuDisappearLayout(rect: CGRect, info: MenuLayoutInfo) -> CGRect {
        if let animationRule = animationRule {
            return animationRule.disappearLayout(rect: rect, info: info)
        }
        return rect
    }

    open func menuUpdateLayout(info: MenuLayoutInfo, downward: Bool, offset: CGPoint) -> CGRect {
        assertionFailure("不能直接使用BaseMenuLayout的menuUpdateLayout方法，需要重写此方法")
        return .zero
    }

    public init() {

    }

    // MARK: 计算方法
    // 边界判断
    // rect: 当前menu的frame
    open func transform(rect: CGRect, info: MenuLayoutInfo) -> CGRect {
        // 将let变成var
        var rect = rect
        let renderRect = renderRect(info: info)

        // 让rect在可以绘制范围内
        if rect.minX < renderRect.minX { rect = CGRect(origin: CGPoint(x: renderRect.minX, y: rect.origin.y), size: rect.size)}
        if rect.minY < renderRect.minY { rect = CGRect(origin: CGPoint(x: rect.origin.x, y: renderRect.minY), size: rect.size) }
        if rect.maxX > renderRect.maxX { rect = CGRect(origin: CGPoint(x: renderRect.maxX - rect.width, y: rect.origin.y), size: rect.size) }
        if rect.maxY > renderRect.maxY { rect = CGRect(origin: CGPoint(x: rect.origin.x, y: renderRect.maxY - rect.height), size: rect.size) }

        return rect
    }

    // 返回menu绘制区域
    open func renderRect(info: MenuLayoutInfo) -> CGRect {
        guard let window = info.menuVC.view.window else { return .zero }
        var menuRenderFrame = self.menuVCRect(info: info)
        if isUseSystemSafeArea {
            let windowSafeRect = window.bounds.inset(by: window.safeAreaInsets)
            menuRenderFrame = windowSafeRect.intersection(menuRenderFrame)
        }
        let menuInsetsFrame = menuRenderFrame.inset(by: insets)
        return window.convert(menuInsetsFrame, to: info.menuVC.view)
    }

    // menuVC相对于window的位置
    open func menuVCRect(info: MenuLayoutInfo) -> CGRect {
        return info.menuVC.view.convert(info.menuVC.view.bounds, to: info.menuVC.view.window)
    }

    // 组合x轴和y轴，并进行边界判断
    open func layout(xLayout: CGFloat, yLayout: CGFloat, info: MenuLayoutInfo) -> CGRect {
        let menuRect = CGRect(origin: CGPoint(x: xLayout, y: yLayout), size: info.menuSize)
        return transform(rect: menuRect, info: info)
    }
}
