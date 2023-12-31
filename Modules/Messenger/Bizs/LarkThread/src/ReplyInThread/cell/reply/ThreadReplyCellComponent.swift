//
//  ThreadDetailCellComponent.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/19.
//

import UIKit
import Foundation
import LarkMessageCore
import LarkCore
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import LarkMessengerInterface
import LarkUIKit
import LarkFeatureSwitch
import LarkFocus
import UniverseDesignIcon
import LarkSearchCore

class ThreadReplyCellProps: ASComponentProps {
    var pinComponent: ComponentWithContext<ThreadDetailContext>?
    var chatPinComponent: ComponentWithContext<ThreadDetailContext>?
    var dlpTipComponent: ComponentWithContext<ThreadDetailContext>?
    var fileRiskComponent: ComponentWithContext<ThreadDetailContext>?
    var restrictComponent: ComponentWithContext<ThreadDetailContext>?
    var syncToChatComponent: ComponentWithContext<ThreadDetailContext>?
    var message: Message
    var avatarTapped: () -> Void
    var avatarLongPressed: (() -> Void)?
    var reactionProvider: () -> ComponentWithContext<ThreadDetailContext>?
    var subComponents: [LarkMessageBase.SubType: ComponentWithContext<ThreadDetailContext>] = [:]

    var name: String
    var time: String
    var topic: String
    var menuTapped: ((UIView) -> Void)?
    var statusTapped: (() -> Void)?
    var isFromMe: Bool
    var contentPreferMaxWidth: CGFloat = 0
    // 翻译状态
    var translateStatus: Message.TranslateState = .origin
    // 翻译icon点击事件
    var translateTapHandler: (() -> Void)?
    // 翻译 tracking
    var translateTrackInfo: [String: Any] = [:]
    // 被其他人自动翻译
    var isAutoTranslatedByReceiver: Bool = false
    // 被其他人自动翻译icon点击事件
    var autoTranslateTapHandler: (() -> Void)?
    // 是否展示翻译 icon
    var canShowTranslateIcon = false
    // 内容的最外层是否有边框
    var hasBorder = false

    // 多选
    // checkbox
    var showCheckBox: Bool = false
    var checked: Bool = false
    var inSelectMode: Bool = false
    var isFlag: Bool = false
    var flagTapEvent: (() -> Void)?
    var fromChatter: Chatter?

    //是否正在被二次编辑
    var isEditing = false
    //二次编辑请求状态
    var editRequestStatus: Message.EditMessageInfo.EditRequestStatus?
    var multiEditRetryCallBack: (() -> Void)?
    // 话题转发卡片：快照详情页对日程、任务等加蒙层禁止点击事件
    var disableContentTouch: Bool = false
    var disableContentTapped: (() -> Void)?

    init(message: Message,
         children: [Component],
         avatarTapped: @escaping () -> Void,
         avatarLongPressed: (() -> Void)?,
         reactionProvider: @escaping () -> ComponentWithContext<ThreadDetailContext>?,
         name: String,
         time: String,
         topic: String = "",
         isFromMe: Bool = false,
         menuTapped: ((UIView) -> Void)? = nil,
         statusTapped: (() -> Void)? = nil) {
        self.message = message
        self.avatarTapped = avatarTapped
        self.avatarLongPressed = avatarLongPressed
        self.reactionProvider = reactionProvider

        self.name = name
        self.time = time
        self.topic = topic
        self.menuTapped = menuTapped
        self.statusTapped = statusTapped
        self.isFromMe = isFromMe
        super.init(children: children)
    }
}

extension ThreadReplyCellProps {
    var avatarKey: String {
        return message.fromChatter?.avatarKey ?? ""
    }

    var chatterID: String {
        return message.fromChatter?.id ?? ""
    }

    var messageStatus: Message.LocalStatus {
        return message.localStatus
    }
}

final class ThreadReplyCellComponent: ASComponent<ThreadReplyCellProps, EmptyState, UIView, ThreadDetailContext> {
    override init(props: ThreadReplyCellProps, style: ASComponentStyle, context: ThreadDetailContext? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([
            highlightViewComponent,
            contentWrapperComponent,
            frontHighLightViewComponent
        ])
    }

