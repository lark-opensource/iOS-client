//
//  ChatSettingAssembly.swift
//  LarkChatSetting
//
//  Created by kongkaikai on 2019/12/13.
//

import Foundation
import LarkContainer
import LarkModel
import LarkUIKit
import LarkRustClient
import LarkCore
import Swinject
import EENavigator
import LarkFeatureGating
import LarkSDKInterface
import LarkAppConfig
import LarkMessengerInterface
import LarkAccountInterface
import LarkShareToken
import LarkOpenChat
import LarkBadge
import LarkAssembler
import LarkSetting

enum ChatSetting {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.chatsetting") // Global
        return v
    }
    //是否开启兼容
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public final class ChatSettingAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(ChatSetting.userScope)
        let userGraph = container.inObjectScope(ChatSetting.userGraph)

        user.register(WithdrawAddGroupMemberService.self) { (r) -> WithdrawAddGroupMemberService in
            let withdrawExpirationByHour = try r.resolve(assert: UserAppConfig.self).appConfig?.chatConfig.withdrawChatterExpirationByHour
            return WithdrawAddGroupMemberServiceImpl(
                userResolver: r,
                chatAPI: try r.resolve(assert: ChatAPI.self),
                chatterAPI: try r.resolve(assert: ChatterAPI.self),
                withdrawExpirationByHour: withdrawExpirationByHour)
        }

        userGraph.register(ShareGroupQRCodeController.self) { (r, chat: Chat, isFormQRcodeEntrance: Bool, isFromShare: Bool) -> ShareGroupQRCodeController in
            let chatAPI = try r.resolve(assert: ChatAPI.self)
            let accountService = try r.resolve(assert: PassportUserService.self)
            let tenantName = accountService.userTenant.tenantName
            let inAppShareService = try r.resolve(assert: InAppShareService.self)
            let viewModel = GroupQRCodeViewModel(
                resolver: r,
                chat: chat,
                chatAPI: chatAPI,
                tenantName: tenantName,
                currentChatterID: accountService.user.userID,
                inAppShareService: inAppShareService,
                isFormQRcodeEntrance: isFormQRcodeEntrance,
                isFromShare: isFromShare
            )
            return ShareGroupQRCodeViewController(resolver: r, viewModel: viewModel, isPopOver: true)
        }

        userGraph.register(ShareGroupLinkController.self) { (r, chat: Chat, isFromChatShare: Bool) -> ShareGroupLinkController in
            let chatAPI = try r.resolve(assert: ChatAPI.self)
            let accountService = try r.resolve(assert: PassportUserService.self)
            let tenantName = accountService.userTenant.tenantName
            let inAppShareService = try r.resolve(assert: InAppShareService.self)
            let viewModel = ShareGroupLinkViewModel(
                resolver: r,
                chat: chat,
                chatAPI: chatAPI,
                tenantName: tenantName,
                currentChatterID: accountService.user.userID,
                isFromChatShare: isFromChatShare,
                inAppShareService: inAppShareService
            )
            return ShareGroupLinkViewController(resolver: r, viewModel: viewModel)
        }

        userGraph.register(ChatSettingCalendarDependency.self) { r -> ChatSettingCalendarDependency in
            return try r.resolve(assert: ChatSettingDependency.self)
        }

        userGraph.register(ChatSettingTodoDependency.self) { r -> ChatSettingTodoDependency in
            return try r.resolve(assert: ChatSettingDependency.self)
        }

        userGraph.register(MeetingMinutesBadgeService.self) { (r, chatId: String, rootPath: Path) -> MeetingMinutesBadgeService in
            return MeetingMinutesBadgeServiceImp(
                chatId: chatId,
                calendarInterface: try r.resolve(assert: ChatSettingCalendarDependency.self),
                rootPath: rootPath
            )
        }
    }

    public func registRouter(container: Container) {
        let resolver = container

        Navigator.shared.registerRoute.type(CustomizeGroupAvatarBody.self)
            .factory(cache: true, CustomizeGroupAvatarHandler.init(resolver:))

        Navigator.shared.registerRoute.type(TeamCustomizeAvatarBody.self)
            .factory(TeamCustomizeAvatarHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ChatInfoBody.self)
            .factory(ChatInfoHandler.init(resolver:))

        Navigator.shared.registerRoute.type(ThreadInfoBody.self)
            .factory(ThreadInfoHandler.init(resolver:))

        // 群成员
        Navigator.shared.registerRoute.type(GroupChatterDetailBody.self)
            .factory(GroupChatterDetailHandler.init(resolver:))

        // 转让群主
        Navigator.shared.registerRoute.type(TransferGroupOwnerBody.self)
            .factory(TransferGroupOwnerHandler.init(resolver:))

        // 群发言权限设置(群禁言)
        Navigator.shared.registerRoute.type(BanningSettingBody.self)
            .factory(cache: true, BanningSettingHandler.init(resolver:))

        // 群邮件发送权限设置
        Navigator.shared.registerRoute.type(MailPermissionSettingBody.self)
            .factory(MailPermissionSettingHandler.init(resolver:))

        // 进群申请审批页面
        Navigator.shared.registerRoute.type(ApprovalBody.self)
            .factory(ApprovalHandler.init(resolver:))

        // 群可被搜索开关设置页面
        Navigator.shared.registerRoute.type(GroupSearchAbleConfigBody.self)
            .factory(GroupSearchAbleConfigHandler.init(resolver:))

        // 群分享历史页面
        Navigator.shared.registerRoute.type(GroupShareHistoryBody.self)
            .factory(GroupShareHistoryHandler.init(resolver:))

        // 填写进群申请页面
        Navigator.shared.registerRoute.type(JoinGroupApplyBody.self)
            .factory(cache: true, JoinGroupApplyHandler.init(resolver:))

        Navigator.shared.registerRoute.type(GroupChatterSelectBody.self)
            .factory(GroupChatterSelectHandler.init(resolver:))

        // 群公告
        Navigator.shared.registerRoute.type(ChatAnnouncementBody.self)
            .factory(ChatAnnouncementControllerHandler.init(resolver:))

        // 老版本群公告
        Navigator.shared.registerRoute.type(ChatOldAnnouncementBody.self)
            .factory(ChatOldAnnouncementControllerHandler.init(resolver:))

        // 群信息:群昵称
        Navigator.shared.registerRoute.type(ModifyNicknameBody.self)
            .factory(ModifyNicknameHandler.init(resolver:))

        // 退群
        Navigator.shared.registerRoute.type(QuitGroupBody.self)
            .factory(QuitGroupHandler.init(resolver:))

        // 群聊信息/群设置
        // 群信息
        Navigator.shared.registerRoute.type(GroupInfoBody.self)
            .factory(GroupInfoHandler.init(resolver:))

        // 群信息:群名称
        Navigator.shared.registerRoute.type(ModifyGroupNameBody.self)
            .factory(ModifyGroupNameHandler.init(resolver:))

        // 群信息:群描述
        Navigator.shared.registerRoute.type(ModifyGroupDescriptionBody.self)
            .factory(ModifyGroupDescriptionHandler.init(resolver:))

        // 群信息:群二维码
        Navigator.shared.registerRoute.type(GroupQRCodeBody.self)
            .factory(GroupQRCodeHandler.init(resolver:))

        // 群设置
        Navigator.shared.registerRoute.type(GroupSettingBody.self)
            .factory(GroupSettingHandler.init(resolver:))

        // 添加群成员
        Navigator.shared.registerRoute.type(AddGroupMemberBody.self)
            .factory(cache: true, AddGroupMemberHandler.init(resolver:))

        Navigator.shared.registerRoute.type(AutomaticallyAddGroupBody.self)
            .factory(AutomaticallyAddGroupHandler.init(resolver:))

        Navigator.shared.registerRoute.type(JoinAndLeaveBody.self)
            .factory(JoinAndLeaveHandler.init(resolver:))

        // 群管理员
        Navigator.shared.registerRoute.type(GroupAdminBody.self)
            .factory(GroupAdminHandler.init(resolver:))

        // 添加群管理员
        Navigator.shared.registerRoute.type(GroupAddAdminBody.self)
            .factory(cache: true, GroupAddAdminHandler.init(resolver:))

        // 申请群成员上限
        Navigator.shared.registerRoute.type(GroupApplyForLimitBody.self)
            .factory(cache: true, GroupApplyForLimitHandler.init(resolver:))

        // 翻译设置
        Navigator.shared.registerRoute.type(ChatTranslateSettingBody.self)
            .factory(cache: true, ChatTranslateSettingHandler.init(resolver:))

        // 聊天背景
        Navigator.shared.registerRoute.type(ChatThemeBody.self)
            .factory(cache: true, ChatThemeHandler.init(resolver:))

        // 聊天背景预览
        Navigator.shared.registerRoute.type(ChatThemePreviewBody.self)
            .factory(cache: true, ChatThemePreviewHandler.init(resolver:))
    }

    @_silgen_name("Lark.OpenChat.Messenger.ChatSetting")
    static public func openChatRegister() {
        ChatSettingModule.register(ChatSettingMicroAppSubModule.self)
        ChatSettingModule.register(ChatSettingMessengerSearchSubModule.self)
    }
}
