//
//  MergeForwardDetailHandler.swift
//  Lark
//
//  Created by liuwanlin on 2018/8/15.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkContainer
import Swinject
import LarkCore
import LarkMessageCore
import EENavigator
import LarkNavigator
import LarkModel
import RxSwift
import LKCommonsLogging
import LarkMessageBase
import LarkFeatureGating
import LarkSDKInterface
import LarkMessengerInterface
import AsyncComponent
import LarkSceneManager
import RustPB

final class MergeForwardDetailHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    static let logger = Logger.log(MergeForwardDetailHandler.self, category: "Module.MergeForwardDetailHandler")
    let disposeBag: DisposeBag = DisposeBag()

    func handle(_ body: MergeForwardDetailBody, req: EENavigator.Request, res: Response) throws {
        guard let content = body.message.content as? MergeForwardContent else {
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
        let pushHandlerRegister = MergeForwardPushHandlersRegister(channelId: body.chatId, userResolver: resolver)
        let onError = { (error) in
            res.end(error: error)
            MergeForwardDetailHandler.logger.error("get chatId failure", additionalData: ["chatId": body.chatId], error: error)
        }
        rxChat
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chat) in
                let chatWrapper: ChatPushWrapper
                do {
                    chatWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
                } catch {
                    onError(error)
                    return
                }
                let dragManager = DragInteractionManager()
                dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
                let context = MergeForwardContext(
                    resolver: resolver,
                    dragManager: dragManager,
                    defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: resolver)
                )
                context.downloadFileScene = body.downloadFileScene
                let dependency = MergeForwardMessageDetailVMDependency(userResolver: resolver)
                let messages = fixMergeForwardContent(body.message)
                let viewModel = MergeForwardMessageDetailContentViewModel(
                    dependency: dependency,
                    context: context,
                    chatWrapper: chatWrapper,
                    pushHandler: pushHandlerRegister,
                    inputMessages: messages)
                let controller = MergeForwardMessageDetailViewControlller(contentTitle: content.title, viewModel: viewModel)
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
