//
//  ChatMessageReadServiceTracker.swift
//  LarkMessageCore
//
//  Created by zhenning on 2019/9/25.
//

import Foundation
import Homeric
import LKCommonsTracker
import LarkModel

public final class ChatMessageReadServiceTracker {

    public static func trackReadMessage(chat: Chat?, chatId: String, messageId: String, messageType: Message.TypeEnum, isMute: Bool, isInBox: Bool, trackContext: [String: Any]) {
        var params: [String: Any] = [
            "chat_id": chatId,
            "message_id": messageId,
            "message_type": messageType.rawValue,
            "is_mute": isMute,
            "is_chatbox": isInBox
        ]
        if let notice = trackContext["notice"] as? String {
            params["notice"] = notice
        }
        if let chat = chat {
            params["chat_type"] = chat.type.rawValue
            params.merge(chat.trackTypeInfo, uniquingKeysWith: { (first, _) in first })
        }
        Tracker.post(TeaEvent(Homeric.MESSAGE_READ, category: "message", params: params))
    }

    /// 已读所有推送消息（包含推广消息、奖励通知消息）
    public static func trackCardAanalyticsIfNeed(analytics: String) {
        // analytics中存在type&&activity且值都有效才进行打点
        if let data = analytics.data(using: .utf8),
            let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            let type = "\(jsonDict["type"] ?? "")"
            let activity = "\(jsonDict["activity"] ?? "")"
            if !type.isEmpty, !activity.isEmpty {
                Tracker.post(TeaEvent(Homeric.READ_ACTIVITY_AWARD_MESSAGE, params: ["type": type, "activity": activity]))
            }
        }
    }
}
