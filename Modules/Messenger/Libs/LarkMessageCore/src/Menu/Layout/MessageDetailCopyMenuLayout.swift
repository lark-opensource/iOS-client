//
//  MessageDetailCopyMenuLayout.swift
//  Action
//
//  Created by 赵冬 on 2019/8/8.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RichLabel
import LarkMenuController

// 会话页面布局规则文档 https://bytedance.feishu.cn/space/doc/OPhfest2xG8pzQlacVu81d

protocol MessageDetailCopyExtra: AnyObject {
    func isByDrag() -> Bool
    func getCurrentAvoidRect(info: MenuLayoutInfo) -> CGRect?
}

struct YLayoutRule: MenuLayoutRule {
    var priority: MenuRulePriority
    weak var delegate: MessageDetailCopyExtra?
    init(delegate: MessageDetailCopyExtra?, priority: MenuRulePriority = .normal) {
        self.delegate = delegate
        self.priority = priority
    }
    func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool {
        if delegate?.getCurrentAvoidRect(info: info) != nil {
            return true
        }
        return false
    }
    func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        guard let rect = delegate?.getCurrentAvoidRect(info: info) else {
            return nil
        }
        let render = layout.renderRect(info: info)
        if rect.top - info.menuSize.height > render.top {
            return rect.top - info.menuSize.height
        } else if rect.bottom + info.menuSize.height < render.bottom {
            return rect.bottom
        } else {
            return rect.bottom
        }
    }
}

struct YMessageDetailCopyRule: MenuLayoutRule {
    var priority: MenuRulePriority
    let offset: CGFloat
    weak var delegate: MessageDetailCopyExtra?
    init(delegate: MessageDetailCopyExtra?, priority: MenuRulePriority = .high, offset: CGFloat = 0) {
        self.delegate = delegate
        self.priority = priority
        self.offset = offset
    }
    func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool {
        if let isByDrag = delegate?.isByDrag(), !isByDrag, info.transformTrigerLocation() != nil {
            return true
        }
        return false
    }
    func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        guard let isByDrag = delegate?.isByDrag(), !isByDrag, let point = info.transformTrigerLocation() else { return nil }
        let render = layout.renderRect(info: info)
        if render.top + info.menuSize.height < point.y {
            return point.y - info.menuSize.height - offset
        } else {
            return point.y + offset
        }
    }
}

final class NewMessageDetailCopyMenuLayout: CommonMenuLayout, MessageDetailCopyExtra {
    let message: Message
    let displayViewBlcok: ((UIView) -> UIView?)?
    let extraInfo: [String: Any]
    let appearOffset: CGFloat = 22
    static let copyMessageTypes: [Message.TypeEnum] = [.text, .post]
    public init(
        message: Message,
        insets: UIEdgeInsets = UIEdgeInsets.zero,
        extraInfo: [String: Any],
        displayViewBlcok: ((UIView) -> UIView?)?) {
            self.message = message
            self.extraInfo = extraInfo
            self.displayViewBlcok = displayViewBlcok
            super.init(xLayoutRules: [], yLayoutRules: [])
            super.xLayoutRules = [XFollowGestureRule(), XMiddleRule()]
            super.yLayoutRules = [YMessageDetailCopyRule(delegate: self, offset: appearOffset), YLayoutRule(delegate: self)]
            self.insets = insets
            self.animationRule = YTranslateAnimationRule(offset: appearOffset)
    }

    // MARK: protocol
    func isByDrag() -> Bool {
        return (extraInfo[ChatMenuLayout.TriggerByDragKey] as? Bool) ?? false
    }
    func getCurrentAvoidRect(info: MenuLayoutInfo) -> CGRect? {
        guard var layoutRect = info.transformTrigerView() else { return nil }
        if let labelRect = self.displaySelectionRect(info: info) {
            layoutRect = labelRect
        }
        return layoutRect
    }

    // MARK: public
    public override func menuAppearLayout(rect: CGRect, info: MenuLayoutInfo) -> CGRect {
        if info.origin == nil {
            let rect = menuLayout(info: info)
            return super.menuAppearLayout(rect: rect, info: info)
        } else {
            return rect
        }
    }

