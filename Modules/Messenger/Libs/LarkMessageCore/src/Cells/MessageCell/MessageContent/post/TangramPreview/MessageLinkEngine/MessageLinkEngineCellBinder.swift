//
//  MessageLinkEngineCellBinder.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/5/11.
//

import EEFlexiable
import AsyncComponent
import LarkMessageBase

final public class MessageLinkEngineCellBinder<C: PageContext>: ComponentBinder<C> {
    private let context: C?

    private let props: NewChatMessageCellProps<C>
    private let style = ASComponentStyle()
    private var _component: NewChatMessageCellComponent<C>
    public override var component: ComponentWithContext<C> {
        return _component
    }

    private lazy var avatarContainerProps = AvatarContainerComponentProps()
    private lazy var avatarContainer = AvatarContainerComponent<C>(props: avatarContainerProps, style: ASComponentStyle(), context: context)

    private lazy var headerComponentProps = HeaderComponentProps<C>()
    private lazy var headerComponent = HeaderComponent<C>(props: headerComponentProps, style: ASComponentStyle(), context: context)

    private let bubbleViewProps: BubbleViewLayoutComponentProps<C>
    private lazy var bubbleView = BubbleViewLayoutComponent<C>(props: bubbleViewProps, context: context)

    private lazy var contentProps = ContentComponentProps<C>(bubbleView: bubbleView.getBubbleView())
    private lazy var content = ContentComponent<C>(props: contentProps, style: ASComponentStyle(), context: context)

    public init(key: String? = nil, context: C? = nil, contentComponent: ComponentWithContext<C>) {
        self.context = context
        self.bubbleViewProps = BubbleViewLayoutComponentProps<C>(contentComponent: contentComponent)
        props = NewChatMessageCellProps()
        _component = NewChatMessageCellComponent(
            props: props,
            style: style,
            context: context
        )
        super.init(key: key, context: context)
        _component.lifeCycle = self
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? MessageEngineCellViewModel<C> else {
            assertionFailure()
            return
        }
        var subComponents: [ChatMessageCellSubType: ComponentWithContext<C>] = [:]
        if updateAvatar(vm: vm) {
            subComponents[.avatar] = avatarContainer
        }
        if updateHeader(vm: vm) {
            subComponents[.header] = headerComponent
        }
        if updateContent(vm: vm) {
            subComponents[.content] = content
        }
        props.subComponents = subComponents
        props.inSelectMode = false
        props.isSingle = false
        props.isFold = false
        props.isEphemeral = vm.message.isEphemeral
        props.cellBackgroundColor = .clear
        props.avatarLayout = .left
        props.maxCellWidth = vm.maxCellWidth
        props.avatarSize = vm.avatarConfig.avatarSize
        props.cellHorizontalPadding = 16
        _component.props = props
    }

    private func updateAvatar(vm: MessageEngineCellViewModel<C>) -> Bool {
        guard vm.avatarConfig.showAvatar else { return false }
        avatarContainerProps.fromChatter = vm.fromChatter
        avatarContainerProps.isScretChat = false
        avatarContainerProps.avatarLayout = .left
        avatarContainerProps.avatarSize = vm.avatarConfig.avatarSize
        avatarContainerProps.avatarTapped = { [weak vm] in
            vm?.onAvatarTapped()
        }
        avatarContainer.props = avatarContainerProps
        return true
    }

    private func updateHeader(vm: MessageEngineCellViewModel<C>) -> Bool {
        guard vm.headerConfig.showHeader else { return false }
        headerComponentProps.fromChatter = vm.fromChatter
        headerComponentProps.nameAndDescColor = vm.chatComponentTheme.nameAndDescColor
        headerComponentProps.chatterStatusDivider = vm.chatComponentTheme.chatterStatusDivider
        headerComponentProps.getDisplayName = { [weak vm] chatter in
            guard let vm = vm else { return "" }
            return vm.context.getDisplayName(chatter: chatter, chat: vm.metaModel.getChat(), scene: .head)
        }
        headerComponentProps.nameFont = UIFont.ud.body1
        headerComponentProps.nameTextColor = UIColor.ud.textTitle
        headerComponentProps.formatTime = vm.formatTime
        headerComponentProps.contentPreferMaxWidth = vm.contentPreferMaxWidth
        headerComponentProps.nameTag = vm.nameTag
        headerComponentProps.shwoFocusStatus = false
        headerComponentProps.subComponents = vm.allSubComponents
        headerComponent.props = headerComponentProps
        return true
    }

    private func updateContent(vm: MessageEngineCellViewModel<C>) -> Bool {
        updateBubble(vm: vm)

        contentProps.flagIconMargin = 0 // 不展示标记
        contentProps.hasMessageStatus = false // 不展示已读未读
        contentProps.showCheckBox = false
        contentProps.checked = false
        contentProps.selectedEnable = false
        contentProps.isFold = false
        contentProps.avatarLayout = .left
        contentProps.bubbleView = bubbleView.getBubbleView()
        contentProps.subComponents = vm.allSubComponents
        contentProps.oneOfSubComponentsDisplay = { [weak vm] types in
            return vm?.oneOfSubComponentsDisplay(types) ?? false
        }
        content.props = contentProps
        return true
    }

    private func updateBubble(vm: MessageEngineCellViewModel<C>) {
        bubbleViewProps.contentPreferMaxWidth = vm.contentPreferMaxWidth
        bubbleViewProps.contentPadding = MessageLinkEngineConfig.getContentPadding(
            message: vm.message,
            defaultContentPadding: vm.metaModelDependency.contentPadding
        )
        bubbleViewProps.isFromMe = vm.isFromMe
        bubbleViewProps.isFileCard = vm.isFileCard
        bubbleViewProps.contentConfig = vm.content.contentConfig
        bubbleViewProps.bubbleConfig = vm.bubbleConfig
        bubbleViewProps.displayInThreadMode = vm.metaModel.message.displayInThreadMode
        bubbleViewProps.avatarLayout = .left
        bubbleViewProps.oneOfSubComponentsDisplay = { [weak vm] types in
            return vm?.oneOfSubComponentsDisplay(types) ?? false
        }
        bubbleViewProps.contentComponent = vm.contentComponent
        // 子组件
        bubbleViewProps.subComponents = vm.allSubComponents
        bubbleView.props = bubbleViewProps

        // 消息链接卡片场景目前只支持reply和reaction两个子组件，后续预期也不会新增，UX要求在此场景下左右无间距，上下间距为4
        // 但在会话内，上下左右间距是一样的，无法单独设置且改动成本较大，因此在Binder里单独对这俩场景特化
        if bubbleViewProps.bubbleConfig.bubbleStyle == .normal {
            let padding = CSSValue(cgfloat: MessageLinkEngineConfig.normalBubblePadding)
            if bubbleViewProps.subComponents[.reply] != nil {
                bubbleViewProps.contentComponent._style.marginTop = padding
            }
            if let reaction = bubbleViewProps.subComponents[.reaction] {
                reaction._style.marginTop = padding
            }
        }
    }
}

extension MessageLinkEngineCellBinder: ChatMessageCellComponentLifeCycle {
    public func update(view: UIView) {
        bubbleView.updateColor()
    }
}
