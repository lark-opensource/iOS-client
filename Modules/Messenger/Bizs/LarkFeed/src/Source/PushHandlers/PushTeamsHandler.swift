//
//  PushTeamsHandler.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/15.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel
import LarkSDKInterface

final class PushTeamsHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Im_V1_PushTeams) throws {
        guard let pushCenter = self.pushCenter else { return }
        FeedContext.log.info("teamlog/pushTeams. \(message.description)")
        pushCenter.post(message)
    }
}

extension Im_V1_PushTeams: CustomStringConvertible {
    public var description: String {
        return "\(self.teams.map({ "teamEntityId: \($0), teamEntityDesc: \($1.description)" }))"
    }
}