    override func update(view: UIView) {
        super.update(view: view)
        // 多选态消息整个消息屏蔽点击事件，只响应cell层的显示时间和选中事件
        view.isUserInteractionEnabled = (context?.isPreview == true) ? false : !props.inSelectMode
    }

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }

    override func willReceiveProps(_ old: ThreadReplyCellProps, _ new: ThreadReplyCellProps) -> Bool {
        syncPropsToComponents(props: new)
        return true
    }

    /// 标记按钮，右上角
    private lazy var flagIconComponent: TappedImageComponent<ThreadDetailContext> = {
       let props = TappedImageComponentProps()
        props.image = UDIcon.getIconByKey(.flagFilled, iconColor: UIColor.ud.colorfulRed, size: CGSize(width: 16, height: 16))
        props.iconSize = CGSize(width: 16, height: 16)

        let style = ASComponentStyle()
        style.position = .absolute
        style.width = 16
        style.height = 16
        style.right = 0
        style.display = .none
        return TappedImageComponent<ThreadDetailContext>(props: props, style: style)
    }()

    private lazy var pinLayoutComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginTop = 8
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var dlpTipLayoutComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var riskFileLayoutComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginBottom = 8
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var restrictLayoutComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginBottom = 8
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// 同时转发到群的提示
    private lazy var syncToChatLayoutComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginBottom = 2
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// 签名前面的 “｜” 分割线
    private lazy var chatterStatusDivider: UIViewComponent<ThreadDetailContext> = {
        let props = ASComponentProps()
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.ud.lineDividerDefault
        style.width = 1
        style.height = 10
        style.marginLeft = 8
        style.marginRight = 6
        return UIViewComponent<ThreadDetailContext>(props: props, style: style)
    }()

    private lazy var editRequestStatusComponent: MultiEditStatusComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.marginTop = 4
        let props = MultiEditStatusComponentProps(requestStatus: self.props.editRequestStatus)
        props.retryCallback = self.props.multiEditRetryCallBack
        return MultiEditStatusComponent(props: props, style: style)
    }()

    private func syncPropsToComponents(props: ThreadReplyCellProps) {
        var rightComponents: [ComponentWithContext<ThreadDetailContext>] = []

        //主要内容的Components。有些场景会需要有一个边框把这些Components包起来
        var mainContentComponents: [ComponentWithContext<ThreadDetailContext>] = []
        mainContentComponents.append(contentsOf: [subContentComponent,
                                                  translateButton])
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.width = 100%
        wrapperStyle.flexDirection = .column
        wrapperStyle.marginTop = 4
        if props.hasBorder {
            wrapperStyle.borderWidth = 1
            wrapperStyle.cornerRadius = 10
            wrapperStyle.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
            wrapperStyle.boxSizing = .borderBox
            wrapperStyle.backgroundColor = UIColor.ud.bgFloat
        }

        let mainContentComponent = UIViewComponent<ThreadDetailContext>(props: .empty, style: wrapperStyle)
        mainContentComponent.setSubComponents(mainContentComponents)

        rightComponents.append(contentsOf: [
            syncToChatLayoutComponent,
            nameContainer,
            mainContentComponent,
            riskFileLayoutComponent,
            dlpTipLayoutComponent,
            restrictLayoutComponent,
            statusContainer,
            editRequestStatusComponent
        ])

        avatarComponent.props.avatarKey = props.avatarKey
        avatarComponent.props.medalKey = props.fromChatter?.medalKey ?? ""
        avatarComponent.props.id = props.chatterID
        avatarComponent.props.onTapped.value = { [weak props] _ in
            props?.avatarTapped()
        }
        avatarComponent.props.longPressed = { [weak props] _ in
            guard let avatarLongPressed = props?.avatarLongPressed else {
                return
            }
            avatarLongPressed()
        }
        nameComponent.props.text = props.name
        if let focusStatus = props.fromChatter?.focusStatusList.topActive {
            focusTagComponent.props.focusStatus = focusStatus
            focusTagComponent.style.display = .flex
        } else {
            focusTagComponent.style.display = .none
        }

        // pin
        if let pinComponent = props.pinComponent {
            pinLayoutComponent.setSubComponents([pinComponent])
            pinLayoutComponent.style.display = .flex
            highlightViewComponent.style.backgroundColor = UDMessageColorTheme.imMessageBgPin
        } else {
            pinLayoutComponent.setSubComponents([])
            pinLayoutComponent.style.display = .none
            highlightViewComponent.style.backgroundColor = UIColor.clear
        }

        if let chatterStatus = props.subComponents[.chatterStatus] {
            /// 这里UX要求的距离是4，由于LKLabel默认会给文字后面拼接上一个" ",导致实际宽度较宽，故距离少设置一些
            timeComponent.style.marginLeft = 4
            self.userStatusContainer.setSubComponents([chatterStatusDivider, chatterStatus])
            self.nameContainer.setSubComponents([nameComponent, focusTagComponent, userStatusContainer, timeComponent, flagIconComponent])
        } else {
            timeComponent.style.marginLeft = 8
            self.userStatusContainer.setSubComponents([])
            self.nameContainer.setSubComponents([nameComponent, focusTagComponent, timeComponent, flagIconComponent])
        }
        self.nameComponent.style.maxWidth = CSSValue(
            cgfloat: props.contentPreferMaxWidth * 0.65
        )
        self.nameComponent.props.contentPreferMaxWidth = props.contentPreferMaxWidth * 0.65

        let isFailed = props.messageStatus == .fail
        let isSuccess = props.messageStatus == .success

        timeComponent.props.text = props.time
        translateContainer.style.display = isSuccess ? .flex : .none
        timeComponent.style.display = isSuccess ? .flex : .none
        messageStatusComponent.props.isFailed = isFailed
        messageStatusComponent.props.onTapped = { [weak props] _ in
            props?.statusTapped?()
        }
        var needShowStatus = true
        let messageType = props.message.type
        /// 消息发送成功 & 假成功都不展示失败
        if isSuccess || props.messageStatus == .fakeSuccess {
            needShowStatus = false
        }
        /// 视频图片消息 本身会有进度 只要在失败的时候 需要展示下
        if (messageType == .image || messageType == .media), !isFailed {
            needShowStatus = false
        }

        statusContainer.style.display = !needShowStatus ? .none : .flex
        messageStatusComponent.style.display = !needShowStatus ? .none : .flex
        // dlp
        // dlp拦截后需要隐藏statusComponent
        if let dlpTipComponent = props.dlpTipComponent {
            dlpTipLayoutComponent.setSubComponents([dlpTipComponent])
            dlpTipLayoutComponent.style.display = .flex
            messageStatusComponent.style.display = .none
            statusContainer.style.display = .none
        } else {
            dlpTipLayoutComponent.setSubComponents([])
            dlpTipLayoutComponent.style.display = .none
        }

        if let fileRiskComponent = props.fileRiskComponent {
            riskFileLayoutComponent.setSubComponents([fileRiskComponent])
            riskFileLayoutComponent.style.display = .flex
        } else {
            riskFileLayoutComponent.setSubComponents([])
            riskFileLayoutComponent.style.display = .none
        }

        if props.inSelectMode, let restrictComponent = props.restrictComponent {
            restrictLayoutComponent.setSubComponents([restrictComponent])
            restrictLayoutComponent.style.display = .flex
        } else {
            restrictLayoutComponent.setSubComponents([])
            restrictLayoutComponent.style.display = .none
        }

        if let syncToChatComponent = props.syncToChatComponent {
            syncToChatLayoutComponent.setSubComponents([syncToChatComponent])
            syncToChatLayoutComponent.style.display = .flex
            avatarComponent.style.marginTop = 20.auto()
        } else {
            syncToChatLayoutComponent.setSubComponents([])
            syncToChatLayoutComponent.style.display = .none
            avatarComponent.style.marginTop = 0
        }

        // content
        var contentChildren: [ComponentWithContext<ThreadDetailContext>] = props.getChildren()
        if props.disableContentTouch {
            contentChildren.append(contentTouchComponent)
        }
        subContentComponent.children = contentChildren

        // 翻译
        var translateCompoments: [ComponentWithSubContext<ThreadDetailContext, ThreadDetailContext>] = []
        translateCompoments.append(autoTranslatedByReceiver)
        translateContainer.setSubComponents(translateCompoments)

        let translateProps = translateButton.props
        translateProps.translateDisplayInfo = .display(backgroundColor: .clear)
        translateProps.translateStatus = props.translateStatus
        translateProps.trackInfo = props.translateTrackInfo
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

        // 被其他人自动翻译icon
        let showAutoIcon = props.isFromMe && props.translateStatus == .origin && props.isAutoTranslatedByReceiver
        autoTranslatedByReceiver.style.display = showAutoIcon ? .flex : .none
        if autoTranslatedByReceiver.style.display == .none {
            self.translateContainer.style.display = .none
        } else {
            self.translateContainer.style.display = .flex
        }

        if let tcPreview = props.subComponents[.tcPreview] {
            tcPreview._style.marginTop = 12
            rightComponents.append(tcPreview)
        }

        if let reactionComponent = props.reactionProvider() {
            reactionComponent._style.marginTop = 8
            rightComponents.append(reactionComponent)
        }
        rightComponents.append(pinLayoutComponent)

        // 标记小红旗
        flagIconComponent.props.onClicked = { _ in
            if let block = props.flagTapEvent {
                block()
            }
        }
        /// 是否展示标记
        flagIconComponent.style.display = props.isFlag ? .flex : .none
        nameContainer.style.paddingRight = props.isFlag ? 16 : 0
        // 多选
        checkboxImageViewComponent._style.display = props.showCheckBox ? .flex : .none
        checkboxImageViewComponent.props.isSelected = props.checked
        checkboxImageViewComponent.props.isEnabled = true
        if props.inSelectMode, checkboxImageViewComponent.style.display == .none {
            let checkboxStyle = checkboxImageViewComponent.style
            contentWrapperComponent.style.marginLeft = CSSValue(cgfloat: Self.selectModeMargin)
        } else {
            contentWrapperComponent.style.marginLeft = 0
        }
        style.backgroundColor = props.checked ? UIColor.ud.N600.withAlphaComponent(0.05) : nil

        rightComponentsContainer.setSubComponents(rightComponents)

        editRequestStatusComponent.style.display = (props.editRequestStatus == .failed) || (props.editRequestStatus == .wating) ? .flex : .none
        editRequestStatusComponent.props.requestStatus = props.editRequestStatus
        editRequestStatusComponent.props.retryCallback = props.multiEditRetryCallBack

        if props.checked {
            style.backgroundColor = UIColor.ud.N600.withAlphaComponent(0.05)
        } else if props.isFlag {
            style.backgroundColor = UDMessageColorTheme.imMessageBgPin
        } else if props.isEditing {
            style.backgroundColor = UDMessageColorTheme.imMessageBgEditing
        } else {
            style.backgroundColor = nil
        }
    }

    private static let checkBoxMarginRight: CGFloat = 16
    static let selectModeMargin = LKCheckbox.Layout.iconMidSize.width + checkBoxMarginRight
    /// 多选checkbox
    private lazy var checkboxImageViewComponent: LKCheckboxComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: LKCheckbox.Layout.iconMidSize.width)
        style.height = CSSValue(cgfloat: LKCheckbox.Layout.iconMidSize.height)
        style.marginRight = CSSValue(cgfloat: Self.checkBoxMarginRight)
        style.marginTop = 6
        style.flexShrink = 0
        style.flexGrow = 0
        let props = LKCheckboxComponentProps()
        return LKCheckboxComponent<ThreadDetailContext>(props: props, style: style)
    }()

    /// 回退为历史的布局方向（row布局）
    private lazy var contentWrapperComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.paddingLeft = 16
        style.paddingRight = 16
        style.paddingTop = 8
        style.paddingBottom = 8
        style.alignContent = .stretch
        style.width = 100%
        return ASLayoutComponent<ThreadDetailContext>(
            style: style,
            [
                checkboxImageViewComponent,
                avatarComponent,
                rightComponentsContainer
            ]
        )
    }()

    /// highlight view
    private lazy var highlightViewComponent: UIViewComponent<ThreadDetailContext> = {
        let viewProps = ASComponentProps()
        viewProps.key = MessageCommonCell.highlightViewKey

        let viewStyle = ASComponentStyle()
        viewStyle.position = .absolute
        viewStyle.backgroundColor = UIColor.clear
        viewStyle.top = 0
        viewStyle.bottom = 0
        viewStyle.width = 100%
        return UIViewComponent<ThreadDetailContext>(props: viewProps, style: viewStyle)
    }()

    /// 消息高亮前蒙层
    private lazy var frontHighLightViewComponent: ASComponent<ASComponentProps, EmptyState, HighlightFrontRectangleView, ThreadDetailContext> = {
        let viewProps = ASComponentProps()
        viewProps.key = MessageCommonCell.highlightBubbleViewKey

        let viewStyle = ASComponentStyle()
        viewStyle.position = .absolute
        viewStyle.backgroundColor = .ud.N900
        viewStyle.top = 0
        viewStyle.bottom = 0
        viewStyle.width = 100%
        return ASComponent<ASComponentProps, EmptyState, HighlightFrontRectangleView, ThreadDetailContext>(props: viewProps, style: viewStyle)
    }()

    lazy var nameContainer: ASLayoutComponent<ThreadDetailContext> = {
        let nameComponentStyle = ASComponentStyle()
        nameComponentStyle.justifyContent = .flexStart
        nameComponentStyle.width = 100%
        nameComponentStyle.alignItems = .center
        return ASLayoutComponent(style: nameComponentStyle, [nameComponent, focusTagComponent, timeComponent])
    }()

    private lazy var userStatusContainer: ASLayoutComponent<ThreadDetailContext> = {
        let statusComponentStyle = ASComponentStyle()
        statusComponentStyle.justifyContent = .flexStart
        statusComponentStyle.alignItems = .center
        return ASLayoutComponent(style: statusComponentStyle, [])
    }()

    private lazy var translateContainer: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.alignContent = .stretch
        style.justifyContent = .flexEnd
        style.alignItems = .center
        style.width = 100%
        style.height = 22.auto()
        return ASLayoutComponent<ThreadDetailContext>(style: style, [autoTranslatedByReceiver])
    }()

    private lazy var statusContainer: ASLayoutComponent<ThreadDetailContext> = {
        let messageStatusStyle = ASComponentStyle()
        messageStatusStyle.justifyContent = .flexStart
        messageStatusStyle.height = 20
        messageStatusStyle.width = 100%
        messageStatusStyle.marginTop = 6
        return ASLayoutComponent(style: messageStatusStyle, [messageStatusComponent])
    }()

    private lazy var rightComponentsContainer: ASLayoutComponent<ThreadDetailContext> = {
        let rightStyle = ASComponentStyle()
        rightStyle.flexDirection = .column
        rightStyle.alignItems = .flexStart
        rightStyle.flexGrow = 1
        rightStyle.paddingLeft = 8
        return ASLayoutComponent(style: rightStyle, [])
    }()

    private lazy var subContentComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.width = 100%
        return ASLayoutComponent<ThreadDetailContext>(style: style, props.getChildren())
    }()

    // 话题转发卡片：快照详情页对日程、任务等加蒙层禁止点击事件
    private lazy var contentTouchComponent: TouchViewComponent<ThreadDetailContext> = {
        let touchComponentProps = TouchViewComponentProps()
        touchComponentProps.onTapped = props.disableContentTapped
        let touchComponentStyle = ASComponentStyle()
        touchComponentStyle.top = 0
        touchComponentStyle.bottom = 0
        touchComponentStyle.width = 100%
        touchComponentStyle.position = .absolute
        return TouchViewComponent(props: touchComponentProps, style: touchComponentStyle)
    }()

    private lazy var avatarComponent: AvatarComponent<ThreadDetailContext> = {
        let avatarProps = AvatarComponent<ThreadDetailContext>.Props()
        avatarProps.avatarKey = props.avatarKey
        avatarProps.onTapped.value = { [weak self] _ in
            self?.props.avatarTapped()
        }
        avatarProps.longPressed = { [weak self] _ in
            guard let `self` = self, let avatarLongPressed = self.props.avatarLongPressed else {
                return
            }
            avatarLongPressed()
        }
        let avatarStyle = ASComponentStyle()
        avatarStyle.flexShrink = 0
        avatarStyle.top = 2
        avatarStyle.width = 36.auto()
        avatarStyle.height = avatarStyle.width
        return AvatarComponent<ThreadDetailContext>(props: avatarProps, style: avatarStyle)
    }()

    private lazy var nameComponent: ChatMessagePersonalNameUILabelComponent<ThreadDetailContext> = {
        // name
        let nameProps = ChatMessagePersonalNameUILabelComponentProps()
        nameProps.font = UIFont.ud.body1
        nameProps.textColor = UIColor.ud.N900
        nameProps.oneLineHeight = 20
        let nameStyle = ASComponentStyle()
        nameStyle.height = 20
        nameStyle.flexShrink = 0
        nameStyle.backgroundColor = .clear
        return ChatMessagePersonalNameUILabelComponent<ThreadDetailContext>(props: nameProps, style: nameStyle)
    }()

    /// 个人状态 icon
    private lazy var focusTagComponent: FocusTagComponent<ThreadDetailContext> = {
        let props = FocusTagComponent<ThreadDetailContext>.Props()
        props.preferredSingleIconSize = 16
        let style = ASComponentStyle()
        style.display = .none
        style.marginLeft = 6
        style.flexShrink = 0
        return FocusTagComponent<ThreadDetailContext>(props: props, style: style)
    }()

    private lazy var timeComponent: UILabelComponent<ThreadDetailContext> = {
        // time
        let timeProps = UILabelComponentProps()
        timeProps.font = UIFont.systemFont(ofSize: 12)
        timeProps.textColor = UIColor.ud.N500
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        timeProps.lineBreakMode = .byWordWrapping
        timeProps.text = props.time
        let timeStyle = ASComponentStyle()
        timeStyle.backgroundColor = .clear
        timeStyle.marginLeft = 8
        timeStyle.flexShrink = 0
        return UILabelComponent<ThreadDetailContext>(props: timeProps, style: timeStyle)
    }()

    private lazy var messageStatusComponent: MessageStatusButtonComponent<ThreadDetailContext> = {
        let messageStatusButtonProps = MessageStatusButtonComponent<ThreadDetailContext>.Props(isFailed: false)

        let buttonStyle = ASComponentStyle()
        buttonStyle.justifyContent = .flexEnd
        return MessageStatusButtonComponent<ThreadDetailContext>(props: messageStatusButtonProps, style: buttonStyle)
    }()

    // MARK: - 翻译
    /// 翻译button 左下角
    private lazy var translateButton: TranslateButtonComponent<ThreadDetailContext> = {
        let props = TranslateButtonComponent<ThreadDetailContext>.Props()
        let style = ASComponentStyle()
        style.alignSelf = .flexStart
        style.marginTop = 8
        style.marginBottom = 4
        return TranslateButtonComponent<ThreadDetailContext>(props: props, style: style)
    }()

    /// 消息被其他人自动翻译icon 右下角
    private lazy var autoTranslatedByReceiver: TranslatedByReceiverCompentent<ThreadDetailContext> = {
        let props = TranslatedByReceiverCompentent<ThreadDetailContext>.Props()
        props.tapHandler = { [weak self] in
            guard let `self` = self else { return }
            self.props.autoTranslateTapHandler?()
        }

        let style = ASComponentStyle()
        style.alignSelf = .flexStart
        style.width = 16
        style.height = 16
        return TranslatedByReceiverCompentent<ThreadDetailContext>(props: props, style: style)
    }()

}
