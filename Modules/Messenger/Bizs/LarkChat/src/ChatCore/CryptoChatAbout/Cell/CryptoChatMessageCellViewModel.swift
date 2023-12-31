//
//  CryptoChatMessageCellViewModel.swift
//  LarkChat
//
//  Created by zc09v on 2021/11/24.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import EEFlexiable
import AsyncComponent
import LarkMessageCore
import LarkTag
import LarkUIKit
import LarkCore
import RxRelay
import LarkMessageBase
import EENavigator
import LarkNavigator
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkExtensions
import LarkSDKInterface
import SuiteAppConfig
import LarkBizAvatar
import LarkAlertController
import LKCommonsLogging
import LarkContainer
import UniverseDesignColor
import LarkSetting

final class CryptoChatMessageCellViewModel: ChatMessageCellViewModel {
    private lazy var readStatesProtectEnable: Bool = context.getStaticFeatureGating(.init(stringLiteral: "chat.message.readstate_protect"))
    lazy var threadReplyBubbleOptimize: Bool = context.getStaticFeatureGating("im.message.thread_reply_bubble_optimize")

    var hasMessageStatus: Bool {
        let chatWithBot = metaModel.getChat().chatter?.type == .bot
        // 有消息状态首先是我发的消息，如果是和机器人的消息发送成功了也不显示
        // 或者不是我发的，但是有密聊倒计时
        return config.hasStatus && (isFromMe && !(chatWithBot && message.localStatus == .success)) || !isFromMe
    }

    var nameTag: [Tag] = []
    let avatarLayout: AvatarLayout

    init(metaModel: ChatMessageMetaModel,
         context: ChatContext,
         contentFactory: ChatMessageSubFactory,
         getContentFactory: @escaping (ChatMessageMetaModel, ChatCellMetaModelDependency) -> MessageSubFactory<ChatContext>,
         subfactories: [SubType: ChatMessageSubFactory],
         metaModelDependency: ChatCellMetaModelDependency) {
        let avartarLayout: AvatarLayout
        if context.dataSourceAPI?.supportAvatarLeftRightLayout ?? false,
           context.isMe(metaModel.message.fromId, chat: metaModel.getChat()) {
            avartarLayout = .right
        } else {
            avartarLayout = .left
        }
        self.avatarLayout = avartarLayout
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subfactories,
            initBinder: { contentComponent in
                return NewCryptoChatMessageCellComponentBinder(context: context, contentComponent: contentComponent)
            },
            cellLifeCycleObseverRegister: nil
        )
        self.nameTag = nameTags(for: self.fromChatter)
        super.calculateRenderer()
    }

    override func update(metaModel: ChatMessageMetaModel, metaModelDependency: ChatCellMetaModelDependency? = nil) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        if let metaModelDependency = metaModelDependency {
            self.config = metaModelDependency.config
        }
        if message.isRecalled && !(content is RecalledContentViewModel) {
            self.updateContent(contentBinder: RecalledContentComponentBinder(
                viewModel: RecalledContentViewModel<ChatMessageMetaModel, ChatCellMetaModelDependency, ChatContext>(
                    metaModel: metaModel,
                    metaModelDependency: ChatCellMetaModelDependency(
                        contentPadding: self.metaModelDependency.contentPadding,
                        contentPreferMaxWidth: self.metaModelDependency.contentPreferMaxWidth
                    ),
                    context: context
                ),
                actionHandler: RecalledMessageActionHandler(context: context)
            ))
        } else {
            self.updateContent(metaModel: metaModel, metaModelDependency: metaModelDependency)
        }
        self.nameTag = nameTags(for: message.fromChatter)
        self.calculateRenderer()
    }

    override func didSelect() {
        if message.localStatus == .success {
            self.toggleTime()
        }
        super.didSelect()
    }
}

