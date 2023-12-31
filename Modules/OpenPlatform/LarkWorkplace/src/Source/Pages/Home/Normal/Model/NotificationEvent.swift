//
//  NotificationEvent.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/7/15.
//

import Foundation

enum WorkplaceNotificationEvent: String {
    case workplaceCommonAppDataChange
    /// 其他地方调用
    func postDataNeedUpdateNoti(anObject: Any? = nil) {
        NotificationCenter.default.post(name: notificationName(), object: anObject)
    }
    func notificationName() -> NSNotification.Name {
        return Notification.Name(rawValue: self.rawValue)
    }
}

typealias WPNoti = WorkplaceNotificationEvent
