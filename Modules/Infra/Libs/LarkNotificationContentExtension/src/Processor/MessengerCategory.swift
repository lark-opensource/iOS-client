//
//  MessengerCategory.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/5/18.
//

import Foundation
import UserNotifications
import UserNotificationsUI

public struct MessengerCategory {
    public static var category: String = "messenger"

    public static func getCategory() -> UNNotificationCategory {
        var replyAction: UNNotificationAction
        var okAction: UNNotificationAction
        // Set up actions.
        if #available(iOS 15.0, *) {
            replyAction = UNTextInputNotificationAction(identifier: "replyAction",
                                                        title: BundleI18n.LarkNotificationContentExtension.Lark_Core_QuickReply_ReplyButton,
                                                        options: [.authenticationRequired],
                                                        icon: UNNotificationActionIcon(templateImageName: "larkreply"))
            okAction = UNNotificationAction(identifier: "okAction",
                                            title: BundleI18n.LarkNotificationContentExtension.Emoji_OK,
                                            options: [.authenticationRequired],
                                            icon: UNNotificationActionIcon(templateImageName: "larkok"))
        } else {
            replyAction = UNTextInputNotificationAction(identifier: "replyAction",
                                                        title: BundleI18n.LarkNotificationContentExtension.Lark_Core_QuickReply_ReplyButton,
                                                        options: [.authenticationRequired])
            okAction = UNNotificationAction(identifier: "okAction",
                                            title: BundleI18n.LarkNotificationContentExtension.Emoji_OK,
                                            options: [.authenticationRequired])
        }

        // Set up categories.
        let messengerCategory = UNNotificationCategory(identifier: "messenger", actions: [replyAction, okAction],
                                                       intentIdentifiers: [],
                                                       options: [])

        return messengerCategory
    }
}
