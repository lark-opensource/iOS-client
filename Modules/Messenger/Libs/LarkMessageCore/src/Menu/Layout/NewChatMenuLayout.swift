//
//  ChatMenuLayout.swift
//  LarkMessageCore
//
//  Created by kangsiwan on 2021/12/22.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RichLabel
import LarkMenuController
import LarkSetting
import LKCommonsLogging

// chatMenuLayout满足此协议，来让规则可以拿到额外的信息
protocol ChatMenuLayoutExtra: AnyObject {
    func isByDrag() -> Bool
    func isNewLayoutStyle(info: MenuLayoutInfo) -> Bool
    func getLastAvoidRect(info: MenuLayoutInfo) -> CGRect?
    func getCurrentAvoidRect(info: MenuLayoutInfo) -> CGRect?
    func getLKSelectedLabel(info: MenuLayoutInfo) -> LKSelectionLabel?
}
// y轴方向的不遮挡
// chat向上滑，menu向上展示，且可以放下；chat向下滑，menu向下展示，且可以放下；否则上面可以放下放在上面，下面可以放下放在下面
struct YUnblankRule: MenuLayoutRule {
    var priority: MenuRulePriority
    let offset: CGFloat
    weak var delegate: ChatMenuLayoutExtra?
    private static let logger = Logger.log(YUnblankRule.self, category: "Chat.Menu.Layout.Y.Unblank.Rule")
    init(delegate: ChatMenuLayoutExtra?, priority: MenuRulePriority = .normal, offset: CGFloat = 0) {
        self.delegate = delegate
        self.priority = priority
        self.offset = offset
    }

    func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool {
        YUnblankRule.logger.info("canUseCondition")
        guard let currentRect = delegate?.getCurrentAvoidRect(info: info) else { return false }
        let renderRect = layout.renderRect(info: info)
        if (currentRect.top - info.menuSize.height - offset > renderRect.top) ||
           (currentRect.bottom + info.menuSize.height + offset < renderRect.bottom) {
            YUnblankRule.logger.info("canUseCondition true")
            return true
        }
        return false
    }
    func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        guard let currentRect = delegate?.getCurrentAvoidRect(info: info) else { return nil }
        let renderRect = layout.renderRect(info: info)
        // 如果可以拿到上一次的位置，优先根据上一次的位置不遮挡放menu
        if let lastRect = delegate?.getLastAvoidRect(info: info) {
            // chat向上滑，menu向上展示，且可以放下
            if currentRect.centerY <= lastRect.centerY, currentRect.top - info.menuSize.height - offset >= renderRect.top {
                YUnblankRule.logger.info("ruleImplement \(currentRect.top - info.menuSize.height - offset)")
                return currentRect.top - info.menuSize.height - offset
            }
            // chat向下滑，menu向下展示，且可以放下
            else if currentRect.centerY > lastRect.centerY, currentRect.bottom + info.menuSize.height + offset <= renderRect.bottom {
                YUnblankRule.logger.info("ruleImplement \(currentRect.bottom + offset)")
                return currentRect.bottom + offset
            }
        }
        // 如果没有上一次的位置，或者根据上一次位置不能放下menu。则哪里能放下就放哪里
        // 向上展示，且可以放下
        if currentRect.top - info.menuSize.height - offset >= renderRect.top {
            YUnblankRule.logger.info("ruleImplement \(currentRect.top - info.menuSize.height - offset)")
            return currentRect.top - info.menuSize.height - offset
        }
        // 向下展示，且可以放下
        else if currentRect.bottom + info.menuSize.height + offset <= renderRect.bottom {
            YUnblankRule.logger.info("ruleImplement \(currentRect.bottom + offset)")
            return currentRect.bottom + offset
        }
        // 不论向上或者向下放，都放不下menu
        YUnblankRule.logger.info("ruleImplement menu放不下")
        return nil
    }
}

// y轴方向遮挡
// chat向上滑，menu向上展示，不考虑是否可以放下；chat向下滑，menu向下展示，不考虑是否可以放下
struct YBlankRule: MenuLayoutRule {
    var priority: MenuRulePriority
    let offset: CGFloat
    weak var delegate: ChatMenuLayoutExtra?
    private static let logger = Logger.log(YBlankRule.self, category: "Chat.Menu.Layout.Y.Blank.Rule")
    init(delegate: ChatMenuLayoutExtra?, priority: MenuRulePriority = .low, offset: CGFloat = 0) {
        self.delegate = delegate
        self.priority = priority
        self.offset = offset
    }
    func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool {
        YBlankRule.logger.info("canUseCondition")
        guard let currentRect = delegate?.getCurrentAvoidRect(info: info), let lastRect = delegate?.getLastAvoidRect(info: info) else { return false }
        YBlankRule.logger.info("canUseCondition true")
        return true
    }
    func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        guard let currentRect = delegate?.getCurrentAvoidRect(info: info), let lastRect = delegate?.getLastAvoidRect(info: info) else { return nil }
        if currentRect.centerY <= lastRect.centerY {
            YBlankRule.logger.info("ruleImplement \(currentRect.top - info.menuSize.height - offset)")
            return currentRect.top - info.menuSize.height - offset
        } else {
            YBlankRule.logger.info("ruleImplement \(currentRect.bottom + offset)")
            return currentRect.bottom + offset
        }
    }
}

