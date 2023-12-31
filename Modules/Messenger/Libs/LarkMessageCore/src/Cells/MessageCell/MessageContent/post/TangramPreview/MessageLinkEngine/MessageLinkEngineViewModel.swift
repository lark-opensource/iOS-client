//
//  MessageLinkEngineViewModel.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/5/11.
//

import RustPB
import LarkModel
import EENavigator
import LarkSetting
import LarkMessageBase
import LarkSDKInterface
import TangramComponent
import LKCommonsTracker
import DynamicURLComponent
import LarkMessengerInterface
import ThreadSafeDataStructure

public struct MessageLinkEngineConfig {
    // 头像大小
    static var avatarSize: CGFloat {
        return 24.auto()
    }
    static var bubbleLeft: CGFloat {
        return 16 * 2 + avatarSize + 6 // 16: 头像左边距，6: 头像右边距
    }
    // 卡片最大宽度
    static let contentMaxWidth: CGFloat = 400
    // 卡片最大高度
    static let contentMaxHeight: CGFloat = 320
    // 卡片上最多展示5条
    static let limitMessageInCard: Int = 5
    // normal样式下padding
    static let normalBubblePadding: CGFloat = 4

    static func getContentPadding(message: Message, defaultContentPadding: CGFloat) -> CGFloat {
        // 普通模式下内容顶格展示（contentPadding给的0），但是话题回复模式下，需要加一个padding
        if message.showInThreadModeStyle {
            return ChatCellUIStaticVariable.bubblePadding
        }
        // 被降级为文本时，使用默认padding
        if shouldUseDefaultFactory(message: message) {
            return defaultContentPadding
        }
        if message.type == .mergeForward {
            return ChatCellUIStaticVariable.bubblePadding
        }
        return defaultContentPadding
    }

    // 消息链接化场景下，消息是否应该降级
    public static func shouldUseDefaultFactory(message: Message) -> Bool {
        // 话题转发卡片
        if let content = message.content as? MergeForwardContent, content.isFromPrivateTopic {
            return true
        }
        return false
    }
}

class MessageLinkEngineViewModel<C: PageContext>: URLEngineAbility {
    private let componentProps: MessageLinkWrapperComponentProps
    private let component: MessageLinkWrapperComponent<EmptyContext>
    var tcComponent: Component {
        return component
    }
    private(set) var engineVM: SafeAtomic<MessageListEngineViewModel<MessageEngineMetaModel, MessageEngineCellMetaModelDependency, C>?> = nil + .readWriteLock
    private let messageLink: MessageLink
    private let previewID: String
    private let targetVCProvider: (() -> UIViewController?)?
    private let getChat: () -> Chat
    private let context: C
    // 埋点公参
    private let trackParams: [AnyHashable: Any]
    // 卡片可见时埋点是否已上报过
    private var isCardViewTracked = false

    init(
        context: C,
        messageLink: MessageLink,
        previewID: String,
        containerChat: @escaping () -> Chat,
        vmFactory: MessageLinkEngineCellViewModelFactory<C>,
        getContentMaxWidth: @escaping () -> CGFloat, // iPad等场景需要动态获取
        targetVCProvider: (() -> UIViewController?)?,
        trackParams: [AnyHashable: Any]
    ) {
        self.trackParams = trackParams
        self.context = context
        self.messageLink = messageLink
        self.previewID = previewID
        self.targetVCProvider = targetVCProvider
        let props = MessageLinkWrapperComponentProps()
        self.componentProps = props
        self.component = MessageLinkWrapperComponent(props: props)
        /// 消息链接化场景应该传原始的Chat
        self.getChat = {
            // 如果就是当前会话，那直接使用当前会话Chat：为了防止MessageLink中Chat数据不全
            if messageLink.chat.id == containerChat().id {
                return containerChat()
            }
            return messageLink.chat
        }
        let metaModels = messageLink.entityIDs.prefix(MessageLinkEngineConfig.limitMessageInCard).compactMap { id in
            if let entity = messageLink.entities[id] {
                return MessageEngineMetaModel(message: entity.message, getChat: self.getChat)
            }
            return nil
        }
        var config = MessageListEngineConfig()
        config.componentSpacing = 12
        // UX要求上间距是16，但是由于消息Cell自带了4的上间距，所以此处为12
        config.marginTop = 12
        config.marginBottom = 16
        let engineVM = MessageListEngineViewModel(
            metaModels: metaModels,
            metaModelDependency: { renderer in
                let metaModelDependency = MessageEngineCellMetaModelDependency(
                    renderer: renderer,
                    contentPadding: 0,
                    contentPreferMaxWidth: { message in
                        let contentMaxWidth = min(getContentMaxWidth(), MessageLinkEngineConfig.contentMaxWidth) - MessageLinkEngineConfig.bubbleLeft
                        return ChatCellUIStaticVariable.getContentPreferMaxWidth(
                            message: message,
                            maxCellWidth: contentMaxWidth,
                            maxContentWidth: contentMaxWidth,
                            bubblePadding: MessageLinkEngineConfig.getContentPadding(message: message, defaultContentPadding: 0) * 2
                        )
                    },
                    maxCellWidth: { _ in return min(getContentMaxWidth(), MessageLinkEngineConfig.contentMaxWidth) },
                    updateRootComponent: { [weak self] in
                        self?.engineVM.value?.updateRootComponent()
                    },
                    avatarConfig: MessageEngineAvatarConfig(showAvatar: true, avatarSize: MessageLinkEngineConfig.avatarSize),
                    headerConfig: MessageEngineHeaderConfig(showHeader: true)
                )
                return metaModelDependency
            },
            vmFactory: vmFactory,
            config: config
        )
        self.engineVM.value = engineVM
        self.componentProps.renderer.value = engineVM.renderer
        self.componentProps.showMoreTapped.value = { [weak self] in self?.showMore() }
        self.component.setup(props: self.componentProps)
    }

