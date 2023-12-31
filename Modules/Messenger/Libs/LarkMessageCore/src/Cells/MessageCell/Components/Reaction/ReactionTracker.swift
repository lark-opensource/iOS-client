//
//  ReactionTracker.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/3.
//

import Foundation
import Homeric
import LarkModel
import LKCommonsTracker
import LarkMessageBase

final class ReactionTracker {
    static func trackReaction(message: Message, chat: Chat?, scene: ContextScene, type: String, tab: String, time: TimeInterval) {
        let topic: String
        switch scene {
        case .threadDetail, .replyInThread: topic = "topic_thread"
        case .threadChat: topic = "topic_card"
        /// TODO: 这个埋点的key
        case .threadPostForwardDetail: topic = "topic_forward_thread"
        case .newChat: topic = "new_chat"
        case .mergeForwardDetail: topic = "mergeForwardDetail"
        case .messageDetail: topic = "messageDetail"
        case .pin: topic = "pinList"
        @unknown default:
            assert(false, "new value")
            topic = "unknown"
        }
        var params: [String: Any] = ["topic_id": message.id,
                                     "group_id": message.channel.id,
                                     "message_id": message.id,
                                     "location": topic,
                                     "message_type": message.type.rawValue,
                                     "reaction_type": type,
                                     "reaction_object_id": message.id,
                                     "action_position": topic,
                                     "notice": message.trackAtType,
                                     "reaction_time": Int(time * 1000),
                                     "tab": tab,
                                     "message_aim_type": message.type.trackValue]
        if let chat = chat {
            params["chat_type"] = chat.type.rawValue
            params["chat_id"] = chat.id
            params.merge(chat.trackTypeInfo, uniquingKeysWith: { (first, _) in first })
        }
        Tracker.post(TeaEvent(Homeric.MESSAGE_REACTION, category: "message", params: params))
    }
}
