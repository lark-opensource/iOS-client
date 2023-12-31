//
//  OpenMessageMenuContext.swift
//  LarkOpenChat
//
//  Created by Ping on 2023/11/21.
//

import RustPB
import LarkModel

public enum OpenMessageMenuType {
    case single // 单选
    case multi // 多选
}

public struct MessageInfo {
    // messageID
    public let id: String
    public let type: Message.TypeEnum

    public init(id: String, type: Message.TypeEnum) {
        self.id = id
        self.type = type
    }

    public static func transform(from: Message) -> MessageInfo {
        return MessageInfo(id: from.id, type: from.type)
    }
}

public class OpenMessageMenuContext {
    public let chat: Chat
    public let menuType: OpenMessageMenuType
    // 选中的消息，单选时只有一条，多选时可能多条
    // 这里抽一个MessageInfo的原因是多选时内存里可能没有Message
    public let messageInfos: [MessageInfo]

    public init(chat: Chat, menuType: OpenMessageMenuType, messageInfos: [MessageInfo]) {
        self.chat = chat
        self.menuType = menuType
        self.messageInfos = messageInfos
    }
}
