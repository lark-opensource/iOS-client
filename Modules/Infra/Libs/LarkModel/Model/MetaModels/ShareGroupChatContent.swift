//
//  ShareGroupChatContent.swift
//  LarkModel
//
//  Created by chengzhipeng-bytedance on 2018/5/18.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation
import UIKit
import RustPB

public struct ShareGroupChatContent: MessageContent {
    // 固有字段
    public let shareChatID: String
    public var joinToken: String
    public let expireTime: TimeInterval

    // 附加字段
    public var chat: Chat?

    public init(shareChatID: String, joinToken: String, expireTime: TimeInterval) {
        self.shareChatID = shareChatID
        self.joinToken = joinToken
        self.expireTime = TimeInterval(expireTime)
    }

    public static func transform(pb: RustPB.Basic_V1_Message) -> ShareGroupChatContent {
        return ShareGroupChatContent(
            shareChatID: pb.content.shareChatID,
            joinToken: pb.content.joinToken,
            expireTime: TimeInterval(pb.content.expireTime)
        )
    }

    public mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        if let chat = entity.chats[shareChatID] {
            self.chat = Chat.transform(pb: chat)
        }
    }

    public mutating func complement(previewID: String, messageLink: RustPB.Basic_V1_MessageLink, message: Message) {
        if let chat = messageLink.chats[shareChatID] {
            self.chat = Chat.transform(pb: chat)
        }
    }
}
