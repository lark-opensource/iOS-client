//
//  TeamAssembly.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/5.
//

import Swinject
import Foundation
import EENavigator
import LarkMessengerInterface
import LarkAssembler
import LarkAppLinkSDK
import LarkOpenChat
import LarkOpenFeed
import LarkContainer
import LarkTab
import LarkSDKInterface

public final class TeamAssembly: LarkAssemblyInterface {
    public init() {}

    public func registRouter(container: Container) {
        // 创建团队路由
        Navigator.shared.registerRoute.type(CreateTeamBody.self).factory(cache: true, CreateTeamHandler.init(resolver:))

        // 创建团队群组路由
        Navigator.shared.registerRoute.type(TeamCreateGroupBody.self).factory(cache: true, TeamCreateGroupHandler.init(resolver:))

        // 团队设置路由
        Navigator.shared.registerRoute.type(TeamSettingBody.self).factory(cache: true, TeamSettingHandler.init(resolver:))

        // 团队信息页路由
        Navigator.shared.registerRoute.type(TeamInfoBody.self).factory(cache: true, TeamInfoHandler.init(resolver:))

        // 关联团队群路由
        Navigator.shared.registerRoute.type(TeamBindGroupBody.self).factory(cache: true, TeamBindGroupHandler.init(resolver:))

        // 团队描述路由
        Navigator.shared.registerRoute.type(TeamDescriptionBody.self).factory(cache: true, TeamDescriptionHandler.init(resolver:))

        // 团队名称设置路由
        Navigator.shared.registerRoute.type(TeamNameConfigBody.self).factory(cache: true, TeamNameConfigHandler.init(resolver:))

        // 团队成员页面路由
        Navigator.shared.registerRoute.type(TeamMemberListBody.self).factory(cache: true, TeamMemberListHandler.init(resolver:))

        // 团队添加成员
        Navigator.shared.registerRoute.type(TeamAddMemberBody.self).factory(cache: true, TeamAddMemberHandler.init(resolver:))

        // 设置团队公开群
        Navigator.shared.registerRoute.type(TeamSetOpenGroupBody.self).factory(cache: true, TeamSetOpenGroupHandler.init(resolver:))

        // 团队动态
        Navigator.shared.registerRoute.type(TeamEventBody.self).factory(cache: true, TeamEventHandler.init(resolver:))

        // 快捷添加团队
        Navigator.shared.registerRoute.type(EasilyJoinTeamBody.self).factory(cache: true, EasilyJoinTeamHandler.init(resolver:))

        // 团队群组设置在团队里的隐私设置
        Navigator.shared.registerRoute.type(TeamGroupPrivacyBody.self).factory(cache: true, TeamGroupPrivacyHandler.init(resolver:))
    }

    public func registLarkAppLink(container: Container) {
        LarkAppLinkSDK.registerHandler(path: "/client/team/set_open_chat") { applink in
            Self.setOpenGroup(applink: applink, container: container)
        }

        LarkAppLinkSDK.registerHandler(path: "/client/team/feed") { applink in
            Self.switchToFeedTab(applink: applink, container: container)
        }
    }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(TeamUserScope.userScope)
        let userGraph = container.inObjectScope(TeamUserScope.userGraph)

        user.register(TeamActionService.self) { (r) -> TeamActionService in
            let teamAPI = try r.resolve(assert: TeamAPI.self)
            return TeamActionServiceImpl(teamAPI: teamAPI, resolver: r)
        }
    }

    // TODO: UserResolver 依赖于Applink的改造传递UserRsolver信息
    private static func setOpenGroup(applink: LarkAppLinkSDK.AppLink, container: Container) {
        guard let from = applink.context?.from() else { return }
        guard let url = try? URL.createURL3986(string: applink.url.absoluteString) else {
            return
        }
        let params = url.queryParameters
        guard let teamId = params["teamId"], let chatId = params["chatId"] else {
            return
        }
        let body = TeamSetOpenGroupBody(teamId: Int64(teamId) ?? 0, chatId: Int64(chatId) ?? 0)
        Navigator.shared.push(body: body, from: from)
    }

    private static func switchToFeedTab(applink: LarkAppLinkSDK.AppLink, container: Container) {
        guard let from = applink.context?.from() else { return }
        guard let url = try? URL.createURL3986(string: applink.url.absoluteString) else {
            TeamEventViewModel.logger.error("teamEvent/teamfeed/ createURLError")
            return
        }
        let params = url.queryParameters
        guard let teamId = params["teamId"] else {
            TeamEventViewModel.logger.error("teamEvent/teamfeed/ analyzeTeamIDError")
            return
        }
        TeamEventViewModel.logger.info("teamEvent/teamfeed/ teamID: \(teamId)")
        TeamTracker.trackChatMian(teamID: teamId)
        let feedListPageSwitchService = try? container.resolve(type: FeedListPageSwitchService.self)
        feedListPageSwitchService?.switchToFeedTeamList(teamId: teamId)
        Navigator.shared.switchTab(Tab.feed.url, from: from)
    }

    @_silgen_name("Lark.OpenChat.Messenger.Team")
    static public func assembleChatSetting() {
        ChatSettingModule.register(ChatSettingTeamSubModule.self)
    }
}

import LarkSetting
/// 用于FG控制UserResolver的迁移, 控制Resolver类型.
/// 使用UserResolver后可能抛错，需要控制对应的兼容问题
public enum TeamUserScope {
    public static var userScopeCompatibleMode: Bool { !Feature.userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
