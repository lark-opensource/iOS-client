//
//  GroupInfoHandler.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/3/17.
//

import Foundation
import EENavigator
import LarkModel
import Swinject
import LarkCore
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkShareToken
import LarkNavigator

final class ModifyGroupDescriptionHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: ModifyGroupDescriptionBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI: ChatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        guard !body.chatId.isEmpty, let chat = chatAPI.getLocalChat(by: body.chatId) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }

        let controller = GroupDescriptionController(
            chat: chat,
            currentChatterId: self.userResolver.userID,
            chatAPI: chatAPI,
            navi: self.userResolver.navigator
        )
        controller.title = body.title ?? BundleI18n.LarkChatSetting.Lark_Legacy_GroupDescription

        res.end(resource: controller)
    }
}

final class GroupQRCodeHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: GroupQRCodeBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI: ChatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        let inAppShareService = try self.userResolver.resolve(assert: InAppShareService.self)
        guard !body.chatId.isEmpty, let chat = chatAPI.getLocalChat(by: body.chatId) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }

        let accountService = try userResolver.resolve(assert: PassportUserService.self)
        let viewModel = GroupQRCodeViewModel(
            resolver: self.userResolver,
            chat: chat,
            chatAPI: chatAPI,
            tenantName: accountService.userTenant.tenantName,
            currentChatterID: accountService.user.userID,
            inAppShareService: inAppShareService,
            isFormQRcodeEntrance: true,
            isFromShare: false
        )

        res.end(resource: GroupQRCodeController(resolver: self.userResolver, viewModel: viewModel, isPopOver: false))
    }
}

final class GroupInfoHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: GroupInfoBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI: ChatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        guard !body.chatId.isEmpty, let chat = chatAPI.getLocalChat(by: body.chatId) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }
        let accountService = try userResolver.resolve(assert: PassportUserService.self)
        let viewModel = GroupInfoViewModel(
            resolver: self.userResolver,
            chatWrapper: try self.userResolver.resolve(assert: ChatPushWrapper.self, argument: chat),
            currentChatterId: accountService.user.userID,
            chatAPI: chatAPI)
        res.end(resource: GroupInfoViewController(viewModel: viewModel))
    }
}
