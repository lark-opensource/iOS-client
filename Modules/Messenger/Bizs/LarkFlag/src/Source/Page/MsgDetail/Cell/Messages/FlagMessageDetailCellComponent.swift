//
//  FlagMessageDetailCellComponent.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import UIKit
import Foundation
import LarkMessageCore
import EEFlexiable
import AsyncComponent
import LarkModel
import LarkTag
import LarkMessageBase
import LarkUIKit
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkBizAvatar
import UniverseDesignIcon
import UniverseDesignColor

extension FlagMessageDetailContext: AvatarContext {
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

final class FlagMessageDetailCellProps: ASComponentProps {
    // 配置
    var config: FlagMessageDetailChatCellConfig
    // 头像和名字
    var fromChatter: Chatter?
    var nameTag: [Tag] = []
    var isScretChat: Bool = false
    var getDisplayName: ((Chatter) -> String)?
    var avatarTapped: ((BizAvatar) -> Void)?
    // 时间
    var hasTime: Bool = false
    var bottomFormatTime: String = ""
    // 消息状态
    var hasMessageStatus: Bool = true
    // 加急
    var isUrgent: Bool = false
    // 内容
    var contentComponent: ComponentWithContext<FlagMessageDetailContext>
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
    // 子组件
    var subComponents: [SubType: ComponentWithContext<FlagMessageDetailContext>] = [:]
    var isFromMe: Bool = false

    // 标记相关
    var isFlag: Bool = false
    var flagTapEvent: (() -> Void)?

    init(config: FlagMessageDetailChatCellConfig, contentComponent: ComponentWithContext<FlagMessageDetailContext>) {
        self.config = config
        self.contentComponent = contentComponent
    }
}

final class FlagMessageDetailCellComponent: ASComponent<FlagMessageDetailCellProps, EmptyState, UIView, FlagMessageDetailContext> {
    override init(props: FlagMessageDetailCellProps, style: ASComponentStyle, context: FlagMessageDetailContext? = nil) {
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
    lazy var leftContainer: ASLayoutComponent<FlagMessageDetailContext> = {
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: 16 + 30.auto() + 6)
        style.flexShrink = 0
        style.flexDirection = .column
        style.alignItems = .flexEnd
        style.paddingRight = 8
        return ASLayoutComponent(style: style, context: context, [avatarContainer])
    }()

    /// 头像
    lazy var avatar: AvatarComponent<FlagMessageDetailContext> = {
        let props = AvatarComponent<FlagMessageDetailContext>.Props()
        props.key = "chat-cell-avatar"
        let style = ASComponentStyle()
        style.width = 30.auto()
        style.height = 30.auto()
        return AvatarComponent(props: props, style: style)
    }()

    /// 头像容器
    lazy var avatarContainer: ASLayoutComponent<FlagMessageDetailContext> = {
        let style = ASComponentStyle()
        return ASLayoutComponent(style: style, context: context, [avatar])
    }()

    /// 右边顶部区域，包含名字、tag和个人状态
    lazy var header: ASLayoutComponent<FlagMessageDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginBottom = 4
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// 放在气泡区域的checkbox
    lazy var checkbox: UIImageViewComponent<FlagMessageDetailContext> = {
        let style = ASComponentStyle()
        style.width = 20
        style.height = 20
        style.position = .absolute
        style.marginTop = -10
        style.top = 50%
        style.left = -36
        let props = UIImageViewComponentProps()
        return UIImageViewComponent<FlagMessageDetailContext>(props: props, style: style)
    }()

    /// 名字
    lazy var name: UILabelComponent<FlagMessageDetailContext> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.caption1
        props.textColor = UIColor.ud.N500

        let style = ASComponentStyle()
        style.flexShrink = 0
        style.backgroundColor = .clear
        style.marginRight = 4
        return UILabelComponent<FlagMessageDetailContext>(props: props, style: style)
    }()

    /// tag
    lazy var tag: TagComponent<FlagMessageDetailContext> = {
        let props = TagComponentProps()
        props.tags = self.props.nameTag

        let style = ASComponentStyle()
        style.marginRight = 4
        return TagComponent(props: props, style: style)
    }()

    /// 气泡
    lazy var bubbleView: BubbleViewComponent<FlagMessageDetailContext> = {
        self.props.contentComponent._style.maxWidth = CSSValue(
            cgfloat: props.contentPreferMaxWidth
        )

        let props = BubbleViewComponent<FlagMessageDetailContext>.Props()
        props.key = PostViewComponentConstant.bubbleKey
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.flexWrap = .noWrap
        style.alignItems = .flexStart

        return BubbleViewComponent<FlagMessageDetailContext>(props: props, style: style, context: context)
    }()

