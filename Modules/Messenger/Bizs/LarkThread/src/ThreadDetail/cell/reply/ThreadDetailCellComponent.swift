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

class ThreadDetailCellProps: ASComponentProps {
    var message: Message
    var avatarTapped: () -> Void
    var avatarLongPressed: (() -> Void)?
    var reactionProvider: () -> ComponentWithContext<ThreadDetailContext>?
    var flagComponent: ComponentWithContext<ThreadDetailContext>?
    var name: String
    var time: String
    var topic: String
    var menuTapped: ((UIView) -> Void)?
    var statusTapped: (() -> Void)?
    var isFromMe: Bool
    var hasBorder: Bool = false
    var dlpTipComponent: ComponentWithContext<ThreadDetailContext>?
    var fileRiskComponent: ComponentWithContext<ThreadDetailContext>?
    var tcPreviewComponent: ComponentWithContext<ThreadDetailContext>?

    // 翻译状态
    var translateStatus: Message.TranslateState = .origin
    // 翻译icon点击事件
    var translateTapHandler: (() -> Void)?
    // 被其他人自动翻译
    var isAutoTranslatedByReceiver: Bool = false
    // 被其他人自动翻译icon点击事件
    var autoTranslateTapHandler: (() -> Void)?
    // 是否展示翻译 icon
    var canShowTranslateIcon = false
    // 翻译埋点
    var translateTrackInfo: [String: Any] = [:]

    // 多选
    // checkbox
    var showCheckBox: Bool = false
    var checked: Bool = false
    var inSelectMode: Bool = false
    //是否正在被二次编辑
    var isEditing = false
    //二次编辑请求状态
    var editRequestStatus: Message.EditMessageInfo.EditRequestStatus?
    var multiEditRetryCallBack: (() -> Void)?

    var fromChatter: Chatter?
    // 话题转发卡片：快照详情页对日程、任务等加蒙层禁止点击事件
    var disableContentTouch: Bool = false
    var disableContentTapped: (() -> Void)?

