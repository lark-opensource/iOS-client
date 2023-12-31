//
//  Alert.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/18.
//

import Foundation
import UserNotifications

public struct Alert: JSONCodable {
    public let title: String?
    public let subtitle: String?
    public let body: String?
    public let soundName: String?
    public let badge: Int?
    public let sound: UNNotificationSound? //TODO sound 序列化与反序列化

    public init(title: String? = nil,
                subtitle: String? = nil,
                body: String? = nil,
                soundName: String? = nil,
                badge: Int? = nil,
                sound: UNNotificationSound? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.soundName = soundName
        self.badge = badge
        self.sound = sound
    }

    public init?(dict: [String: Any]) {
        self.title = dict["title"] as? String
        self.subtitle = dict["subtitle"] as? String
        self.body = dict["body"] as? String
        self.soundName = dict["soundName"] as? String
        self.badge = dict["badge"] as? Int
        self.sound = nil
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]

        dict["title"] = self.title
        dict["subtitle"] = self.subtitle
        dict["body"] = self.body
        dict["soundName"] = self.soundName
        dict["badge"] = self.badge

        return dict
    }
}