    /// 标记按钮，右上角
    lazy var flagIconComponent: TappedImageComponent<FlagMessageDetailContext> = {
        let props = TappedImageComponentProps()
        props.image = UDIcon.getIconByKey(.flagFilled, iconColor: UIColor.ud.colorfulRed, size: CGSize(width: 16, height: 16))
        props.hitTestEdgeInsets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        props.iconSize = CGSize(width: 16, height: 16)
        let style = ASComponentStyle()
        style.width = 16
        style.height = 100%
        style.marginLeft = 6
        return TappedImageComponent<FlagMessageDetailContext>(props: props, style: style)
    }()

    /// 消息状态容器： [flagComponent , statusComponent]
    lazy var contentStatusContainer: ASLayoutComponent<FlagMessageDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .columnReverse
        style.alignItems = .flexStart
        style.flexWrap = .noWrap
        style.height = 100%
        style.justifyContent = .spaceBetween
        return ASLayoutComponent(style: style, context: context, [])
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
    private lazy var translateStatus: TranslateStatusCompentent<FlagMessageDetailContext> = {
        let props = TranslateStatusCompentent<FlagMessageDetailContext>.Props()
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
        return TranslateStatusCompentent<FlagMessageDetailContext>(props: props, style: style)
    }()

    /// 消息被其他人自动翻译icon 右下角
    private lazy var autoTranslatedByReceiver: TranslatedByReceiverCompentent<FlagMessageDetailContext> = {
        let props = TranslatedByReceiverCompentent<FlagMessageDetailContext>.Props()
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
        return TranslatedByReceiverCompentent<FlagMessageDetailContext>(props: props, style: style)
    }()

    /// 内容区域，包含气泡
    lazy var content: ASLayoutComponent<FlagMessageDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .flexStart
        style.flexWrap = .noWrap

