//
//  ChatInfoHandler.swift
//  Pods
//
//  Created by liuwanlin on 2019/2/14.
//

import UIKit
import Foundation
import EENavigator
import LarkModel
import Swinject
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkSendMessage
import LarkContainer
import RxSwift
import LarkMessageBase
import LKCommonsLogging
import LarkMessengerInterface
import LarkOpenChat
import LarkOpenIM
import LarkCore
import AppContainer
import LarkNavigator

/// for thread setting
final class ThreadInfoHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: ThreadInfoBody, req: EENavigator.Request, res: Response) throws {
        let tracker = AppreciableTracker(userResolver: userResolver)
        tracker.start(chat: body.chat, pageName: "ChatInfoViewController")
        tracker.initViewStart()
        let vc = try createVC(
            chat: body.chat,
            hasModifyAccess: body.hasModifyAccess,
            hideFeedSetting: body.hideFeedSetting,
            resolver: userResolver,
            tracker: tracker,
            action: body.action,
            chatSettingType: .ignore
        )
        res.end(resource: vc)
    }
}

final class ChatInfoHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: ChatInfoBody, req: EENavigator.Request, res: Response) throws {
        if body.chat.isInMeetingTemporary {
            /// 临时入会用户不属于群成员，无法进入群设置
            res.end(resource: EmptyResource())
            return
        }
        let tracker = AppreciableTracker(userResolver: userResolver)
        tracker.start(chat: body.chat, pageName: "ChatInfoViewController")
        tracker.initViewStart()
        let vc = try createVC(
            chat: body.chat,
            panoEnabled: false,
            resolver: userResolver,
            tracker: tracker,
            action: body.action,
            chatSettingType: body.type
        )
        res.end(resource: vc)
    }
}

final class ModifyGroupNameHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: ModifyGroupNameBody, req: EENavigator.Request, res: Response) throws {
        guard !body.chatId.isEmpty,
              let chat = try userResolver.resolve(assert: ChatAPI.self).getLocalChat(by: body.chatId) else {
                res.end(error: RouterError.invalidParameters("chatId"))
                return
        }
        let accountService = try userResolver.resolve(assert: PassportUserService.self)
        let controller = GroupNameViewController(
            chat: chat,
            currentChatterId: accountService.user.userID,
            chatAPI: try userResolver.resolve(assert: ChatAPI.self),
            navi: userResolver.navigator
        )
        controller.title = body.title ?? BundleI18n.LarkChatSetting.Lark_Legacy_GroupName

        res.end(resource: controller)
    }
}

private func createVC(
    chat: Chat,
    hasModifyAccess: Bool = true,
    hideFeedSetting: Bool = false,
    panoEnabled: Bool = false,
    resolver: UserResolver,
    tracker: AppreciableTracker,
    action: EnterChatSettingAction,
    chatSettingType: P2PChatSettingBody.ChatSettingType
) throws -> UIViewController {
    let container = Container(parent: BootLoader.container)
    let context = ChatSettingContext(parent: container, store: Store(), userStorage: resolver.storage, compatibleMode: resolver.compatibleMode)
    let viewModel = ChatInfoViewModel(
        resolver: resolver,
        pushCenter: try resolver.userPushCenter,
        chatPushWrapper: try resolver.resolve(assert: ChatPushWrapper.self, argument: chat),
        chat: chat,
        hasModifyAccess: hasModifyAccess,
        hideFeedSetting: hideFeedSetting,
        chatSettingType: chatSettingType,
        chatSettingContext: context,
        action: action
    )
    // 进行所有Module的加载
    ChatSettingModule.onLoad(context: context)
    // Module注册提供的服务
    ChatSettingModule.registGlobalServices(container: container)

    return ChatInfoViewController(viewModel: viewModel, appreciableTracker: tracker)

}

final class ModifyNicknameHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: ModifyNicknameBody, req: EENavigator.Request, res: Response) throws {

        guard !body.chatId.isEmpty else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }

        let controller = NicknameViewController(
            userResolver: userResolver,
            chat: body.chat,
            oldName: body.oldNickname,
            chatId: body.chatId,
            chatterAPI: try userResolver.resolve(assert: ChatterAPI.self),
            saveNickName: body.saveNickName
        )
        controller.title = body.title ?? BundleI18n.LarkChatSetting.Lark_Legacy_PersoncardGroupalias

        res.end(resource: controller)
    }
}

