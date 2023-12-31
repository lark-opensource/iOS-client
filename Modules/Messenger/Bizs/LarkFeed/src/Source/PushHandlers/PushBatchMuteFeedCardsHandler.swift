//
//  PushMuteFeedCardsHandler.swift
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

struct PushMuteFeedCards: PushMessage {
    let taskID: String
}

final class PushBatchMuteFeedCardsHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Feed_V1_PushBatchMuteFeedCards) throws {
        guard let pushCenter = self.pushCenter else { return }
        FeedContext.log.info("feedlog/feedcard/batch/action/pushBatchMuteFeedCards. \(message.taskID)")
        let pushMuteFeedCards = PushMuteFeedCards(taskID: message.taskID)
        pushCenter.post(pushMuteFeedCards)
    }
}
