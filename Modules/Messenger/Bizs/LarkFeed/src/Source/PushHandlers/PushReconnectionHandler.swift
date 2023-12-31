//
//  PushReconnectionHandler.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/26.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import LarkModel

struct PushReconnection: PushMessage {
}

final class PushReconnectionHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Basic_V1_ReconnectionResponse) throws {
        guard let pushCenter = self.pushCenter else { return }
        let info = PushReconnection()
        FeedContext.log.info("feedlog/pushReconnection")
        pushCenter.post(info)
    }
}
