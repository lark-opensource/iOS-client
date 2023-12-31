//
//  dasdasdasd.swift
//  LarkTeam
//
//  Created by xiaruzhen on 2022/9/16.
//

import Foundation
import RustPB
import LarkModel

// MARK: - Team
extension LarkModel.Chat {

    enum TeamChatModeSwitch: Int {
        case none
        case memberToVisitor
        case visitorToMember
    }

    // 是否是团队群
    var isTeamChat: Bool {
        return isAssociatedTeam
    }

    // 是否是团队私有群
    func isTeamPrivateGroup(teamID: Int64?) -> Bool {
        guard let teamID = teamID, isTeamChat else { return false }
        if let chatType = teamEntity.teamsChatType[teamID] {
            return chatType == .private
        }
        return false
    }

    // 是否是团队公开群
    func isTeamOpenGroup(teamID: Int64?) -> Bool {
        guard let teamID = teamID, isTeamChat else { return false }
        if let chatType = teamEntity.teamsChatType[teamID] {
            return chatType == .open
        }
        return false
    }

    // 是否是团队可发现群
    func isTeamDiscoverableGroup(teamID: Int64) -> Bool {
        guard isTeamChat else { return false }
        var discoverable = false
        teamEntity.teamChatInfos.forEach { chatInfo in
            if chatInfo.teamID == teamID {
                discoverable = chatInfo.discoverable
                return
            }
        }
        return discoverable
    }

    // 是否有添加团队成员权限
    func isAllowAddMemberForTeam(_ team: Basic_V1_Team) -> Bool {
        isTeamChat && team.isAllowAddTeamMember
    }

    // 是否有删除团队成员权限
    func isAllowDeleteMemberForTeam(_ team: Basic_V1_Team) -> Bool {
        isTeamChat && team.isTeamManagerForMe
    }

    // 是否有解绑团队权限
    func isAllowUnbindTeam(_ team: Basic_V1_Team, userId: String) -> Bool {
        return (isHasGroupAuthorized(userId: userId) || team.isTeamManagerForMe)
    }

    // 是否是访客模式，如果为访客模式，则chat进入只读不可写的状态
    func isTeamVisitorMode(teamID: Int64?) -> Bool {
        guard let teamID = teamID else { return false }
        let isTeamMember = true
        return isTeamMember && isTeamOpenGroup(teamID: teamID) && (role != .member)
    }

    // 是否有设置群为团队下的公开群的权限
    func isAllowSetOpenGroup(teamID: Int64?, userId: String) -> Bool {
        guard let teamID = teamID else { return false }
        return isHasGroupAuthorized(userId: userId) && isTeamPrivateGroup(teamID: teamID)
    }

    // 是否有群成员以上的权限
    func isHasGroupAuthorized(userId: String) -> Bool {
        return isGroupOwner(userId: userId) || isGroupAdmin
    }

    // 是否是群主
    func isGroupOwner(userId: String) -> Bool {
        return userId == ownerId
    }

    var teamChatDescription: String {
        return "\(id), isTeamChat: \(isAssociatedTeam), role: \(role), chatType: \(teamEntity.teamsChatType)"
    }

    var isAllowBinded: Bool {
        return !(type == .p2P
            || isCrypto
            || isPrivateMode)
    }
}
