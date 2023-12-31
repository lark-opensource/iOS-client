//
//  MessageReactionsPushHandler.swift
//  LarkSDK
//
//  Created by 赵家琛 on 2020/7/20.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LarkModel

final class MessageReactionsPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Im_V1_PushMessageReactions) {
        let chatId = message.chatID
        let entity = message.entity
        let messageReactions = message.msgID2Reactions.mapValues { (reactions) -> [Reaction] in
            return reactions.reactions.map { (pb) -> Reaction in
                Reaction.transform(entity: entity, pb: pb, chatID: chatId)
            }
        }
        self.pushCenter?.post(PushMessageReactions(chatId: chatId, messageReactions: messageReactions))
    }
}
