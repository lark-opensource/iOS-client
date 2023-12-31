//
//  EENotificationRequest.swift
//  EENotification
//
//  Created by 姚启灏 on 2018/12/6.
//

import Foundation
import UserNotifications

public struct NotificationRequest {
    public let group: String
    public let identifier: String
    public let version: String
    public let trigger: NotificationTrigger?

    public private(set) var userInfo: [AnyHashable: Any]

    private var alertInfo: [AnyHashable: Any] {
        get {
            return userInfo[NotificationUserInfoKey.alert] as? [AnyHashable: Any] ?? [:]
        }
        set {
            self.userInfo[NotificationUserInfoKey.alert] = newValue
        }
    }

    public var title: String {
        get {
            return self.alertInfo[NotificationUserInfoKey.Alert.title] as? String ?? ""
        }
        set {
            self.alertInfo[NotificationUserInfoKey.Alert.title] = newValue
        }
    }

    public var subtitle: String {
        get {
            return self.alertInfo[NotificationUserInfoKey.Alert.subtitle] as? String ?? ""
        }
        set {
            self.alertInfo[NotificationUserInfoKey.Alert.subtitle] = newValue
        }
    }

    public var body: String {
        get {
            return self.alertInfo[NotificationUserInfoKey.Alert.body] as? String ?? ""
        }
        set {
            self.alertInfo[NotificationUserInfoKey.Alert.body] = newValue
        }
    }

    public var categoryIdentifier: String? {
        get {
            return self.alertInfo[NotificationUserInfoKey.Alert.categoryIdentifier] as? String
        }
        set {
            self.alertInfo[NotificationUserInfoKey.Alert.categoryIdentifier] = newValue
        }
    }

    public var badge: Int? {
        get {
            return self.alertInfo[NotificationUserInfoKey.Alert.badge] as? Int
        }
        set {
            self.alertInfo[NotificationUserInfoKey.Alert.badge] = newValue
        }
    }

    public var soundName: String {
        get {
            return self.alertInfo[NotificationUserInfoKey.Alert.soundName] as? String ?? ""
        }
        set {
            self.alertInfo[NotificationUserInfoKey.Alert.soundName] = newValue
        }
    }

    public var launchImageName: String {
        get {
            return self.alertInfo[NotificationUserInfoKey.Alert.launchImageName] as? String ?? ""
        }
        set {
            self.alertInfo[NotificationUserInfoKey.Alert.launchImageName] = newValue
        }
    }

    public var threadIdentifier: String {
        get {
            return self.alertInfo[NotificationUserInfoKey.Alert.threadIdentifier] as? String ?? ""
        }
        set {
            self.alertInfo[NotificationUserInfoKey.Alert.threadIdentifier] = newValue
        }
    }

    public init(group: String, identifier: String, version: String, userInfo: [AnyHashable: Any], trigger: NotificationTrigger?) {
        self.group = group
        self.identifier = identifier
        self.version = version
        self.trigger = trigger
        self.userInfo = userInfo

        self.userInfo[NotificationUserInfoKey.group] = group
        self.userInfo[NotificationUserInfoKey.identifier] = identifier
        self.userInfo[NotificationUserInfoKey.version] = version
        if self.userInfo[NotificationUserInfoKey.alert] as? [AnyHashable: Any] == nil {
            self.userInfo[NotificationUserInfoKey.alert] = [:]
        }
    }
}

extension NotificationRequest {
    //EENotificationRequest -> UNNotificationRequest，UNNotificationRequest设置相关属性
    public func transformNotificationRequest() -> UNNotificationRequest? {
        let content = UNMutableNotificationContent()
        content.userInfo = self.userInfo
        if let categoryIdentifier = self.categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }

        if !self.soundName.isEmpty {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: self.soundName))
        }
        if let badge = self.badge {
            content.badge = NSNumber(integerLiteral: badge)
        }
        content.title = self.title
        content.subtitle = self.subtitle
        content.body = self.body
        content.launchImageName = self.launchImageName
        content.threadIdentifier = self.threadIdentifier

        //将fireDate转换为timeIntervalSinceNow时间戳，然后转为UNTimeIntervalNotificationTrigger
        if let fireDate = self.trigger?.fireDate {
            if fireDate <= Date() {
                assertionFailure("此通知已过时")
                return nil
            }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fireDate.timeIntervalSinceNow, repeats: false)
            return UNNotificationRequest(identifier: self.identifier, content: content, trigger: trigger)
        }

        return UNNotificationRequest(identifier: self.identifier, content: content, trigger: nil)
    }
}

extension UNNotificationRequest {
    public func transformEENotificationRequest() -> NotificationRequest {
        let group = self.content.userInfo[NotificationUserInfoKey.group] as? String

        //因为之前是将date转换为timeIntervalSince1970，需要转回date
        var date: Date?
        if let trigger = self.trigger as? UNTimeIntervalNotificationTrigger {
            date = Date(timeIntervalSince1970: trigger.timeInterval)
        }
        let version = self.content.userInfo[NotificationUserInfoKey.version] as? String ?? ""
        return NotificationRequest(group: group ?? "",
                                   identifier: self.identifier,
                                   version: version,
                                   userInfo: self.content.userInfo,
                                   trigger: NotificationTrigger(fireDate: date))
    }
}

extension UNNotification {
    public func transformEENotificationRequest() -> NotificationRequest {
        return self.request.transformEENotificationRequest()
    }
}
