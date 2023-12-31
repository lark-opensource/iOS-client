//
//  MyAIMainChatViewControllerComponentGenerator.swift
//  LarkChat
//
//  Created by ByteDance on 2023/10/17.
//

import Foundation
import LarkCore
import LarkMessageCore
import LarkMessengerInterface
import LarkMessageBase
import LarkOpenChat
import LarkContainer
import RxCocoa
import LarkModel

class MyAIMainChatViewControllerComponentGenerator: ChatViewControllerComponentGenerator {
    override var chatDataProviderType: ChatDataProviderProtocol.Type { return MyAIMainChatDataProvider.self }

    override func chatMessageViewModel(pushWrapper: ChatPushWrapper,
                                       pushHandlerRegister: ChatPushHandlersRegister,
                                       context: ChatContext,
                                       chatKeyPointTracker: ChatKeyPointTracker,
                                       fromWhere: ChatFromWhere) throws -> ChatMessagesViewModel {
        let chatMessagesVMDependency = try self.chatMessagesVMDependency(pushWrapper: pushWrapper,
                                                                         context: context,
                                                                         chatKeyPointTracker: chatKeyPointTracker,
                                                                         fromWhere: fromWhere)
        let myAIPageService = try context.userResolver.resolve(type: MyAIPageService.self)
        let pushCenter = try resolver.userPushCenter
        let chatDataProvider = chatDataProviderType.init(chatContext: context, chatWrapper: pushWrapper, pushCenter: pushCenter)
        let chatMessagesViewModel = OldMyAIMainChatMessagesViewModel(userResolver: userResolver,
                                                                  messagesDatasource: try self.messagesDataSource(pushWrapper: pushWrapper,
                                                                                                                  context: context),
                                                                  chatDataContext: NormalChatDataContext(chatWrapper: pushWrapper),
                                                                  chatDataProvider: chatDataProvider,
                                                                  dependency: chatMessagesVMDependency,
                                                                  context: context,
                                                                  chatWrapper: pushWrapper,
                                                                  pushHandlerRegister: pushHandlerRegister,
                                                                  inSelectMode: inSelectMode,
                                                                  supportUserUniversalLastPostionSetting: supportUserUniversalLastPostionSetting,
                                                                  gcunit: needCellVMGC
                                                                  ? GCUnit(limitWeight: 256, limitGCRoundSecondTime: 10, limitGCMSCost: 100)
                                                                  : nil
        )
        return chatMessagesViewModel
    }

    override func chatTableView(userResolver: UserResolver,
                       pushWrapper: ChatPushWrapper,
                       keepOffset: @escaping () -> Bool,
                       fromWhere: ChatFromWhere) -> ChatTableView {
        return AIMainChatTableView(userResolver: userResolver,
                                   isOnlyReceiveScroll: pushWrapper.chat.value.isTeamVisitorMode,
                                   keepOffset: keepOffset,
                                   chatFromWhere: fromWhere)
    }

    override func messagesDataSource(pushWrapper: ChatPushWrapper, context: ChatContext) throws -> ChatMessagesDatasource {
        let messageBurnService = try? self.resolver.resolve(type: MessageBurnService.self)

        let messageCellProcessor = MyAIMainChatMessageDatasourceProcessor(userResolver: context.userResolver,
                                                                          isNewRecalledEnable: context.isNewRecallEnable)

        let datasource = MyAIMainChatMessagesDatasource(chat: {
                                                            return pushWrapper.chat.value
                                                        },
                                                        vmFactory: NormalChatCellViewModelFactory(
                                                            context: context,
                                                            registery: ChatMessageSubFactoryRegistery(
                                                                context: context, defaultFactory: UnknownContentFactory(context: context)),
                                                            cellLifeCycleObseverRegister: NormalChatCellLifeCycleObseverRegister(userResolver: userResolver)
                                                        ), isMessageBurned: { message in
                                                            return messageBurnService?.isBurned(message: message) ?? false
                                                        }, messageCellProcessor: messageCellProcessor)
        messageCellProcessor.dependency = datasource
        return datasource
    }

    override func chatFooter(pushWrapper: ChatPushWrapper, context: ChatFooterContext) -> ChatFooterView? {
        return nil
    }

    override func messageSender(chat: BehaviorRelay<Chat>, context: ChatContext, chatKeyPointTracker: ChatKeyPointTracker, fromWhere: ChatFromWhere) -> MessageSender {
        let sender = MessageSender(userResolver: self.userResolver, actionPosition: .chat, chatInfo: chatKeyPointTracker.chatInfo, chat: chat)
        sender.addModifier(modifier: DisplayModeModifier(chat: chat))
        sender.addModifier(modifier: ChatFromModifier(fromWhere: fromWhere))
        if let myAIPageService: MyAIPageService = try? context.userResolver.resolve(type: MyAIPageService.self) {
            sender.addModifier(modifier: MainChatConfigModifier(mainChatConfig: myAIPageService.myAIMainChatConfig))
        }
        return sender
    }
}
