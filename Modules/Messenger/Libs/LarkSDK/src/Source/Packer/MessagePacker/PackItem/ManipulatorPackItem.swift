//
//  ManipulatorPackItem.swift
//  LarkSDK
//
//  Created by lichen on 2018/10/18.
//

import Foundation
import LarkModel

final class ManipulatorPackItem: PackItem<Message> {
    override func collect(model: Message) -> CollectItem {
        if let content = model.content as? SystemContent,
            content.manipulator == nil,
            let manipulatorID = content.e2eeCallInfo?.manipulatorID {
            let chatId = model.channel.type == .chat ? model.channel.id : ""
            return CollectItem(data: [.chatChatter: [manipulatorID]], extraInfo: [.chatId: chatId])
        }
        return .default
    }

    override func pack(model: Message, data: PackData) -> Message {
        let chatters: [String: Chatter] = data.getData(for: .chatChatter)
        if var content = model.content as? SystemContent,
            let manipulatorID = content.e2eeCallInfo?.manipulatorID,
            let chatter = chatters[manipulatorID] {
            content.manipulator = chatter
            model.content = content
        }
        return model
    }
}
