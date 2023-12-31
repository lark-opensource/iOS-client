//
//  MyAIChatModeViewControllerComponentGenerator.swift
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
import LarkModel
import RxSwift
import RxCocoa
import LarkSDKInterface
import TangramService
import RustPB
import LarkContainer
import LarkBadge

class MyAIChatModeViewControllerComponentGenerator: ChatViewControllerComponentGenerator {
    override var chatDataProviderType: ChatDataProviderProtocol.Type { return MyAIChatModeDataProvider.self }
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
        let chatMessagesViewModel = ChatMessagesViewModel(userResolver: userResolver,
                                                          messagesDatasource: try self.messagesDataSource(pushWrapper: pushWrapper,
                                                                                                      context: context),
                                                          chatDataContext: MyAIChatModeDataContext(myAIPageService: myAIPageService),
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

    override func messagesDataSource(pushWrapper: ChatPushWrapper, context: ChatContext) throws -> ChatMessagesDatasource {
        let messageBurnService = try? self.resolver.resolve(type: MessageBurnService.self)
        let myAIPageService = try context.userResolver.resolve(type: MyAIPageService.self)
        let messageCellProcessor = MyAIChatModeMessageDatasourceProcessor(myAIPageService: myAIPageService,
                                                                          isNewRecalledEnable: context.isNewRecallEnable)
        let datasource = ChatMessagesDatasource(
            chat: {
                return pushWrapper.chat.value
            },
            vmFactory: NormalChatCellViewModelFactory(
                context: context,
                registery: ChatMessageSubFactoryRegistery(
                    context: context, defaultFactory: UnknownContentFactory(context: context)
                ),
                cellLifeCycleObseverRegister: NormalChatCellLifeCycleObseverRegister(userResolver: userResolver)
            ),
            isMessageBurned: { message in
                return messageBurnService?.isBurned(message: message) ?? false
            },
            messageCellProcessor: messageCellProcessor
        )
        messageCellProcessor.dependency = datasource
        return datasource
    }

    override func chatTableView(userResolver: UserResolver, pushWrapper: ChatPushWrapper, keepOffset: @escaping () -> Bool, fromWhere: ChatFromWhere) -> ChatTableView {
        return AIChatTableView(userResolver: userResolver,
                               isOnlyReceiveScroll: false,
                               keepOffset: keepOffset,
                               chatFromWhere: fromWhere)
    }

    override func canCreateChatMenu(chat: Chat) -> Bool {
        return false
    }

    override func widgetsView(moduleContext: ChatModuleContext, pushWrapper: ChatPushWrapper, targetVC: UIViewController) -> ChatWidgetsContainerView? {
        return nil
    }

    override func statusDisplayView(chat: BehaviorRelay<Chat>, chatNameObservable: Observable<String>, urlPushObservable: Observable<URLPreviewScenePush>) -> StatusDisplayView? {
        return nil
    }

    override func scheduleSendTipView(chatId: Int64,
                                      threadId: Int64?,
                                      rootId: Int64?,
                                      scene: GetScheduleMessagesScene,
                                      messageObservable: Observable<[Message]>,
                                      sendEnable: Bool,
                                      disableObservable: Observable<Bool>,
                                      pushObservable: Observable<PushScheduleMessage>) -> ChatScheduleSendTipView? {
        return nil
    }

    override func unreadMessagesTipViewModel(chatContext: ChatContext,
                                             chat: Chat,
                                             pushCenter: PushNotificationCenter,
                                             readPosition: Int32,
                                             lastMessagePosition: Int32) -> LarkMessageCore.BaseUnreadMessagesTipViewModel? {
        guard let threadAPI = try? userResolver.resolve(type: ThreadAPI.self),
              let myAIPageService = try? chatContext.userResolver.resolve(type: MyAIPageService.self) else { return nil }
        return MyAIChatModeDownUnReadMessagesTipViewModel(userResolver: userResolver,
                                                          threadId: myAIPageService.chatModeThreadMessage?.id ?? "",
                                                          myAIChatModeId: myAIPageService.chatModeConfig.aiChatModeId,
                                                          readPosition: readPosition,
                                                          lastMessagePosition: lastMessagePosition,
                                                          threadAPI: threadAPI,
                                                          pushCenter: pushCenter)
    }

    override func timezoneView(chatNameObservable: Observable<String>) -> TimeZoneView? {
        return nil
    }

    override func chatFooter(pushWrapper: ChatPushWrapper, context: ChatFooterContext) -> ChatFooterView? {
        return nil
    }

    override func chatBanner(pushWrapper: ChatPushWrapper, context: ChatBannerContext) -> ChatBannerView? {
        return nil
    }

    override func pinSummaryView(pinSummaryContext: ChatPinSummaryContext, pushWrapper: ChatPushWrapper, chatVC: UIViewController) -> ChatPinSummaryContainerView? {
        return nil
    }

    override func needDisplayTabs(chat: Chat) -> Bool {
        return false
    }

    override func createThreadPanel(hasChatMenuItem: Bool, pushWrapper: ChatPushWrapper) -> ChatCreateThreadPanel? {
        return nil
    }

    override func createChatFrozenMask() -> UIView? {
        return nil
    }

    override func readService(pushWrapper: ChatPushWrapper,
                              context: ChatContext,
                              audioToTextEnable: Bool,
                              fromWhere: ChatFromWhere) throws -> ChatMessageReadService {
        let chat = pushWrapper.chat.value
        let forceNotEnabled = chat.isTeamVisitorMode
        let threadAPI = try self.resolver.resolve(assert: ThreadAPI.self)
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chat.id
        channel.type = .chat
        return try self.resolver.resolve( // user:checked
            assert: ChatMessageReadService.self,
            arguments: PutReadScene.chat(chat),
            forceNotEnabled,
            audioToTextEnable,
            chat.isRemind,
            chat.isInBox,
            ["chat": chat,
             "chatFromWhere": fromWhere.rawValue] as [String: Any], { () -> Int32 in
                return pushWrapper.chat.value.readPosition
            }, { [weak context] (info: PutReadInfo) in
                let messageIDs = info.ids.map { (chatIDAndMessageID) -> String in
                    return chatIDAndMessageID.messageID
                }

                guard let myAIPageService = try? context?.userResolver.resolve(type: MyAIPageService.self),
                      let myAIChatModeThreadId = myAIPageService.chatModeThreadMessage?.id else { return }
                threadAPI.updateThreadMessagesMeRead(
                    channel: channel,
                    threadId: myAIChatModeThreadId,
                    messageIds: messageIDs,
                    maxPositionInThread: info.maxPosition,
                    maxPositionBadgeCountInThread: max(0, info.maxBadgeCount)
                )
            }
        )
    }

    override func navigationBar(moduleContext: ChatModuleContext, pushWrapper: ChatPushWrapper, blurEnabled: Bool, targetVC: UIViewController, chatPath: Path) -> ChatNavigationBar {
        // 如果分会场升级为场景FG关闭，则依然使用Chat样式的导航栏
        guard (try? moduleContext.userResolver.resolve(type: MyAIPageService.self))?.larkMyAIScenariosThread ?? false else {
            return super.navigationBar(moduleContext: moduleContext, pushWrapper: pushWrapper, blurEnabled: blurEnabled, targetVC: targetVC, chatPath: chatPath)
        }
        ChatModeNavigationBarModule.onLoad(context: moduleContext.navigaionContext)
        ChatModeNavigationBarModule.registGlobalServices(container: moduleContext.container)
        let navigationBarModule: BaseChatNavigationBarModule = ChatModeNavigationBarModule(context: moduleContext.navigaionContext)
        let viewModel = ChatNavigationBarViewModel(
            chatWrapper: pushWrapper,
            module: navigationBarModule
        )
        let navBar = ChatNavigationBarImp(viewModel: viewModel, blurEnabled: blurEnabled, darkStyle: false)
        return navBar
    }

    override func messageSender(chat: BehaviorRelay<Chat>, context: ChatContext, chatKeyPointTracker: ChatKeyPointTracker, fromWhere: ChatFromWhere) -> MessageSender {
        let sender = MessageSender(userResolver: self.userResolver, actionPosition: .chat, chatInfo: chatKeyPointTracker.chatInfo, chat: chat)
        sender.addModifier(modifier: DisplayModeModifier(chat: chat))
        sender.addModifier(modifier: ChatFromModifier(fromWhere: fromWhere))
        if let myAIPageService: MyAIPageService = try? context.userResolver.resolve(type: MyAIPageService.self) {
            sender.addModifier(modifier: ChatModeConfigModifier(chatModeConfig: myAIPageService.chatModeConfig))
        }
        return sender
    }
}
