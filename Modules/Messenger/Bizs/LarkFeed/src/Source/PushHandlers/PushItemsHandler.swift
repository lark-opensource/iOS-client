//
//  PushItemsHandler.swift
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

final class PushItemsHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Im_V1_PushItems) throws {
        guard let pushCenter = self.pushCenter else { return }
        FeedContext.log.info("teamlog/pushItems. \(message.description)")
        pushCenter.post(message)
    }
}

extension Im_V1_PushItems: CustomStringConvertible {
    public var description: String {
        return "action: \(action), "
        + "items: \(items.map({ $0.description })), "
        + "teams: \(teams.map({ "teamEntityId: \($0), teamEntityDesc: \($1.description)" }))"
    }
}
