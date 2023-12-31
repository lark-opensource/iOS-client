//
//  OpenAppChatContent.swift
//  NotificationUserInfo
//
//  Created by 袁平 on 2020/5/20.
//

import Foundation
public struct OpenAppChatContent: PushContent {
    public var url: String

    public init(url: String) {
        self.url = url
    }

    public init(dict: [String: Any]) {
        self.url = dict["url"] as? String ?? ""
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["url"] = self.url
        return dict
    }

    public static func getIdentifier(messageId: String) -> String {
        return "OpenAppChat_\(messageId)"
    }
}
