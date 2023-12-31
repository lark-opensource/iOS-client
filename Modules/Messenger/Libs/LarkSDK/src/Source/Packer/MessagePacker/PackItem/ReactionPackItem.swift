//
//  ReactionPackItem.swift
//  Lark
//
//  Created by liuwanlin on 2018/6/11.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel

final class ReactionPackItem: PackItem<Message> {
    override func collect(model: Message) -> CollectItem {
        var chatterIds: [String] = []
        if !model.isRecalled {
            chatterIds = model.reactions.flatMap { (reaction) -> [String] in
                let existChatterIds = reaction.chatters?.map({ (chatter) -> String in
                    return chatter.id
                }) ?? []
                let missChatterIds = reaction.chatterIds.filter { (chatterId) -> Bool in
                    !existChatterIds.contains(chatterId)
                }
                return missChatterIds
            }
        }
        if chatterIds.isEmpty {
            return .default
        }
        let chatId = model.channel.type == .chat ? model.channel.id : ""
        return CollectItem(data: [.chatChatter: chatterIds], extraInfo: [.chatId: chatId])
    }

    override func pack(model: Message, data: PackData) -> Message {
        var packChatters: [String: Chatter] = data.getData(for: .chatChatter)
        model.reactions = model.reactions.map { (reaction) in
            //将已经有的chatter也添加到packChatters里，保证packChatters中数据是完整的
            for chatter in reaction.chatters ?? [] {
                packChatters[chatter.id] = chatter
            }
            reaction.chatters = reaction.chatterIds.compactMap({ (chatterId) -> Chatter? in
                return packChatters[chatterId]
            })
            return reaction
        }
        return model
    }
}
