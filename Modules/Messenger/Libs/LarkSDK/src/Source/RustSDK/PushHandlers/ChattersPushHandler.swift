//
//  ChattersPushHandler.swift
//  Lark-Rust
//
//  Created by liuwanlin on 2017/12/28.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import LarkModel
import LarkSDKInterface

import LarkContainer
import LKCommonsLogging

final class ChattersPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static var logger = Logger.log(ChattersPushHandler.self, category: "Rust.PushHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Basic_V1_Entity) {
        var chatters = message.chatters.compactMap { tuple -> LarkModel.Chatter? in
            return try? LarkModel.Chatter.transformChatter(entity: message, id: tuple.key)
        }
        let chatChatters = message.chatChatters.flatMap { (chatId, chatChatter) -> [LarkModel.Chatter] in
            return chatChatter.chatters.compactMap({ (chatterId, _) -> LarkModel.Chatter? in
                return try? LarkModel.Chatter.transformChatChatter(entity: message, chatID: chatId, id: chatterId)
            })
        }
        chatters.append(contentsOf: chatChatters)
        self.pushCenter?.post(PushChatters(chatters: chatters))
    }
}
