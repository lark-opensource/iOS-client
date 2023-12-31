//
//  ChatNotificationUserInfo.swift
//  LarkCore
//
//  Created by zc09v on 2018/8/29.
//

import Foundation
import LarkModel
import RustPB

struct ChatNotificationUserInfo: NotificationUserInfo {
    enum InfoKey: String {
        case chatId = "chat_id"
        case messageId = "message_id"
        case position = "position"
        case direct = "direct"
        case belongTo = "belong_to"
        case emailId = "email_id"
    }

    enum NofInfoBelongTo: Int {
        case unknown = 0
        case chat = 1
        case email = 2
    }

    enum DirectType: Int {
        case toDefault = 1
        case toLatestUnreadMessage
        case toMessage
    }

    public let channel: RustPB.Basic_V1_Channel
    public let messageId: String
    public let messagePosition: Int32
    public let direct: DirectType
    public let userInfoType: NotificationUserInfoType

    public init(channel: RustPB.Basic_V1_Channel, messageId: String, messagePosition: Int32, direct: DirectType) {
        self.channel = channel
        self.messageId = messageId
        self.messagePosition = messagePosition
        self.direct = direct
        self.userInfoType = .forChat
    }

    public func toDict() -> [String: Any]? {
        guard let channelId = Int64(channel.id), let messageId = Int64(messageId) else {
            return nil
        }
        var channelKey: String = ""
        let belongTo: NofInfoBelongTo
        switch channel.type {
        case .chat:
            channelKey = ChatNotificationUserInfo.InfoKey.chatId.rawValue
            belongTo = .chat
        case .email:
            channelKey = ChatNotificationUserInfo.InfoKey.emailId.rawValue
            belongTo = .email
        @unknown default:
            belongTo = .unknown
        }
        return [NotificationUserInfoType.key: userInfoType.rawValue,
                channelKey: channelId,
                ChatNotificationUserInfo.InfoKey.messageId.rawValue: messageId,
                ChatNotificationUserInfo.InfoKey.position.rawValue: messagePosition,
                ChatNotificationUserInfo.InfoKey.direct.rawValue: direct.rawValue,
                ChatNotificationUserInfo.InfoKey.belongTo.rawValue: belongTo.rawValue]
    }
}