// x轴方向：根据选择的label居中
struct XSelectOneLineRule: MenuLayoutRule {
    var priority: MenuRulePriority
    weak var delegate: ChatMenuLayoutExtra?
    private static let logger = Logger.log(XSelectOneLineRule.self, category: "Chat.Menu.Layout.X.SelectOneLine.Rule")
    init(delegate: ChatMenuLayoutExtra?, priority: MenuRulePriority = .high) {
        self.priority = priority
        self.delegate = delegate
    }
    // 如果选中的是一行，则根据一行的居中
    func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool {
        XSelectOneLineRule.logger.info("canUseCondition")
        guard let label = delegate?.getLKSelectedLabel(info: info) else {
            return false
        }
        let startC = label.convert(label.startCursor.rect, to: info.menuVC.view)
        let endC = label.convert(label.endCursor.rect, to: info.menuVC.view)
        if startC.top == endC.top {
            XSelectOneLineRule.logger.info("canUseCondition true")
            return true
        }
        return false
    }
    func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        guard let label = delegate?.getLKSelectedLabel(info: info) else { return nil }
        let startC = label.convert(label.startCursor.rect, to: info.menuVC.view)
        let endC = label.convert(label.endCursor.rect, to: info.menuVC.view)
        if startC.top == endC.top {
            XSelectOneLineRule.logger.info("ruleImplement \(startC.left + (endC.right - startC.left) / 2 - info.menuSize.width / 2)")
            return startC.left + (endC.right - startC.left) / 2 - info.menuSize.width / 2
        }
        return nil
    }
}

// y轴方向：第一次出现，并且满足特定条件，根据手指位置放menu
struct YFirstRule: MenuLayoutRule {
    weak var delegate: ChatMenuLayoutExtra?
    var priority: MenuRulePriority
    let offset: CGFloat
    private static let logger = Logger.log(YFirstRule.self, category: "Chat.Menu.Layout.Y.First.Rule")
    init(delegate: ChatMenuLayoutExtra?, priority: MenuRulePriority = .high, offset: CGFloat = 0) {
        self.delegate = delegate
        self.priority = priority
        self.offset = offset
    }

    func canUseCondition(info: MenuLayoutInfo, layout: CommonMenuLayout) -> Bool {
        YFirstRule.logger.info("canUseCondition info.origin \(info.origin)")
        if info.origin == nil, let isNewLayoutStyle = delegate?.isNewLayoutStyle(info: info), isNewLayoutStyle,
           info.transformTrigerLocation() != nil, let isByDrag = delegate?.isByDrag(), !isByDrag {
            YFirstRule.logger.info("canUseCondition true")
            return true
        }
        return false
    }

    func ruleImplement(info: MenuLayoutInfo, layout: CommonMenuLayout) -> CGFloat? {
        guard let point = info.transformTrigerLocation() else { return nil }
        let renderRect = layout.renderRect(info: info)
        if renderRect.top + info.menuSize.height < point.y {
            YFirstRule.logger.info("ruleImplement \(point.y - info.menuSize.height - offset)")
            return point.y - info.menuSize.height - offset
        } else {
            YFirstRule.logger.info("ruleImplement \(point.y + offset)")
            return point.y + offset
        }
    }
}

public final class ChatMenuLayout: CommonMenuLayout, ChatMenuLayoutExtra {
    // MARK: public 属性
    public static let TriggerByDragKey = "TriggerByDragKey"

    // MARK: private 属性
    static let copyMessageTypes: [Message.TypeEnum] = [.text, .post]
    private static let logger = Logger.log(ChatMenuLayout.self, category: "menu.layout.chatMenuLayout")
    // 上一次 消失的时候 trigerView 的位置
    // 用于下一次出现的时候进行判断
    private var lastTrigerViewRect: CGRect?
    // 外部设置安全区域
    private let displayViewBlcok: ((UIView) -> UIView?)?
    private let extraInfo: [String: Any]
    // 将要出现时的offset
    private let appearOffset: CGFloat = 22
    private let menuOffset: CGFloat = 8

