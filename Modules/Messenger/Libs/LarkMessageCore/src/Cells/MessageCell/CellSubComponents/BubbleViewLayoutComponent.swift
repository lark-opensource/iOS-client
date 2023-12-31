//
//  BubbleViewLayoutComponent.swift
//  LarkChat
//
//  Created by Ping on 2023/2/21.
//

import UIKit
import Foundation
import LarkSetting
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import UniverseDesignColor

// 气泡样式
public enum BubbleStyle: Equatable {
    case normal //正常样式
    case thread //话题样式
}

public struct BubbleViewConfig {
    // 是否改变气泡上半部分的圆角
    public var changeTopCorner: Bool
    // 是否改变气泡下半部分的圆角
    public var changeBottomCorner: Bool
    public var changeRaiusReverse: Bool
    // 是否支持Bubble高亮
    public var supportHighlight: Bool
    public var bubbleStyle: BubbleStyle
    // 边框颜色
    public var strokeColor: UIColor
    // 背景颜色
    public var fillColor: UIColor
    // 边框宽度
    public var strokeWidth: CGFloat

    public init(changeTopCorner: Bool = false,
                changeBottomCorner: Bool = false,
                changeRaiusReverse: Bool = false,
                supportHighlight: Bool = true,
                bubbleStyle: BubbleStyle = .normal,
                strokeColor: UIColor = UIColor.clear,
                fillColor: UIColor = UIColor.clear,
                strokeWidth: CGFloat = 1) {
        self.changeTopCorner = changeTopCorner
        self.changeBottomCorner = changeBottomCorner
        self.changeRaiusReverse = changeRaiusReverse
        self.supportHighlight = supportHighlight
        self.bubbleStyle = bubbleStyle
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.strokeWidth = strokeWidth
    }
}

public final class BubbleViewLayoutComponentProps<C: Context> {
    public var contentConfig: ContentConfig?
    public var bubbleConfig: BubbleViewConfig = BubbleViewConfig()
    // 是否是话题模式下创建的
    public var displayInThreadMode: Bool = false
    // 气泡背景、宽度FG，FG开后：话题模式创建的背景为白色，气泡宽度固定为屏幕的宽度；话题回复背景为蓝/灰色，气泡宽度根据内容自适应
    public var threadReplyBubbleOptimize: Bool = false
    public var contentPreferMaxWidth: CGFloat = 0
    public var contentPadding: CGFloat = 0
    public var isFromMe: Bool = false
    // 是否是文件卡片（文件消息且渲染出了卡片）
    public var isFileCard: Bool = false
    public var avatarLayout: AvatarLayout = .left
    public var bubbleTapHandler: (() -> Void)?
    public var oneOfSubComponentsDisplay: (([SubType]) -> Bool)?
    // 内容
    public var contentComponent: ComponentWithContext<C>
    // 子组件
    public var subComponents: [SubType: ComponentWithContext<C>] = [:]

    public init(contentComponent: ComponentWithContext<C>) {
        self.contentComponent = contentComponent
    }
}

public final class BubbleViewLayoutComponent<C: Context> {
    public var props: BubbleViewLayoutComponentProps<C> {
        didSet {
            update()
        }
    }
    let context: C?

    /// 气泡
    private lazy var bubbleView: BubbleViewComponent<C> = {
        self.props.contentComponent._style.maxWidth = CSSValue(
            cgfloat: self.bubbleWidth()
        )
        let props = BubbleViewComponent<C>.Props()
        props.key = PostViewComponentConstant.bubbleKey
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.flexWrap = .noWrap
        style.alignItems = .flexStart

        return BubbleViewComponent<C>(props: props, style: style, context: context)
    }()