    init(message: Message,
         avatarTapped: @escaping () -> Void,
         avatarLongPressed: (() -> Void)? = nil,
         reactionProvider: @escaping () -> ComponentWithContext<ThreadDetailContext>?,
         name: String,
         time: String,
         topic: String = "",
         isFromMe: Bool = false,
         menuTapped: ((UIView) -> Void)?,
         statusTapped: (() -> Void)? = nil,
         children: [Component]) {
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

extension ThreadDetailCellProps {
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

final class ThreadDetailCellComponent: ASComponent<ThreadDetailCellProps, EmptyState, UIView, ThreadDetailContext> {
    override init(props: ThreadDetailCellProps, style: ASComponentStyle, context: ThreadDetailContext? = nil) {
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

    override func willReceiveProps(_ old: ThreadDetailCellProps, _ new: ThreadDetailCellProps) -> Bool {
        syncPropsToComponents(props: new)
        return true
    }

    private func syncPropsToComponents(props: ThreadDetailCellProps) {
        /// 原顺序
        /// nameContainer
        /// subContentComponent
        /// timeAndTranslateContainer
        /// statusContainer
        /// editRequestStatusComponent

        //主要内容的Components。有些场景会需要有一个边框把这些Components包起来
        var mainContentComponents: [ComponentWithContext<ThreadDetailContext>] = []
        mainContentComponents.append(contentsOf: [
            subContentComponent,
            translateButton
        ])
        if let tcPreview = props.tcPreviewComponent {
            tcPreview._style.marginTop = 12
            if props.hasBorder {
                tcPreview._style.marginLeft = 12
                tcPreview._style.marginRight = 12
                tcPreview._style.marginBottom = 12
            }
            mainContentComponents.append(tcPreview)
        }
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

        var rightComponents: [ComponentWithContext<ThreadDetailContext>] = []
        rightComponents.append(contentsOf: [
            nameContainer,
            mainContentComponent,
            timeAndTranslateContainer,
            riskFileLayoutComponent,
            dlpTipLayoutComponent,
            statusContainer,
            editRequestStatusComponent
        ])

        let isFailed = props.messageStatus == .fail
        let isSuccess = props.messageStatus == .success

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
            focusTagComponent.style.display = .flex
            focusTagComponent.props.focusStatus = focusStatus
        } else {
            focusTagComponent.style.display = .none
        }
        timeComponent.props.text = props.time
        timeAndTranslateContainer.style.display = isSuccess ? .flex : .none
        timeComponent.style.display = isSuccess ? .flex : .none

        // 标记小红旗
        if let flag = props.flagComponent {
            flag._style.position = .absolute
            flag._style.right = 0
            nameContainer.setSubComponents([nameComponent, focusTagComponent, flag])
        } else {
            nameContainer.setSubComponents([nameComponent, focusTagComponent])
        }
        messageStatusComponent.props.isFailed = isFailed
        messageStatusComponent.props.onTapped = { [weak props] _ in
            props?.statusTapped?()
        }
        statusContainer.style.display = isSuccess ? .none : .flex
        messageStatusComponent.style.display = isSuccess ? .none : .flex
        editRequestStatusComponent.style.display = (props.editRequestStatus == .failed) || (props.editRequestStatus == .wating) ? .flex : .none
        editRequestStatusComponent.props.requestStatus = props.editRequestStatus
        editRequestStatusComponent.props.retryCallback = props.multiEditRetryCallBack

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

        // 文件安全检测
        if let fileRiskComponent = props.fileRiskComponent {
            riskFileLayoutComponent.setSubComponents([fileRiskComponent])
            riskFileLayoutComponent.style.display = .flex
        } else {
            riskFileLayoutComponent.setSubComponents([])
            riskFileLayoutComponent.style.display = .none
        }

        // content
        var contentChildren: [ComponentWithContext<ThreadDetailContext>] = props.getChildren()
        if props.disableContentTouch {
            contentChildren.append(contentTouchComponent)
        }
        subContentComponent.children = contentChildren

        // 翻译
        /// 原顺序
        /// timeComponent
        /// translateStatus
        /// autoTranslatedByReceiver
        var timeCompomentAndTranslateComponents: [ComponentWithSubContext<ThreadDetailContext, ThreadDetailContext>] = []
        timeCompomentAndTranslateComponents.append(timeComponent)
        timeCompomentAndTranslateComponents.append(autoTranslatedByReceiver)
        timeAndTranslateContainer.setSubComponents(timeCompomentAndTranslateComponents)

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

        if let reactionComponent = props.reactionProvider() {
            reactionComponent._style.marginTop = 5
            rightComponents.append(reactionComponent)
        }

        // 多选
        checkboxImageViewComponent._style.display = props.showCheckBox ? .flex : .none
        checkboxImageViewComponent.props.isSelected = props.checked
        checkboxImageViewComponent.props.isEnabled = true
        if props.checked {
            style.backgroundColor = UIColor.ud.N600.withAlphaComponent(0.05)
        } else if let flag = props.flagComponent, flag._style.display == .flex {
            style.backgroundColor = UDMessageColorTheme.imMessageBgPin
        } else if props.isEditing {
            style.backgroundColor = UDMessageColorTheme.imMessageBgEditing
        } else {
            style.backgroundColor = nil
        }
        rightComponentsContainer.setSubComponents(rightComponents)
    }

    /// 多选checkbox

    private lazy var checkboxImageViewComponent: LKCheckboxComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: LKCheckbox.Layout.iconMidSize.width)
        style.height = CSSValue(cgfloat: LKCheckbox.Layout.iconMidSize.height)
        style.marginTop = 6
        style.marginRight = 16
        style.flexShrink = 0
        style.flexGrow = 0
        let props = LKCheckboxComponentProps()
        return LKCheckboxComponent<ThreadDetailContext>(props: props, style: style)
    }()

    private lazy var contentWrapperComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.paddingLeft = 16
        style.paddingRight = 16
        style.paddingTop = 12
        style.paddingBottom = 20
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

    private lazy var topAndContentWrapperComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.flexDirection = .column
        return ASLayoutComponent<ThreadDetailContext>(
            style: style,
            [
                contentWrapperComponent
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

    private lazy var nameContainer: ASLayoutComponent<ThreadDetailContext> = {
        let nameComponentStyle = ASComponentStyle()
        nameComponentStyle.justifyContent = .flexStart
        nameComponentStyle.width = 100%
        nameComponentStyle.alignItems = .center
        return ASLayoutComponent(style: nameComponentStyle, [nameComponent, focusTagComponent])
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
        style.marginBottom = 10
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var timeAndTranslateContainer: ASLayoutComponent<ThreadDetailContext> = {
        let timeStyle = ASComponentStyle()
        timeStyle.alignContent = .stretch
        timeStyle.justifyContent = .spaceBetween
        timeStyle.alignItems = .center
        timeStyle.width = 100%
        timeStyle.height = 22.auto()
        var subComponents: [ComponentWithSubContext<ThreadDetailContext, ThreadDetailContext>] = []
        if AIFeatureGating.translationOptimization.isEnabled {
            subComponents = [timeComponent]
        } else {
            subComponents = [timeComponent, autoTranslatedByReceiver]
        }
        return ASLayoutComponent<ThreadDetailContext>(style: timeStyle, subComponents)
    }()

    private lazy var statusContainer: ASLayoutComponent<ThreadDetailContext> = {
        let messageStatusStyle = ASComponentStyle()
        messageStatusStyle.justifyContent = .flexEnd
        messageStatusStyle.height = 20
        messageStatusStyle.width = 100%

        return ASLayoutComponent(style: messageStatusStyle, [messageStatusComponent])
    }()

    private lazy var editRequestStatusComponent: MultiEditStatusComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.marginTop = 4
        let props = MultiEditStatusComponentProps(requestStatus: self.props.editRequestStatus)
        props.retryCallback = self.props.multiEditRetryCallBack
        return MultiEditStatusComponent(props: props, style: style)
    }()

    private lazy var rightComponentsContainer: ASLayoutComponent<ThreadDetailContext> = {
        let rightStyle = ASComponentStyle()
        rightStyle.flexDirection = .column
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
        touchComponentProps.onTapped = self.props.disableContentTapped
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
        avatarStyle.width = 24.auto()
        avatarStyle.height = avatarStyle.width
        return AvatarComponent<ThreadDetailContext>(props: avatarProps, style: avatarStyle)
    }()

    private lazy var nameComponent: UILabelComponent<ThreadDetailContext> = {
        // name
        let nameProps = UILabelComponentProps()
        nameProps.font = UIFont.ud.body1
        nameProps.textColor = UIColor.ud.N900
        nameProps.lineBreakMode = .byTruncatingTail
        let nameStyle = ASComponentStyle()
        nameStyle.height = 20
        nameStyle.backgroundColor = .clear
        return UILabelComponent<ThreadDetailContext>(props: nameProps, style: nameStyle)
    }()

    /// 个人状态 icon
    private lazy var focusTagComponent: FocusTagComponent<ThreadDetailContext> = {
        let props = FocusTagComponent<ThreadDetailContext>.Props()
        props.preferredSingleIconSize = 16
        let style = ASComponentStyle()
        style.display = .none
        style.flexShrink = 0
        style.flexGrow = 0
        style.marginLeft = 6
        return FocusTagComponent<ThreadDetailContext>(props: props, style: style)
    }()

    private lazy var timeComponent: UILabelComponent<ThreadDetailContext> = {
        // time
        let timeProps = UILabelComponentProps()
        timeProps.font = UIFont.ud.caption1
        timeProps.textColor = UIColor.ud.N500
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        timeProps.lineBreakMode = .byWordWrapping
        timeProps.text = props.time
        let timeStyle = ASComponentStyle()
        timeStyle.alignSelf = .flexEnd
        timeStyle.backgroundColor = .clear
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
