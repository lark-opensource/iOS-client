//
//  BadgeContent.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/18.
//

import Foundation

public struct BadgeContent: PushContent {
    public var messageIds: [String]

    public init(messageIds: [String]) {
        self.messageIds = messageIds
    }

    public init?(dict: [String: Any]) {
        self.messageIds = dict["messageIds"] as? [String] ?? []
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["messageIds"] = self.messageIds
        return dict
    }
}
