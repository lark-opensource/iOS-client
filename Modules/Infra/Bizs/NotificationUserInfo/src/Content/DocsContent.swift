//
//  DocsContent.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/19.
//

import Foundation

public struct DocsContent: PushContent {
    public var messageId: String
    public var url: String
    public var state: MessageState

    public init?(dict: [String: Any]) {
        self.messageId = dict["messageId"] as? String ?? ""
        self.url = dict["url"] as? String ?? ""
        self.state = MessageState(rawValue: dict["state"] as? Int ?? 0) ?? .normal
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["url"] = self.url
        dict["state"] = self.state.rawValue
        dict["messageId"] = self.messageId
        return dict
    }
}
