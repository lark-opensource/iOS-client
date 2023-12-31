//
//  ChatKeyboardTopExtendMetaModel.swift
//  LarkOpenChat
//
//  Created by zc09v on 2021/8/9.
//

import Foundation
import LarkModel
import LarkOpenIM

/// Chat中键盘上方扩展区域所需的MetaModel
public struct ChatKeyboardTopExtendMetaModel: MetaModel {
    public let chat: Chat

    public init(chat: Chat) {
        self.chat = chat
    }
}