        return ASLayoutComponent(style: style, context: context, [
            bubbleView
        ])
    }()

    /// pin和reply一行，容器包一下
    lazy var footerReplyPin: ASLayoutComponent<FlagMessageDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .flexStart
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// 底部容器
    lazy var footer: ASLayoutComponent<FlagMessageDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        let topStyle = ASComponentStyle()
        return ASLayoutComponent(style: style, [])
    }()

    /// 底部时间
    lazy var bottomTime: UILabelComponent<FlagMessageDetailContext> = {
        let font = UIFont.ud.caption1
        let props = UILabelComponentProps()
        props.textColor = UIColor.ud.N500
        props.font = font
        let style = ASComponentStyle()
        style.height = CSSValue(cgfloat: font.pointSize)
        style.backgroundColor = .clear
        style.marginTop = 4
        return UILabelComponent<FlagMessageDetailContext>(props: props, style: style)
    }()

    /// 右边容器
    lazy var rightContainer: ASLayoutComponent<FlagMessageDetailContext> = {
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

    override func willReceiveProps(_ old: FlagMessageDetailCellProps, _ new: FlagMessageDetailCellProps) -> Bool {
        setupHeaderView(props: new)
        setupBubbleView(props: new)
        setupContentView(props: new)
        setupBottomView(props: new)
        self.style.backgroundColor = (oneOfSubComponentsDisplay([.pin]) || new.isFlag) ? UIColor.ud.Y50 : nil
        return true
    }

    // Header
    private func setupHeaderView(props: FlagMessageDetailCellProps) {
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
            var headerSubComponents: [ComponentWithContext<FlagMessageDetailContext>] = [name, tag]
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
    private func setupBubbleView(props: FlagMessageDetailCellProps) {
        func setTopLeftRightMargin(_ component: ComponentWithContext<FlagMessageDetailContext>, margin: CSSValue) {
            component._style.marginTop = margin
            component._style.marginLeft = margin
            component._style.marginRight = margin
        }

        // CornerRadiusView直接添加subComponent会导致reuse的bug
        let whiteWrapper = self.getUIViewComponent()
        var whiteWrapperSubComponents: [ComponentWithContext<FlagMessageDetailContext>] = []
        var bubbleSubComponents: [ComponentWithContext<FlagMessageDetailContext>] = []

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

        // 内容
        let hasMargin = props.contentConfig?.hasMargin ?? true
        let hasPaddingBottom: Bool = props.contentConfig?.hasPaddingBottom ?? true
        whiteWrapperSubComponents.append(props.contentComponent)
        setTopLeftRightMargin(props.contentComponent, margin: hasMargin ? margin : 0)
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
        bubbleSubComponents.append(self.translateStatus)
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

        bubbleView.setSubComponents(bubbleSubComponents)

        // 有点赞或者回复的时候（如果有内边距，气泡底部padding=margin，否则为padding=0）
        // 有点赞有内边距
        if self.oneOfSubComponentsDisplay([.reaction]) {
            whiteWrapper._style.paddingBottom = padding
        } // 有回复的时候取决于hasPaddingBottom
        else if self.oneOfSubComponentsDisplay([.reply]) {
            whiteWrapper._style.paddingBottom = hasPaddingBottom ? padding : 0
        } else {
            whiteWrapper._style.paddingBottom = hasMargin && hasPaddingBottom ? padding : 0
        }

        bubbleView.props.changeBottomLeftRadius = props.config.changeBottomCorner
        bubbleView.props.changeTopLeftRadius = props.config.changeTopCorner

        wrapper.style.ui.masksToBounds = props.contentConfig?.maskToBounds ?? false

        wrapper.style.ui.borderRadius = BorderRadius(topLeft: props.config.changeTopCorner ? 2 : 8,
                                            topRight: 8,
                                            bottomRight: 8,
                                            bottomLeft: props.config.changeBottomCorner ? 2 : 8)

        if self.oneOfSubComponentsDisplay([.docsPreview]) {
            props.subComponents[.urlPreview]?._style.display = .none
        }

        // 配置变化重新设置最大宽度
        if let contentMaxWdith = props.contentConfig?.contentMaxWidth {
            bubbleView._style.maxWidth = CSSValue(cgfloat: contentMaxWdith)
            whiteWrapper._style.maxWidth = CSSValue(cgfloat: contentMaxWdith)
            wrapper._style.maxWidth = CSSValue(cgfloat: contentMaxWdith)
        } else {
            bubbleView._style.maxWidth = CSSValue(cgfloat: props.contentPreferMaxWidth)
            whiteWrapper._style.maxWidth = CSSValue(cgfloat: props.contentPreferMaxWidth)
            wrapper._style.maxWidth = CSSValue(cgfloat: props.contentPreferMaxWidth)
        }
        // 有边框则设置背景透明
        if props.contentConfig?.hasBorder ?? false {
            bubbleView.props.fillColor = UIColor.clear
            wrapper.style.backgroundColor = (props.contentConfig?.isCard ?? false) ? UIColor.ud.bgFloat : UIColor.ud.bgBody
            wrapper.props.showBoder = true
            let borderStyle = props.contentConfig?.borderStyle ?? .card
            switch borderStyle {
            case .card:
                bubbleView.props.strokeColor = UDColor.getValueByKey(.imMessageCardBorder) ?? UDColor.N300 & UDColor.N900.withAlphaComponent(0)
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
            wrapper.props.showBoder = false
        }
    }

    // UIViewComponent
    private func getUIViewComponent() -> UIViewComponent<FlagMessageDetailContext> {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.flexDirection = .column
        style.alignItems = .flexStart
        style.flexWrap = .noWrap
        return UIViewComponent<FlagMessageDetailContext>(props: .empty, style: style, context: context)
    }

    // GradientWrapperComponent
    private func getCornerRadiusComponent(props: FlagMessageDetailCellProps) -> CornerRadiusComponent<FlagMessageDetailContext> {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.alignItems = .flexStart
        style.flexWrap = .noWrap
        return CornerRadiusComponent<FlagMessageDetailContext>(props: CornerRadiusComponent.Props(), style: style, context: context)
    }

    // content
    private func setupContentView(props: FlagMessageDetailCellProps) {
        // 气泡
        var contentSubComponents: [ComponentWithContext<FlagMessageDetailContext>] = [bubbleView]
        // 右边状态栏
        var contentStatusComponents: [ComponentWithContext<FlagMessageDetailContext>] = []
        if props.isFlag {
            flagIconComponent.props.onClicked = { _ in
                if let block = props.flagTapEvent {
                    block()
                }
            }
            contentStatusComponents.append(flagIconComponent)
        }
        contentStatusContainer.setSubComponents(contentStatusComponents)
        contentSubComponents.append(contentStatusContainer)
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
    private func setupBottomView(props: FlagMessageDetailCellProps) {
        var footerSubs: [ComponentWithContext<FlagMessageDetailContext>] = []

        // Forward
        if let forward = props.subComponents[.forward] {
            footerSubs.append(forward)
        }
        // Time
        bottomTime.style.display = .none
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
            self.oneOfSubComponentsDisplay([.replyStatus, .pin, .urgentTip, .forward])
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
}
