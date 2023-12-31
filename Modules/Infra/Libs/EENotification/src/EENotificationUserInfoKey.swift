//
//  EENotificationUserInfoKey.swift
//  EENotification
//
//  Created by 姚启灏 on 2018/12/10.
//

import Foundation

public struct NotificationUserInfoKey {
    public static let group = "group"
    public static let identifier = "identifier"
    public static let version = "version"
    public static let alert = "alert"

    struct Alert {
        public static let title = "title"
        public static let subtitle = "subtitle"
        public static let body = "body"
        public static let badge = "badge"
        public static let soundName = "soundName"
        public static let launchImageName = "launchImageName"
        public static let threadIdentifier = "threadIdentifier"
        public static let categoryIdentifier = "categoryIdentifier"
    }
}
