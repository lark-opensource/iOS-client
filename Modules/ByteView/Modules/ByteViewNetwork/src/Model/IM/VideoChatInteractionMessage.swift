//
//  VideoChatInteractionMessage.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

public typealias MessageRichText = Basic_V1_RichText

/// Videoconference_V1_ReactionMessageContent
public struct ReactionMessageContent: Equatable {
    public init(content: String, count: Int) {
        self.content = content
        self.count = count
    }

    public var content: String
    public var count: Int
}

/// 前端可能有对 key 的自定义渲染样式需求，所以此处不应该由SDK构造完整字符串
/// - Videoconference_V1_SystemMessageContent
public struct SystemMessageContent: Equatable {
    public init(type: SystemMessageType) {
        self.type = type
    }

    public var type: SystemMessageType

    public enum SystemMessageType: Int, Hashable {
        case unknown // = 0
        case joinMeeting // = 1
    }
}

/// - Videoconference_V1_TextMessageContent
public struct TextMessageContent: Equatable {
    public init(content: MessageRichText) {
        self.content = content
    }

    public var content: MessageRichText
}

/// - Videoconference_V1_EncryptedMessageContent
public struct EncryptedMessageContent: Equatable {
    public init(content: Data) {
        self.content = content
    }

    public var content: Data
}

/// 互动消息
/// - Videoconference_V1_VideoChatInteractionMessage
public struct VideoChatInteractionMessage: Equatable {

    public init(id: String, type: TypeEnum, meetingID: String, content: VideoChatInteractionMessageContent?, fromUser: VideoChatParticipant,
                tenantID: Int64, cid: String, position: Int32, createMilliTime: String, tags: [Tag]) {
        self.id = id
        self.type = type
        self.meetingID = meetingID
        self.content = content
        self.fromUser = fromUser
        self.tenantID = tenantID
        self.cid = cid
        self.position = position
        self.createMilliTime = createMilliTime
        self.tags = tags
    }

    public var id: String

    public var type: TypeEnum

    public var meetingID: String

    public var fromUser: VideoChatParticipant

    /// 使用uuid即可，确保不会碰撞, cid这个命名遵从 IM 的命名规则
    public var cid: String

    /// reaction类型消息可忽略此字段
    public var position: Int32

    /// 毫秒级时间戳
    public var createMilliTime: String

    public var tags: [Tag]

    public var tenantID: Int64

    public var content: VideoChatInteractionMessageContent?

    public var textContent: TextMessageContent? {
        if case .textContent(let v) = content {
            return v
        }
        return nil
    }

    public var reactionContent: ReactionMessageContent? {
        if case .reactionContent(let v) = content {
            return v
        }
        return nil
    }

    public var systemContent: SystemMessageContent? {
        if case .systemContent(let v) = content {
            return v
        }
        return nil
    }

    public var encryptedContent: EncryptedMessageContent? {
        if case .encryptedContent(let v) = content {
            return v
        }
        return nil
    }

    public enum TypeEnum: Int, Hashable {
        case unknown // = 0
        case text // = 1
        case system // = 2
        case reaction // = 3
        case encrypted // = 4
    }

    public enum Tag: Int, Hashable {
        case unknown
        case guest // = 1
    }
}

public enum VideoChatInteractionMessageContent: Equatable {
    case reactionContent(ReactionMessageContent)
    case textContent(TextMessageContent)
    case systemContent(SystemMessageContent)
    case encryptedContent(EncryptedMessageContent)
}

/// Videoconference_V1_VideoChatParticipant
public struct VideoChatParticipant: Equatable {
    public init(userID: String, type: ParticipantType, deviceID: String, name: String, avatarKey: String,
                role: Participant.Role, isBot: Bool) {
        self.userID = userID
        self.type = type
        self.deviceID = deviceID
        self.name = name
        self.avatarKey = avatarKey
        self.role = role
        self.isBot = isBot
    }

    public var userID: String

    /// vc系统里，使用user_id + device_id 唯一标识一个用户
    public var deviceID: String

    public var name: String

    public var avatarKey: String

    public var type: ParticipantType

    public var role: Participant.Role

    public var isBot: Bool
}

extension VideoChatInteractionMessage: CustomStringConvertible {

    public var description: String {
        String(
            indent: "VideoChatInteractionMessage",
            "id: \(id)",
            "type: \(type)",
            "fromUser: \(fromUser)",
            "meetingId: \(meetingID)",
            "cid: \(cid)",
            "position: \(position)",
            "createMilliTime: \(createMilliTime)",
            "tags: \(tags)",
            "tenantId: \(tenantID)"
        )
    }
}
