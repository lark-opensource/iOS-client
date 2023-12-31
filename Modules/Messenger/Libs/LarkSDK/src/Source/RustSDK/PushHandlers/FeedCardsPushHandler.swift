//
//  FeedCardsPushHandler.swift
//  Lark
//
//  Created by Yuguo on 2017/12/21.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

import LarkModel
import LKCommonsLogging

/// Received scenes:
/// 1. manually move feed from inbox to done.
/// 2. manually move feed from done to inbox.
/// 3. new chats created.
final class FeedCardsPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static var logger = Logger.log(FeedCardsPushHandler.self, category: "Rust.PushHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Basic_V1_Entity) {
        let chatsMap = RustAggregatorTransformer.transformToChatsMap(
            fromEntity: message
        )
        chatsMap.values.forEach {
            self.pushCenter?.post(PushChat(chat: $0))
            Self.logger.info("chatTrace receive pushFeedCards \($0.id) \($0.badge) \($0.lastVisibleMessagePosition) \($0.lastMessagePosition)")
        }
    }
}