// MARK: - NewChatMessageCellComponent
extension CryptoChatMessageCellViewModel {
    // 是否展示头像
    var showAvatar: Bool {
        // 吸附消息不展示头像，密聊没有选中状态 & 折叠消息
        if !config.isSingle {
            return false
        }
        return true
    }

    // 是否显示Header区域
    var showHeader: Bool {
        return config.isSingle && config.hasHeader && avatarLayout == .left
    }

    // 是否是文件卡片（文件消息且渲染出了卡片）
    var isFileCard: Bool {
        return message.type == .file && getSubComponent(subType: .tcPreview) != nil
    }

    var bubbleConfig: BubbleViewConfig {
        return BubbleViewConfig(
            changeTopCorner: config.changeTopCorner,
            changeBottomCorner: config.changeBottomCorner,
            changeRaiusReverse: (avatarLayout == .right),
            bubbleStyle: .normal,
            strokeColor: bubbleStrokeColor,
            fillColor: bubbleFillColor,
            strokeWidth: bubbleStrokeWidth
        )
    }

    private var bubbleStrokeColor: UIColor {
        let contentConfig = content.contentConfig
        if contentConfig?.hasBorder ?? false {
            let borderStyle = contentConfig?.borderStyle ?? .card
            return (borderStyle == .card) ? UDMessageColorTheme.imMessageCardBorder : UIColor.ud.lineBorderCard
        } else {
            return UIColor.clear
        }
    }

    private var bubbleFillColor: UIColor {
        let contentConfig = content.contentConfig
        // 有边框则设置背景透明
        if contentConfig?.hasBorder ?? false {
            return UIColor.clear
        } else {
            // 气泡背景样式，white为自己发的/分享日常/分享群卡片
            let contentBackgroundStyle = contentConfig?.backgroundStyle ?? (isFromMe ? .white : .gray)
            switch contentBackgroundStyle {
            case .white:
                // white为蓝色的背景
                return context.getColor(for: .Message_Bubble_Background, type: .mine)
            case .gray:
                // gray为灰色的背景
                return context.getColor(for: .Message_Bubble_Background, type: .other)
            case .clear:
                return UIColor.clear
            }
        }
    }

    private var bubbleStrokeWidth: CGFloat {
        let contentConfig = content.contentConfig
        if (contentConfig?.hasBorder ?? false), contentConfig?.borderStyle == .image {
            return 1 / UIScreen.main.scale
        }
        return 1
    }

    var flagIconMargin: CGFloat {
        // 语音消息有小红点，图标位置单独处理
        guard let audioContent = self.content as? AudioContentViewModel else {
            return 6.0
        }
        return audioContent.hasRedDot ? 19.0 : 6.0
    }

    var highlightBgColor: UIColor {
        return isHightlight ? UDMessageColorTheme.imMessageBgLocation : UIColor.clear
    }

    var showHighlightBlur: Bool {
        return oneOfSubComponentsDisplay([.pin, .flag])
    }

    var highlightBlurColor: UIColor {
        return chatComponentTheme.pinHighlightColor
    }

    var cellComponentBgColor: UIColor {
        if oneOfSubComponentsDisplay([.pin, .flag]) {
            // backgroundColor is yellow when cell was pined
            return UDMessageColorTheme.imMessageBgPin
        } else if chatComponentTheme.isDefaultScene {
            return UIColor.ud.bgBody & UIColor.ud.bgBase
        } else {
            // backgroundColor is nil when nothing
            return .clear
        }
    }

    func oneOfSubComponentsDisplay(_ types: [SubType]) -> Bool {
        return types.contains(where: { getSubComponent(subType: $0)?._style.display == .flex })
    }
}

final class NewCryptoChatMessageCellComponentBinder: ComponentBinder<ChatContext> {
    private let context: ChatContext?

    private let props: NewChatMessageCellProps<ChatContext>
    private let style = ASComponentStyle()
    private var _component: NewChatMessageCellComponent<ChatContext>
    override var component: ComponentWithContext<ChatContext> {
        return _component
    }

