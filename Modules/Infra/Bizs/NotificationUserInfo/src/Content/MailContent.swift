//
//  MailContent.swift
//  NotificationUserInfo
//
//  Created by KT on 2019/6/19.
//

import Foundation

public struct MailContent: PushContent {
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

    public static func getIdentifier(messageId: String, mailId: String) -> String {
        return "Mail_\(messageId)_\(mailId)"
    }
}
