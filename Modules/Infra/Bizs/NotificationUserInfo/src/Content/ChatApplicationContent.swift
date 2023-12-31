//
//  ChatApplicationContent.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/18.
//

import Foundation

public struct ChatApplicationContent: PushContent {
    public var url: String

    public init(url: String) {
        self.url = url
    }

    public init?(dict: [String: Any]) {
        self.url = dict["url"] as? String ?? ""
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["url"] = self.url
        return dict
    }
}
