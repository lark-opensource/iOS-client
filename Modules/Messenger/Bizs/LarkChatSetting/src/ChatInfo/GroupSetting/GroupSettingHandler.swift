//
//  GroupSettingHandler.swift
//  LarkChat
//
//  Created by kkk on 2019/3/11.
//

import RxSwift
import Foundation
import LarkModel
import EENavigator
import Swinject
import LarkCore
import LarkUIKit
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LKCommonsLogging
import LarkMessengerInterface
import LarkNavigator

/// 群发言权限设置
final class BanningSettingHandler: UserTypedRouterHandler {
    private let disposeBag = DisposeBag()
    private static let logger = Logger.log(BanningSettingHandler.self, category: "Module.ChatSetting")

    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: BanningSettingBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        guard !body.chatId.isEmpty,
            let chat = chatAPI.getLocalChat(by: body.chatId) else {
                res.end(error: RouterError.invalidParameters("chatId"))
                return
        }
        try self.userResolver.resolve(assert: ChatterAPI.self).getChatter(id: chat.ownerId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chatter in
                guard let self = self, let chatter = chatter else {
                    assertionFailure("chatter is nil")
                    Self.logger.error("get Chatter is nil")
                    return
                }
                let viewModel = BanningSettingViewModel(chat: chat, owner: chatter, chatAPI: chatAPI, userResolver: self.userResolver)
                let controller = BanningSettingController(viewModel: viewModel)
                res.end(resource: controller)
            }, onError: { error in
                res.end(error: error)
            }).disposed(by: self.disposeBag)
        res.wait()
    }
}

/// 群邮件发送权限设置
final class MailPermissionSettingHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: MailPermissionSettingBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        guard !body.chatId.isEmpty,
            let chat = chatAPI.getLocalChat(by: body.chatId)
             else {
                res.end(error: RouterError.invalidParameters("chatId"))
                return
        }

        let viewModel = MailPermissionSettingViewModel(chat: chat, chatAPI: chatAPI, chatWrapper: try userResolver.resolve(assert: ChatPushWrapper.self, argument: chat))
        let controller = MailPermissionSettingViewController(viewModel: viewModel)
        res.end(resource: controller)
    }
}

/// 群设置
final class GroupSettingHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: GroupSettingBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        let accountService = try userResolver.resolve(assert: PassportUserService.self)
        guard !body.chatId.isEmpty, let chat = chatAPI.getLocalChat(by: body.chatId) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }
        NewChatSettingTracker.imGroupManageView(chat: chat,
                                                myUserId: accountService.user.userID,
                                                isOwner: accountService.user.userID == chat.ownerId,
                                                isAdmin: chat.isGroupAdmin)
        let viewModel = GroupSettingViewModel(
            resolver: self.userResolver,
            chatWrapper: try self.userResolver.resolve(assert: ChatPushWrapper.self, argument: chat),
            chatAPI: chatAPI,
            chatterAPI: try self.userResolver.resolve(assert: ChatterAPI.self),
            currentUserId: accountService.user.userID,
            chatService: try self.userResolver.resolve(assert: ChatService.self),
            pushChatAdmin: try self.userResolver.userPushCenter.observable(for: PushChatAdmin.self),
            calendarInterface: try self.userResolver.resolve(assert: ChatSettingCalendarDependency.self),
            scrollToBottom: body.scrollToBottom,
            openSettingCellType: body.openSettingCellType)

        let controller = GroupSettingViewController(viewModel: viewModel)
        res.end(resource: controller)
    }
}

/// 入群审批
final class ApprovalHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: ApprovalBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        guard let chat = chatAPI.getLocalChat(by: body.chatId) else { return }
        let accountService = try userResolver.resolve(assert: PassportUserService.self)
        let isOwner = accountService.user.userID == chat.ownerId
        let isAdmin = chat.isGroupAdmin

        guard !body.chatId.isEmpty, isOwner || isAdmin else {
                res.end(error: RouterError.invalidParameters("chatId"))
                return
        }
        let viewModel = ApproveViewModel(chat: chat, chatAPI: chatAPI, userResolver: self.userResolver)
        let controller = ApproveViewController(viewModel: viewModel)
        res.end(resource: controller)
    }
}

// 群可被搜索开关设置页面
final class GroupSearchAbleConfigHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: GroupSearchAbleConfigBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        guard let chat = chatAPI.getLocalChat(by: body.chatId) else { return }

        guard !body.chatId.isEmpty else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }
        NewChatSettingTracker.chatAllowToBeSearchedTrack(chat: chat)
        let viewModel = GroupSearchAbleConfigViewModel(
            resolver: self.userResolver,
            chatWrapper: try self.userResolver.resolve(assert: ChatPushWrapper.self, argument: chat))
        let controller = GroupSearchAbleConfigViewController(viewModel: viewModel)
        res.end(resource: controller)
    }
}

/// 群分享历史
final class GroupShareHistoryHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: GroupShareHistoryBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        guard let chat = chatAPI.getLocalChat(by: body.chatId) else { return }
        let accountService = try userResolver.resolve(assert: PassportUserService.self)
        let isOwner = accountService.user.userID == chat.ownerId
        let isAdmin = chat.isGroupAdmin

        guard !body.chatId.isEmpty, isOwner || isAdmin else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }

        let viewModel = GroupShareHistoryViewModel(
            chatID: body.chatId,
            chatAPI: chatAPI,
            isThreadGroup: body.isThreadGroup,
            userResolver: self.userResolver)
        let controller = GroupShareHistoryController(viewModel: viewModel)
        controller.title = body.title ?? BundleI18n.LarkChatSetting.Lark_Group_SharingHistory
        res.end(resource: controller)
    }
}

/// for group members join and leave history
/// 群成员进退群历史
final class AutomaticallyAddGroupHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: AutomaticallyAddGroupBody, req: EENavigator.Request, res: Response) throws {
        let controller = AutomaticallyAddGroupController(rules: body.rules)
        res.end(resource: controller)
    }
}

/// for group members join and leave history
/// 群成员进退群历史
final class JoinAndLeaveHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: JoinAndLeaveBody, req: EENavigator.Request, res: Response) throws {
        let viewModel = JoinAndLeaveViewModel(
            chatID: body.chatId,
            chatAPI: try self.userResolver.resolve(assert: ChatAPI.self), userResolver: self.userResolver)
        let controller = JoinAndLeaveController(viewModel: viewModel)
        res.end(resource: controller)
    }
}

final class GroupApplyForLimitHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: GroupApplyForLimitBody, req: EENavigator.Request, res: Response) throws {
        let viewModel = GroupApplyForLimitViewModel(chatID: body.chatId,
                                                    chatAPI: try self.userResolver.resolve(assert: ChatAPI.self),
                                                    chatterAPI: try self.userResolver.resolve(assert: ChatterAPI.self),
                                                    userResolver: self.userResolver)
        let controller = GroupApplyForLimitViewController(viewModel: viewModel)
        res.end(resource: controller)
    }
}
