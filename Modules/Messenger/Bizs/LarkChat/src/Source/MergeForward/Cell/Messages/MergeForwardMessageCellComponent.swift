//
//  MergeForwardMessageCellComponent.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import UIKit
import Foundation
import LarkMessageCore
import EEFlexiable
import LarkSetting
import AsyncComponent
import LarkModel
import LarkTag
import LarkMessageBase
import LarkUIKit
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkBizAvatar
import UniverseDesignColor
import LarkSearchCore

extension MergeForwardContext: AvatarContext {
    public func handleTapAvatar(chatterId: String, chatId: String) {
        let body = PersonCardBody(chatterId: chatterId,
                                  chatId: chatId,
                                  source: .chat)

        if Display.phone {
            self.navigator(type: .push, body: body, params: nil)
        } else {
            self.navigator(
                type: .present,
                body: body,
                params: NavigatorParams(prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                }))
        }
    }
}

final class MergeForwardMessageCellProps: ASComponentProps {
    // 配置
    var config: ChatCellConfig
    var bubbleStyle: BubbleStyle = .normal
    // 是否是话题模式下创建的
    var displayInThreadMode: Bool = false
    // 气泡背景、宽度FG，FG开后：话题模式创建的背景为白色，气泡宽度固定为屏幕的宽度；话题回复背景为蓝/灰色，气泡宽度根据内容自适应
    let threadReplyBubbleOptimize: Bool
    // 头像和名字
    var fromChatter: Chatter?
    var nameTag: [Tag] = []
    var isScretChat: Bool = false
    var getDisplayName: ((Chatter) -> String)?
    var avatarTapped: ((BizAvatar) -> Void)?
    // 消息类型
    var messageType: Message.TypeEnum = .unknown
    // 时间
    var hasTime: Bool = false
    var bottomFormatTime: String = ""
    // 消息状态
    var hasMessageStatus: Bool = true
    // 加急
    var isUrgent: Bool = false
    // 内容
    var contentComponent: ComponentWithContext<MergeForwardContext>
    var contentConfig: ContentConfig?
    var contentPreferMaxWidth: CGFloat = 0
    var contentPadding: CGFloat = 0
    // checkbox
    var showCheckBox: Bool = false
    var checked: Bool = false
    // 翻译状态
    var translateStatus: Message.TranslateState = .origin
    // 翻译icon点击事件
    var translateTapHandler: (() -> Void)?
    // 被其他人自动翻译
    var isAutoTranslatedByReceiver: Bool = false
    // 被其他人自动翻译icon点击事件
    var autoTranslateTapHandler: (() -> Void)?
    // 是否可交互
    var isUserInteractionEnabled: Bool = true
    // 子组件
    var subComponents: [SubType: ComponentWithContext<MergeForwardContext>] = [:]
    var contenTapHandler: (() -> Void)?
    var isFromMe: Bool = false

    init(context: PageContext, config: ChatCellConfig, contentComponent: ComponentWithContext<MergeForwardContext>) {
        threadReplyBubbleOptimize = context.getStaticFeatureGating("im.message.thread_reply_bubble_optimize")
        self.config = config
        self.contentComponent = contentComponent
    }
}

final class MergeForwardMessageCellComponent: ASComponent<MergeForwardMessageCellProps, EmptyState, UIView, MergeForwardContext> {
    override init(props: MergeForwardMessageCellProps, style: ASComponentStyle, context: MergeForwardContext? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.paddingBottom = 2
        setSubComponents([
            leftContainer,
            rightContainer
        ])
    }

    private var isFromMe: Bool {
        return props.isFromMe
    }

