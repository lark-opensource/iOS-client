//
//  PushLoadFeedCardsStatusHandler.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/9.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LKCommonsLogging

extension Feed_V1_PushLoadFeedCardsStatus: PushMessage {}

final class PushLoadFeedCardsStatusHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Feed_V1_PushLoadFeedCardsStatus) throws {
        guard let pushCenter = self.pushCenter else { return }
        FeedContext.log.info("feedlog/pushLoadFeedsStatus. listType: \(message.feedType) status: \(message.status)")
        pushCenter.post(message)
    }
}
