//
//  ChatMessageModel.swift
//  ByteView
//
//  Created by wulv on 2020/12/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

struct ChatMessageModel {
    let meetingID: String
    let userType: ParticipantType
    let userRole: ParticipantRole
    let userAvatarKey: String
    let userId: String
    let content: MessageRichText
    let type: VideoChatInteractionMessage.TypeEnum
    let userName: String
    let createTime: String // 毫秒
    let position: Int
    let id: String
    let deviceID: String
    let pid: ByteviewUser
    let tags: [VideoChatInteractionMessage.Tag]
    let tenantID: Int64
    let isBot: Bool

    init(message: VideoChatInteractionMessage) {
        let fromUser = message.fromUser
        self.meetingID = message.meetingID
        self.userType = fromUser.type
        self.userRole = ParticipantRole(rawValue: fromUser.role.rawValue) ?? .unknown
        self.userAvatarKey = fromUser.avatarKey
        self.userId = fromUser.userID
        self.content = message.textContent?.content ?? MessageRichText()
        self.type = message.type
        self.userName = fromUser.name
        self.createTime = message.createMilliTime
        self.position = Int(message.position)
        self.id = message.id
        self.deviceID = fromUser.deviceID
        self.pid = fromUser.pid
        self.tags = message.tags
        self.tenantID = message.tenantID
        self.isBot = message.fromUser.isBot
    }
}

extension ChatMessageModel: Equatable {
    static func == (lhs: ChatMessageModel, rhs: ChatMessageModel) -> Bool {
        return lhs.id == rhs.id
    }
}
