//
//  MessageLinkDetailHandler.swift
//  LarkChat
//
//  Created by Ping on 2023/5/25.
//

import RustPB
import RxSwift
import LarkCore
import Swinject
import LarkModel
import EENavigator
import LarkOpenChat
import LarkNavigator
import LarkMessageBase
import LarkMessageCore
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface

final class MessageLinkDetailHandler: UserTypedRouterHandler {
    static let logger = Logger.log(MessageLinkDetailHandler.self, category: "MessageLinkDetailHandler")

    let disposeBag: DisposeBag = DisposeBag()

    func handle(_ body: MessageLinkDetailBody, req: EENavigator.Request, res: Response) throws {
        let rxChat: Observable<Chat>
        switch body.chatInfo {
        case .chat(let chat):
            // 加 `.observeOn(MainScheduler.asyncInstance)` 模拟异步
            rxChat = Observable<Chat>.just(chat).observeOn(MainScheduler.asyncInstance)
        case .chatID(let chatID):
            rxChat = fetch(chatID: chatID)
        }

        let resolver = self.userResolver
        let pushHandlerRegister = MergeForwardPushHandlersRegister(channelId: body.chatID, userResolver: resolver)
        let onError = { (error) in
            res.end(error: error)
            MessageLinkDetailHandler.logger.error("get chatId failure", additionalData: ["chatId": body.chatID], error: error)
        }
        rxChat
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chat) in
                let dragManager = DragInteractionManager()
                dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
                let chatWrapper: ChatPushWrapper
                let context = MergeForwardContext(
                    resolver: resolver,
                    dragManager: dragManager,
                    defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: resolver)
                )
                let dependency = MergeForwardMessageDetailVMDependency(userResolver: resolver)
                do {
                    chatWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
                } catch {
                    onError(error)
                    return
                }
                let viewModel = MergeForwardMessageDetailContentViewModel(
                    dependency: dependency,
                    context: context,
                    chatWrapper: chatWrapper,
                    pushHandler: pushHandlerRegister,
                    inputMessages: body.messages,
                    messageDatasourceService: body.dataSourceService,
                    registery: MessageLinkDetailSubFactoryRegistery(context: context, defaultFactory: MessageEngineUnknownContentFactory(context: context))
                )
                let controller = MergeForwardMessageDetailViewControlller(
                    contentTitle: body.title,
                    viewModel: viewModel,
                    chatInfo: body.mergeForwardChatInfo,
                    messageActionModule: MessageLinkDetailActionModule.self
                )
                context.pageAPI = controller
                context.dataSourceAPI = viewModel
                context.chatPageAPI = controller
                context.pageContainer.register(ChatScreenProtectService.self) { [weak context] in
                    return ChatScreenProtectService(chat: chatWrapper.chat,
                                                    getTargetVC: { [weak context] in return context?.pageAPI },
                                                    userResolver: resolver)
                }
                res.end(resource: controller)
            }, onError: onError).disposed(by: self.disposeBag)
        res.wait()
    }

    private func fetch(chatID: String) -> Observable<Chat> {
        guard let chatAPI = try? self.userResolver.resolve(assert: ChatAPI.self),
              let chatterAPI = try? self.userResolver.resolve(assert: ChatterAPI.self) else {
            return .just(MessageLinkDetailHandler.getMockChat(id: chatID))
        }
        return chatAPI.fetchChats(by: [chatID], forceRemote: false)
            .flatMap({ (chats) -> Observable<Chat> in
                if let chat = chats[chatID] {
                    if chat.type == .p2P, chat.chatter == nil {
                        return chatterAPI.getChatter(id: chat.chatterId).map({ (chatter) -> Chat in
                            chat.chatter = chatter
                            return chat
                        })
                    }
                    return .just(chat)
                } else {
                    // 无权限时拉不到Chat，Mock一个
                    return .just(MessageLinkDetailHandler.getMockChat(id: chatID))
                }
            }).observeOn(MainScheduler.instance)
    }

    private static func getMockChat(id: String) -> Chat {
        let chat = Chat.transform(pb: RustPB.Basic_V1_Chat())
        chat.isSuper = false
        chat.isCrypto = false
        chat.id = id
        chat.oncallId = ""
        return chat
    }
}