    /// 消息气泡高亮蒙层
    lazy var highLightBubbleView: HighlightFrontBubbleViewComponent<C> = {
        self.props.contentComponent._style.maxWidth = CSSValue(
            cgfloat: self.bubbleWidth()
        )

        let props = HighlightFrontBubbleViewComponent<C>.Props()
        props.key = MessageCommonCell.highlightBubbleViewKey
        let style = ASComponentStyle()
        style.position = .absolute
        style.backgroundColor = UIColor.clear
        style.top = 0
        style.bottom = 0
        style.width = 100%

        return HighlightFrontBubbleViewComponent<C>(props: props, style: style, context: context)
    }()

    private lazy var bubbleTouchView: TouchViewComponent<C> = {
        let props = TouchViewComponentProps()
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.flexWrap = .noWrap
        style.alignItems = .flexStart
        return TouchViewComponent<C>(props: props, style: style, context: context)
    }()

    private var wrapper: CornerRadiusComponent<C> = CornerRadiusComponent<C>(props: CornerRadiusComponent.Props(), style: ASComponentStyle())

    public init(props: BubbleViewLayoutComponentProps<C>, context: C? = nil) {
        self.props = props
        self.context = context
    }

    private func update() {
        func setTopLeftRightMargin(_ component: ComponentWithContext<C>, margin: CSSValue) {
            component._style.marginTop = margin
            component._style.marginLeft = margin
            component._style.marginRight = margin
        }

        // TODO: @姚启灏
        // CornerRadiusView直接添加subComponent会导致reuse的bug
        let whiteWrapper = self.getUIViewComponent()
        var whiteWrapperSubComponents: [ComponentWithContext<C>] = []
        var bubbleSubComponents: [ComponentWithContext<C>] = []

        let margin = CSSValue(cgfloat: props.contentPadding)
        let padding = CSSValue(cgfloat: props.contentPadding)

        // 回复
        if let reply = props.subComponents[.reply] ?? props.subComponents[.cryptoReply] {
            reply._style.flexGrow = 1
            reply._style.alignSelf = .stretch
            whiteWrapperSubComponents.append(reply)
            if props.isFromMe {
                whiteWrapper._style.paddingBottom = padding
            }
        }

        if let reply = props.subComponents[.syncToChat] {
            whiteWrapperSubComponents.append(reply)
        }

        // 内容
        // thread模式下都添加margin
        let hasMargin = (props.bubbleConfig.bubbleStyle == .thread && !props.isFileCard) ? true : (props.contentConfig?.hasMargin ?? true)
        // 文件卡片总是有paddingBottom
        let hasPaddingBottom: Bool = props.isFileCard ? true : props.contentConfig?.hasPaddingBottom ?? true
        whiteWrapperSubComponents.append(props.contentComponent)
        if props.contentConfig?.hideContent ?? false {
            props.contentComponent._style.display = .none
        } else {
            props.contentComponent._style.display = .flex
        }
        setTopLeftRightMargin(props.contentComponent, margin: hasMargin ? margin : 0)
        if props.bubbleConfig.bubbleStyle == .thread {
            if !(props.contentConfig?.threadStyleConfig?.addBorderBySelf ?? false) {
                props.contentComponent._style.cornerRadius = 10
                if props.isFileCard {
                    // 文件卡片thread样式特化：不需要添加border（也不会addBorderBySelf）
                    props.contentComponent._style.boxSizing = .contentBox
                    props.contentComponent._style.border = nil
                } else {
                    props.contentComponent._style.boxSizing = .borderBox
                    props.contentComponent._style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderCard, style: .solid))
                }
            }
        }

        props.contentComponent._style.maxWidth = CSSValue(
            cgfloat: props.contentPreferMaxWidth
        )

        // docs预览
        if let docPreview = props.subComponents[.docsPreview] {
            setTopLeftRightMargin(docPreview, margin: margin)
            whiteWrapperSubComponents.append(docPreview)
        }

        // url预览
        if let urlPreview = props.subComponents[.urlPreview] {
            setTopLeftRightMargin(urlPreview, margin: margin)
            whiteWrapperSubComponents.append(urlPreview)
        }

        // TangramComponent渲染出的预览
        if let tcPreview = props.subComponents[.tcPreview] {
            whiteWrapperSubComponents.append(tcPreview)
        }

        // actionButton
        if let actionButton = props.subComponents[.actionButton] {
            setTopLeftRightMargin(actionButton, margin: margin)
            whiteWrapperSubComponents.append(actionButton)
        }

        // 如果有引用链接 + 赞踩/重新生成，那么引用链接 + 赞踩赞踩/重新生成占满气泡，赞踩/重新生成用绝对布局展示在引用链接右上方
        if let referenceList = props.subComponents[.referenceList], let feedbackRegenerate = props.subComponents[.feedbackRegenerate] {
            // 重置下面else分支设置的style、设置绝对布局
            setTopLeftRightMargin(feedbackRegenerate, margin: 0); feedbackRegenerate._style.alignSelf = .flexStart
            feedbackRegenerate._style.position = .absolute; feedbackRegenerate._style.right = 0; feedbackRegenerate._style.top = 0
            // 搞一个容器来撑满气泡
            let containerComponentStyle = ASComponentStyle(); containerComponentStyle.width = CSSValue(cgfloat: self.bubbleWidth() - 2 * props.contentPadding)
            let containerComponent = ASLayoutComponent(key: "reference_feedback_regenerate_component_key", style: containerComponentStyle, [referenceList, feedbackRegenerate])
            setTopLeftRightMargin(containerComponent, margin: margin)
            whiteWrapperSubComponents.append(containerComponent)
        } else if let feedbackRegenerate = props.subComponents[.feedbackRegenerate] { // 如果只有赞踩/重新生成，则赞踩/重新生成和气泡右对齐
            // 重置上面if分支设置的style、设置右对齐
            feedbackRegenerate._style.position = .relative; feedbackRegenerate._style.right = CSSValueUndefined; feedbackRegenerate._style.top = CSSValueUndefined
            setTopLeftRightMargin(feedbackRegenerate, margin: margin); feedbackRegenerate._style.alignSelf = .flexEnd
            whiteWrapperSubComponents.append(feedbackRegenerate)
        } else if let referenceList = props.subComponents[.referenceList] {
            // 如果只有引用链接，则正常展示
            setTopLeftRightMargin(referenceList, margin: margin)
            whiteWrapperSubComponents.append(referenceList)
        }

        // 点赞
        if let reaction = props.subComponents[.reaction] {
            whiteWrapperSubComponents.append(reaction)
        }

        // 话题模式外露评论
        if let revealReplyInTread = props.subComponents[.revealReplyInTread] {
            revealReplyInTread._style.marginTop = margin //左右不设置边距，自身要响应点击事件
            whiteWrapperSubComponents.append(revealReplyInTread)
        }

        // 左上角加急icon
        if let urgent = props.subComponents[.urgent] {
            whiteWrapperSubComponents.append(urgent)
        }

        // 气泡
        whiteWrapper.setSubComponents(whiteWrapperSubComponents)
        self.wrapper = self.getCornerRadiusComponent()
        wrapper.setSubComponents([whiteWrapper])
        bubbleSubComponents.append(wrapper)

        // 将翻译组件添加在视图最上层，以防点击失效
        if let translateStatus = props.subComponents[.translateStatus] {
            bubbleSubComponents.append(translateStatus)
        }
        // 被其他人自动翻译icon
        if let autoTranslatedByReceiver = props.subComponents[.autoTranslatedByReceiver] {
            bubbleSubComponents.append(autoTranslatedByReceiver)
        }
        if props.bubbleConfig.supportHighlight {
            bubbleSubComponents.append(highLightBubbleView)
        }
        bubbleView.setSubComponents(bubbleSubComponents)

        switch self.props.bubbleConfig.bubbleStyle {
        case .normal:
            // 有点赞或者回复的时候（如果有内边距，气泡底部padding=margin，否则为padding=0）
            // 有点赞有内边距
            if self.oneOfSubComponentsDisplay([.reaction, .feedbackRegenerate]) {
                whiteWrapper._style.paddingBottom = padding
            } // 有回复的时候取决于hasPaddingBottom
            else if self.oneOfSubComponentsDisplay([.reply, .syncToChat]) || self.oneOfSubComponentsDisplay([.cryptoReply]) ||
                        props.isFileCard { // 文件卡片特化：没有左右margin，hasMargin是false，但是希望有paddingBottom
                whiteWrapper._style.paddingBottom = hasPaddingBottom ? padding : 0
            } else {
                whiteWrapper._style.paddingBottom = hasMargin && hasPaddingBottom ? padding : 0
            }
            bubbleView.props.changeBottomLeftRadius = props.bubbleConfig.changeBottomCorner
            bubbleView.props.changeTopLeftRadius = props.bubbleConfig.changeTopCorner
            highLightBubbleView.props.changeBottomLeftRadius = props.bubbleConfig.changeBottomCorner
            highLightBubbleView.props.changeTopLeftRadius = props.bubbleConfig.changeTopCorner
        case .thread:
            whiteWrapper._style.paddingBottom = 0
        }

        wrapper.style.ui.masksToBounds = props.contentConfig?.maskToBounds ?? false

        if self.oneOfSubComponentsDisplay([.docsPreview]) {
            props.subComponents[.urlPreview]?._style.display = .none
        }

        let bubbleWidth = self.bubbleWidth()
        // 话题模式下创建的Thread才使用定宽，否则都用内容撑开最大宽度
        if (props.bubbleConfig.bubbleStyle == .normal) || (props.threadReplyBubbleOptimize && !props.displayInThreadMode) {
            // 配置变化重新设置最大宽度
            if let contentMaxWdith = props.contentConfig?.contentMaxWidth {
                bubbleView._style.maxWidth = CSSValue(cgfloat: contentMaxWdith)
                highLightBubbleView._style.maxWidth = CSSValue(cgfloat: contentMaxWdith)
                whiteWrapper._style.maxWidth = CSSValue(cgfloat: contentMaxWdith)
                wrapper._style.maxWidth = CSSValue(cgfloat: contentMaxWdith)
                bubbleTouchView._style.maxWidth = CSSValue(cgfloat: contentMaxWdith)
            } else {
                bubbleView._style.maxWidth = CSSValue(cgfloat: bubbleWidth)
                highLightBubbleView._style.maxWidth = CSSValue(cgfloat: bubbleWidth)
                whiteWrapper._style.maxWidth = CSSValue(cgfloat: bubbleWidth)
                wrapper._style.maxWidth = CSSValue(cgfloat: bubbleWidth)
                bubbleTouchView._style.maxWidth = CSSValue(cgfloat: bubbleWidth)
            }
            bubbleView._style.width = CSSValueAuto
            whiteWrapper._style.width = CSSValueAuto
            wrapper._style.width = CSSValueAuto
            bubbleTouchView._style.width = CSSValueAuto
        } else {
            bubbleView._style.width = CSSValue(cgfloat: bubbleWidth)
            highLightBubbleView._style.width = CSSValue(cgfloat: bubbleWidth)
            bubbleTouchView._style.width = CSSValue(cgfloat: bubbleWidth)
            whiteWrapper._style.width = CSSValue(cgfloat: bubbleWidth)
            wrapper._style.width = CSSValue(cgfloat: bubbleWidth)
            bubbleView._style.maxWidth = CSSValueUndefined
            whiteWrapper._style.maxWidth = CSSValueUndefined
            wrapper._style.maxWidth = CSSValueUndefined
            bubbleTouchView._style.maxWidth = CSSValueUndefined
        }

        // 设置边框
        switch self.props.bubbleConfig.bubbleStyle {
        case .normal:
            if props.contentConfig?.hasBorder ?? false {
                wrapper.props.showBoder = true
            } else {
                wrapper.props.showBoder = false
            }
        case .thread:
            wrapper.props.showBoder = true
        }

        // 话题模式下bubbleView需要被bubbleTouchView包一层
        switch props.bubbleConfig.bubbleStyle {
        case .normal:
            bubbleTouchView.props.onTapped = nil
        case .thread:
            bubbleTouchView.setSubComponents([bubbleView])
            bubbleTouchView.props.onTapped = props.bubbleTapHandler
        }

        updateColor()

        bubbleView.props.changeRaiusReverse = props.bubbleConfig.changeRaiusReverse
        highLightBubbleView.props.changeRaiusReverse = props.bubbleConfig.changeRaiusReverse
        switch props.avatarLayout {
        case .left:
            if let urgent = props.subComponents[.urgent] {
                urgent._style.ui.borderRadius = BorderRadius(topLeft: props.bubbleConfig.changeTopCorner ? 2 : 8,
                                                            topRight: 0,
                                                            bottomRight: 0,
                                                            bottomLeft: 0)
            }
            wrapper.style.ui.borderRadius = BorderRadius(topLeft: props.bubbleConfig.changeTopCorner ? 2 : 8,
                                                         topRight: 8,
                                                         bottomRight: 8,
                                                         bottomLeft: props.bubbleConfig.changeBottomCorner ? 2 : 8)
        case .right:
            if let urgent = props.subComponents[.urgent] {
                urgent._style.ui.borderRadius = BorderRadius(topLeft: 8,
                                                            topRight: 0,
                                                            bottomRight: 0,
                                                            bottomLeft: 0)
            }
            wrapper.style.ui.borderRadius = BorderRadius(topLeft: 8,
                                                         topRight: props.bubbleConfig.changeTopCorner ? 2 : 8,
                                                         bottomRight: props.bubbleConfig.changeBottomCorner ? 2 : 8,
                                                         bottomLeft: 8)
        }
    }

    public func getBubbleView() -> ComponentWithContext<C> {
        switch props.bubbleConfig.bubbleStyle {
        case .normal:
            return bubbleView
        case .thread:
            return bubbleTouchView
        }
    }

    public func updateColor() {
        bubbleView.props.strokeColor = props.bubbleConfig.strokeColor
        bubbleView.props.fillColor = props.bubbleConfig.fillColor
        bubbleView.props.strokeWidth = props.bubbleConfig.strokeWidth
        if props.bubbleConfig.bubbleStyle == .normal, (props.contentConfig?.hasBorder ?? false) {
            let borderStyle = props.contentConfig?.borderStyle ?? .card
            // 有边框则设置背景透明
            if borderStyle == .image {
                let lineWidth = 1 / UIScreen.main.scale
                wrapper.props.lineWidth = lineWidth
            }
            if case .custom(_, let backgroundColor) = borderStyle {
                wrapper.style.backgroundColor = backgroundColor
            } else {
                wrapper.style.backgroundColor = (props.contentConfig?.isCard ?? false) ? UIColor.ud.bgFloat : (UIColor.ud.bgBody & UIColor.ud.bgBase)
            }
        }
    }

    // UIViewComponent
    private func getUIViewComponent() -> UIViewComponent<C> {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.flexDirection = .column
        style.alignItems = .flexStart
        style.flexWrap = .noWrap
        return UIViewComponent<C>(props: .empty, style: style, context: context)
    }

    // GradientWrapperComponent
    private func getCornerRadiusComponent() -> CornerRadiusComponent<C> {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.alignItems = .flexStart
        style.flexWrap = .noWrap
        return CornerRadiusComponent<C>(props: CornerRadiusComponent.Props(), style: style, context: context)
    }

    private func bubbleWidth() -> CGFloat {
        if props.bubbleConfig.bubbleStyle == .thread {
            //话题模式下，会默认给content增加padding,算bubble宽度时，要把padding加回来
            return props.contentPreferMaxWidth + props.contentPadding * 2
        }
        return props.contentPreferMaxWidth
    }

    private func oneOfSubComponentsDisplay(_ types: [SubType]) -> Bool {
        return props.oneOfSubComponentsDisplay?(types) ?? false
    }
}
