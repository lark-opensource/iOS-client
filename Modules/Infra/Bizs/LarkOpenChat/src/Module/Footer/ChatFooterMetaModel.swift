//
//  ChatFooterMetaModel.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2022/7/7.
//

import Foundation
import LarkModel
import LarkOpenIM

/// Footer所需的MetaModel
public struct ChatFooterMetaModel: MetaModel {
    public let chat: Chat

    public init(chat: Chat) {
        self.chat = chat
    }
}
