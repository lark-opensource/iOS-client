//
//  MessageContent.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/18.
//

import Foundation

public struct MessageContent: PushContent {
    public var messageId: String
    public var chatId: String
    public var userId: String
    public var position: Int32?
    public var threadId: String
    public var url: String
    public var state: MessageState
    public var isRemote: Bool // 是否来自离线推送

    public init(messageId: String,
                chatId: String = "",
                position: Int32? = nil,
                threadId: String = "",
                userId: String = "",
                url: String,
                state: MessageState,
                isRemote: Bool = true) {
        self.chatId = chatId
        self.position = position
        self.threadId = threadId
        self.userId = userId
        self.url = url
        self.state = state
        self.messageId = messageId
        self.isRemote = isRemote
    }

    public init?(dict: [String: Any]) {
        guard let messageId = dict["messageId"] as? String,
        let chatId = dict["chatId"] as? String,
        let threadId =  dict["threadId"] as? String,
        let userId =  dict["userId"] as? String else { return nil }

        self.messageId = messageId
        self.chatId = chatId
        self.position = dict["position"] as? Int32
        self.threadId = threadId
        self.userId = userId
        self.url = dict["url"] as? String ?? ""
        self.state = MessageState(rawValue: dict["state"] as? Int ?? 0) ?? .normal
        self.isRemote = dict["is_remote"] as? Bool ?? true
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["url"] = self.url
        dict["state"] = self.state.rawValue
        dict["messageId"] = self.messageId
        dict["chatId"] = self.chatId
        dict["position"] = self.position
        dict["threadId"] = self.threadId
        dict["userId"] = self.userId
        dict["is_remote"] = self.isRemote
        return dict
    }
}

public enum MessageState: Int {
    // 0, 1, 2
    case normal, recalled, deleted
    // 101
    case failed = 101
}
