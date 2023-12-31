//
//  MessageDetailCellComponent.swift
//  Action
//
//  Created by 赵冬 on 2019/7/22.
//

import Foundation
import UIKit
import LarkMessageCore
import EEFlexiable
import AsyncComponent
import LarkModel
import LarkTag
import LarkMessageBase
import LarkMessengerInterface
import LarkFeatureSwitch
import RustPB
import UniverseDesignIcon
import UniverseDesignColor
import LarkSearchCore

final class MessageDetailCellProps: SafeASComponentProps {
    var isRootMessage: Bool = false
    // 标题
    var title: String?
    // 名字
    var name: String = ""
    // 时间
    var time: String = ""
    var fromChatter: Chatter?
    var showSecretAvatarIcon: Bool = false
    var hasBorder = false
    // 消息类型
    var messageType: Message.TypeEnum = .unknown
    var avatarTapped: (() -> Void)?
    var avatarLongPressed: (() -> Void)?
    var messageLocalStatus: MessageLocalStatus = .none
    var menuTapped: ((MenuButton) -> Void)?
    var didTappedLocalStatus: LocalStatusComponent<MessageDetailContext>.Props.TapHandler?
    // 内容
    private var _contentComponent: ComponentWithContext<MessageDetailContext>
    var contentComponent: ComponentWithContext<MessageDetailContext> {
        get {
            safeRead {
                self._contentComponent
            }
        }
        set {
            safeWrite {
                self._contentComponent = newValue
            }
        }
    }
    // 翻译状态
    var translateStatus: Message.TranslateState = .origin
    var canShowTranslateIcon: Bool = false
    // 翻译埋点
    var translateTrackingInfo: [String: Any] = [:]
    // 翻译icon点击事件
    var translateTapHandler: (() -> Void)?
    // 被其他人自动翻译
    var isAutoTranslatedByReceiver: Bool = false
    // 被其他人自动翻译icon点击事件
    var autoTranslateTapHandler: (() -> Void)?
    var isFromMe: Bool = false
    var isDecryptoFail: Bool = false
    // 子组件
    var displayRule = RustPB.Basic_V1_DisplayRule()
    let subComponentMaigin: CGFloat = 4

    private var _subComponents: [SubType: ComponentWithContext<MessageDetailContext>] = [:]
    var subComponents: [SubType: ComponentWithContext<MessageDetailContext>] {
        get {
            safeRead {
                self._subComponents
            }
        }
        set {
            safeWrite {
                self._subComponents = newValue
            }
        }
    }
    //是否正在被二次编辑
    var isEditing = false
    var hideUserInfo: Bool = false

    var dynamicAuthorityEnum: DynamicAuthorityEnum = .allow

    init (contentComponent: ComponentWithContext<MessageDetailContext>) {
        self._contentComponent = contentComponent
    }
}

extension MessageDetailCellProps {
}

struct MessageDetailCellConsts {
    static let avatarKey = "messageDetail-cell-avatar"
    static let contentKey = "messageDetail-cell-content"
    static let containerKey = "messageDetail-cell-middle-container"
}

final class MessageDetailCellComponent: ASComponent<MessageDetailCellProps, EmptyState, UIView, MessageDetailContext> {
    override init(props: MessageDetailCellProps, style: ASComponentStyle, context: MessageDetailContext? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.flexDirection = .column
        setSubComponents([
            urgentContainer,
            wrapperComponent,
            frontHighLightViewComponent,
            seperateLineComponent
        ])
    }

    private var isFromMe: Bool {
        return props.isFromMe
    }

    private lazy var title: UILabelComponent<MessageDetailContext> = {
        let titleProps = UILabelComponentProps()
        titleProps.font = UIFont.ud.title2
        titleProps.textColor = UIColor.ud.N900
        titleProps.numberOfLines = 10
        titleProps.lineBreakMode = .byWordWrapping
        let style = ASComponentStyle()
        style.width = 100%
        style.marginBottom = 4
        style.backgroundColor = .clear
        return UILabelComponent<MessageDetailContext>(props: titleProps, style: style)
    }()

