//
//  LarkNCEExtra.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/4/11.
//

import Foundation

public struct LarkNCEExtra {
    public let chatId: String
    public let userId: String
    public let position: UInt64?
    public let threadId: String
    public let messageID: String
    public let isRemote: Bool

    public init?(dict: [String: Any]) {
        self.chatId = dict["chatId"] as? String ?? ""
        self.userId = dict["userId"] as? String ?? ""
        self.position = dict["position"] as? UInt64
        self.threadId = dict["threadId"] as? String ?? ""
        self.messageID = dict["messageId"] as? String ?? ""
        self.isRemote = dict["is_remote"] as? Bool ?? true
    }

    public static func getExtraDict(from userInfo: [AnyHashable: Any]) -> LarkNCEExtra? {
        if let extra = userInfo["extra"] as? [AnyHashable: Any], let dict = extra["content"] as? [String: Any] {
            return LarkNCEExtra(dict: dict)
        }
        return nil
    }
}

