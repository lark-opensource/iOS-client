//
//  NewChatMessageCellComponentBinder.swift
//  LarkChat
//
//  Created by Ping on 2023/2/17.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import LarkMessageCore

final class NewChatMessageCellComponentBinder: ComponentBinder<ChatContext> {
    private let context: ChatContext?

    private let props: NewChatMessageCellProps<ChatContext>
    private let style = ASComponentStyle()
    private var _component: NewChatMessageCellComponent<ChatContext>
    override var component: ComponentWithContext<ChatContext> {
        return _component
    }

    private lazy var avatarContainerProps = AvatarContainerComponentProps()
    private lazy var avatarContainer = AvatarContainerComponent<ChatContext>(props: avatarContainerProps, style: ASComponentStyle(), context: context)

    private lazy var topComponent = TopComponent<ChatContext>(style: ASComponentStyle(), context: context)

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
        guard let vm = vm as? NormalChatMessageCellViewModel else {
            assertionFailure()
            return
        }
        var subComponents: [ChatMessageCellSubType: ComponentWithContext<ChatContext>] = [:]
        if updateAvatar(vm: vm) {
            subComponents[.avatar] = avatarContainer
        }
        if vm.showTop {
            subComponents[.top] = topComponent
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
        props.inSelectMode = vm.inSelectMode
        props.isSingle = vm.config.isSingle
        props.isFold = vm.message.isFoldRootMessage
        props.isEphemeral = vm.message.isEphemeral
        props.cellBackgroundColor = vm.cellComponentBgColor
        props.avatarLayout = vm.avatarLayout
        props.maxCellWidth = vm.context.maxCellWidth
        _component.props = props
    }

    private func updateAvatar(vm: NormalChatMessageCellViewModel) -> Bool {
        guard vm.showAvatar else { return false }
        avatarContainerProps.avatarTapped = { [weak vm] in
            vm?.onAvatarTapped()
        }
        avatarContainerProps.fromChatter = vm.fromChatter
        avatarContainerProps.isScretChat = false
        avatarContainerProps.avatarLayout = vm.avatarLayout
        avatarContainer.props = avatarContainerProps
        return true
    }

    private func updateHeader(vm: NormalChatMessageCellViewModel) -> Bool {
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

        headerComponentProps.subComponents = vm.allSubComponents
        headerComponent.props = headerComponentProps
        return true
    }

    private func updateContent(vm: NormalChatMessageCellViewModel) -> Bool {
        updateBubble(vm: vm)

        let isFold = vm.message.isFoldRootMessage
        contentProps.flagIconMargin = vm.flagIconMargin
        contentProps.hasMessageStatus = vm.hasMessageStatus
        contentProps.showCheckBox = vm.showCheckBox
        contentProps.checked = vm.checked
        contentProps.selectedEnable = (vm.content.contentConfig?.selectedEnable ?? false)
        contentProps.isFold = isFold
        contentProps.avatarLayout = vm.avatarLayout
        contentProps.bubbleView = bubbleView.getBubbleView()
        contentProps.subComponents = vm.allSubComponents
        contentProps.oneOfSubComponentsDisplay = { [weak vm] types in
            return vm?.oneOfSubComponentsDisplay(types) ?? false
        }
        content.props = contentProps
        return true
    }

    private func updateHighlight(vm: NormalChatMessageCellViewModel) -> Bool {
        highlightComponentProps.highlightBgColor = vm.highlightBgColor
        highlightComponentProps.showHighlightBlur = vm.showHighlightBlur
        highlightComponentProps.highlightBlurColor = vm.highlightBlurColor
        highlightComponent.props = highlightComponentProps
        return true
    }

    private func updateBubble(vm: NormalChatMessageCellViewModel) {
        bubbleViewProps.contentPreferMaxWidth = vm.contentPreferMaxWidth
        bubbleViewProps.contentPadding = vm.metaModelDependency.contentPadding
        bubbleViewProps.isFromMe = vm.isFromMe
        bubbleViewProps.isFileCard = vm.isFileCard
        bubbleViewProps.contentConfig = vm.content.contentConfig
        bubbleViewProps.bubbleConfig = vm.bubbleConfig
        bubbleViewProps.displayInThreadMode = vm.metaModel.message.displayInThreadMode
        bubbleViewProps.avatarLayout = vm.avatarLayout
        bubbleViewProps.bubbleTapHandler = { [weak vm] in
            vm?.toReplyInThread()
        }
        bubbleViewProps.oneOfSubComponentsDisplay = { [weak vm] types in
            return vm?.oneOfSubComponentsDisplay(types) ?? false
        }
        bubbleViewProps.contentComponent = vm.contentComponent
        // 子组件
        bubbleViewProps.subComponents = vm.allSubComponents
        bubbleViewProps.threadReplyBubbleOptimize = vm.threadReplyBubbleOptimize
        bubbleView.props = bubbleViewProps
    }

    private func updateFooter(vm: NormalChatMessageCellViewModel) -> Bool {
        let showTime = vm.showTime
        footerComponentProps.showTime = showTime
        if showTime {
            footerComponentProps.bottomFormatTime = vm.formatTime
        }
        footerComponentProps.bottomTimeTextColor = vm.chatComponentTheme.bottomTimeTextColor
        footerComponentProps.isEphemeral = vm.message.isEphemeral
        footerComponentProps.avatarLayout = vm.avatarLayout
        footerComponentProps.inSelectMode = vm.inSelectMode
        footerComponentProps.oneOfSubComponentsDisplay = { [weak vm] types in
            return vm?.oneOfSubComponentsDisplay(types) ?? false
        }
        // 子组件
        footerComponentProps.subComponents = vm.allSubComponents
        footerComponent.props = footerComponentProps
        return true
    }
}

extension NewChatMessageCellComponentBinder: ChatMessageCellComponentLifeCycle {
    func update(view: UIView) {
        bubbleView.updateColor()
    }
}
