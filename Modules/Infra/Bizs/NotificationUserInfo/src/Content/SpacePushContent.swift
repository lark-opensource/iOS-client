//
//  SpacePushContent.swift
//  NotificationUserInfo
//
//  Created by chenjiahao.gill on 2019/8/5.
//

import Foundation

public final class SpacePushContent: PushContent {
    public var url: String

    public init(url: String) {
        self.url = url
    }

    required public init?(dict: [String: Any]) {
        self.url = dict["url"] as? String ?? ""
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["url"] = self.url
        return dict
    }

    public static func getIdentifier(messageId: String) -> String {
        return "SpacePush_\(messageId)"
    }
}
