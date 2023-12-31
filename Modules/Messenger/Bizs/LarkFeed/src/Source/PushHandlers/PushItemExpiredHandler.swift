//
//  PushItemExpiredHandler.swift
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

extension Im_V1_PushItemExpired: PushMessage {}

final class PushItemExpiredHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Im_V1_PushItemExpired) throws {
        guard let pushCenter = self.pushCenter else { return }
        FeedContext.log.info("teamlog/pushItemExpired. \(message.description)")
        pushCenter.post(message)
    }
}

extension Im_V1_PushItemExpired: CustomStringConvertible {
    public var description: String {
        return "hasParentID: \(hasParentID), parentID: \(parentID)"
    }
}
