//
//  UrgentTracker.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/10.
//

import Foundation
import Homeric
import LKCommonsTracker
import LarkModel

final class UrgentTracker {
    static func trackMessageUrgentCreate(chat: Chat, messageID: String, messageType: String) {
        Tracker.post(TeaEvent(Homeric.BUZZ_CREATE, category: "message", params: ["message_id": messageID,
                                                                                 "message_type": messageType,
                                                                                 "chat_id": chat.id,
                                                                                 "chat_type": chat.trackType,
                                                                                 "is_bot_chat": chat.isSingleBot ? "true" : "false",
                                                                                 "is_meeting_chat": chat.isMeeting ? "true" : "false"]))
    }
}