    /// Cell将要出现的时候
    func willDisplay() {
        engineVM.value?.willDisplay()
        trackCardView()
    }

    /// Cell不再显示的时候
    func didEndDisplay() {
        engineVM.value?.didEndDisplay()
    }

    /// Size发生变化
    func onResize() {
        engineVM.value?.onResize()
    }

    // 跳转详情页
    func showMore() {
        guard let vc = targetVCProvider?() else { return }
        let messages = messageLink.entityIDs.prefix(MessageLinkEngineConfig.limitMessageInCard).compactMap({ messageLink.entities[$0]?.message })
        var chatName = messageLink.chatInfo.name
        if !messageLink.chatInfo.isAuth {
            if messageLink.chatInfo.isP2PBot {
                chatName = BundleI18n.LarkMessageCore.Lark_IM_MessageLinkFromBot_Text
            } else {
                chatName = (messageLink.chatInfo.type == .p2P ?
                            BundleI18n.LarkMessageCore.Lark_IM_MessageLinkFromPrivateChat_Text :
                                BundleI18n.LarkMessageCore.Lark_IM_MessageLinkFromGroupChat_Text)
            }
        }
        let mergeForwardChatInfo = MergeForwardChatInfo(
            isAuth: messageLink.chatInfo.isAuth,
            chatName: chatName,
            chatID: "\(messageLink.metaInfo.fromChatID)",
            position: (messageLink.metaInfo.hasJumpPos && messageLink.metaInfo.jumpPos >= 0) ? messageLink.metaInfo.jumpPos : nil
        )
        tcLogger.info("[URLPreview] MessageLink showMore: isAuth = \(messageLink.chatInfo.isAuth) -> chatID = \(messageLink.metaInfo.fromChatID) -> position = \(messageLink.metaInfo.jumpPos)")
        let body = MessageLinkDetailBody(
            chatInfo: .chatID("\(messageLink.metaInfo.fromChatID)"),
            messages: messages,
            dataSourceService: MessageLinkDataSourceHandler(
                messageAPI: try? context.resolver.resolve(assert: MessageAPI.self),
                messageLink: messageLink,
                previewID: previewID
            ),
            title: BundleI18n.LarkMessageCore.Lark_IM_MessageLink_ChatHistory_Title,
            mergeForwardChatInfo: mergeForwardChatInfo
        )
        context.navigator.push(body: body, from: vc)
        trackCardClick()
    }

    private func trackCardClick() {
        var params: [AnyHashable: Any] = [
            "occasion": "chat",
            "root_msg_cnt": messageLink.entityIDs.count,
            "root_chat_id": "\(messageLink.metaInfo.fromChatID)",
            "root_msg_id": messageLink.entityIDs.map({ "\($0)" }),
            "click": "details",
            "target": "none" // 数仓做埋点链路的时候需要用到
        ]
        params += trackParams
        Tracker.post(TeaEvent("im_msg_link_card_click", params: params))
    }

    private func trackCardView() {
        guard !isCardViewTracked else { return }
        isCardViewTracked = true
        var params: [AnyHashable: Any] = [
            "occasion": "chat",
            "root_msg_cnt": messageLink.entityIDs.count,
            "root_chat_id": "\(messageLink.metaInfo.fromChatID)",
            "root_msg_id": messageLink.entityIDs.map({ "\($0)" })
        ]
        params += trackParams
        Tracker.post(TeaEvent("im_msg_link_card_view", params: params))
    }
}
