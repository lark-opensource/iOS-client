//
//  ChatsPushHandler.swift
//  Lark-Rust
//
//  Created by Yuguo on 2017/12/27.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface

import LarkContainer
import LarkModel
import LKCommonsLogging

/// Received scenes:
/// 1. chat unread count changed.
/// 2. chat setting changed.
final class ChatsPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    static var logger = Logger.log(ChatsPushHandler.self, category: "Rust.PushHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Basic_V1_Entity) {
        let chatsMap = RustAggregatorTransformer.transformToChatsMap(
            fromEntity: message
        )
        chatsMap.values.forEach { (chat) in
            self.pushCenter?.post(PushChat(chat: chat))
            Self.logger.info("""
                             chatTrace receive pushChat \(chat.id) \(chat.badge)
                             \(chat.lastVisibleMessagePosition) \(chat.lastMessagePosition)
                             \(chat.readPosition) \(chat.displayInThreadMode)
                            """)
        }
    }
}
