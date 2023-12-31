//
//  CallChatterPackItem.swift
//  Lark
//
//  Created by liuwanlin on 2018/6/11.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel

final class CallChatterPackItem: PackItem<Message> {
    override func collect(model: Message) -> CollectItem {
        if let content = model.content as? SystemContent,
            content.callee == nil,
            let calleeId = content.calleeId {
            let chatId = model.channel.type == .chat ? model.channel.id : ""
            return CollectItem(data: [.chatChatter: [calleeId]], extraInfo: [.chatId: chatId])
        }
        return .default
    }

    override func pack(model: Message, data: PackData) -> Message {
        let chatters: [String: Chatter] = data.getData(for: .chatChatter)
        if var content = model.content as? SystemContent,
            let calleeId = content.calleeId,
            let chatter = chatters[calleeId] {
            content.callee = chatter
            model.content = content
        }
        return model
    }
}
