//
//  CanvasIdGenerator.swift
//  LarkCore
//
//  Created by Saafo on 2021/3/2.
//

import Foundation
import LarkModel
import LKCommonsLogging

public final class CanvasIdGenerator {

    static let logger = Logger.log(CanvasIdGenerator.self, category: "Module.LarkCore.CanvasIdGenerator")

    public static func generate(for chat: Chat?, replyMessage: Message?, multiEditMessage: Message?) -> String {
        guard let chat = chat else {
            Self.logger.error("Generate for nil chat. Please check the provided chat info.")
            return "chat_null"
        }
        let id: String
        if chat.chatMode == .threadV2,
           let replyMessage = replyMessage {
            // 如果在话题群回复某条话题，用 message id 存储
            id = "chat_" + replyMessage.id
            Self.logger.info("Generate for replyMessage: \(id)")
        } else if let multiEditMessage = multiEditMessage {
            id = "chat_multiEdit_" + multiEditMessage.id
            Self.logger.info("Generate for multiEditMessage: \(id)")
        } else {
            // 在话题群新建新话题，在普通单聊或群聊中，用 chat id 存储
            id = "chat_" + chat.id
            Self.logger.info("Generate for chat: \(id)")
        }
        return id
    }
}