    private lazy var avatarContainerProps = AvatarContainerComponentProps()
    private lazy var avatarContainer = AvatarContainerComponent<ChatContext>(props: avatarContainerProps, style: ASComponentStyle(), context: context)

    private lazy var headerComponentProps = HeaderComponentProps<ChatContext>()
    private lazy var headerComponent = HeaderComponent<ChatContext>(props: headerComponentProps, style: ASComponentStyle(), context: context)

    private lazy var footerComponentProps = FooterComponentProps<ChatContext>()
    private lazy var footerComponent = FooterComponent<ChatContext>(props: footerComponentProps, style: ASComponentStyle(), context: context)

    private let bubbleViewProps: BubbleViewLayoutComponentProps<ChatContext>
    private lazy var bubbleView = BubbleViewLayoutComponent<ChatContext>(props: bubbleViewProps, context: context)

    private lazy var contentProps = ContentComponentProps<ChatContext>(bubbleView: bubbleView.getBubbleView())
    private lazy var content = ContentComponent<ChatContext>(props: contentProps, style: ASComponentStyle(), context: context)

    private lazy var highlightComponentProps = HighlightViewComponentProps<ChatContext>()
    private lazy var highlightComponent = HighlightViewComponent<ChatContext>(props: highlightComponentProps, style: ASComponentStyle(), context: context)

    init(key: String? = nil, context: ChatContext? = nil, contentComponent: ComponentWithContext<ChatContext>) {
        self.context = context
        self.bubbleViewProps = BubbleViewLayoutComponentProps<ChatContext>(contentComponent: contentComponent)
        props = NewChatMessageCellProps()
        style.width = CSSValue(cgfloat: UIScreen.main.bounds.width)
        _component = NewChatMessageCellComponent(
            props: props,
            style: style,
            context: context
        )
        super.init(key: key, context: context)
        _component.lifeCycle = self
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CryptoChatMessageCellViewModel else {
            assertionFailure()
            return
        }
        var subComponents: [ChatMessageCellSubType: ComponentWithContext<ChatContext>] = [:]
        if updateAvatar(vm: vm) {
            subComponents[.avatar] = avatarContainer
        }
        if updateHeader(vm: vm) {
            subComponents[.header] = headerComponent
        }
        if updateContent(vm: vm) {
            subComponents[.content] = content
        }
        if updateHighlight(vm: vm) {
            subComponents[.highlight] = highlightComponent
        }
        if updateFooter(vm: vm) {
            subComponents[.footer] = footerComponent
        }
        props.subComponents = subComponents
        props.inSelectMode = false
        props.isSingle = vm.config.isSingle
        props.isFold = false
        props.isEphemeral = false
        props.cellBackgroundColor = vm.cellComponentBgColor
        props.avatarLayout = vm.avatarLayout
        props.maxCellWidth = vm.context.maxCellWidth
        _component.props = props
    }

    private func updateAvatar(vm: CryptoChatMessageCellViewModel) -> Bool {
        guard vm.showAvatar else { return false }
        avatarContainerProps.avatarTapped = { [weak vm] in
            vm?.onAvatarTapped()
        }
        avatarContainerProps.fromChatter = vm.fromChatter
        avatarContainerProps.isScretChat = true
        avatarContainerProps.avatarLayout = vm.avatarLayout
        avatarContainerProps.hideUserInfo = vm.hideUserInfo
        avatarContainer.props = avatarContainerProps
        return true
    }