    public override func menuUpdateLayout(info: MenuLayoutInfo, downward: Bool, offset: CGPoint) -> CGRect {
        if let origin = info.origin {
            let x = origin.origin.x + offset.x
            let y = origin.origin.y + (downward ? offset.y : (origin.height - info.menuSize.height + offset.y))
            return CGRect(origin: CGPoint(x: x, y: y), size: info.menuSize)
        } else {
            assertionFailure()
            return .zero
        }
    }

    // MARK: private
    // 返回用于之后布局的 rect, 如果是 label，则返回可拖拽区域
    private func displaySelectionRect(info: MenuLayoutInfo) -> CGRect? {
        guard let displayView = self.displayViewBlcok?(info.trigerView),
            let displayRect = info.transformView(view: displayView) else { return nil }

        let offset: CGFloat = 10
        if let label = displayView as? LKSelectionLabel {
            return CGRect(
                x: displayRect.minX,
                y: displayRect.minY + label.startCursor.rect.top - offset,
                width: displayRect.width,
                height: label.endCursor.rect.bottom - label.startCursor.rect.top + 2 * offset
            )
        } else {
            return CGRect(
                x: displayRect.minX,
                y: displayRect.minY - offset,
                width: displayRect.width,
                height: displayRect.height + 2 * offset
            )
        }
    }
}

public final class MessageDetailCopyMenuLayout: MenuBarLayout {

    let message: Message
    let insets: UIEdgeInsets
    let displayViewBlcok: ((UIView) -> UIView?)?
    let extraInfo: [String: Any]

    let appearOffset: CGFloat = 22

    // 上一次 消失的时候 trigerView 的位置
    // 用于下一次出现的时候进行判断
    var lastTrigerViewRect: CGRect?

    public init(
        message: Message,
        insets: UIEdgeInsets = UIEdgeInsets.zero,
        extraInfo: [String: Any],
        displayViewBlcok: ((UIView) -> UIView?)?
    ) {
        self.message = message
        self.insets = insets
        self.extraInfo = extraInfo
        self.displayViewBlcok = displayViewBlcok
    }

    static let copyMessageTypes: [Message.TypeEnum] = [.text, .post]

    public func calculate(info: MenuLayoutInfo) -> CGRect {
        return self.layout(info: info)
    }

    public func calculateAppear(info: MenuLayoutInfo) -> CGRect {
        if info.origin == nil {
            return self.appearLayout(info: info)
        } else {
            return self.calculate(info: info)
        }
    }

    public func calculateDisappear(info: MenuLayoutInfo) -> CGRect {
        self.lastTrigerViewRect = info.transformTrigerView()
        if let origin = info.origin {
            return origin
        } else {
            assertionFailure()
            return .zero
        }
    }

    public func calculateUpdate(info: MenuLayoutInfo, downward: Bool, offset: CGPoint) -> CGRect {
        if let origin = info.origin {
            let originPoint: CGPoint
            if downward {
                originPoint = CGPoint(x: origin.origin.x + offset.x, y: origin.origin.y + offset.y)
            } else {
                originPoint = CGPoint(
                    x: origin.origin.x + offset.x,
                    y: origin.origin.y + origin.height - info.menuSize.height + offset.y
                )
            }
            return self.transform(rect: CGRect(origin: originPoint, size: info.menuSize), info: info)
        } else {
            assertionFailure()
            return .zero
        }
    }

    // MARK: - Private

    // 判断 rect 边界 保证 rect 合法
    private func transform(rect: CGRect, info: MenuLayoutInfo) -> CGRect {
        var rect = rect
        let renderRect = self.renderRect(info: info)

        // 首先需要 rect 的范围在 menuVC 内部
        if rect.minX < renderRect.minX { rect = CGRect(origin: CGPoint(x: renderRect.minX, y: rect.origin.y), size: rect.size) }
        if rect.minY < renderRect.minY { rect = CGRect(origin: CGPoint(x: rect.origin.x, y: renderRect.minY), size: rect.size) }
        if rect.maxX > renderRect.maxX { rect = CGRect(origin: CGPoint(x: renderRect.maxX - rect.width, y: rect.origin.y), size: rect.size) }
        if rect.maxY > renderRect.maxY { rect = CGRect(origin: CGPoint(x: rect.origin.x, y: renderRect.maxY - rect.height), size: rect.size) }

        return rect
    }

