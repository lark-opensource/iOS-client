//
//  PreviewChatHandler.swift
//  LarkChat
//
//  Created by liuwanlin on 2019/6/11.
//

import Foundation
import EENavigator
import LarkModel
import Swinject
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import UniverseDesignToast
import LKCommonsLogging
import LarkNavigator

final class PreviewChatHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    private static let logger = Logger.log(PreviewChatHandler.self, category: "LarkChat.PreviewChatHandler")
    private let disposeBag = DisposeBag()

    func handle(_ body: PreviewChatBody, req: EENavigator.Request, res: Response) throws {
        GroupCardTracker.startEnterGroupCard()
        GroupCardTracker.initViewStart()

        guard let from = req.context.from() else {
            assertionFailure()
            return
        }
        let viewForShowingHUD = from.fromViewController?.viewIfLoaded

        let chat = body.content.chat
        if let chat = chat {
            let resolver = self.resolver
            let chatAPI = try resolver.resolve(assert: ChatAPI.self)
            let model = GroupCardJoinModel(content: body.content, messageId: body.messageId, chatAPI: chatAPI)
            let router = try resolver.resolve(assert: GroupCardJoinRouter.self)
            let viewModel = GroupCardJoinViewModel(
                groupShareContent: model,
                chatterAPI: try resolver.resolve(assert: ChatterAPI.self),
                chatAPI: chatAPI,
                chat: chat,
                currentChatterId: userResolver.userID,
                router: router,
                joinStatus: body.joinStatus,
                joinStatusCallback: body.joinStatusCallback
            )
            let controller = GroupCardJoinViewController(userResolver: userResolver, viewModel: viewModel)
            router.rootVCBlock = { [weak controller] in
                controller
            }
            GroupCardTracker.initViewCostEnd()
            res.end(resource: controller)
        } else {
            assertionFailure("no chat")
            let error = NSError(domain: "no chat for \(body.content.shareChatID)", code: -1, userInfo: nil)
            res.end(error: error)
        }
    }
}

// 根据chat进入群卡片
final class PreviewChatCardWithChatHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    private static let logger = Logger.log(PreviewChatHandler.self, category: "LarkChat")
    private let disposeBag = DisposeBag()

    func handle(_ body: PreviewChatCardWithChatBody, req: EENavigator.Request, res: Response) throws {
        GroupCardTracker.startEnterGroupCard()
        GroupCardTracker.initViewStart()

        let chat = body.chat
        let resolver = self.resolver
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)
        let model = GroupCardJoinModel(content: ShareGroupChatContentMeta(chat: chat),
                                       isFromSearch: body.isFromSearch,
                                       chatAPI: chatAPI)
        let router = try resolver.resolve(assert: GroupCardJoinRouter.self)
        let viewModel = GroupCardJoinViewModel(
            groupShareContent: model,
            chatterAPI: try resolver.resolve(assert: ChatterAPI.self),
            chatAPI: chatAPI,
            chat: chat,
            currentChatterId: userResolver.userID,
            router: router,
            joinStatusCallback: nil
        )
        let controller = GroupCardJoinViewController(userResolver: userResolver, viewModel: viewModel)
        router.rootVCBlock = { [weak controller] in
            controller
        }
        GroupCardTracker.initViewCostEnd()
        res.end(resource: controller)
    }
}