    private lazy var urgentContainer: ASLayoutComponent<MessageDetailContext> = {
        let style = ASComponentStyle()
        return ASLayoutComponent<MessageDetailContext>(style: style, [])
    }()

    private lazy var wrapperComponent: ASLayoutComponent<MessageDetailContext> = {
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.padding = 16
        wrapperStyle.paddingTop = 4
        wrapperStyle.paddingBottom = 0
        wrapperStyle.alignContent = .stretch
        wrapperStyle.flexDirection = .column
        wrapperStyle.width = 100%
        wrapperStyle.marginTop = 4
        return ASLayoutComponent<MessageDetailContext>(style: wrapperStyle,
                                                       context: context,
                                                       [title,
                                                        topContainer,
                                                        middleContainer,
                                                        bottomContainer])
    }()

    /// 消息高亮前蒙层
    private lazy var frontHighLightViewComponent: ASComponent<ASComponentProps, EmptyState, HighlightFrontRectangleView, MessageDetailContext> = {
        let viewProps = ASComponentProps()
        viewProps.key = MessageCommonCell.highlightBubbleViewKey

        let viewStyle = ASComponentStyle()
        viewStyle.position = .absolute
        viewStyle.backgroundColor = .ud.N900
        viewStyle.top = 0
        viewStyle.bottom = 0
        viewStyle.width = 100%
        return ASComponent<ASComponentProps, EmptyState, HighlightFrontRectangleView, MessageDetailContext>(props: viewProps, style: viewStyle)
    }()

