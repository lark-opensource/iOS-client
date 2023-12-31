//
//  ThreadMessageCellComponent.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/15.
//

import UIKit
import Foundation
import LarkBizAvatar
import LarkModel
import RichLabel
import EEFlexiable
import AsyncComponent
import LarkMessageCore
import LarkMessageBase
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkFeatureGating
import RustPB
import LarkUIKit
import LarkFocus
import UniverseDesignIcon
import LKCommonsLogging
import LarkSearchCore

enum Cons {
    static var widthOfavatarImageView: CGFloat { 40.auto() }
    static let leadingOfContentView: CGFloat = 16
    static let spacingOfAvatarAndName: CGFloat = 8
    static let spacingOfNameAndChatName: CGFloat = 17
    static let trailingOfChatName: CGFloat = 48
    static let topOfFooterContainer: CGFloat = 10
    static var actionIconSize: CGFloat { 18.auto() }
    static var thumbIconWidth: CGFloat { 36.auto() }
    static var thumbIconHeight: CGFloat { 42.auto() }
    static var actionIconTapInset: UIEdgeInsets {
        UIEdgeInsets(top: -16, left: -16, bottom: -16, right: -16)
    }
    static var actionIconTop: CGFloat { 12.auto() }
    static var actionIconBottom: CGFloat { 12.auto() }
    static var footerHeight: CGFloat {
        actionIconSize + actionIconTop + actionIconBottom
    }
}

final class ThreadMessageCellProps: ASComponentProps {
    var chatterID: String

    var avatarKey: String
    var avatarTapped: () -> Void

    var name: String
    var time: String

    var chatName: String
    var showChatName: Bool
    var showChatNameSecondLine: Bool
    var chatNameOnTap: () -> Void

    var latestAtMessages: [Message]

    var isFollow: Bool
    var followTapped: () -> Void

    var replyCount: Int
    var replyInfos: [(nameCount: Int, replyAttributedString: NSAttributedString, height: CGFloat)]

    var addReplyTapped: () -> Void
    var hasMenu: Bool
    var menuTapped: (UIView) -> Void

    var messageStatus: Message.LocalStatus
    var statusTapped: () -> Void

    var dlpState: Message.MessageDLPState

    var thumbsUpUseAnimation: Bool
    var thumbsUpTapped: () -> Void

    var forwardButtonTapped: () -> Void
    var shouldShowForwardButton: Bool

    var pinComponent: ComponentWithContext<ThreadContext>?

    var dlpTipComponent: ComponentWithContext<ThreadContext>?

    var fileRiskComponent: ComponentWithContext<ThreadContext>?

    var forwardDescriptionComponent: ComponentWithContext<ThreadContext>?

    var reactionComponent: ComponentWithContext<ThreadContext>?

    var tcPreviewComponent: ComponentWithContext<ThreadContext>?

    var isFromMe: Bool

    var showTranslate: Bool = true
    var identifier: String = ""

    var fromChatter: Chatter?

    var isDecryptoFail: Bool = false

    var hasBorder: Bool = false

    //二次编辑请求状态
    var editRequestStatus: Message.EditMessageInfo.EditRequestStatus?
    var multiEditRetryCallBack: (() -> Void)?

    // 翻译状态
    var translateStatus: Message.TranslateState = .origin
    // 翻译icon点击事件
    var translateTapHandler: (() -> Void)?
    // 翻译埋点
    var translateTrackInfo: [String: Any] = [:]
    // 被其他人自动翻译
    var isAutoTranslatedByReceiver: Bool = false
    // 被其他人自动翻译icon点击事件
    var autoTranslateTapHandler: (() -> Void)?
    // 是否展示翻译 icon
    var canShowTranslateIcon = false

    /// thread状态
    var state: RustPB.Basic_V1_ThreadState
    var borderConfig: (showBorder: Bool, maxWidth: CSSValue) = (false, CSSValueUndefined)
    weak var delegate: LKLabelExpensionIndexDelegate?

    init(chatterID: String,
         avatarKey: String,
         avatarTapped: @escaping () -> Void,
         name: String,
         time: String,
         chatName: String,
         showChatName: Bool,
         showChatNameOnNextLine: Bool,
         chatNameOnTap: @escaping () -> Void,
         latestAtMessages: [Message],
         isFollow: Bool,
         followTapped: @escaping () -> Void,
         replyCount: Int,
         replyInfos: [(nameCount: Int, replyAttributedString: NSAttributedString, height: CGFloat)],
         messageStatus: Message.LocalStatus,
         statusTapped: @escaping () -> Void,
         dlpState: Message.MessageDLPState,
         thumbsUpUseAnimation: Bool,
         thumbsUpTapped: @escaping () -> Void,
         addReplyTapped: @escaping () -> Void,
         forwardButtonTapped: @escaping () -> Void,
         shouldShowForwardButton: Bool,
         hasMenu: Bool,
         isFromMe: Bool,
         state: RustPB.Basic_V1_ThreadState,
         menuTapped: @escaping (UIView) -> Void,
         delegate: LKLabelExpensionIndexDelegate? = nil,
         children: [Component]) {
        self.chatterID = chatterID
        self.avatarKey = avatarKey
        self.avatarTapped = avatarTapped
        self.name = name
        self.time = time
        self.chatName = chatName
        self.showChatName = showChatName
        self.showChatNameSecondLine = showChatNameOnNextLine
        self.latestAtMessages = latestAtMessages
        self.chatNameOnTap = chatNameOnTap
        self.isFollow = isFollow
        self.followTapped = followTapped
        self.replyCount = replyCount
        self.replyInfos = replyInfos
        self.addReplyTapped = addReplyTapped
        self.hasMenu = hasMenu
        self.isFromMe = isFromMe
        self.state = state
        self.menuTapped = menuTapped
        self.messageStatus = messageStatus
        self.statusTapped = statusTapped
        self.dlpState = dlpState
        self.delegate = delegate
        self.thumbsUpTapped = thumbsUpTapped
        self.thumbsUpUseAnimation = thumbsUpUseAnimation
        self.forwardButtonTapped = forwardButtonTapped
        self.shouldShowForwardButton = shouldShowForwardButton
        super.init(children: children)
    }
}