    private func updateHeader(vm: CryptoChatMessageCellViewModel) -> Bool {
        guard vm.showHeader else { return false }
        headerComponentProps.fromChatter = vm.fromChatter
        headerComponentProps.nameAndDescColor = vm.chatComponentTheme.nameAndDescColor
        headerComponentProps.chatterStatusDivider = vm.chatComponentTheme.chatterStatusDivider
        headerComponentProps.getDisplayName = { [weak vm] chatter in
            guard let vm = vm else { return "" }
            return vm.getDisplayName(chatter: chatter, chat: vm.metaModel.getChat(), scene: .head)
        }
        headerComponentProps.contentPreferMaxWidth = vm.contentPreferMaxWidth
        headerComponentProps.nameTag = vm.nameTag

        headerComponentProps.subComponents = vm.getSubComponents()
        headerComponent.props = headerComponentProps
        return true
    }

    private func updateContent(vm: CryptoChatMessageCellViewModel) -> Bool {
        updateBubble(vm: vm)

        contentProps.flagIconMargin = vm.flagIconMargin
        contentProps.hasMessageStatus = vm.hasMessageStatus
        contentProps.showCheckBox = false
        contentProps.checked = false
        contentProps.selectedEnable = (vm.content.contentConfig?.selectedEnable ?? false)
        contentProps.isFold = false
        contentProps.avatarLayout = vm.avatarLayout
        contentProps.bubbleView = bubbleView.getBubbleView()
        contentProps.subComponents = vm.getSubComponents()
        contentProps.oneOfSubComponentsDisplay = { [weak vm] types in
            return vm?.oneOfSubComponentsDisplay(types) ?? false
        }
        content.props = contentProps
        return true
    }

    private func updateBubble(vm: CryptoChatMessageCellViewModel) {
        bubbleViewProps.contentPreferMaxWidth = vm.contentPreferMaxWidth
        bubbleViewProps.contentPadding = vm.metaModelDependency.contentPadding
        bubbleViewProps.isFromMe = vm.isFromMe
        // 密聊不支持文件卡片渲染
        bubbleViewProps.isFileCard = vm.isFileCard
        bubbleViewProps.contentConfig = vm.content.contentConfig
        bubbleViewProps.bubbleConfig = vm.bubbleConfig
        bubbleViewProps.avatarLayout = vm.avatarLayout
        bubbleViewProps.bubbleTapHandler = nil
        bubbleViewProps.oneOfSubComponentsDisplay = { [weak vm] types in
            return vm?.oneOfSubComponentsDisplay(types) ?? false
        }
        bubbleViewProps.contentComponent = vm.contentComponent
        // 子组件
        bubbleViewProps.subComponents = vm.getSubComponents()
        bubbleViewProps.threadReplyBubbleOptimize = vm.threadReplyBubbleOptimize
        bubbleView.props = bubbleViewProps
    }

    private func updateHighlight(vm: CryptoChatMessageCellViewModel) -> Bool {
        highlightComponentProps.highlightBgColor = vm.highlightBgColor
        highlightComponentProps.showHighlightBlur = vm.showHighlightBlur
        highlightComponentProps.highlightBlurColor = vm.highlightBlurColor
        highlightComponent.props = highlightComponentProps
        return true
    }

    private func updateFooter(vm: CryptoChatMessageCellViewModel) -> Bool {
        footerComponentProps.showTime = vm.hasTime
        if vm.hasTime {
            footerComponentProps.bottomFormatTime = vm.formatTime
        }
        footerComponentProps.bottomTimeTextColor = vm.chatComponentTheme.bottomTimeTextColor
        footerComponentProps.isEphemeral = false
        footerComponentProps.avatarLayout = vm.avatarLayout
        footerComponentProps.inSelectMode = false
        footerComponentProps.oneOfSubComponentsDisplay = { [weak vm] types in
            return vm?.oneOfSubComponentsDisplay(types) ?? false
        }
        // 子组件
        footerComponentProps.subComponents = vm.getSubComponents()
        footerComponent.props = footerComponentProps
        return true
    }

}

extension NewCryptoChatMessageCellComponentBinder: ChatMessageCellComponentLifeCycle {
    func update(view: UIView) {
        bubbleView.updateColor()
    }
}
