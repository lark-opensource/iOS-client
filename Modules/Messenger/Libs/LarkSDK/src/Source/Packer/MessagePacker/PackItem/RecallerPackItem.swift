//
//  RecallerPackItem.swift
//  Lark
//
//  Created by liuwanlin on 2018/7/23.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel

final class RecallerPackItem: PackItem<Message> {
    override func collect(model: Message) -> CollectItem {
        if !model.recallerId.isEmpty, model.recaller != nil {
            let chatId = model.channel.type == .chat ? model.channel.id : ""
            return CollectItem(data: [.chatChatter: [model.recallerId]], extraInfo: [.chatId: chatId])
        }
        return .default
    }

    override func pack(model: Message, data: PackData) -> Message {
        let chatters: [String: Chatter] = data.getData(for: .chatChatter)
        if !model.recallerId.isEmpty,
            let chatter = chatters[model.recallerId] {
            model.recaller = chatter
        }
        return model
    }
}
