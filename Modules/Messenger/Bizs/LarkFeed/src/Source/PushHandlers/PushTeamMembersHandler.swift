//
//  PushTeamMembersHandler.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/12/9.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel
import LarkSDKInterface

final class PushTeamMembersHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Im_V1_PushTeamMembers) throws {
        guard let pushCenter = self.pushCenter else { return }
        FeedContext.log.info("teamlog/pushTeamMembers. \(message.description)")
        pushCenter.post(message)
    }
}

extension Im_V1_PushTeamMembers: CustomStringConvertible {
    public var description: String {
        return "teamID: \(teamID), "
        + "type: \(type), "
        + "count: \(teamMemberInfos.count), "
        + "infos: \(teamMemberInfos.map { $0.description })"
    }
}