    // 如果为true，选中文字时根据游标来返回位置。否则返回lark的位置
    // 如果为false，在第一次展示的时候，不遮挡view
    private let isNewLayoutStyle: Bool
    // MARK: public 方法
    public init(insets: UIEdgeInsets = UIEdgeInsets.zero,
                displayViewBlcok: ((UIView) -> UIView?)?,
                isNewLayoutStyle: Bool,
                extraInfo: [String: Any]) {
        // 如果为true，选中文字时根据游标来返回位置。否则返回lark的位置
        // 如果为false，在第一次展示的时候，不遮挡view
        self.isNewLayoutStyle = isNewLayoutStyle
        self.displayViewBlcok = displayViewBlcok
        self.extraInfo = extraInfo
        super.init(xLayoutRules: [], yLayoutRules: [])
        // X轴
        let xLayoutRules: [MenuLayoutRule] = [XSelectOneLineRule(delegate: self),
                                              XFollowGestureRule(),
                                              XMiddleRule()]
        // Y轴
        let yLayoutRules: [MenuLayoutRule] = [YFirstRule(delegate: self, offset: appearOffset),
                                              YUnblankRule(delegate: self, offset: menuOffset),
                                              YBlankRule(delegate: self, offset: 0)]
        super.xLayoutRules = xLayoutRules
        super.yLayoutRules = yLayoutRules
        self.insets = insets
        self.animationRule = YTranslateAnimationRule(offset: appearOffset)
    }

    public override func menuAppearLayout(rect: CGRect, info: MenuLayoutInfo) -> CGRect {
        if info.origin == nil, isNewLayoutStyle {
            return super.menuAppearLayout(rect: rect, info: info)
        } else {
            return rect
        }
    }

    public override func menuDisappearLayout(rect: CGRect, info: MenuLayoutInfo) -> CGRect {
        self.lastTrigerViewRect = info.transformTrigerView()
        return super.menuDisappearLayout(rect: rect, info: info)
    }

    public override func menuUpdateLayout(info: MenuLayoutInfo, downward: Bool, offset: CGPoint) -> CGRect {
        let rect = menuLayout(info: info)
        // 为了解决：当view在上方出现，点击加号后上面放不下，则展示在下面的问题
        // 新位置和老位置，在view的同一侧，则使用新位置；在view的不同侧，则新位置要放在老位置的一侧
        guard let origin = info.origin, let currentRect = getCurrentAvoidRect(info: info) else {
            let x = rect.origin.x + offset.x
            let y = rect.origin.y + (downward ? offset.y : -offset.y)
            return CGRect(origin: CGPoint(x: x, y: y), size: info.menuSize)
        }
        let oldLocationIsTop: Bool = origin.top < currentRect.top
        let newLocationIsTop: Bool = rect.top < currentRect.top
        if oldLocationIsTop == newLocationIsTop {
            let x = rect.origin.x + offset.x
            let y = rect.origin.y + (downward ? offset.y : -offset.y)
            return CGRect(origin: CGPoint(x: x, y: y), size: info.menuSize)
        } else if oldLocationIsTop {
            let x = rect.origin.x + offset.x
            // view的y轴位置 - menu的高度
            let y = currentRect.top - rect.size.height
            return CGRect(origin: CGPoint(x: x, y: y), size: info.menuSize)
        } else {
            return CGRect(origin: origin.origin, size: info.menuSize)
        }
    }

    // MARK: protocol
    func getLKSelectedLabel(info: MenuLayoutInfo) -> LKSelectionLabel? {
        if let displayView = self.displayViewBlcok?(info.trigerView), let label = displayView as? LKSelectionLabel, showOneActionBar(info) {
            return label
        }
        return nil
    }
    func isByDrag() -> Bool {
        return (extraInfo[ChatMenuLayout.TriggerByDragKey] as? Bool) ?? false
    }
    func isNewLayoutStyle(info: MenuLayoutInfo) -> Bool {
        return isNewLayoutStyle
    }
    func getLastAvoidRect(info: MenuLayoutInfo) -> CGRect? {
        return self.lastTrigerViewRect
    }
    func getCurrentAvoidRect(info: MenuLayoutInfo) -> CGRect? {
        if var rect = info.transformTrigerView() {
            if let labelRect = self.displaySelectionRect(info: info) {
                rect = labelRect
            }
            return rect
        }
        return nil
    }

    // 是否没有reactionBar
    private func showOneActionBar(_ info: MenuLayoutInfo) -> Bool {
        let menuVC = info.menuVC as? MenuViewController
        let messageMenuView = menuVC?.viewModel.menuView as? MenuBar
        return messageMenuView?.hideRelactionBar ?? false
    }

    // 返回用于之后布局的 rect, 如果是 label，则返回可拖拽区域
    private func displaySelectionRect(info: MenuLayoutInfo) -> CGRect? {
        guard let displayView = self.displayViewBlcok?(info.trigerView),
            let displayRect = info.transformView(view: displayView) else { return nil }
        let offset: CGFloat = 10
        let showOneActionBar = self.showOneActionBar(info)
        if let label = displayView as? LKSelectionLabel, (isNewLayoutStyle || showOneActionBar) {
            return CGRect(
                x: displayRect.minX,
                y: displayRect.minY + label.startCursor.rect.top - offset,
                width: displayRect.width,
                height: label.endCursor.rect.bottom - label.startCursor.rect.top + 2 * offset
            )
        } else if displayView is LKSelectionLabel {
            return CGRect(x: displayRect.minX, y: displayRect.minY - offset, width: displayRect.width, height: displayRect.height + 2 * offset)
        } else {
            return displayRect
        }
    }
}