    // 返回 menu 绘制区域
    private func renderRect(info: MenuLayoutInfo) -> CGRect {

        guard let window = info.menuVC.view.window else { return .zero }
        // window safe Rect
        let windowSafeRect = window.bounds.inset(by: window.safeAreaInsets)
        // menu 在 window 上的 frame
        let menuVcFrame = self.menuVCRect(info: info)
        let menuRenderFrame = windowSafeRect.intersection(menuVcFrame)
        if menuRenderFrame.height <= 0 {
            assertionFailure()
            return .zero
        }
        let menuInsetsFrame = menuRenderFrame.inset(by: insets)
        return window.convert(menuInsetsFrame, to: info.menuVC.view)
    }

    private func menuVCRect(info: MenuLayoutInfo) -> CGRect {
        return info.menuVC.view.convert(info.menuVC.view.bounds, to: info.menuVC.view.window)
    }

    private func layout(info: MenuLayoutInfo) -> CGRect {
        let x = self.xLayout(info: info)
        var y = self.yLayout(info: info)

        /// 被 drag 触发的 menu，第一次不跟手出现
        let triggerByDrag = (self.extraInfo[ChatMenuLayout.TriggerByDragKey] as? Bool) ?? false

        if !triggerByDrag,
            let point = info.transformTrigerLocation() {
            let renderRect = self.renderRect(info: info)
            if renderRect.top + info.menuSize.height < point.y {
                y = point.y - info.menuSize.height - appearOffset
            } else {
                y = point.y + appearOffset
            }
        }

        let menuRect = CGRect(origin: CGPoint(x: x, y: y), size: info.menuSize)
        return self.transform(rect: menuRect, info: info)
    }

    private func appearLayout(info: MenuLayoutInfo) -> CGRect {
        var rect = self.layout(info: info)

        if let location = info.transformTrigerLocation() {
            if location.y > rect.centerY {
                rect.origin.y += min(appearOffset, location.y - rect.centerY)
            } else {
                rect.origin.y -= min(appearOffset, rect.centerY - location.y)
            }
        }

        return self.transform(rect: rect, info: info)
    }

    // menu x 轴 布局
    private func xLayout(info: MenuLayoutInfo) -> CGFloat {
        if let point = info.transformTrigerLocation() {
            return point.x - info.menuSize.width / 2
        }
        let x = (info.menuVC.view.frame.width - info.menuSize.width - insets.left - insets.right) / 2 + insets.left
        return x
    }

    // menu y 轴 布局
    private func yLayout(info: MenuLayoutInfo) -> CGFloat {
        guard let rect = info.transformTrigerView() else { return 0 }

        // 用于布局的 rect
        var layoutRect = rect
        if let labelRect = self.displaySelectionRect(info: info) {
            layoutRect = labelRect
        }

        var y: CGFloat = rect.bottom
        let renderRect = self.renderRect(info: info)
        // 判断上方是否可以放下
        if (layoutRect.top - info.menuSize.height) > renderRect.top {
            y = layoutRect.top - info.menuSize.height
            return y
        }
        // 判断下方是否可以放下
        if (layoutRect.bottom + info.menuSize.height) < renderRect.bottom {
            y = layoutRect.bottom
            return y
        }
        return y
    }

    // 返回用于之后布局的 rect, 如果是 label，则返回可拖拽区域
    private func displaySelectionRect(info: MenuLayoutInfo) -> CGRect? {
        guard let displayView = self.displayViewBlcok?(info.trigerView),
            let displayRect = info.transformView(view: displayView) else { return nil }

        let offset: CGFloat = 10

        if let label = displayView as? LKSelectionLabel {
            return CGRect(
                x: displayRect.minX,
                y: displayRect.minY + label.startCursor.rect.top - offset,
                width: displayRect.width,
                height: label.endCursor.rect.bottom - label.startCursor.rect.top + 2 * offset
            )
        } else {
            return CGRect(
                x: displayRect.minX,
                y: displayRect.minY - offset,
                width: displayRect.width,
                height: displayRect.height + 2 * offset
            )
        }
    }
}
