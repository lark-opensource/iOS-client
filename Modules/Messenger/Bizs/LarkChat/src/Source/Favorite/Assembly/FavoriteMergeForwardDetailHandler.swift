//
//  FavoriteMergeForwardDetailHandler.swift
//  LarkChat
//
//  Created by zc09v on 2019/7/16.
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
import RustPB
import LarkNavigator

final class FavoriteMergeForwardDetailHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    static let logger = Logger.log(FavoriteMergeForwardDetailHandler.self, category: "Module.FavoriteMergeForwardDetailHandler")
    let disposeBag: DisposeBag = DisposeBag()

    func handle(_ body: FavoriteMergeForwardDetailBody, req: EENavigator.Request, res: Response) throws {
        guard let content = body.message.content as? MergeForwardContent else {
            res.end(error: nil)
            return
        }
        let userResolver = self.userResolver
        let pushHandlerRegister = MergeForwardPushHandlersRegister(channelId: body.chatId, userResolver: userResolver)
        let favoriteAPI = try userResolver.resolve(assert: FavoritesAPI.self)
        func onError(_ error: Error) {
            res.end(error: error)
            FavoriteMergeForwardDetailHandler.logger.error("get chatId failure", additionalData: ["chatId": body.chatId], error: error)
        }
        try self.fetch(chatId: body.chatId)
            .subscribe(onNext: { (chat) in
              do {
                let chatWrapper = try userResolver.resolve(assert: ChatPushWrapper.self, argument: chat)
                let dragManager = DragInteractionManager()
                dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
                let context = MergeForwardContext(
                    resolver: userResolver,
                    dragManager: dragManager,
                    defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: userResolver)
                )
                let dependency = MergeForwardMessageDetailVMDependency(userResolver: userResolver)
                let viewModel = MergeForwardMessageDetailContentViewModel(
                    dependency: dependency,
                    context: context,
                    chatWrapper: chatWrapper,
                    pushHandler: pushHandlerRegister,
                    inputMessages: fixMergeForwardContent(body.message))
                let itemsGenerator = FavoriteMergeForwardDetailBarItemsGenerator(
                    userResolver: userResolver,
                    message: body.message,
                    favoriteId: body.favoriteId,
                    favoriteAPI: favoriteAPI)
                let controller = MergeForwardMessageDetailViewControlller(
                    contentTitle: content.title,
                    viewModel: viewModel,
                    itemsGenerator: itemsGenerator)
                context.pageAPI = controller
                context.dataSourceAPI = viewModel
                context.chatPageAPI = controller
                context.downloadFileScene = .favorite
                itemsGenerator.targetVC = controller
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
