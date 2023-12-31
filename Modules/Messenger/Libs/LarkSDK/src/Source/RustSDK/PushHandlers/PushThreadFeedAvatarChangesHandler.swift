//
//  PushThreadFeedAvatarChangesHandler.swift
//  LarkSDK
//
//  Created by lizhiqiang on 2020/2/16.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkModel
import LarkSDKInterface
import LKCommonsLogging

/// 话题Feed 更换头像push
final class PushThreadFeedAvatarChangesHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private static var logger = Logger.log(PushThreadFeedAvatarChangesHandler.self, category: "LarkThread.Feed")
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Feed_V1_PushThreadFeedAvatarChanges) {
        let topicAvatars = PushThreadFeedAvatarChanges(avatars: message.avatars)
        self.pushCenter?.post(topicAvatars)

        PushThreadFeedAvatarChangesHandler.logger.debug(
            "update thread topic avatars chatIDs: \(Array(topicAvatars.avatars.keys))"
        )
    }
}
