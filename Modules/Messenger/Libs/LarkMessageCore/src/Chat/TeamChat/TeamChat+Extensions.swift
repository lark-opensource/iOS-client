//
//  TeamChat+Extensions.swift
//  LarkMessageCore
//
//  Created by 夏汝震 on 2022/2/22.
//

import Foundation
import LarkAccountInterface
import LarkFeatureGating
import RustPB
import LarkModel
import LarkSetting

// MARK: - Team
public extension LarkModel.Chat {

    enum TeamChatModeSwitch: Int {
        case none
        case memberToVisitor
        case visitorToMember
    }

    // [团队]是否可用
    static func isTeamEnable(fgService: FeatureGatingService) -> Bool {
        getRealTimeFgValueWithLog(FeatureGatingKey.team.rawValue, fgService: fgService)
    }

    static func getRealTimeFgValueWithLog(_ fgKey: String, fgService: FeatureGatingService) -> Bool {
        guard let key = FeatureGatingManager.Key(rawValue: fgKey) else {
            return false
        }
        let enable = fgService.dynamicFeatureGatingValue(with: key)
        return enable
    }

    var isTeamOpenGroupForAnyTeam: Bool {
        self.teamEntity.teamsChatType.values.contains(.open)
    }

    // 是否是访客模式，如果为访客模式，则chat进入只读不可写的状态
    var isTeamVisitorMode: Bool {
        // 临时入会身份高于访客模式
        if self.hasVcChatPermission {
            return false
        }
        return role != .member && self.teamEntity.teamsChatType.values.contains(.open)
    }

    var teamChatDescription: String {
        return "\(id), isTeamChat: \(isAssociatedTeam), role: \(role), chatType: \(teamEntity.teamsChatType)"
    }
}
