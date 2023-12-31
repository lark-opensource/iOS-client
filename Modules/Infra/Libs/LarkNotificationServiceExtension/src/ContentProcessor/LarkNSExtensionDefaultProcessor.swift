//
//  LarkNSExtensionDefaultProcessor.swift
//  LarkNotificationServiceExtension
//
//  Created by mochangxing on 2019/9/3.
//

import Foundation
import NotificationUserInfo
import UserNotifications

public final class LarkNSExtensionDefaultProcessor: LarkNSExtensionContentProcessor {
    public init() {}

    public func transformNotificationExtra(with content: UNNotificationContent) -> Extra? {
        return nil
    }

    public func transformNotificationAlter(with content: UNNotificationContent) -> Alert? {
        return nil
    }
}
