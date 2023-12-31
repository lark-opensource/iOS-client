//
//  LarkNSExtensionBadgeProcessor.swift
//  LarkNotificationServiceExtension
//
//  Created by mochangxing on 2019/8/29.
//

import Foundation
import UserNotifications
import LarkExtensionServices
import NotificationUserInfo

final class LarkNSExtensionBadgeProcessor {

    static func updateBadge(_ badge: Int) {
        var newBadge = badge
        if let oldBadge = LarkBadgeNumberUpdater.getBadgeNumber() {
            newBadge += oldBadge
        }

        LarkBadgeNumberUpdater.updateBadgeNumber(newBadge) { success in
            LarkNSELogger.logger.info("[Lark]: updateBadgeNumber \(newBadge) : \(success)")
        }
    }

    static func processBadge(_ bestAttemptContent: UNMutableNotificationContent, extra: LarkNSEExtra) {
        LarkNSELogger.logger.info("ProcessBadge mutableBadge : \(extra.mutableBadge), notIncreaceBadge: \(extra.notIncreaceBadge)")
        guard extra.mutableBadge, !extra.notIncreaceBadge else {
            let category: [String: Any] = ["Sid": extra.Sid,
                            "messageId": extra.messageID ?? "",
                            "mutableBadge": extra.mutableBadge,
                            "notIncreaceBadge": extra.notIncreaceBadge]
            ExtensionTracker.shared.trackSlardarEvent(key: "APNs_set_badge_error", metric: [:], category: category, params: [:])
            return
        }
        updateBadge(1)
        if let badge = LarkBadgeNumberUpdater.getBadgeNumber() {
            bestAttemptContent.badge = badge as NSNumber
        }
        let category: [String: Any] = ["Sid": extra.Sid, "messageId": extra.messageID ?? ""]
        ExtensionTracker.shared.trackSlardarEvent(key: "APNs_set_badge", metric: [:], category: category, params: [:])
    }
}
