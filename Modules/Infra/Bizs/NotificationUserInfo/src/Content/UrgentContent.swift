//
//  UrgentContent.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/18.
//

import Foundation

public struct UrgentContent: PushContent {
    public init() {}

    public init?(dict: [String: Any]) {}

    public func toDict() -> [String: Any] {
        return [:]
    }

    public static func getIdentifier(messageId: String, urgentId: String) -> String {
        return "Urgent_\(messageId)_\(urgentId)"
    }
}
