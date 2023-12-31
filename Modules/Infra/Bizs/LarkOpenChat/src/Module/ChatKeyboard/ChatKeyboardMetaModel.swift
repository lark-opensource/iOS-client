//
//  ChatKeyboardMetaModel.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2021/12/24.
//

import Foundation
import LarkModel
import LarkOpenIM

/// 键盘所需的 MetaModel
public struct ChatKeyboardMetaModel: MetaModel {
    public let chat: Chat
    public init(chat: Chat) {
        self.chat = chat
    }
}
