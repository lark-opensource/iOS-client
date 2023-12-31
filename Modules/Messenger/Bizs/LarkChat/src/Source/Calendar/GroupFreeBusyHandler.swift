//
//  GroupFreeBusyHandler.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/12/13.
//

import Foundation
import LarkModel
import EENavigator
import Swinject
import LKCommonsLogging
import LarkCore
import LarkTag
import LarkBizTag
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkNavigator

final class GroupFreeBusyHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    func handle(_ body: GroupFreeBusyBody, req: EENavigator.Request, res: Response) throws {
        guard !body.chatId.isEmpty,
            let chat = try resolver.resolve(assert: ChatAPI.self).getLocalChat(by: body.chatId) else {
                res.end(error: RouterError.invalidParameters("chatId"))
                return
        }

        let viewModel = GroupFreeBusyChatterControllerVM(
            userResolver: userResolver,
            chat: chat,
            selectedChatterIds: body.selectedChatterIds,
            chatAPI: try resolver.resolve(assert: ChatAPI.self),
            chatterAPI: try resolver.resolve(assert: ChatterAPI.self),
            serverNTPTimeService: try resolver.resolve(assert: ServerNTPTimeService.self),
            appendTagProvider: chat.isOncall ? { chatter -> [LarkBizTag.TagType]? in
                guard let type = chatter.chatExtra?.oncallRole else { return nil }
                switch type {
                case .user: return [.oncallUser]
                case .oncall: return [.oncallAgent]
                case .userHelper, .oncallHelper, .unknown: return nil
                @unknown default:
                    assert(false, "new value")
                    return nil
                }
                } : nil,
            isOwnerSelectable: true,
            selectCallBack: body.selectCallBack)

        let controller = GroupFreeBusyController(viewModel: viewModel)

        res.end(resource: controller)
    }
}