final class ThreadMessageCellComponent: ASComponent<ThreadMessageCellProps, EmptyState, UIView, ThreadContext> {
    static let hightViewKey = "threadMessageCell_highlightKey"
    static let logger = Logger.log(ThreadMessageCellComponent.self, category: "Module.IM.ThreadMessageCellComponent")

    override init(props: ThreadMessageCellProps, style: ASComponentStyle, context: ThreadContext? = nil) {
        super.init(props: props, style: style, context: context)
        style.backgroundColor = UIColor.ud.bgBody
        style.flexDirection = .column
        self.setupFooter()
    }

    override func willReceiveProps(_ old: ThreadMessageCellProps, _ new: ThreadMessageCellProps) -> Bool {
        syncPropsToComponent(props: new)
        // 在iPad上根据view宽度动态调整footerComponents排布方式
        if Display.pad,
           let sizeClass = context?.dataSourceAPI?.traitCollection?.horizontalSizeClass {
            if sizeClass == .regular {
                footerContainer.style.justifyContent = .flexStart
                footerContainer.children.forEach { (component) in
                    component._style.marginLeft = 0
                    component._style.marginRight = 40
                }
            } else {
                footerContainer.style.justifyContent = .spaceAround
                footerContainer.children.forEach { (component) in
                    component._style.marginLeft = 0
                    component._style.marginRight = 0
                }
            }
        }
        return true
    }

