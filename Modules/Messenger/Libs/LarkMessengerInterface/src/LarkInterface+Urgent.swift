//
//  LarkInterface+Urgent.swift
//  LarkInterface
//
//  Created by liuwanlin on 2018/5/22.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import EENavigator
import RustPB

//给某人加急
public struct UrgentChatterBody: PlainBody {
    public static let pattern = "//client/urgent/single"

    public let messageId: String
    public let chatterId: String
    public let chat: Chat
    public let chatFromWhere: ChatFromWhere

    public init(chatterId: String, messageId: String, chat: Chat, chatFromWhere: ChatFromWhere) {
        self.messageId = messageId
        self.chatterId = chatterId
        self.chat = chat
        self.chatFromWhere = chatFromWhere
    }
}

public enum UrgentScene: Int, Codable {
    case p2PChat = 1
    case groupChat
}

//通过选择列表加急
public struct UrgentBody: CodablePlainBody {
    public static let pattern = "//client/urgent/list"

    public let messageId: String
    public let urgentScene: UrgentScene
    public let chatFromWhere: ChatFromWhere

    public init(messageId: String, urgentScene: UrgentScene, chatFromWhere: ChatFromWhere) {
        self.messageId = messageId
        self.urgentScene = urgentScene
        self.chatFromWhere = chatFromWhere
    }
}

// 加急中心
public struct UrgentMessage {
    public var message: Message
    public var urgent: RustPB.Basic_V1_Urgent

    public init(urgent: RustPB.Basic_V1_Urgent, message: Message) {
        self.urgent = urgent
        self.message = message
    }
}

public protocol UrgencyCenter {
    func loadAll()
    func confirmUrgency(messageId: String, urgentConfirmSuccess: @escaping () -> Void)
}
