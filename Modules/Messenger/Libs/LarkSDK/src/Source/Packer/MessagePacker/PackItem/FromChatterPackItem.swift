//
//  FromChatterPackItem.swift
//  Lark
//
//  Created by liuwanlin on 2018/6/11.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel

final class FromChatterPackItem: PackItem<Message> {
    override func collect(model: Message) -> CollectItem {
        //有些系统消息对应的fromChatterId会被赋值为1，需要过滤掉
        if model.fromChatter != nil || model.fromId == "1" {
            return .default
        }
        let chatId = model.channel.type == .chat ? model.channel.id : ""
        return CollectItem(data: [.chatChatter: [model.fromId]], extraInfo: [.chatId: chatId])
    }

    override func pack(model: Message, data: PackData) -> Message {
        let chatters: [String: Chatter] = data.getData(for: .chatChatter)
        if let chatter = chatters[model.fromId] {
            model.fromChatter = chatter
        }
        return model
    }
}
