//
//  MessageForwardContentPreviewHandler.swift
//  LarkChat
//
//  Created by ByteDance on 2022/8/2.
//

import Foundation
import LarkContainer
import Swinject
import LarkCore
import LarkMessageCore
import EENavigator
import LarkModel
import RxSwift
import LKCommonsLogging
import LarkMessageBase
import LarkFeatureGating
import LarkSDKInterface
import LarkMessengerInterface
import AsyncComponent
import LarkNavigator

final class MessageForwardContentPreviewHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    static let logger = Logger.log(MergeForwardDetailHandler.self, category: "Module.MessageForwardContentPreviewBody")
    let disposeBag: DisposeBag = DisposeBag()

    func handle(_ body: MessageForwardContentPreviewBody, req: EENavigator.Request, res: Response) throws {
        if body.messages.isEmpty {
            res.end(error: nil)
            return
        }
        let rxChat: Observable<Chat>
        switch body.chatInfo {
        case .chat(let chat):
            // 加 `.observeOn(MainScheduler.asyncInstance)` 模拟异步
            rxChat = Observable<Chat>.just(chat).observeOn(MainScheduler.asyncInstance)
        case .chatId(let chatId):
            rxChat = try fetch(chatId: chatId)
        }
        let resolver = self.userResolver
        let onError = { (error) in
            res.end(error: error)
            Self.logger.error("get chatId failure", additionalData: ["chatId": body.chatId], error: error)
        }
        let pushHandlerRegister = MergeForwardPushHandlersRegister(channelId: body.chatId, userResolver: resolver)
        rxChat
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chat) in
              do {
                let dragManager = DragInteractionManager()
                dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
                let context = MergeForwardContext(
                    resolver: resolver,
                    dragManager: dragManager,
                    defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: resolver)
                )
                context.downloadFileScene = nil
                context.mergeForwardType = .contentPreview
                let dependency = MergeForwardMessageDetailVMDependency(userResolver: resolver)
                let chatWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
                let messages = body.messages
                let viewModel = MergeForwardMessageDetailContentViewModel(
                    dependency: dependency,
                    context: context,
                    chatWrapper: chatWrapper,
                    isShowBgImageView: true,
                    pushHandler: pushHandlerRegister,
                    inputMessages: messages)
                let controller = MergeForwardMessageDetailViewControlller(contentTitle: body.title, viewModel: viewModel)
                context.pageAPI = controller
                context.dataSourceAPI = viewModel
                context.chatPageAPI = controller
                res.end(resource: controller)
              } catch { onError(error) }
            }, onError: onError).disposed(by: self.disposeBag)
        res.wait()
    }

    private func fetch(chatId: String) throws -> Observable<Chat> {
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        let chatterAPI = try resolver.resolve(assert: ChatterAPI.self)
        return chatAPI.fetchChats(by: [chatId], forceRemote: false)
            .flatMap({ (chats) -> Observable<Chat> in
                if let chat = chats[chatId] {
                    if chat.type == .p2P, chat.chatter == nil {
                        return chatterAPI.getChatter(id: chat.chatterId).map({ (chatter) -> Chat in
                            chat.chatter = chatter
                            return chat
                        })
                    }
                    return .just(chat)
                } else {
                    return .empty()
                }
            }).observeOn(MainScheduler.instance)
    }
}