    private lazy var pinLayoutComponent: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginBottom = 14
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var dlpTipLayoutComponent: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.alignItems = .center
        style.flexDirection = .row
        style.width = 100%
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var riskFileLayoutComponent: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginBottom = 14
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var reactionLayoutComponent: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginTop = 12
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var forwardDescriptionLayoutComponent: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.marginBottom = 14
        return ASLayoutComponent(style: style, context: context, [])
    }()

    private lazy var thumbActionContainer: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.width = Cons.footerHeight.css
        style.height = style.width
        style.alignItems = .center
        style.justifyContent = .center
        return ASLayoutComponent(style: style, context: context, [thumbsUpComponent])
    }()

    private lazy var thumbsUpComponent: LOTAnimationTapComponent<ThreadContext> = {
        var style = ASComponentStyle()
        style.width = Cons.thumbIconWidth.css
        style.height = Cons.footerHeight.css
        let props = LOTAnimationTapComponent<ThreadContext>.Props()
        props.animationFilePath = BundleConfig.LarkThreadBundle.path(forResource: "data",
                                                                     ofType: "json",
                                                                     inDirectory: "lottie/threadThumbsUp/lightMode") ?? ""
        props.animationFilePathDarkMode = BundleConfig.LarkThreadBundle.path(forResource: "data",
                                                                     ofType: "json",
                                                                     inDirectory: "lottie/threadThumbsUp/darkMode")
        props.hitTestEdgeInsets = Cons.actionIconTapInset
        props.playStart = { [weak self] in
            self?.context?.dataSourceAPI?.pauseDataQueue(true)
        }
        props.playCompletion = { [weak self] in
            self?.context?.dataSourceAPI?.pauseDataQueue(false)
        }
        return LOTAnimationTapComponent(props: props, style: style)
    }()

    private lazy var replyActionContainer: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.width = Cons.footerHeight.css
        style.height = style.width
        style.alignItems = .center
        style.justifyContent = .center
        return ASLayoutComponent(style: style, context: context, [replyComponent])
    }()

    private lazy var replyComponent: IconButtonComponent<ThreadContext> = {
        var style = ASComponentStyle()
        style.width = Cons.actionIconSize.css
        style.height = style.width
        let props = IconButtonComponent<ThreadContext>.Props(icon: Resources.threadMessageComment, iconSize: Cons.actionIconSize)
        props.hitTestEdgeInsets = Cons.actionIconTapInset
        return IconButtonComponent(props: props, style: style)
    }()

    private lazy var forwardActionContainer: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.width = Cons.footerHeight.css
        style.height = style.width
        style.alignItems = .center
        style.justifyContent = .center
        return ASLayoutComponent(style: style, context: context, [forwardButtonComponent])
    }()

    private lazy var forwardButtonComponent: IconButtonComponent<ThreadContext> = {
        var style = ASComponentStyle()
        style.width = Cons.actionIconSize.css
        style.height = style.width
        let props = IconButtonComponent<ThreadContext>.Props(icon: Resources.thread_chat_forward, iconSize: Cons.actionIconSize)
        props.hitTestEdgeInsets = Cons.actionIconTapInset
        return IconButtonComponent(props: props, style: style)
    }()

    private lazy var followActionContainer: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.width = Cons.footerHeight.css
        style.height = style.width
        style.alignItems = .center
        style.justifyContent = .center
        return ASLayoutComponent(style: style, context: context, [followComponent, unFollowComponent])
    }()

    private lazy var followComponent: LOTAnimationTapComponent<ThreadContext> = {
        var style = ASComponentStyle()
        style.width = Cons.actionIconSize.css
        style.height = style.width
        let props = LOTAnimationTapComponent<ThreadContext>.Props()
        props.autoPlayWhenTap = true
        props.animationFilePath = BundleConfig.LarkThreadBundle.path(forResource: "data",
                                                                     ofType: "json",
                                                                     inDirectory: "lottie/threadFollowing/lightMode") ?? ""
        props.animationFilePathDarkMode = BundleConfig.LarkThreadBundle.path(forResource: "data",
                                                                             ofType: "json",
                                                                             inDirectory: "lottie/threadFollowing/darkMode") ?? ""
        props.playStart = { [weak self] in
            self?.context?.dataSourceAPI?.pauseDataQueue(true)
        }
        props.playCompletion = { [weak self] in
            self?.context?.dataSourceAPI?.pauseDataQueue(false)
        }
        props.hitTestEdgeInsets = Cons.actionIconTapInset
        return LOTAnimationTapComponent(props: props, style: style)
    }()

    private lazy var unFollowComponent: IconButtonComponent<ThreadContext> = {
        var style = ASComponentStyle()
        style.width = Cons.actionIconSize.css
        style.height = style.width
        let props = IconButtonComponent<ThreadContext>.Props(iconBlock: Resources.thread_following, iconSize: Cons.actionIconSize)
        props.hitTestEdgeInsets = Cons.actionIconTapInset
        return IconButtonComponent(props: props, style: style)
    }()

    private func setupFooter() {
        footerContainer.setSubComponents(
            [thumbActionContainer,
             replyActionContainer,
             forwardActionContainer,
             followActionContainer]
        )
    }

    private lazy var footerLineComponent: UIViewComponent<ThreadContext> = {
        let lineStyle = ASComponentStyle()
        lineStyle.flexGrow = 1
        lineStyle.height = CSSValue(cgfloat: 0.5)
        lineStyle.backgroundColor = UIColor.ud.lineDividerDefault
        lineStyle.marginTop = 12
        return UIViewComponent<ThreadContext>(props: .empty, style: lineStyle)
    }()

    private lazy var editRequestStatusComponent: MultiEditStatusComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.marginTop = 4
        let props = MultiEditStatusComponentProps(requestStatus: self.props.editRequestStatus)
        props.retryCallback = self.props.multiEditRetryCallBack
        return MultiEditStatusComponent(props: props, style: style)
    }()

    private func syncPropsToComponent(props: ThreadMessageCellProps) {
        avatarComponent.props.avatarKey = props.avatarKey
        avatarComponent.props.medalKey = props.fromChatter?.medalKey ?? ""
        avatarComponent.props.id = props.chatterID
        nameComponent.props.text = props.name
        if props.borderConfig.showBorder {
            contentContainer.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.N300, style: .solid))
            contentContainer.style.cornerRadius = 5
        } else {
            contentContainer.style.border = .none
            contentContainer.style.cornerRadius = 0
        }
        // 设置为true后，选区前后光标会被裁减
        contentContainer.style.ui.masksToBounds = true
        contentContainer.style.maxWidth = props.borderConfig.maxWidth
        if let focusStatus = props.fromChatter?.focusStatusList.topActive {
            focusTagComponent.style.display = .flex
            focusTagComponent.props.focusStatus = focusStatus
        } else {
            focusTagComponent.style.display = .none
        }
        if props.showChatName {
        // 显示来自xxx小组
            chatNameComponent.props.onTap = props.chatNameOnTap
            chatNameComponent.props.text = props.chatName
            if props.showChatNameSecondLine {
                // 来自xxx小组显示在第二行
                nameComponent.style.flexGrow = 1
                chatNameIconComponent.style.marginLeft = 8
                chatNameWarpperComponent.style.marginRight = 32
                nameAndMenuWarpperComponent.setSubComponents(
                    [
                        nameAndTagComponent,
                        menuComponent
                    ]
                )
                nameAndTimeContainer.setSubComponents(
                    [
                        nameAndMenuWarpperComponent,
                        chatNameWarpperComponent,
                        timeComponent
                    ]
                )
            } else {
                // 来自xxx小组显示在第一行
                nameComponent.style.flexGrow = 0
                chatNameIconComponent.style.marginLeft = 4
                chatNameWarpperComponent.style.marginRight = 16
                nameAndMenuWarpperComponent.setSubComponents(
                    [
                        nameAndTagComponent,
                        chatNameWarpperComponent,
                        menuComponent
                    ]
                )
                nameAndTimeContainer.setSubComponents(
                    [
                        nameAndMenuWarpperComponent,
                        timeComponent
                    ]
                )
            }
        } else {
            //不显示来自xxx小组
            nameComponent.style.flexGrow = 1
            nameAndTimeContainer.setSubComponents([nameAndMenuWarpperComponent, timeComponent])
            nameAndMenuWarpperComponent.setSubComponents([nameAndTagComponent, menuComponent])
        }

        if props.hasMenu {
            menuComponent.style.display = .flex
        } else {
            menuComponent.style.display = .none
        }
        timeComponent.props.text = props.time

        let isSuccess = props.messageStatus == .success
        // DLP发送失败不显示status icon
        if isSuccess || (props.dlpState == .dlpBlock) {
            footerContainer.style.display = .flex
            footerLineComponent.style.display = .flex
            footerContainer.children.forEach { (component) in
                component._style.display = .flex
            }
            followActionContainer.style.display = .flex
            if props.isFollow && props.dlpState != .dlpBlock {
                followComponent.style.display = .none
                unFollowComponent.style.display = .flex
            } else {
                followComponent.style.display = .flex
                unFollowComponent.style.display = .none
            }

        } else {
            footerContainer.style.display = .none
            footerLineComponent.style.display = .none
            footerContainer.children.forEach { (component) in
                component._style.display = .none
            }
            followComponent.style.display = .none
            unFollowComponent.style.display = .none
        }

        replyContentWrapperComponent.style.display = props.replyInfos.isEmpty ? .none : .flex
        replyContentComponent.setSubComponents(getRepliesContentComponents(props: props))

        // 消息发送状态
        let isMessageSuccess = props.messageStatus == .success || props.dlpState == .dlpBlock
        messageStatusComponent.props.isFailed = props.messageStatus == .fail
        messageStatusComponent.style.display = isMessageSuccess ? .none : .flex
        messageStatusFooterContainer.style.display = isMessageSuccess ? .none : .flex

        // pin
        if let pinComponent = props.pinComponent {
            pinLayoutComponent.setSubComponents([pinComponent])
            pinLayoutComponent.style.display = .flex
        } else {
            pinLayoutComponent.setSubComponents([])
            pinLayoutComponent.style.display = .none
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

        // Forward description
        if let forwardComponent = props.forwardDescriptionComponent {
            forwardDescriptionLayoutComponent.setSubComponents([forwardComponent])
            forwardDescriptionLayoutComponent.style.display = .flex
        } else {
            forwardDescriptionLayoutComponent.setSubComponents([])
            forwardDescriptionLayoutComponent.style.display = .none
        }

        // 内容
        contentContainer.children = props.getChildren()

        var showTranslateIfNeeded: Bool = true
        // 当前设备需要展示翻译的时候,判断业务是否允许
        if showTranslateIfNeeded, !props.showTranslate {
            showTranslateIfNeeded = false
        }

        // Forward button
        if props.shouldShowForwardButton {
            forwardActionContainer.style.display = .flex
        } else {
            forwardActionContainer.style.display = .none
        }

        // Thread状态
        if props.isDecryptoFail {
            closeComponent.style.display = .none
            thumbActionContainer.style.display = .none
            forwardActionContainer.style.display = .none
            replyActionContainer.style.display = .flex
            followActionContainer.style.display = .flex
        } else {
            switch props.state {
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
        }

        if let reactionComponent = props.reactionComponent {
            reactionLayoutComponent.setSubComponents([reactionComponent])
            reactionLayoutComponent.style.display = .flex
        } else {
            reactionLayoutComponent.setSubComponents([])
            reactionLayoutComponent.style.display = .none
        }
        if context?.isPreview == true {
            footerContainer.style.display = .none
            footerLineComponent.style.height = CSSValue(cgfloat: 0.0)
            menuComponent.style.display = .none
        }
        /// 原顺序
        /// pinLayoutComponent,
        /// forwardDescriptionLayoutComponent,
        /// headerComponent,
        /// contentContainer,
        /// translateStatus,
        /// autoTranslatedByReceiver,
        /// replyContentWrapperComponent,
        /// reactionLayoutComponent,
        /// footerLineComponent,
        /// footerContainer,
        /// messageStatusFooterContainer

        //主要内容的Components。有些场景会需要有一个边框把这些Components包起来
        var mainContentComponents: [ComponentWithContext<ThreadContext>] = []
        mainContentComponents.append(contentsOf: [
            contentContainer,
            translateButton,
            autoTranslatedByReceiver
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
        wrapperStyle.marginTop = 12
        if props.hasBorder {
            wrapperStyle.borderWidth = 1
            wrapperStyle.cornerRadius = 10
            wrapperStyle.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
            wrapperStyle.boxSizing = .borderBox
            wrapperStyle.backgroundColor = UIColor.ud.bgFloat
        }
        let mainContentComponent = UIViewComponent<ThreadContext>(props: .empty, style: wrapperStyle)
        mainContentComponent.setSubComponents(mainContentComponents)

        var subCompoments: [ComponentWithSubContext<ThreadContext, ThreadContext>] = []
        subCompoments.append(contentsOf: [
            pinLayoutComponent,
            forwardDescriptionLayoutComponent,
            headerComponent,
            mainContentComponent,
            dlpTipLayoutComponent,
            riskFileLayoutComponent,
            editRequestStatusComponent,
            replyContentWrapperComponent,
            reactionLayoutComponent,
            footerLineComponent,
            footerContainer,
            messageStatusFooterContainer
        ])

        editRequestStatusComponent.style.display = (props.editRequestStatus == .failed) || (props.editRequestStatus == .wating) ? .flex : .none
        editRequestStatusComponent.props.requestStatus = props.editRequestStatus
        editRequestStatusComponent.props.retryCallback = props.multiEditRetryCallBack

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
        wrapperComponent.setSubComponents(subCompoments)
        setSubComponents([selectedHighlightViewComponent,
                          highlightViewComponent,
                          closeComponent,
                          wrapperComponent,
                          frontHighLightViewComponent,
                          createSeprateLine()])
    }

    override func render() -> BaseVirtualNode {
        style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }

    override func update(view: UIView) {
        super.update(view: view)
        avatarComponent.props.onTapped.value = { [weak self] _ in
            self?.props.avatarTapped()
        }

        if props.hasMenu {
            menuComponent.props.onTapped = { [weak self] button in
                self?.props.menuTapped(button)
            }
        } else {
            menuComponent.props.onTapped = nil
        }
        let isSuccess = props.messageStatus == .success

        let repliesIsEmpty = self.props.replyCount == 0
        if isSuccess {
            replyComponent.props.onTapped = { [weak self] _ in
                guard let `self` = self else { return }
                if !repliesIsEmpty {
                    ThreadTracker.trackClickReplyNumButton()
                } else {
                    ThreadTracker.trackClickReplyButton()
                }
                self.props.addReplyTapped()
            }
            followComponent.props.identifier = self.props.identifier
            followComponent.props.tapHandler = { [weak self] in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self?.props.followTapped()
            }
            unFollowComponent.props.onTapped = { [weak self] _ in
                self?.props.followTapped()
            }
            forwardButtonComponent.props.onTapped = { [weak self] _ in
                self?.props.forwardButtonTapped()
            }
            thumbsUpComponent.props.tapHandler = { [weak self] in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self?.props.thumbsUpTapped()
            }
            thumbsUpComponent.props.autoPlayWhenTap = self.props.thumbsUpUseAnimation
            thumbsUpComponent.props.identifier = self.props.identifier
        } else {
            replyComponent.props.onTapped = nil
            followComponent.props.tapHandler = nil
            unFollowComponent.props.onTapped = nil
            thumbsUpComponent.props.tapHandler = nil
        }
    }

    private func createSeprateLine() -> ComponentWithContext<ThreadContext> {
        let viewProps = ASComponentProps()
        let viewStyle = ASComponentStyle()
        viewStyle.backgroundColor = UIColor.ud.bgBase
        viewStyle.height = 10
        viewStyle.width = 100%
        return UIViewComponent<ThreadContext>(props: viewProps, style: viewStyle)
    }

    private var reciveLableDelegates = [ReciveLKLabelEvent]()

    private func getReciveLabelDelegate(index: Int) -> ReciveLKLabelEvent {
        if index < reciveLableDelegates.count {
            return reciveLableDelegates[index]
        } else {
            let recive = ReciveLKLabelEvent(index: index, delegate: props.delegate)
            reciveLableDelegates.append(recive)
            return recive
        }
    }

    private func getRepliesContentComponents(props: ThreadMessageCellProps) -> [ComponentWithContext<ThreadContext>] {
        var components: [ComponentWithContext<ThreadContext>] = []
        if props.replyCount > props.replyInfos.count {
            let lableProps = UILabelComponentProps()
            lableProps.font = UIFont.ud.caption0
            lableProps.textColor = UIColor.ud.textPlaceholder
            let countStr = " " + String(props.replyCount - props.replyInfos.count) + " "
            lableProps.text = BundleI18n.LarkThread.Lark_Chat_TopicCardRepliesCountButton(countStr)
            let style = ASComponentStyle()
            style.backgroundColor = .clear
            style.marginTop = 12
            let countComponent = UILabelComponent<ThreadContext>(props: lableProps, style: style)
            components.append(countComponent)
        }
        for (index, replyInfo) in props.replyInfos.enumerated() {
            let replyProps = RichLabelProps()
            replyProps.attributedText = replyInfo.replyAttributedString
            replyProps.numberOfLines = 2
            replyProps.tapableRangeList = [NSRange(location: 0, length: replyInfo.replyAttributedString.string.count)]
            replyProps.outOfRangeText = NSAttributedString(string: "...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption])
            replyProps.delegate = getReciveLabelDelegate(index: index)

            let replyStyle = ASComponentStyle()
            replyStyle.flexGrow = 1
            replyStyle.backgroundColor = UIColor.clear

            var marginTop: Int
            // 如果不存在”更早回复“文案 && 第一条回复
            if props.replyCount <= props.replyInfos.count && index == 0 {
                marginTop = 12
            } // 存在更早的回复 && 第一条回复
            else if index == 0 {
                marginTop = 6
            }// 不是第一条回复
            else {
                marginTop = 4
            }
            replyStyle.marginTop = CSSValue(integerLiteral: marginTop)
            let replyView = RichLabelComponent<ThreadContext>(props: replyProps, style: replyStyle)
            components.append(replyView)
        }
        return components
    }

    private lazy var wrapperComponent: UIViewComponent<ThreadContext> = {
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.padding = CSSValue(cgfloat: Cons.leadingOfContentView)
        wrapperStyle.paddingBottom = 0
        wrapperStyle.alignContent = .stretch
        wrapperStyle.flexDirection = .column
        wrapperStyle.width = 100%
        return UIViewComponent<ThreadContext>(props: .empty, style: wrapperStyle)
    }()

    /// 消息高亮前蒙层
    private lazy var frontHighLightViewComponent: ASComponent<ASComponentProps, EmptyState, HighlightFrontRectangleView, ThreadContext> = {
        let viewProps = ASComponentProps()
        viewProps.key = MessageCommonCell.highlightBubbleViewKey

        let viewStyle = ASComponentStyle()
        viewStyle.position = .absolute
        viewStyle.backgroundColor = .ud.N900
        viewStyle.top = 0
        viewStyle.bottom = 0
        viewStyle.width = 100%
        return ASComponent<ASComponentProps, EmptyState, HighlightFrontRectangleView, ThreadContext>(props: viewProps, style: viewStyle)
    }()

    /// highlight view
    private lazy var highlightViewComponent: UIViewComponent<ThreadContext> = {
        let viewProps = ASComponentProps()
        viewProps.key = MessageCommonCell.highlightViewKey

        let viewStyle = ASComponentStyle()
        viewStyle.position = .absolute
        viewStyle.backgroundColor = UIColor.clear
        viewStyle.top = 0
        viewStyle.bottom = 0
        viewStyle.width = 100%
        return UIViewComponent<ThreadContext>(props: viewProps, style: viewStyle)
    }()

    private lazy var selectedHighlightViewComponent: UIViewComponent<ThreadContext> = {
        let viewProps = ASComponentProps()
        viewProps.key = ThreadMessageCellComponent.hightViewKey

        let viewStyle = ASComponentStyle()
        viewStyle.position = .absolute
        // TODO: 基础色板中未找到 0xFAFAFB 对应颜色
        viewStyle.backgroundColor = UIColor.ud.N50
        viewStyle.top = 0
        viewStyle.bottom = 0
        viewStyle.width = 100%
        return UIViewComponent<ThreadContext>(props: viewProps, style: viewStyle)
    }()

    private lazy var contentContainer: UIViewComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.width = 100%
        let viewComponent = UIViewComponent<ThreadContext>(props: .empty, style: style)
        viewComponent.setSubComponents(props.getChildren())
        return viewComponent
    }()

    private lazy var headerComponent: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.alignContent = .stretch
        style.width = 100%
        return ASLayoutComponent<ThreadContext>(style: style, [
            avatarComponent,
            nameAndTimeContainer
        ])
    }()

    private lazy var avatarComponent: AvatarComponent<ThreadContext> = {
        let avatarProps = AvatarComponent<ThreadContext>.Props()
        avatarProps.avatarKey = props.avatarKey
        avatarProps.onTapped.value = { [weak self] _ in
            self?.props.avatarTapped()
        }
        let avatarStyle = ASComponentStyle()
        avatarStyle.width = CSSValue(cgfloat: Cons.widthOfavatarImageView)
        avatarStyle.height = CSSValue(cgfloat: Cons.widthOfavatarImageView)
        avatarStyle.flexShrink = 0

        return AvatarComponent<ThreadContext>(props: avatarProps, style: avatarStyle)
    }()

    private lazy var nameComponent: UILabelComponent<ThreadContext> = {
        let nameProps = UILabelComponentProps()
        nameProps.font = UIFont.ud.body1
        nameProps.textColor = UIColor.ud.textTitle
        /// 这里展示补下应该展示..., 不然太奇怪了
        nameProps.lineBreakMode = .byTruncatingTail
        nameProps.text = props.name
        let nameStyle = ASComponentStyle()
        nameStyle.marginLeft = CSSValue(cgfloat: Cons.spacingOfAvatarAndName)
        nameStyle.flexShrink = 1
        nameStyle.flexGrow = 1
        nameStyle.height = 20
        nameStyle.backgroundColor = .clear
        return UILabelComponent<ThreadContext>(props: nameProps, style: nameStyle)
    }()

    /// 个人状态 icon
    private lazy var focusTagComponent: FocusTagComponent<ThreadContext> = {
        let props = FocusTagComponent<ThreadContext>.Props()
        props.preferredSingleIconSize = 16
        let style = ASComponentStyle()
        style.display = .none
        style.flexShrink = 0
        style.flexGrow = 0
        style.marginLeft = 6
        return FocusTagComponent<ThreadContext>(props: props, style: style)
    }()

    private lazy var menuComponent: IconButtonComponent<ThreadContext> = {
        let menuStyle = ASComponentStyle()
        menuStyle.display = props.messageStatus == .success ? .flex : .none
        menuStyle.marginRight = -2
        menuStyle.marginLeft = 8

        let menuProps = IconButtonComponent<ThreadContext>.Props(icon: Resources.thread_more)
        menuProps.hitTestEdgeInsets = UIEdgeInsets(top: -15, left: -15, bottom: -15, right: -15)
        menuProps.onTapped = { [weak self] button in
            self?.props.menuTapped(button)
        }
        return IconButtonComponent<ThreadContext>(props: menuProps, style: menuStyle)
    }()

    private lazy var timeComponent: UILabelComponent<ThreadContext> = {
        let timeProps = UILabelComponentProps()
        timeProps.font = UIFont.ud.caption1
        timeProps.textColor = UIColor.ud.textPlaceholder
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        timeProps.lineBreakMode = .byWordWrapping
        timeProps.text = props.time
        let timeStyle = ASComponentStyle()
        timeStyle.backgroundColor = UIColor.clear
        timeStyle.marginLeft = 8
        timeStyle.marginTop = 1
        timeStyle.height = 17
        timeStyle.backgroundColor = .clear
        return UILabelComponent<ThreadContext>(props: timeProps, style: timeStyle)
    }()

    private lazy var chatNameComponent: UILabelComponent<ThreadContext> = {
        let labelProps = UILabelComponentProps()
        labelProps.text = BundleI18n.LarkThread.Lark_Chat_TopicStatusClosedTip
        labelProps.font = UIFont.ud.body1
        labelProps.textColor = UIColor.ud.textCaption
        labelProps.isEnabled = true
        labelProps.isUserInteractionEnabled = true

        let labelStyle = ASComponentStyle()
        labelStyle.backgroundColor = UIColor.clear
        labelStyle.marginLeft = 5
        labelStyle.flexGrow = 1

        return UILabelComponent<ThreadContext>(props: labelProps, style: labelStyle)
    }()

    private lazy var chatNameIconComponent: UIImageViewComponent<ThreadContext> = {
        let imageProps = UIImageViewComponentProps()
        imageProps.setImage = { $0.set(image: Resources.thread_home_right_arrow) }

        let imageStyle = ASComponentStyle()
        imageStyle.width = 8
        imageStyle.height = 8
        imageStyle.alignSelf = .center
        imageStyle.flexShrink = 0
        return UIImageViewComponent<ThreadContext>(props: imageProps, style: imageStyle)
    }()

    private lazy var chatNameWarpperComponent: UIViewComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.marginLeft = 4
        style.marginRight = 16
        style.flexGrow = 1

        let viewComponent = UIViewComponent<ThreadContext>(props: .empty, style: style)
        viewComponent.setSubComponents([chatNameIconComponent, chatNameComponent])

        return viewComponent
    }()

    private lazy var nameAndTagComponent: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.justifyContent = .flexStart
        style.alignItems = .center
        return ASLayoutComponent<ThreadContext>(style: style, [nameComponent, focusTagComponent])
    }()

    private lazy var nameAndMenuWarpperComponent: ASLayoutComponent<ThreadContext> = {
        let nameAndMenuStyle = ASComponentStyle()
        nameAndMenuStyle.justifyContent = .spaceBetween
        nameAndMenuStyle.width = 100%
        return ASLayoutComponent<ThreadContext>(style: nameAndMenuStyle, [nameAndTagComponent, menuComponent])
    }()

    private lazy var nameAndTimeContainer: ASLayoutComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.justifyContent = .spaceAround
        style.flexGrow = 1
        return ASLayoutComponent<ThreadContext>(style: style, [nameAndMenuWarpperComponent, timeComponent])
    }()

    private lazy var closeComponent: UIViewComponent<ThreadContext> = {
        let font = UIFont.ud.caption0
        let iconSize = font.rowHeight

        let imageProps = UIImageViewComponentProps()
        imageProps.setImage = { $0.set(image: Resources.thread_close.ud.withTintColor(UIColor.ud.iconN2)) }
        let imageStyle = ASComponentStyle()
        imageStyle.width = iconSize.css
        imageStyle.height = imageStyle.width
        imageStyle.flexShrink = 0
        let imageComponent = UIImageViewComponent<ThreadContext>(props: imageProps, style: imageStyle)

        let labelProps = UILabelComponentProps()
        labelProps.text = BundleI18n.LarkThread.Lark_Chat_TopicStatusClosedTip
        labelProps.font = font
        labelProps.textColor = UIColor.ud.textCaption
        let labelStyle = ASComponentStyle()
        labelStyle.backgroundColor = UIColor.clear
        labelStyle.marginLeft = 4
        let labelComponent = UILabelComponent<ThreadContext>(props: labelProps, style: labelStyle)

        let wrapperStyle = ASComponentStyle()
        wrapperStyle.paddingLeft = 16
        wrapperStyle.paddingRight = 16
        wrapperStyle.height = (iconSize * 2).css
        wrapperStyle.alignItems = .center
        wrapperStyle.flexDirection = .row
        wrapperStyle.backgroundColor = UIColor.ud.N300
        wrapperStyle.width = 100%

        let viewComponent = UIViewComponent<ThreadContext>(props: .empty, style: wrapperStyle)
        viewComponent.setSubComponents([imageComponent, labelComponent])

        return viewComponent
    }()

    private lazy var footerContainer: ASLayoutComponent<ThreadContext> = {
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.width = 100%
        wrapperStyle.display = .none
        wrapperStyle.alignItems = .center
        //子容器沿主轴均匀分布，位于首尾两端的子容器到父容器的距离是子容器间距的一半。
        wrapperStyle.justifyContent = .spaceAround
        wrapperStyle.backgroundColor = UIColor.clear
        return ASLayoutComponent<ThreadContext>(style: wrapperStyle, [])
    }()

    private lazy var replyContentWrapperComponent: UIViewComponent<ThreadContext> = {
        let wrapperStyle = ASComponentStyle()
        wrapperStyle.flexDirection = .column
        wrapperStyle.alignContent = .stretch
        wrapperStyle.width = 100%
        wrapperStyle.marginTop = 5
        let wrapper = UIViewComponent<ThreadContext>(props: .empty, style: wrapperStyle)
        let triangleProps = UIImageViewComponentProps()
        triangleProps.setImage = { $0.set(image: Resources.threadReplyTriangle.ud.withTintColor(UIColor.ud.bgFloatOverlay)) }
        let triangleStyle = ASComponentStyle()
        triangleStyle.width = 15
        triangleStyle.height = 8
        triangleStyle.marginLeft = 20
        let triangle = UIImageViewComponent<ThreadContext>(props: triangleProps, style: triangleStyle)
        wrapper.setSubComponents([triangle, replyContentComponent])
        return wrapper
    }()

    private lazy var replyContentComponent: UIViewComponent<ThreadContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.backgroundColor = UIColor.ud.bgFloatOverlay
        style.alignContent = .stretch
        style.width = 100%
        style.cornerRadius = 8
        style.paddingBottom = 12
        style.paddingLeft = 8
        style.paddingRight = 8
        return UIViewComponent<ThreadContext>(props: .empty, style: style)
    }()

    private lazy var messageStatusComponent: MessageStatusButtonComponent<ThreadContext> = {
        let isSuccess = props.messageStatus == .success
        let isFailed = props.messageStatus == .fail

        let messageStatusButtonProps = MessageStatusButtonComponent<ThreadContext>.Props(isFailed: isFailed)
        messageStatusButtonProps.onTapped = { [weak self] _ in
            self?.props.statusTapped()
        }
        let buttonStyle = ASComponentStyle()
        // DLP发送失败不显示status icon
        buttonStyle.display = (isSuccess || props.dlpState == .dlpBlock) ? .none : .flex
        buttonStyle.alignSelf = .flexEnd
        buttonStyle.marginBottom = 12
        return MessageStatusButtonComponent<ThreadContext>(props: messageStatusButtonProps, style: buttonStyle)
    }()

    private lazy var messageStatusFooterContainer: ASLayoutComponent<ThreadContext> = {
        let isSuccess = props.messageStatus == .success

        let wrapperStyle = ASComponentStyle()
        wrapperStyle.justifyContent = .flexEnd
        wrapperStyle.marginTop = CSSValue(cgfloat: Cons.topOfFooterContainer)
        wrapperStyle.height = CSSValue(cgfloat: Cons.footerHeight)
        wrapperStyle.width = 100%
        wrapperStyle.display = (isSuccess || props.dlpState == .dlpBlock) ? .none : .flex
        wrapperStyle.marginBottom = 10
        return ASLayoutComponent<ThreadContext>(style: wrapperStyle, [messageStatusComponent])
    }()

    /// 翻译button 左下角
    private lazy var translateButton: TranslateButtonComponent<ThreadContext> = {
        let props = TranslateButtonComponent<ThreadContext>.Props()
        let style = ASComponentStyle()
        style.alignSelf = .flexStart
        style.marginTop = 8
        style.marginBottom = 4
        return TranslateButtonComponent<ThreadContext>(props: props, style: style)
    }()

    /// 消息被其他人自动翻译icon 右下角
    private lazy var autoTranslatedByReceiver: TranslatedByReceiverCompentent<ThreadContext> = {
        let props = TranslatedByReceiverCompentent<ThreadContext>.Props()
        props.tapHandler = { [weak self] in
            guard let `self` = self else { return }
            self.props.autoTranslateTapHandler?()
        }

        let style = ASComponentStyle()
        style.alignSelf = .flexEnd
        style.width = 16
        style.height = 16
        return TranslatedByReceiverCompentent<ThreadContext>(props: props, style: style)
    }()

}

protocol LKLabelExpensionIndexDelegate: AnyObject {
    func attributedLabel(_ label: LKLabel, index: Int, didSelectText text: String, didSelectRange range: NSRange) -> Bool
}

final class ReciveLKLabelEvent: LKLabelDelegate {
    private let index: Int
    weak var delegate: LKLabelExpensionIndexDelegate?

    init(index: Int, delegate: LKLabelExpensionIndexDelegate?) {
        self.index = index
        self.delegate = delegate
    }

    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return self.delegate?.attributedLabel(
            label,
            index: index,
            didSelectText: text,
            didSelectRange: range) ?? false
    }
}
