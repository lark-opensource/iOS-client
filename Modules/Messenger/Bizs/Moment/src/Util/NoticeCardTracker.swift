//
//  NoticeCardTracker.swift
//  Moment
//
//  Created by liluobin on 2021/3/18.
//

import Foundation
import UIKit
import Homeric
import LKCommonsTracker

final class NoticeCardTracker {
    var displayMessage: [String: String] = [:]
    private var trackedMessageIds: Set<String> = Set()

    func trackNotificationCardView() {
        var toTraceMessageIds = Set(displayMessage.keys)
        toTraceMessageIds.subtract(trackedMessageIds)
        for messageId in toTraceMessageIds {
            trackedMessageIds.insert(messageId)
            Tracer.trackCommunityNotificationCardView(displayMessage[messageId] ?? "")
        }
    }
    func updateValue(key: String, value: RawData.NoticeType) {
        let valueStr: String
        switch value {
        case .unknown:
            valueStr = Tracer.NotificationCellType.unknown.rawValue
        case .follower:
            valueStr = Tracer.NotificationCellType.follow.rawValue
        case .postReaction:
            valueStr = Tracer.NotificationCellType.postReaction.rawValue
        case .commentReaction:
            valueStr = Tracer.NotificationCellType.commentReaction.rawValue
        case .comment:
            valueStr = Tracer.NotificationCellType.postReply.rawValue
        case .reply:
            valueStr = Tracer.NotificationCellType.commentReply.rawValue
        case .atInPost:
            valueStr = Tracer.NotificationCellType.postMention.rawValue
        case .atInComment:
            valueStr = Tracer.NotificationCellType.commentMention.rawValue
        }
        self.displayMessage.updateValue(valueStr, forKey: key)
    }
}
