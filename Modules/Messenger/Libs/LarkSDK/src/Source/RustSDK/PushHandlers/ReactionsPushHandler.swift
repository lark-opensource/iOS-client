//
//  ReactionsPushHandler.swift
//  LarkSDK
//
//  Created by 李晨 on 2019/11/26.
//

import Foundation
import LarkRustClient
import LarkSDKInterface
import LarkModel
import LarkContainer

final class UserRecentReactionPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: PushRecentReactionsResponse) {
        self.pushCenter?.post(
            PushUserReactions(keys: message.userReactions.keys + message.userReactions.extraKeys)
        )
    }
}

final class UserMruReactionPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: PushMRUReactionsResponse) {
        self.pushCenter?.post(
            PushUserMruReactions(keys: message.userMruReactions)
        )
    }
}
