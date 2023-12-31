//
//  ChatMessageTabModule.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/6/16.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkMessengerInterface
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkModel
import LarkContainer
import UniverseDesignColor
import UniverseDesignIcon
import LarkAIInfra

// ChatTabContext.Store KV 存储 Key
enum ChatMessageTabModuleStoreKey: String {
    case chatMessageTabDependency
    case chatViewModel
    case chatMessagesViewModel
    case isMessagePicker
    case ignoreDocAuth
}

final public class ChatMessageTabModule: ChatTabSubModule {
    public override var type: ChatTabType {
        return .message
    }

    override public var shouldDisplayContentTopMargin: Bool {
        return false
    }

    override public var supportLRUCache: Bool {
        return false
    }

    override public class func canInitialize(context: ChatTabContext) -> Bool {
        return true
    }

    override public func getContent(metaModel: ChatTabMetaModel, chat: Chat) -> ChatTabContentViewDelegate? {
        guard metaModel.type == type else { return nil }
        let userResolver = self.userResolver
        guard userResolver.valid,
              let pushCenter = try? self.context.userResolver.userPushCenter
        else { return nil }

        guard let messageTabDependency: ChatMessageTabDependencyProtocol = self.context.store.getValue(for: ChatMessageTabModuleStoreKey.chatMessageTabDependency.rawValue),
              let chatViewModel: ChatViewModel = self.context.store.getValue(for: ChatMessageTabModuleStoreKey.chatViewModel.rawValue),
              let chatMessagesViewModel: ChatMessagesViewModel = self.context.store.getValue(for: ChatMessageTabModuleStoreKey.chatMessagesViewModel.rawValue),
              let chatMessageBaseDelegate = try? self.context.resolver.resolve(assert: ChatMessageBaseDelegate.self),
              let chatOpenService = try? self.context.resolver.resolve(assert: ChatOpenService.self)
        else {
            assertionFailure("can not get required information from message tab store")
            return nil
        }

        let messageVC: ChatMessagesViewController
        if messageTabDependency.isMessagePicker {
            let pickerVC = ChatMessagePickerController(
                chatId: chat.id,
                moduleContext: messageTabDependency.moduleContext,
                componentGenerator: messageTabDependency.componentGenerator,
                router: messageTabDependency.router,
                dependency: messageTabDependency.dependency,
                chatViewModel: chatViewModel,
                chatMessageViewModel: chatMessagesViewModel,
                chatMessageBaseDelegate: chatMessageBaseDelegate,
                chatOpenService: chatOpenService,
                positionStrategy: messageTabDependency.positionStrategy,
                keyboardStartState: messageTabDependency.keyboardStartState,
                chatKeyPointTracker: messageTabDependency.chatKeyPointTracker,
                dragManager: messageTabDependency.dragManager,
                getChatMessagesResultObservable: messageTabDependency.getChatMessagesResultObservable,
                getBufferPushMessages: messageTabDependency.getBufferPushMessages,
                pushCenter: pushCenter,
                chatFromWhere: messageTabDependency.chatFromWhere
            )
            pickerVC.cancel = messageTabDependency.messagePickerCancelHandler
            pickerVC.finish = messageTabDependency.messagePickerFinishHandler
            pickerVC.ignoreDocAuth = messageTabDependency.ignoreDocAuth
            messageVC = pickerVC
        } else {
            let chatVCType: ChatMessagesViewController.Type
            if chat.isP2PAi {
                if let myAIPageService = try? messageTabDependency.moduleContext.userResolver.resolve(type: MyAIPageService.self), myAIPageService.chatMode {
                    chatVCType = MyAIChatModeViewController.self
                } else {
                    chatVCType = MyAIMainViewController.self
                }
            } else {
                chatVCType = NormalChatViewController.self
                let imMyAIChatModeOpenServiceImpl = IMMyAIChatModeOpenServiceImpl(resolver: userResolver, chat: chat)
                self.context.container.register(IMMyAIChatModeOpenService.self) { (_) -> IMMyAIChatModeOpenService in
                    return imMyAIChatModeOpenServiceImpl
                }
            }
            messageVC = chatVCType.init(
                chatId: chat.id,
                moduleContext: messageTabDependency.moduleContext,
                componentGenerator: messageTabDependency.componentGenerator,
                router: messageTabDependency.router,
                dependency: messageTabDependency.dependency,
                chatViewModel: chatViewModel,
                chatMessageViewModel: chatMessagesViewModel,
                chatMessageBaseDelegate: chatMessageBaseDelegate,
                chatOpenService: chatOpenService,
                positionStrategy: messageTabDependency.positionStrategy,
                keyboardStartState: messageTabDependency.keyboardStartState,
                chatKeyPointTracker: messageTabDependency.chatKeyPointTracker,
                dragManager: messageTabDependency.dragManager,
                getChatMessagesResultObservable: messageTabDependency.getChatMessagesResultObservable,
                getBufferPushMessages: messageTabDependency.getBufferPushMessages,
                pushCenter: pushCenter,
                chatFromWhere: messageTabDependency.chatFromWhere
            )
        }
        messageTabDependency.moduleContext.chatContext.pageAPI = messageVC
        messageTabDependency.moduleContext.chatContext.chatPageAPI = messageVC
        chatMessagesViewModel.gcunit?.delegate = messageVC
        self.context.container.register(ChatMessageTabPageAPI.self) { [weak messageVC] (_) -> ChatMessageTabPageAPI in
            return messageVC ?? DefaultChatMessageTabPageAPI()
        }
        if let inlineServiceDelegate = messageVC as? IMMyAIInlineServiceDelegate {
            let scenarioType: InlineAIConfig.ScenarioType = chat.type == .p2P ? .p2pChat : .groupChat
            if let myAIInlineService = try? userResolver.resolve(type: MyAIService.self).imInlineService(delegate: inlineServiceDelegate, scenarioType: scenarioType) {
                self.context.container.register(IMMyAIInlineService.self) { _ in
                    return myAIInlineService
                }
            }
        }
        self.context.container.register(ChatMessagesOpenService.self) { [weak messageVC] _ -> ChatMessagesOpenService in
            return messageVC ?? DefaultChatMessagesOpenService()
        }

        messageVC.targetVC = chatOpenService.chatVC()
        messageVC.updateSceneTargetContentIdentifier()
        messageVC.controllerService = messageTabDependency.controllerService
        return messageVC
    }

    deinit {
        print("deinit ChatMessageTabModule")
    }

    override public func getTabManageItem(_ metaModel: ChatTabMetaModel) -> ChatTabManageItem? {
        guard let content = metaModel.content else { return nil }
        return ChatTabManageItem(
            name: self.getTabTitle(metaModel),
            tabId: content.id,
            canBeDeleted: false,
            canEdit: false,
            canBeSorted: false,
            imageResource: self.getImageResource(metaModel)
        )
    }

    override public func getTabTitle(_ metaModel: ChatTabMetaModel) -> String {
        return BundleI18n.LarkChat.Lark_Groups_TabChat
    }

    override public func getImageResource(_ metaModel: ChatTabMetaModel) -> ChatTabImageResource {
        return .image(UDIcon.getIconByKey(.chatFilled, iconColor: UIColor.ud.colorfulBlue, size: CGSize(width: 20, height: 20)))
    }

    override public func getClickParams(_ metaModel: ChatTabMetaModel) -> [AnyHashable: Any]? {
        return ["tab_type": "msg_tab", "is_oapi_tab": "false"]
    }
}
