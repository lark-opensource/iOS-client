//
//  OpenAppContent.swift
//  NotificationUserInfo
//
//  Created by PGB on 2019/10/9.
//

import Foundation

public struct OpenAppContent: PushContent {
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

    public static func getIdentifier(messageId: String) -> String {
        return "OpenApp_\(messageId)"
    }
}