final class QuitGroupHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: QuitGroupBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI: ChatAPI = try userResolver.resolve(assert: ChatAPI.self)

        guard !body.chatId.isEmpty, let chat = chatAPI.getLocalChat(by: body.chatId) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }

        let pushCenter = try userResolver.userPushCenter
        let accountService = try userResolver.resolve(assert: PassportUserService.self)

        let controller = QuitGroupViewController(
            chat: chat,
            currentChatterId: accountService.user.userID,
            currentTenantId: accountService.userTenant.tenantID,
            chatAPI: chatAPI,
            tips: body.tips,
            isThread: body.isThread,
            navi: userResolver.navigator) { (channlId, status) in
                pushCenter.post(PushLocalLeaveGroupChannnel(channelId: channlId, status: status))
                if status == .success, chat.chatMode == .threadV2, !chat.isPublic {
                    pushCenter.post(PushRemoveMeForRecommendList(channelId: channlId))
                }
        }

        res.end(resource: controller)
    }
}

final class ChatAnnouncementControllerHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    private static let logger = Logger.log(ChatAnnouncementControllerHandler.self, category: "LarkChatSetting.ChatAnnouncementControllerHandler")

    func handle(_ body: ChatAnnouncementBody, req: EENavigator.Request, res: Response) throws {
        let chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        if let chat = chatAPI.getLocalChat(by: body.chatId),
           /// 使用新版本群公告
           chat.announcement.useOpendoc {
            guard !chat.announcement.docURL.isEmpty else {
                Self.logger.error("chat: \(chat.id) announcement docURL is empty")
                res.end(error: RouterError.invalidParameters("docURL"))
                return
            }

            var parameters = [
                "chat_id": chat.id,
                "from": "group_tab_notice",
                "open_type": "announce"
            ]
            if chat.chatMode == .threadV2 {
                parameters["sub_type"] = "community"
            }
            if let url = URL(string: chat.announcement.docURL)?.append(parameters: parameters) {
                // 发送群公告已读请求
                chatAPI.readChatAnnouncement(by: chat.id, updateTime: chat.announcement.updateTime).subscribe().dispose()
                res.redirect(url)
                return
            }
            res.end(error: RouterError.invalidParameters("docURL"))
            return
        }
        /// 使用老版本群公告
        res.redirect(body: ChatOldAnnouncementBody(chatId: body.chatId))
    }
}

final class ChatOldAnnouncementControllerHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    private static let logger = Logger.log(ChatOldAnnouncementControllerHandler.self, category: "LarkChatSetting.ChatAnnouncementControllerHandler")

    func handle(_ body: ChatOldAnnouncementBody, req: EENavigator.Request, res: Response) throws {
        if let controller = GroupCardAnnouncementController(
            userResolver: userResolver,
            chatId: body.chatId,
            chatAPI: try userResolver.resolve(assert: ChatAPI.self),
            chatterAPI: try userResolver.resolve(assert: ChatterAPI.self),
            sendMessageAPI: try userResolver.resolve(assert: SendMessageAPI.self),
            sendThreadAPI: try userResolver.resolve(assert: SendThreadAPI.self),
            navi: userResolver.navigator
        ) {
            res.end(resource: controller)
        } else {
            res.end(error: RouterError.empty)
        }
    }
}

final class ChatTranslateSettingHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    func handle(_ body: ChatTranslateSettingBody, req: EENavigator.Request, res: Response) throws {
        let viewModel = ChatTranslateSettingViewModel(resolver: self.userResolver, chat: body.chat, pushChat: body.pushChat)
        let controller = ChatTranslateSettingViewController(viewModel: viewModel)
        res.end(resource: controller)
    }
}

// 群背景
final class ChatThemeHandler: UserTypedRouterHandler {
    func handle(_ body: ChatThemeBody, req: EENavigator.Request, res: Response) throws {
        let viewModel = ChatThemeViewModel(userResolver: userResolver,
                                           chatId: body.chatId,
                                           title: body.title,
                                           scene: body.scene)
        let controller = ChatThemeViewController(viewModel: viewModel)
        res.end(resource: controller)
    }
}

// 群背景预览
final class ChatThemePreviewHandler: UserTypedRouterHandler {
    func handle(_ body: ChatThemePreviewBody, req: EENavigator.Request, res: Response) throws {
        let viewModel = try ChatThemePreviewViewModel(userResolver: userResolver,
                                                  title: body.title,
                                                  chatId: body.chatId,
                                                  theme: body.theme,
                                                  scope: body.scope,
                                                  hasPersonalTheme: body.hasPersonalTheme,
                                                  isResetPernalTheme: body.isResetPernalTheme,
                                                  isResetCurrentTheme: body.isResetCurrentTheme,
                                                  confirmHandler: body.confirmHandler,
                                                  cancelHandler: body.cancelHandler)
        let controller = ChatThemePreviewViewController(style: body.style,
                                                        viewModel: viewModel)
        res.end(resource: controller)
    }
}
