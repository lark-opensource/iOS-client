//
//  ChatSettingMetaModel.swift
//  LarkOpenChat
//
//  Created by JackZhao on 2021/8/24.
//

import RustPB
import LarkModel
import Foundation
import LarkOpenIM

/// 聊天设置页中所需的MetaModel
public struct ChatSettingMetaModel: MetaModel {
    public var chat: Chat

    public init(chat: Chat) {
        self.chat = chat
    }
}
