//
//  FeatureGating.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/11/25.
//

import Foundation
import LarkSetting
import LarkFeatureGating
import LarkContainer
import LKCommonsLogging

public struct Feature {
    // [团队]功能整体开关
    static func isTeamEnable(userID: String) -> Bool {
        getDynamicFgValue(FeatureGatingKey.team.rawValue, userID: userID)
    }

    // 团队成员列表支持搜索
    static func teamSearchEnable(userID: String) -> Bool {
        return getStaticFgValue("lark.feed.team_search", userID: userID)
    }

    // 团队头像适配v-next
    static func avatarFG(userID: String) -> Bool {
        getDynamicFgValue("messenger.chat.groupavatar.v2.client", userID: userID)
    }

    // 团队群组权限
    static func teamChatPrivacy(userID: String) -> Bool {
        return getStaticFgValue("lark.feed.team_chat_privacy", userID: userID)
    }

    // 其他场景(收藏、头像等)中的图片在查看器中是否支持翻译
    static func imageViewerInOtherScenesTranslateEnable(userID: String) -> Bool {
        getStaticFgValue(FeatureGatingKey.imageViewerInOtherScenesTranslateEnable.rawValue, userID: userID)
    }

    // 团队用户态改造
    static var userScopeFG: Bool {
        let key = "ios.container.scope.user.team"
        let v = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(rawValue: key) ?? "") // Global
        TeamMemberViewModel.logger.info("teamlog/feature/fg/static. \(key):\(v)")
        return v
    }
}

public extension Feature {
    static func getStaticFgValue(_ fgKey: String, userID: String) -> Bool {
        guard let service = getService(userID: userID),
              let key = FeatureGatingManager.Key(rawValue: fgKey) else {
            TeamMemberViewModel.logger.error("teamlog/feature/fg/static. \(fgKey)")
            return false
        }
        // 使用容器服务获取生命周期内不变的FG
        let value = service.staticFeatureGatingValue(with: key)
        TeamMemberViewModel.logger.info("teamlog/feature/fg/static. \(fgKey):\(value)")
        return value
    }

    static func getDynamicFgValue(_ fgKey: String, userID: String) -> Bool {
        guard let service = getService(userID: userID),
              let key = FeatureGatingManager.Key(rawValue: fgKey) else {
            TeamMemberViewModel.logger.error("teamlog/feature/fg/dynamic. \(fgKey)")
            return false
        }
        // 使用容器服务获取生命周期内可变的FG
        let value = service.dynamicFeatureGatingValue(with: key)
        TeamMemberViewModel.logger.info("teamlog/feature/fg/dynamic. \(fgKey):\(value)")
        return value
    }

    static func getService(userID: String) -> FeatureGatingService? {
        return try? Container
            .shared
            .getUserResolver(userID: userID, compatibleMode: TeamUserScope.userScopeCompatibleMode)
            .resolve(assert: FeatureGatingService.self)
    }
}