    /// 左边，包含头像区域
    lazy var leftContainer: ASLayoutComponent<MergeForwardContext> = {
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: 16 + 30.auto() + 6)
        style.flexShrink = 0
        style.flexDirection = .column
        style.alignItems = .flexEnd
        style.paddingRight = 8
        return ASLayoutComponent(style: style, context: context, [avatarContainer])
    }()

    /// 头像
    lazy var avatar: AvatarComponent<MergeForwardContext> = {
        let props = AvatarComponent<MergeForwardContext>.Props()
        props.key = ChatCellConsts.avatarKey
        let style = ASComponentStyle()
        style.width = 30.auto()
        style.height = 30.auto()
        return AvatarComponent(props: props, style: style)
    }()

    /// 头像容器
    lazy var avatarContainer: ASLayoutComponent<MergeForwardContext> = {
        let style = ASComponentStyle()
        return ASLayoutComponent(style: style, context: context, [avatar])
    }()

    /// 右边顶部区域，包含名字、tag和个人状态
    lazy var header: ASLayoutComponent<MergeForwardContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginBottom = 4
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// 放在气泡区域的checkbox
    lazy var checkbox: UIImageViewComponent<MergeForwardContext> = {
        let style = ASComponentStyle()
        style.width = 20
        style.height = 20
        style.position = .absolute
        style.marginTop = -10
        style.top = 50%
        style.left = -36
        let props = UIImageViewComponentProps()
        return UIImageViewComponent<MergeForwardContext>(props: props, style: style)
    }()

    /// 名字
    lazy var name: UILabelComponent<MergeForwardContext> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.caption1
        props.textColor = UIColor.ud.N500

        let style = ASComponentStyle()
        style.flexShrink = 0
        style.backgroundColor = .clear
        style.marginRight = 4
        return UILabelComponent<MergeForwardContext>(props: props, style: style)
    }()

    /// tag
    lazy var tag: TagComponent<MergeForwardContext> = {
        let props = TagComponentProps()
        props.tags = self.props.nameTag

        let style = ASComponentStyle()
        style.marginRight = 4
        return TagComponent(props: props, style: style)
    }()

    /// 气泡
    lazy var bubbleView: BubbleViewComponent<MergeForwardContext> = {
        self.props.contentComponent._style.maxWidth = CSSValue(
            cgfloat: self.bubbleWidth(props: self.props)
        )

        let props = BubbleViewComponent<MergeForwardContext>.Props()
        props.key = PostViewComponentConstant.bubbleKey
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.flexWrap = .noWrap
        style.alignItems = .flexStart

        return BubbleViewComponent<MergeForwardContext>(props: props, style: style, context: context)
    }()

    /// 消息气泡高亮蒙层
    lazy var highLightBubbleView: HighlightFrontBubbleViewComponent<MergeForwardContext> = {
        self.props.contentComponent._style.maxWidth = CSSValue(
            cgfloat: props.contentPreferMaxWidth
        )

        let props = HighlightFrontBubbleViewComponent<MergeForwardContext>.Props()
        props.key = MessageCommonCell.highlightBubbleViewKey
        let style = ASComponentStyle()
        style.position = .absolute
        style.backgroundColor = UIColor.clear
        style.top = 0
        style.bottom = 0
        style.width = 100%

        return HighlightFrontBubbleViewComponent<MergeForwardContext>(props: props, style: style, context: context)
    }()

    lazy var bubbleTouchView: TouchViewComponent<MergeForwardContext> = {
        let props = TouchViewComponentProps()
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.flexWrap = .noWrap
        style.alignItems = .flexStart
        return TouchViewComponent<MergeForwardContext>(props: props, style: style, context: context)
    }()

    /// 翻译相关icon 统一style
    private struct TranslateIconStyle {
        static let position: CSSPosition = .absolute
        static let width: CSSValue = 26
        static let height: CSSValue = 26
        static let bottom: CSSValue = -8
        static let right: CSSValue = -8
    }

    /// 翻译icon 右下角
    private lazy var translateStatus: TranslateStatusCompentent<MergeForwardContext> = {
        let props = TranslateStatusCompentent<MergeForwardContext>.Props()
        props.tapHandler = { [weak self] in
            guard let `self` = self else { return }
            self.props.translateTapHandler?()
        }

        let style = ASComponentStyle()
        style.position = TranslateIconStyle.position
        style.width = TranslateIconStyle.width
        style.height = TranslateIconStyle.height
        style.bottom = TranslateIconStyle.bottom
        style.right = TranslateIconStyle.right
        return TranslateStatusCompentent<MergeForwardContext>(props: props, style: style)
    }()

    /// 消息被其他人自动翻译icon 右下角
    private lazy var autoTranslatedByReceiver: TranslatedByReceiverCompentent<MergeForwardContext> = {
        let props = TranslatedByReceiverCompentent<MergeForwardContext>.Props()
        props.tapHandler = { [weak self] in
            guard let `self` = self else { return }
            self.props.autoTranslateTapHandler?()
        }

        let style = ASComponentStyle()
        style.position = TranslateIconStyle.position
        style.width = TranslateIconStyle.width
        style.height = TranslateIconStyle.height
        style.bottom = TranslateIconStyle.bottom
        style.right = TranslateIconStyle.right
        return TranslatedByReceiverCompentent<MergeForwardContext>(props: props, style: style)
    }()

    /// 内容区域，包含气泡
    lazy var content: ASLayoutComponent<MergeForwardContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .flexStart
        style.flexWrap = .noWrap

        return ASLayoutComponent(style: style, context: context, [
            bubbleView
        ])
    }()

    private func bubbleWidth(props: MergeForwardMessageCellProps) -> CGFloat {
        if props.bubbleStyle == .thread {
            //话题模式下，会默认给content增加padding,算bubble宽度时，要把padding加回来
            return props.contentPreferMaxWidth + props.contentPadding * 2
        }
        return props.contentPreferMaxWidth
    }

    /// pin和reply一行，容器包一下
    lazy var footerReplyPin: ASLayoutComponent<MergeForwardContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .flexStart
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// 底部容器
    lazy var footer: ASLayoutComponent<MergeForwardContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        let topStyle = ASComponentStyle()
        return ASLayoutComponent(style: style, [])
    }()

    /// 底部时间
    lazy var bottomTime: UILabelComponent<MergeForwardContext> = {
        let font = UIFont.ud.caption1
        let props = UILabelComponentProps()
        props.textColor = UIColor.ud.N500
        props.font = font
        let style = ASComponentStyle()
        style.height = CSSValue(cgfloat: font.pointSize)
        style.backgroundColor = .clear
        style.marginTop = 4
        return UILabelComponent<MergeForwardContext>(props: props, style: style)
    }()

    /// 右边容器
    lazy var rightContainer: ASLayoutComponent<MergeForwardContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.flexGrow = 1
        style.paddingRight = 16
        return ASLayoutComponent(style: style, context: context, [
            header,
            content,
            footer
        ])
    }()

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }

    override func willReceiveProps(_ old: MergeForwardMessageCellProps, _ new: MergeForwardMessageCellProps) -> Bool {
        setupHeaderView(props: new)
        setupBubbleView(props: new)
        setupContentView(props: new)
        setupBottomView(props: new)
        self.style.backgroundColor = oneOfSubComponentsDisplay([.pin]) ? UIColor.ud.Y50 : nil
        return true
    }

    // Header
    private func setupHeaderView(props: MergeForwardMessageCellProps) {
        if props.config.isSingle {
            self.style.paddingTop = 24

            // 头像容器
            avatarContainer.style.display = .flex

            // 头像
            avatar.style.display = .flex
            avatar.props.onTapped.value = { [weak props] in
                guard let props = props else { return }
                props.avatarTapped?($0)
            }
            avatar.props.avatarKey = props.fromChatter?.avatarKey ?? ""
            avatar.props.medalKey = ""
            avatar.props.id = props.fromChatter?.id ?? ""

            // 名字
            if let fromChatter = props.fromChatter {
                name.props.text = props.getDisplayName?(fromChatter)
            } else {
                name.props.text = ""
            }

            // tag
            let tagProps = tag.props
            tagProps.tags = props.nameTag
            tag.props = tagProps

            // 整个header（包含名字、tag、个人状态)
            var headerSubComponents: [ComponentWithContext<MergeForwardContext>] = [name, tag]
            if let chatterStatus = props.subComponents[.chatterStatus] {
                headerSubComponents.append(chatterStatus)
            }
            header.setSubComponents(headerSubComponents)
            header.style.display = props.config.hasHeader ? .flex : .none
        } else {
            self.style.paddingTop = 4
            avatarContainer.style.display = .none
            header.style.display = .none
        }
    }

    // 气泡
    private func setupBubbleView(props: MergeForwardMessageCellProps) {
        func setTopLeftRightMargin(_ component: ComponentWithContext<MergeForwardContext>, margin: CSSValue) {
            component._style.marginTop = margin
            component._style.marginLeft = margin
            component._style.marginRight = margin
        }

        // CornerRadiusView直接添加subComponent会导致reuse的bug
        let whiteWrapper = self.getUIViewComponent()
        var whiteWrapperSubComponents: [ComponentWithContext<MergeForwardContext>] = []
        var bubbleSubComponents: [ComponentWithContext<MergeForwardContext>] = []

        let margin = CSSValue(cgfloat: props.contentPadding)
        let padding = CSSValue(cgfloat: props.contentPadding)

        // 回复
        if let reply = props.subComponents[.reply] {
            reply._style.flexGrow = 1
            reply._style.alignSelf = .stretch
            whiteWrapperSubComponents.append(reply)
            if isFromMe {
                whiteWrapper._style.paddingBottom = padding
            }
        }

        if let syncToChat = props.subComponents[.syncToChat] {
            whiteWrapperSubComponents.append(syncToChat)
        }

        // 内容
        // thread模式下都添加margin（文件卡片除外）
        let isFileCard = props.messageType == .file && props.subComponents[.tcPreview] != nil //是否是文件卡片（文件消息且渲染出了卡片）
        let hasMargin = (props.bubbleStyle == .thread && !isFileCard) ? true : (props.contentConfig?.hasMargin ?? true)
        //文件卡片总是有paddingBottom
        let hasPaddingBottom: Bool = isFileCard ? true : props.contentConfig?.hasPaddingBottom ?? true
        whiteWrapperSubComponents.append(props.contentComponent)
        setTopLeftRightMargin(props.contentComponent, margin: hasMargin ? margin : 0)
        if props.bubbleStyle == .thread {
            if !(props.contentConfig?.threadStyleConfig?.addBorderBySelf ?? false) {
                props.contentComponent._style.cornerRadius = 10
                if isFileCard {
                    //文件卡片thread样式特化：不需要添加border（也不会addBorderBySelf）
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

        // TangramComponent渲染出的预览
        if let tcPreview = props.subComponents[.tcPreview] {
            setTopLeftRightMargin(tcPreview, margin: margin)
            whiteWrapperSubComponents.append(tcPreview)
        }

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

        // 点赞
        if let reaction = props.subComponents[.reaction] {
            setTopLeftRightMargin(reaction, margin: margin)
            whiteWrapperSubComponents.append(reaction)
        }

        // 话题模式外露评论
        if let revealReplyInTread = props.subComponents[.revealReplyInTread] {
            revealReplyInTread._style.marginTop = margin //左右不设置边距，自身要响应点击事件
            whiteWrapperSubComponents.append(revealReplyInTread)
        }

        /// 左上角加急icon
        if let urgent = props.subComponents[.urgent] {
            // 设置圆角
            urgent._style.ui.borderRadius = BorderRadius(topLeft: props.config.changeTopCorner ? 2 : 8,
                                                        topRight: 0,
                                                        bottomRight: 0,
                                                        bottomLeft: 0)
            whiteWrapperSubComponents.append(urgent)
        }

        // 气泡
        whiteWrapper.setSubComponents(whiteWrapperSubComponents)
        let wrapper = self.getCornerRadiusComponent(props: props)
        wrapper.setSubComponents([whiteWrapper])
        bubbleSubComponents.append(wrapper)

        // 将翻译组件添加在视图最上层，以防点击失效
        /// 翻译icon
        let translateProps = self.translateStatus.props
        translateProps.translateDisplayInfo = .display(backgroundColor: self.isFromMe ? UDMessageColorTheme.imMessageBgBubblesBlue
                                                       : UIColor.ud.N100)
        translateProps.translateStatus = props.translateStatus
        self.translateStatus.props = translateProps
        self.translateStatus.style.display = props.translateStatus != .origin ? .flex : .none

        /// 被其他人自动翻译icon
        let showAutoIcon = self.isFromMe && props.translateStatus == .origin && props.isAutoTranslatedByReceiver
        bubbleSubComponents.append(self.autoTranslatedByReceiver)
        self.autoTranslatedByReceiver.style.display = showAutoIcon ? .flex : .none
        bubbleSubComponents.append(highLightBubbleView)

        bubbleView.setSubComponents(bubbleSubComponents)

        switch self.props.bubbleStyle {
        case .normal:
            // 有点赞或者回复的时候（如果有内边距，气泡底部padding=margin，否则为padding=0）
            // 有点赞有内边距
            if self.oneOfSubComponentsDisplay([.reaction]) {
                whiteWrapper._style.paddingBottom = padding
            } // 有回复的时候取决于hasPaddingBottom
            else if self.oneOfSubComponentsDisplay([.reply]) || self.oneOfSubComponentsDisplay([.cryptoReply]) ||
                        isFileCard { //文件卡片特化：没有左右margin，hasMargin是false，但是希望有paddingBottom
                whiteWrapper._style.paddingBottom = hasPaddingBottom ? padding : 0
            } else {
                whiteWrapper._style.paddingBottom = hasMargin && hasPaddingBottom ? padding : 0
            }
            bubbleView.props.changeBottomLeftRadius = props.config.changeBottomCorner
            bubbleView.props.changeTopLeftRadius = props.config.changeTopCorner
            highLightBubbleView.props.changeBottomLeftRadius = props.config.changeBottomCorner
            highLightBubbleView.props.changeTopLeftRadius = props.config.changeTopCorner
        case .thread:
            whiteWrapper._style.paddingBottom = 0
        }

        wrapper.style.ui.masksToBounds = props.contentConfig?.maskToBounds ?? false

        wrapper.style.ui.borderRadius = BorderRadius(topLeft: props.config.changeTopCorner ? 2 : 8,
                                            topRight: 8,
                                            bottomRight: 8,
                                            bottomLeft: props.config.changeBottomCorner ? 2 : 8)

        if self.oneOfSubComponentsDisplay([.docsPreview]) {
            props.subComponents[.urlPreview]?._style.display = .none
        }

        let bubbleWidth = self.bubbleWidth(props: props)
        // 话题模式下创建的Thread才使用定宽，否则都用内容撑开最大宽度
        if (props.bubbleStyle == .normal) || (props.threadReplyBubbleOptimize && !props.displayInThreadMode) {
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
            bubbleTouchView._style.width = CSSValue(cgfloat: bubbleWidth)
            highLightBubbleView._style.width = CSSValue(cgfloat: bubbleWidth)
            whiteWrapper._style.width = CSSValue(cgfloat: bubbleWidth)
            wrapper._style.width = CSSValue(cgfloat: bubbleWidth)
            bubbleView._style.maxWidth = CSSValueUndefined
            highLightBubbleView._style.maxWidth = CSSValueUndefined
            whiteWrapper._style.maxWidth = CSSValueUndefined
            wrapper._style.maxWidth = CSSValueUndefined
            bubbleTouchView._style.maxWidth = CSSValueUndefined
        }

        // 设置边框
        switch self.props.bubbleStyle {
        case .normal:
            if props.contentConfig?.hasBorder ?? false {
                wrapper.props.showBoder = true
            } else {
                wrapper.props.showBoder = false
            }
        case .thread:
            wrapper.props.showBoder = true
        }

        if props.bubbleStyle == .normal {
        // 有边框则设置背景透明
        if props.contentConfig?.hasBorder ?? false {
            bubbleView.props.fillColor = UIColor.clear
            wrapper.style.backgroundColor = (props.contentConfig?.isCard ?? false) ? UIColor.ud.bgFloat : UIColor.ud.bgBody
            let borderStyle = props.contentConfig?.borderStyle ?? .card
            switch borderStyle {
            case .card:
                bubbleView.props.strokeColor = UDMessageColorTheme.imMessageCardBorder
            case .image:
                let lineWidth = 1 / UIScreen.main.scale
                wrapper.props.lineWidth = lineWidth
                bubbleView.props.strokeWidth = lineWidth
                bubbleView.props.strokeColor = UIColor.ud.lineBorderCard
            case .other:
                bubbleView.props.strokeColor = UIColor.ud.lineBorderCard
            case .custom(let strokeColor, let backgroundColor):
                bubbleView.props.strokeWidth = 1
                bubbleView.props.strokeColor = strokeColor
                wrapper.style.backgroundColor = backgroundColor
            }
        } else {
            // 气泡背景样式，white为自己发的/分享日常/分享群卡片
            let contentBackgroundStyle = props.contentConfig?.backgroundStyle ?? (isFromMe ? .white : .gray)
            if contentBackgroundStyle == .white {
                // white为蓝色的背景
                let fillColor = context?.getColor(for: .Message_Bubble_Background, type: .mine) ?? .clear
                bubbleView.props.fillColor = fillColor
                bubbleView.props.strokeColor = UIColor.clear
            } else {
                // gray为灰色的背景
                let fillColor = context?.getColor(for: .Message_Bubble_Background, type: .other) ?? .clear
                bubbleView.props.fillColor = fillColor
                bubbleView.props.strokeColor = UIColor.clear
            }
        }
        } else if props.displayInThreadMode || !props.threadReplyBubbleOptimize {
            // 话题模式创建的话题，设置白色背景
            bubbleView.props.fillColor = UIColor.ud.bgBody
            bubbleView.props.strokeWidth = 1
            bubbleView.props.strokeColor = UIColor.ud.lineBorderCard
        } else {
            // 话题回复，需要设置背景，去掉边框
            bubbleView.props.fillColor = context?.getColor(for: .Message_Bubble_Background, type: props.isFromMe ? .mine : .other) ?? .clear
            bubbleView.props.strokeColor = UIColor.clear
        }
    }

    // UIViewComponent
    private func getUIViewComponent() -> UIViewComponent<MergeForwardContext> {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.flexDirection = .column
        style.alignItems = .flexStart
        style.flexWrap = .noWrap
        return UIViewComponent<MergeForwardContext>(props: .empty, style: style, context: context)
    }

    // GradientWrapperComponent
    private func getCornerRadiusComponent(props: MergeForwardMessageCellProps) -> CornerRadiusComponent<MergeForwardContext> {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.alignItems = .flexStart
        style.flexWrap = .noWrap
        return CornerRadiusComponent<MergeForwardContext>(props: CornerRadiusComponent.Props(), style: style, context: context)
    }

    // content
    private func setupContentView(props: MergeForwardMessageCellProps) {
        // 气泡
        var contentSubComponents: [ComponentWithContext<MergeForwardContext>]
        switch props.bubbleStyle {
        case .normal:
            contentSubComponents = [bubbleView]
            bubbleTouchView.props.onTapped = nil
        case .thread:
            bubbleTouchView.setSubComponents([bubbleView])
            contentSubComponents = [bubbleTouchView]
            bubbleTouchView.props.onTapped = props.contenTapHandler
        }
        // 右边状态栏
        if let status = props.subComponents[.messageStatus] {
            let oldDisplay = status._style.display
            status._style.display = props.hasMessageStatus ? oldDisplay : .none
            contentSubComponents.append(status)
        }
        // 左边绝对定位的checkbox
        checkbox._style.display = props.showCheckBox ? .flex : .none
        var image: UIImage!
        if props.checked {
            image = BundleResources.pickerOn
        } else if props.contentConfig?.selectedEnable ?? false {
            image = BundleResources.pickerOff
        } else {
            image = BundleResources.pickerOff_Ban
        }
        checkbox.props.setImage = { $0.set(image: image) }
        style.backgroundColor = props.checked ? UIColor.ud.N600.withAlphaComponent(0.05) : nil
        contentSubComponents.append(checkbox)

        content.setSubComponents(contentSubComponents)
    }

    // 底部View
    private func setupBottomView(props: MergeForwardMessageCellProps) {
        var footerSubs: [ComponentWithContext<MergeForwardContext>] = []

        // Forward
        if let forward = props.subComponents[.forward] {
            footerSubs.append(forward)
        }
        let mergeContext = context as? MergeForwardContext
        // 底部UrgentTip
        if let urgentTips = props.subComponents[.urgentTip] {
            if mergeContext?.mergeForwardType == .targetPreview { urgentTips._style.display = .none }
            footerSubs.append(urgentTips)
        }
        // 文件安全检测提示
        if let riskFile = props.subComponents[.riskFile] {
            footerSubs.append(riskFile)
        }
        // Reply & Pin (这两个占一行)
        var replyAndPin: [ComponentWithContext<MergeForwardContext>] = []
        if let replyStatus = props.subComponents[.replyStatus] {
            if mergeContext?.mergeForwardType == .targetPreview { replyStatus._style.display = .none }
            replyStatus._style.flexShrink = 0
            replyAndPin.append(replyStatus)
        }
        if let replyStatus = props.subComponents[.replyThreadInfo] {
            replyStatus._style.flexShrink = 0
            replyStatus._style.flexDirection = .row
            replyAndPin.append(replyStatus)
        }
        if let pin = props.subComponents[.pin] {
            if mergeContext?.mergeForwardType == .targetPreview { pin._style.display = .none }
            pin._style.flexShrink = 1
            pin._style.marginTop = props.subComponents[.replyThreadInfo] == nil ? 4 : 8
            replyAndPin.append(pin)
        }
        footerReplyPin.setSubComponents(replyAndPin)
        footerSubs.append(footerReplyPin)

        // Time
        bottomTime.style.display = props.hasTime ? .flex : .none
        bottomTime.props.text = props.bottomFormatTime
        footerSubs.append(bottomTime)

        // 整个footer容器
        footer.setSubComponents(footerSubs)
        // UI要求pin或者urgent等显示在会话气泡下时，下一个消息的气泡与它间距为4，原本为2
        footer.style.marginTop = 0
        footer.style.marginBottom =
            self.oneOfSubComponentsDisplay([.replyStatus, .pin, .urgentTip, .forward])
            ? 4
            : 0

        // 如果时间、回复数、pin、加急、语音转发有一个显示的情况下，footer容器就需要显示
        let anySubComponentShow = props.hasTime ||
        self.oneOfSubComponentsDisplay([.replyStatus, .replyThreadInfo, .pin, .urgentTip, .forward, .riskFile])
        footer.style.display = anySubComponentShow ? .flex : .none
    }

    private func oneOfSubComponentsDisplay(_ types: [SubType]) -> Bool {
        let index = types.firstIndex { (type) -> Bool in
            if let component = props.subComponents[type] {
                return component._style.display == .flex
            }
            return false
        }
        return index != nil
    }

    override func update(view: UIView) {
        super.update(view: view)
        // 内容预览与目标预览禁止消息交互事件
        view.isUserInteractionEnabled = props.isUserInteractionEnabled
    }
}
