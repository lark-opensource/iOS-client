//
//  ThreadReplyRootCellComponent.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/21.
//

import UIKit
import Foundation
import LarkCore
import LarkModel
import LarkMessageCore
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import LarkMessengerInterface
import LarkUIKit
import LarkFeatureSwitch
import RustPB
import LarkFocus
import UniverseDesignIcon
import LarkSearchCore

final class ThreadReplyRootCellProps: ThreadReplyCellProps {
    var title: String = ""
    var state: RustPB.Basic_V1_ThreadState?
    var borderConfig: (showBorder: Bool, maxWidth: CSSValue) = (false, CSSValueUndefined)
    var showTranslate: Bool = true
    var isDecryptoFail: Bool = false
}

final class ThreadReplyRootCellComponent: ASComponent<ThreadReplyRootCellProps, EmptyState, UIView, ThreadDetailContext> {
    private let avatarHeight: CGFloat = 36.auto()
    private let checkboxHeight: CGFloat = 20

    override init(props: ThreadReplyRootCellProps, style: ASComponentStyle, context: ThreadDetailContext? = nil) {
        style.flexDirection = .column
        super.init(props: props, style: style, context: context)
        setSubComponents([highlightViewComponent,
                          urgentLayoutComponent,
                          closeComponent,
                          wrapperComponent,
                          frontHighLightViewComponent])
        syncPropsToComponent(props: props)
    }

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }

    override func willReceiveProps(_ old: ThreadReplyRootCellProps, _ new: ThreadReplyRootCellProps) -> Bool {
        syncPropsToComponent(props: new)
        return true
    }

    override func update(view: UIView) {
        super.update(view: view)
        // 多选态消息整个消息屏蔽点击事件，只响应cell层的显示时间和选中事件
        view.isUserInteractionEnabled = (context?.isPreview == true) ? false : !props.inSelectMode
    }

    private func syncPropsToComponent(props: ThreadReplyRootCellProps) {
        avatarComponent.props.avatarKey = props.avatarKey
        avatarComponent.props.medalKey = props.fromChatter?.medalKey ?? ""
        avatarComponent.props.id = props.chatterID
        nameComponent.props.text = props.name
        timeComponent.props.text = props.time
        titleComponent.props.text = props.title
        titleComponent.style.display = !props.title.isEmpty ? .flex : .none
        if let focusStatus = props.fromChatter?.focusStatusList.topActive {
            focusTagComponent.style.display = .flex
            focusTagComponent.props.focusStatus = focusStatus
        } else {
            focusTagComponent.style.display = .none
        }
        var components: [ComponentWithContext<ThreadDetailContext>] = []

        //主要内容的Components。有些场景会需要有一个边框把这些Components包起来
        var mainContentComponents: [ComponentWithContext<ThreadDetailContext>] = []
        mainContentComponents.append(contentsOf: [titleComponent,
                                           contentContainer,
                                           dlpTipLayoutComponent,
                                           translateButton,
                                           autoTranslatedByReceiver,
                                           editRequestStatusComponent])
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.width = 100%
        wrapperStyle.flexDirection = .column
        wrapperStyle.alignItems = .flexStart
        if props.title.isEmpty {
            wrapperStyle.marginTop = 8
            contentContainer.style.marginTop = 0
        } else {
            wrapperStyle.marginTop = 10
            contentContainer.style.marginTop = 8
        }
        if props.hasBorder {
            wrapperStyle.borderWidth = 1
            wrapperStyle.cornerRadius = 10
            wrapperStyle.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
            wrapperStyle.boxSizing = .borderBox
            wrapperStyle.backgroundColor = UIColor.ud.bgFloat
        }

        let mainContentComponent = UIViewComponent<ThreadDetailContext>(props: .empty, style: wrapperStyle)
        components.append(contentsOf: [
            topAndHeaderComponent,
            mainContentComponent
        ])

        if let urgent = props.subComponents[.urgent] {
            urgentLayoutComponent.setSubComponents([urgent])
        } else {
            urgentLayoutComponent.setSubComponents([])
        }

        if let tcPreview = props.subComponents[.tcPreview] {
            tcPreview._style.marginTop = 12
            if props.hasBorder {
                tcPreview._style.marginLeft = 12
                tcPreview._style.marginRight = 12
                tcPreview._style.marginBottom = 12
            }
            mainContentComponents.append(tcPreview)
        }
        mainContentComponent.setSubComponents(mainContentComponents)

        if let reactionComponent = props.reactionProvider() {
            reactionComponent._style.marginTop = 8
            components.append(reactionComponent)
        }
        if let urgentTip = props.subComponents[.urgentTip] {
            components.append(urgentTip)
        }
        components.append(riskFileLayoutComponent)
        components.append(pinLayoutComponent)
        components.append(restrictLayoutComponent)

        contentComponent.setSubComponents(components)
        self.nameComponent.style.maxWidth = CSSValue(
            cgfloat: props.contentPreferMaxWidth * 0.7
        )
        self.nameComponent.props.contentPreferMaxWidth = props.contentPreferMaxWidth * 0.7
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
        // dlp
        if let dlpTipComponent = props.dlpTipComponent {
            dlpTipLayoutComponent.setSubComponents([dlpTipComponent])
            dlpTipLayoutComponent.style.display = .flex
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

        // 保密消息
        if props.inSelectMode, let restrictComponent = props.restrictComponent {
            restrictLayoutComponent.setSubComponents([restrictComponent])
            restrictLayoutComponent.style.display = .flex
        } else {
            restrictLayoutComponent.setSubComponents([])
            restrictLayoutComponent.style.display = .none
        }

        /// chatter status
        if let chatterStatus = props.subComponents[.chatterStatus] {
            userStatusContainer.setSubComponents([focusTagComponent, chatterStatusDivider, chatterStatus])
            nameContainer.setSubComponents([nameComponent, userStatusContainer])
        } else {
            userStatusContainer.setSubComponents([focusTagComponent])
            nameContainer.setSubComponents([nameComponent, userStatusContainer])
        }

        // 内容
        var contentChildren: [ComponentWithContext<ThreadDetailContext>] = props.getChildren()
        if props.disableContentTouch {
            contentChildren.append(contentTouchComponent)
        }
        contentContainer.children = contentChildren
        if props.borderConfig.showBorder {
            contentContainer.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.N300, style: .solid))
            contentContainer.style.cornerRadius = 5
        } else {
            contentContainer.style.border = .none
            contentContainer.style.cornerRadius = 0
        }
        contentContainer.style.maxWidth = props.borderConfig.maxWidth
        if titleComponent.style.display == .flex {
            contentContainer.style.marginTop = 2
        } else {
            contentContainer.style.marginTop = 8
        }
        var showTranslateIfNeeded: Bool = true
        // 当前设备需要展示翻译的时候,判断业务是否允许
        if showTranslateIfNeeded, !props.showTranslate {
            showTranslateIfNeeded = false
        }

        // 翻译
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
        autoTranslatedByReceiver.style.display = showAutoIcon && showTranslateIfNeeded ? .flex : .none

        // Thread状态
        if props.isDecryptoFail {
            closeComponent.style.display = .none
        } else if let state = props.state {
            switch state {
            case .closed:
                closeComponent.style.display = .flex
            case .open:
                closeComponent.style.display = .none
            case .unknownState:
                closeComponent.style.display = .none
            @unknown default:
                assert(false, "new value")
                closeComponent.style.display = .none
            }
        } else {
            closeComponent.style.display = .none
        }

        flagIconComponent.props.onClicked = { _ in
            if let block = props.flagTapEvent {
                block()
            }
        }

        // 多选
        // 绝对定位的checkbox
        checkboxImageViewComponent._style.display = props.showCheckBox ? .flex : .none
        checkboxImageViewComponent.props.isEnabled = true
        checkboxImageViewComponent.props.isSelected = props.checked

        editRequestStatusComponent.style.display = (props.editRequestStatus == .failed) || (props.editRequestStatus == .wating) ? .flex : .none
        editRequestStatusComponent.props.requestStatus = props.editRequestStatus
        editRequestStatusComponent.props.retryCallback = props.multiEditRetryCallBack

        flagIconComponent.style.display = props.isFlag ? .flex : .none
        nameContainer.style.paddingRight = props.isFlag ? 16 : 0

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

    /// 多选checkbox
    private lazy var checkboxImageViewComponent: LKCheckboxComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: LKCheckbox.Layout.iconMidSize.width)
        style.height = CSSValue(cgfloat: LKCheckbox.Layout.iconMidSize.height)
        style.marginTop = CSSValue(cgfloat: (avatarHeight - checkboxHeight) / 2)
        style.marginRight = 16
        style.flexShrink = 0
        style.flexGrow = 0
        let props = LKCheckboxComponentProps()
        return LKCheckboxComponent<ThreadDetailContext>(props: props, style: style)
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

    private lazy var userStatusContainer: ASLayoutComponent<ThreadDetailContext> = {
        let statusComponentStyle = ASComponentStyle()
        statusComponentStyle.justifyContent = .flexStart
        statusComponentStyle.alignItems = .center
        return ASLayoutComponent(style: statusComponentStyle, [])
    }()

    /// 加急icon
    private lazy var urgentLayoutComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.position = .absolute
        style.top = 0
        style.left = 0
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var contentComponent: UIViewComponent<ThreadDetailContext> = {
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.width = 100%
        wrapperStyle.flexDirection = .column
        return UIViewComponent<ThreadDetailContext>(props: .empty, style: wrapperStyle)
    }()

    /// 签名前面的 “｜” 分割线
    private lazy var chatterStatusDivider: UIViewComponent<ThreadDetailContext> = {
        let props = ASComponentProps()
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.ud.lineDividerDefault
        style.width = 1
        style.height = 10
        style.marginLeft = 6
        style.marginRight = 6
        return UIViewComponent<ThreadDetailContext>(props: props, style: style)
    }()

    private lazy var wrapperComponent: UIViewComponent<ThreadDetailContext> = {
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.paddingLeft = 16
        wrapperStyle.paddingRight = 16
        wrapperStyle.paddingTop = 16
        wrapperStyle.paddingBottom = 8
        wrapperStyle.alignContent = .stretch
        let wrapperComponent = UIViewComponent<ThreadDetailContext>(props: .empty, style: wrapperStyle)
        wrapperComponent.setSubComponents([
        checkboxImageViewComponent,
        contentComponent
        ])
        return wrapperComponent
    }()

    private lazy var topAndHeaderComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.flexDirection = .column
        return ASLayoutComponent<ThreadDetailContext>(
            style: style,
            [
                topComponentsContainer,
                headerContainer
            ]
        )
    }()

    private lazy var topComponentsContainer: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.flexDirection = .column
        style.paddingBottom = 12

        return ASLayoutComponent(style: style, [])
    }()

    private lazy var pinLayoutComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginTop = 8
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var restrictLayoutComponent: ASLayoutComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginBottom = 8
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var riskFileLayoutComponent: ASLayoutComponent<ThreadDetailContext> = {
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

    private lazy var contentContainer: UIViewComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.width = 100%
        let viewComponent = UIViewComponent<ThreadDetailContext>(props: .empty, style: style)
        viewComponent.setSubComponents(props.getChildren())
        return viewComponent
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

    private lazy var headerContainer: ComponentWithContext<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.alignContent = .spaceBetween
        style.width = 100%
        return ASLayoutComponent<ThreadDetailContext>(style: style, [
            avatarComponent,
            nameAndTimeContainer,
            flagIconComponent
        ])
    }()

    private lazy var avatarComponent: AvatarComponent<ThreadDetailContext> = {
        let avatarProps = AvatarComponent<ThreadDetailContext>.Props()
        avatarProps.avatarKey = props.avatarKey
        avatarProps.onTapped.value = { [weak self] _ in
            self?.props.avatarTapped()
        }
        let avatarStyle = ASComponentStyle()
        avatarStyle.width = CSSValue(cgfloat: avatarHeight)
        avatarStyle.height = CSSValue(cgfloat: avatarHeight)
        avatarStyle.marginRight = 8
        avatarStyle.flexShrink = 0
        return AvatarComponent<ThreadDetailContext>(props: avatarProps, style: avatarStyle)
    }()

    private lazy var nameContainer: ASLayoutComponent<ThreadDetailContext> = {
        let nameComponentStyle = ASComponentStyle()
        nameComponentStyle.justifyContent = .flexStart
        nameComponentStyle.width = 100%
        nameComponentStyle.alignItems = .center
        return ASLayoutComponent(style: nameComponentStyle, [nameComponent, focusTagComponent])
    }()

    private lazy var titleComponent: UILabelComponent<ThreadDetailContext> = {
        let nameProps = UILabelComponentProps()
        nameProps.font = UIFont.ud.title3
        nameProps.textColor = UIColor.ud.textTitle
        nameProps.lineBreakMode = .byTruncatingTail
        nameProps.text = props.title
        nameProps.numberOfLines = 0
        let nameStyle = ASComponentStyle()
        nameStyle.backgroundColor = .clear
        return UILabelComponent<ThreadDetailContext>(props: nameProps, style: nameStyle)
    }()

    private lazy var nameComponent: ChatMessagePersonalNameUILabelComponent<ThreadDetailContext> = {
        let nameProps = ChatMessagePersonalNameUILabelComponentProps()
        nameProps.font = UIFont.ud.body1
        nameProps.textColor = UIColor.ud.N900
        nameProps.oneLineHeight = UIFont.ud.body1.figmaHeight
        nameProps.text = props.name
        let nameStyle = ASComponentStyle()
        nameStyle.backgroundColor = .clear
        nameStyle.flexShrink = 0
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
        let timeProps = UILabelComponentProps()
        timeProps.font = UIFont.ud.caption1
        timeProps.textColor = UIColor.ud.N500
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        timeProps.lineBreakMode = .byWordWrapping
        timeProps.text = props.time
        let timeStyle = ASComponentStyle()
        timeStyle.backgroundColor = .clear
        return UILabelComponent<ThreadDetailContext>(props: timeProps, style: timeStyle)
    }()

    private lazy var closeComponent: UIViewComponent<ThreadDetailContext> = {
        let font = UIFont.ud.caption0
        let iconSize = font.rowHeight

        let imageProps = UIImageViewComponentProps()
        imageProps.setImage = { $0.set(image: Resources.thread_close) }
        let imageStyle = ASComponentStyle()
        imageStyle.width = CSSValue(cgfloat: iconSize)
        imageStyle.height = imageStyle.width
        imageStyle.flexShrink = 0
        let imageComponent = UIImageViewComponent<ThreadDetailContext>(props: imageProps, style: imageStyle)

        let labelProps = UILabelComponentProps()
        labelProps.text = BundleI18n.LarkThread.Lark_Chat_TopicStatusClosedTip
        labelProps.font = font
        labelProps.textColor = UIColor.ud.N600
        let labelStyle = ASComponentStyle()
        labelStyle.backgroundColor = UIColor.clear
        labelStyle.marginLeft = 4
        let labelComponent = UILabelComponent<ThreadDetailContext>(props: labelProps, style: labelStyle)

        let wrapperStyle = ASComponentStyle()
        wrapperStyle.paddingLeft = 16
        wrapperStyle.paddingRight = 16
        wrapperStyle.height = CSSValue(cgfloat: iconSize * 2)
        wrapperStyle.alignItems = .center
        wrapperStyle.flexDirection = .row
        wrapperStyle.backgroundColor = UIColor.ud.N300
        wrapperStyle.width = 100%

        let viewComponent = UIViewComponent<ThreadDetailContext>(props: .empty, style: wrapperStyle)
        viewComponent.setSubComponents([imageComponent, labelComponent])

        return viewComponent
    }()

    private lazy var nameAndTimeContainer: ComponentWithContext<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.justifyContent = .spaceAround
        style.flexGrow = 1
        return ASLayoutComponent<ThreadDetailContext>(style: style, [nameContainer, timeComponent])
    }()

    /// 翻译button 左下角
    private lazy var translateButton: TranslateButtonComponent<ThreadDetailContext> = {
        let props = TranslateButtonComponent<ThreadDetailContext>.Props()
        let style = ASComponentStyle()
        style.alignSelf = .flexStart
        style.marginTop = 8
        style.marginBottom = 5
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
        style.width = 16
        style.height = 16
        return TranslatedByReceiverCompentent<ThreadDetailContext>(props: props, style: style)
    }()

    private lazy var editRequestStatusComponent: MultiEditStatusComponent<ThreadDetailContext> = {
        let style = ASComponentStyle()
        style.marginTop = 4
        let props = MultiEditStatusComponentProps(requestStatus: self.props.editRequestStatus)
        props.retryCallback = self.props.multiEditRetryCallBack
        return MultiEditStatusComponent(props: props, style: style)
    }()
}
