//
//  ChatWidgetMetaModel.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/1/9.
//

import Foundation
import LarkModel
import LarkOpenIM

public struct ChatWidgetMetaModel: MetaModel {
    public let chat: Chat
    public init(chat: Chat) {
        self.chat = chat
    }
}
