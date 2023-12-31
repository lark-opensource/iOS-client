//
//  MessageChatPinPayload.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/31.
//

import Foundation
import RustPB
import LarkModel
import LarkOpenChat

struct MessageChatPinPayload: ChatPinPayload {
    let messageID: Int64
    var message: Message?
}
