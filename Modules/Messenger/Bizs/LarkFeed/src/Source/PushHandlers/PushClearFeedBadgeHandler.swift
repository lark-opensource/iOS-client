//
//  PushClearFeedBadgeHandler.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/8/8.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel
import LarkSDKInterface

struct PushBatchClearFeedBadge: PushMessage {
    let taskID: String
}

final class PushClearFeedBadgeHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Feed_V1_PushBatchClearFeedBadge) throws {
        guard let pushCenter = self.pushCenter else { return }
        FeedContext.log.info("feedlog/feedcard/batch/action/clearBatchFeedBadge. \(message.taskID)")
        let pushBatchClearFeedBadge = PushBatchClearFeedBadge(taskID: message.taskID)
        pushCenter.post(pushBatchClearFeedBadge)
    }
}
