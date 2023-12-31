//
//  ChatPinCardMetaModel.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import LarkModel
import LarkOpenIM

public struct ChatPinCardMetaModel: MetaModel {
    public let chat: Chat
    public init(chat: Chat) {
        self.chat = chat
    }
}