    /// 头像密聊icon
    lazy var secretAvatarIcon: UIViewComponent<MessageDetailContext> = {
        let style = ASComponentStyle()
        style.display = self.props.showSecretAvatarIcon ? .flex : .none
        style.position = .absolute
        style.right = -4
        style.bottom = -2
        style.width = 16
        style.height = 16
        style.cornerRadius = 16 / 2
        style.backgroundColor = UIColor.ud.N700 & UIColor.ud.N300
        style.alignItems = .center
        style.justifyContent = .center

        let imageProps = UIImageViewComponentProps()
        let iconSize: CGFloat = 10
        imageProps.setImage = { $0.set(image: UDIcon.getIconByKey(.lockChatFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: iconSize, height: iconSize))) }
        let imageStyle = ASComponentStyle()
        imageStyle.width = CSSValue(cgfloat: iconSize)
        imageStyle.height = CSSValue(cgfloat: iconSize)
        let imageComponent = UIImageViewComponent<MessageDetailContext>(props: imageProps, style: imageStyle)
        let viewComponent = UIViewComponent<MessageDetailContext>(props: .empty, style: style)
        viewComponent.setSubComponents([imageComponent])
        return viewComponent
    }()

    /// 头像容器
    lazy var avatarContainer: ASLayoutComponent<MessageDetailContext> = {
        let style = ASComponentStyle()
        style.flexShrink = 0
        style.width = CSSValue(cgfloat: .auto(32))
        style.height = style.width
        style.marginRight = 8
        style.marginTop = 4
        return ASLayoutComponent(style: style, context: context, [avatar, secretAvatar, secretAvatarIcon])
    }()

    /// 头像
    private lazy var avatar: AvatarComponent<MessageDetailContext> = {
        let avatarProps = AvatarComponent<MessageDetailContext>.Props()
        avatarProps.avatarKey = MessageDetailCellConsts.avatarKey
        let avatarStyle = ASComponentStyle()
        avatarStyle.flexShrink = 0
        avatarStyle.width = CSSValue(cgfloat: .auto(32))
        avatarStyle.height = avatarStyle.width
        avatarStyle.display = .flex
        return AvatarComponent<MessageDetailContext>(props: avatarProps, style: avatarStyle)
    }()

    //单聊密聊头像的假头像
    lazy var secretAvatar: TappedImageComponent<MessageDetailContext> = {
        let props = TappedImageComponentProps()
        props.key = ChatCellConsts.secretAvatarKey
        props.image = Resources.secret_single_head
        props.iconSize = CGSize(width: CGFloat(32.auto().value),
                                height: CGFloat(32.auto().value))
        let style = ASComponentStyle()
        style.display = .none
        style.flexShrink = 0
        return TappedImageComponent<MessageDetailContext>(props: props, style: style)
    }()

    private lazy var name: UILabelComponent<MessageDetailContext> = {
        let nameProps = UILabelComponentProps()
        nameProps.font = UIFont.ud.caption1
        nameProps.textColor = getColor(key: .NameAndSign, oldColor: UIColor.ud.N500)
        nameProps.lineBreakMode = .byTruncatingTail
        nameProps.text = props.name
        let nameStyle = ASComponentStyle()
        nameStyle.backgroundColor = .clear
        nameStyle.display = .flex
        return UILabelComponent<MessageDetailContext>(props: nameProps, style: nameStyle)
    }()

    private lazy var time: UILabelComponent<MessageDetailContext> = {
        let timeProps = UILabelComponentProps()
        timeProps.font = UIFont.ud.caption1
        timeProps.textColor = getColor(key: .NameAndSign, oldColor: UIColor.ud.N500)
        timeProps.text = props.time
        let timeStyle = ASComponentStyle()
        timeStyle.display = .flex
        timeStyle.backgroundColor = .clear
        return UILabelComponent<MessageDetailContext>(props: timeProps, style: timeStyle)
    }()

    private lazy var messageStatus: MessageDetailStatusComponent<MessageDetailContext> = {
        let messageStatusStyle = ASComponentStyle()
        messageStatusStyle.flexShrink = 0
        let messageStatusProps = MessageDetailStatusComponent<MessageDetailContext>.Props()
        messageStatusProps.menuTapped = { [weak self] button in
            self?.props.menuTapped?(button)
        }
        messageStatusProps.didTappedLocalStatus = { [weak self] in
            self?.props.didTappedLocalStatus?($0, $1)
        }
        return MessageDetailStatusComponent<MessageDetailContext>(props: messageStatusProps, style: messageStatusStyle, context: context)
    }()

    private lazy var nameAndTimeContainer: ComponentWithContext<MessageDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.justifyContent = .spaceBetween
        style.flexGrow = 1
        style.paddingRight = 10
        style.marginTop = 4
        return ASLayoutComponent<MessageDetailContext>(style: style, [name, time])
    }()

    /// pin和reply一行，容器包一下
    private lazy var replyAndPinContainer: ASLayoutComponent<MessageDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.display = .flex
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// 翻译相关icon 统一style
    private struct TranslateIconStyle {
        static let position: CSSPosition = .relative
        static let width: CSSValue = 26
        static let height: CSSValue = 26
        static let left: CSSValue = -5
    }

    /// 翻译button 左下角
    private lazy var translateButton: TranslateButtonComponent<MessageDetailContext> = {
        let props = TranslateButtonComponent<MessageDetailContext>.Props()
        let style = ASComponentStyle()
        style.alignSelf = .flexStart
        style.marginTop = 8
        style.marginBottom = 5
        return TranslateButtonComponent<MessageDetailContext>(props: props, style: style)
    }()

    /// 消息被其他人自动翻译icon 左下角
    private lazy var autoTranslatedByReceiver: TranslatedByReceiverCompentent<MessageDetailContext> = {
        let props = TranslatedByReceiverCompentent<MessageDetailContext>.Props()
        props.tapHandler = { [weak self] in
            guard let `self` = self else { return }
            self.props.autoTranslateTapHandler?()
        }

        let style = ASComponentStyle()
        style.position = TranslateIconStyle.position
        style.width = TranslateIconStyle.width
        style.height = TranslateIconStyle.height
        style.left = TranslateIconStyle.left
        return TranslatedByReceiverCompentent<MessageDetailContext>(props: props, style: style)
    }()

    private lazy var translateContainer: IconViewComponent<MessageDetailContext> = {
        let props = IconViewComponentProps()
        props.onViewClicked = { [weak self] in
            guard let `self` = self else { return }
            self.props.translateTapHandler?()
        }
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.display = .flex
        style.marginBottom = 4
        style.marginTop = 2
        return IconViewComponent(props: props, style: style)
    }()

    private lazy var seperateLineComponent: ComponentWithContext<MessageDetailContext> = {
        let style = ASComponentStyle()
        style.marginLeft = 16
        style.marginRight = 16
        style.height = 0.5
        style.backgroundColor = UIColor.ud.lineDividerDefault
        return UIViewComponent<MessageDetailContext>(props: .empty, style: style)
    }()

    private lazy var topContainer: ComponentWithContext<MessageDetailContext> = {
        let style = ASComponentStyle()
        style.alignContent = .stretch
        style.marginTop = 10
        style.width = 100%
        return ASLayoutComponent<MessageDetailContext>(style: style, [
            avatarContainer,
            nameAndTimeContainer,
            topRightContainer
        ])
    }()

    private lazy var topRightContainer: ASLayoutComponent<MessageDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.alignItems = .flexEnd
        style.justifyContent = .spaceBetween
        return ASLayoutComponent<MessageDetailContext>(style: style, [messageStatus])
    }()

    private lazy var content: UIViewComponent<MessageDetailContext> = {
        let props = ASComponentProps()
        props.key = MessageDetailCellConsts.contentKey
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .flexStart
        style.flexWrap = .noWrap
        style.paddingTop = 0
        style.paddingBottom = 4
        return UIViewComponent<MessageDetailContext>(props: props, style: style)
    }()

    private lazy var bottomContainer: ASLayoutComponent<MessageDetailContext> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.marginTop = 2
        style.flexDirection = .column
        return ASLayoutComponent<MessageDetailContext>(style: style, [])
    }()

    private lazy var middleContainer: UIViewComponent<MessageDetailContext> = {
        let style = ASComponentStyle()
        props.key = MessageDetailCellConsts.containerKey
        style.width = 100%
        style.flexDirection = .column
        return UIViewComponent<MessageDetailContext>(props: ASComponentProps(), style: style)
    }()

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }

    override func willReceiveProps(_ old: MessageDetailCellProps, _ new: MessageDetailCellProps) -> Bool {
        setupTitle(props: new)
        setUrgentContainer(props: new)
        setupTopContainer(props: new)
        setupContent(props: new)
        setupMiddleContainer(props: new)
        setupBottomContainer(props: new)
        seperateLineComponent._style.display = new.isRootMessage ? .flex : .none
        return true
    }

    private func setupTitle(props: MessageDetailCellProps) {
        if let text = props.title {
            title.props.text = text
            title.style.display = .flex
        } else {
            title.style.display = .none
        }
    }

    private func setTopBottomMargin(_ component: ComponentWithContext<MessageDetailContext>, margin: CSSValue) {
        component._style.marginTop = margin
        component._style.marginBottom = margin
    }

    private func setUrgentContainer(props: MessageDetailCellProps) {
        // 左上角加急icon
        if let urgent = props.subComponents[.urgent] {
            urgentContainer.setSubComponents([urgent])
        }
    }

    private func setupTopContainer(props: MessageDetailCellProps) {
        if props.hideUserInfo {
            secretAvatar.style.display = .flex
            secretAvatar.props.onClicked = { [weak props] _ in
                props?.avatarTapped?()
            }
            secretAvatar.props.onLongPressed = { [weak props] _ in
                guard let avatarLongPressed = props?.avatarLongPressed else {
                    return
                }
                avatarLongPressed()
            }
            avatar.style.display = .none
            avatar.props.onTapped.value = nil
            avatar.props.longPressed = nil
            name.props.text = BundleI18n.LarkChat.Lark_IM_SecureChatUser_Title
            name.style.display = .flex
        } else {
            // 头像
            avatar.style.display = .flex
            secretAvatar.style.display = .none
            secretAvatar.props.onClicked = nil
            secretAvatar.props.onLongPressed = nil
            avatar.props.onTapped.value = { [weak props] _ in
                props?.avatarTapped?()
            }
            avatar.props.avatarKey = props.fromChatter?.avatarKey ?? ""
            avatar.props.medalKey = props.fromChatter?.medalKey ?? ""
            avatar.props.id = props.fromChatter?.id ?? ""
            avatar.props.longPressed = { [weak props] _ in
                guard let avatarLongPressed = props?.avatarLongPressed else {
                    return
                }
                avatarLongPressed()
            }
            name.props.text = props.name
            name.style.display = .flex
        }
        time.props.text = props.time
        secretAvatarIcon.style.display = props.showSecretAvatarIcon ? .flex : .none

        if props.isDecryptoFail {
            self.topRightContainer.style.display = .none
            return
        }
        self.topRightContainer.style.display = .flex
        if props.dynamicAuthorityEnum.authorityAllowed {
            messageStatus.style.display = .flex
            let messageStatusProps = MessageDetailStatusComponent<MessageDetailContext>.Props()
            messageStatusProps.messageLocalStatus = props.messageLocalStatus
            messageStatusProps.menuTapped = { [weak self] button in
                self?.props.menuTapped?(button)
            }
            messageStatusProps.didTappedLocalStatus = { [weak self] in
                self?.props.didTappedLocalStatus?($0, $1)
            }
            messageStatus.props = messageStatusProps
        } else {
            messageStatus.style.display = .none
        }

        if let countDown = props.subComponents[.countDown] {
            self.topRightContainer.setSubComponents([messageStatus,
                                                     countDown])
        }
    }

    private func setupContent(props: MessageDetailCellProps) {
        if oneOfSubComponentsDisplay([.pin, .chatPin, .flag]) {
            self.style.backgroundColor = UDMessageColorTheme.imMessageBgPin
        } else if props.isEditing {
            self.style.backgroundColor = UDMessageColorTheme.imMessageBgEditing
        } else {
            self.style.backgroundColor = nil
        }
        if let flag = props.subComponents[.flag] {
            flag._style.height = 100%
            flag._style.marginLeft = 6
            content.setSubComponents([props.contentComponent, flag])
        } else {
            content.setSubComponents([props.contentComponent])
        }
    }

    private func setupMiddleContainer(props: MessageDetailCellProps) {

        let margin = CSSValue(cgfloat: props.subComponentMaigin)
        var middleSubComponents: [ComponentWithContext<MessageDetailContext>] = [content]
        // docs预览
        if let docsPreview = props.subComponents[.docsPreview] {
            setTopBottomMargin(docsPreview, margin: margin)
            middleSubComponents.append(docsPreview)
        }

        // url预览
        if let urlPreview = props.subComponents[.urlPreview] {
            setTopBottomMargin(urlPreview, margin: margin)
            middleSubComponents.append(urlPreview)
        }

        // TangramComponent渲染出的预览
        if let tcPreview = props.subComponents[.tcPreview] {
            setTopBottomMargin(tcPreview, margin: margin)
            if props.hasBorder {
                tcPreview._style.marginLeft = 12
                tcPreview._style.marginRight = 12
                tcPreview._style.marginBottom = 12
            }
            middleSubComponents.append(tcPreview)
        }

        if self.oneOfSubComponentsDisplay([.docsPreview]) {
            props.subComponents[.urlPreview]?._style.display = .none
        }

        middleContainer.setSubComponents(middleSubComponents)

        middleContainer.style.marginTop = 10
        if props.hasBorder {
            middleContainer.style.borderWidth = 1
            middleContainer.style.cornerRadius = 10
            middleContainer.style.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
            middleContainer.style.boxSizing = .borderBox
            middleContainer.style.backgroundColor = UIColor.ud.bgFloat
        } else {
            middleContainer.style.borderWidth = 0
            middleContainer.style.cornerRadius = 0
            middleContainer.style.border = nil
            middleContainer.style.boxSizing = .contentBox
            middleContainer.style.backgroundColor = .clear
        }
    }

    private func setupBottomContainer(props: MessageDetailCellProps) {
        let margin = CSSValue(cgfloat: props.subComponentMaigin)
        var bottomSubComponents: [ComponentWithContext<MessageDetailContext>] = []
        //二次编辑状态
        if let multiEditStatus = props.subComponents[.multiEditStatus] {
            setTopBottomMargin(multiEditStatus, margin: margin)
            bottomSubComponents.append(multiEditStatus)
        }

        // 翻译 button
        setTopBottomMargin(translateButton, margin: margin)
        bottomSubComponents.append(translateButton)

        if let reaction = props.subComponents[.reaction] {
            setTopBottomMargin(reaction, margin: margin)
            bottomSubComponents.append(reaction)
        }

        if let forward = props.subComponents[.forward] {
            setTopBottomMargin(forward, margin: margin)
            bottomSubComponents.append(forward)
        }

        // 底部UrgentTip
        if let urgentTips = props.subComponents[.urgentTip] {
            setTopBottomMargin(urgentTips, margin: margin)
            bottomSubComponents.append(urgentTips)
        }

        var replyAndPin: [ComponentWithContext<MessageDetailContext>] = []
        if let replyStatus = props.subComponents[.replyStatus], props.isRootMessage {
            replyStatus._style.flexShrink = 0
            setTopBottomMargin(replyStatus, margin: margin)
            replyAndPin.append(replyStatus)
        }
        if let pin = props.subComponents[.pin] {
            pin._style.flexShrink = 1
            setTopBottomMargin(pin, margin: margin)
            replyAndPin.append(pin)
        }
        if let chatPin = props.subComponents[.chatPin] {
            chatPin._style.flexShrink = 1
            setTopBottomMargin(chatPin, margin: margin)
            bottomSubComponents.append(chatPin)
        }
        if let dlpTip = props.subComponents[.dlpTip] {
            dlpTip._style.flexShrink = 1
            setTopBottomMargin(dlpTip, margin: margin)
            bottomSubComponents.append(dlpTip)
        }
        // 文件安全检测提示
        if let riskFile = props.subComponents[.riskFile] {
            riskFile._style.flexShrink = 1
            setTopBottomMargin(riskFile, margin: margin)
            bottomSubComponents.append(riskFile)
        }
        replyAndPinContainer.setSubComponents(replyAndPin)
        bottomSubComponents.append(replyAndPinContainer)
        /// 翻译icon
        var translateComponents: [ComponentWithContext<MessageDetailContext>] = []
        let translateProps = translateButton.props
        translateProps.translateDisplayInfo = .display(backgroundColor: .clear)
        translateProps.translateStatus = props.translateStatus
        translateProps.trackInfo = props.translateTrackingInfo
        translateProps.canShowTranslateIcon = props.canShowTranslateIcon
        if props.translateStatus == .origin && props.canShowTranslateIcon {
            translateProps.buttonStatus = .normal
            translateButton.style.display = .flex
            translateProps.tapHandler = { [weak self] in
                guard let `self` = self else { return }
                self.props.translateTapHandler?()
            }
            translateProps.text = BundleI18n.AI.Lark_ASLTranslation_IMOriginalText_TraslateIcon_Hover
        } else if props.translateStatus == .translating {
            translateProps.buttonStatus = .disable
            translateButton.style.display = .flex
            translateProps.tapHandler = nil
            translateProps.text = BundleI18n.AI.Lark_Legacy_Ing
        } else {
            translateProps.buttonStatus = .normal
            translateButton.style.display = .none
            translateProps.tapHandler = { [weak self] in
                guard let `self` = self else { return }
                self.props.translateTapHandler?()
            }
            translateProps.text = BundleI18n.AI.Lark_ASLTranslation_IMOriginalText_TraslateIcon_Hover
        }
        translateButton.props = translateProps

        /// 被其他人自动翻译icon
        let showAutoIcon = self.isFromMe && props.translateStatus == .origin && props.isAutoTranslatedByReceiver
        translateComponents.append(autoTranslatedByReceiver)
        autoTranslatedByReceiver.style.display = showAutoIcon ? .flex : .none
        translateContainer.setSubComponents(translateComponents)

        bottomContainer.setSubComponents(bottomSubComponents)
        if self.oneOfSubComponentsDisplay([.reaction, .replyStatus, .pin, .docsPreview, .urlPreview, .forward, .urgentTip]) {
            bottomContainer.style.marginBottom = 12
        } else {
            bottomContainer.style.marginBottom = 0
        }
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

    @inline(__always)
    private func getColor(key: ColorKey, oldColor: UIColor) -> UIColor {
        return context?.getColor(for: key, type: isFromMe ? .mine : .other) ?? oldColor
    }
}
