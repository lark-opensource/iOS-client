//
//  MinutesDetailNotification.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/13.
//

extension Notification.Name {
    struct MinutesDetailNotification {
        static let kGoTopNotificationName = Notification.Name(rawValue: "com.minutes.detail.gotop")
        static let kSubtitleViewLeaveTopNotificationName = Notification.Name(rawValue: "com.minutes.detail.subtitle.leavetop")
        static let kInfoViewLeaveTopNotificationName = Notification.Name(rawValue: "com.minutes.detail.info.leavetop")
    }
}
