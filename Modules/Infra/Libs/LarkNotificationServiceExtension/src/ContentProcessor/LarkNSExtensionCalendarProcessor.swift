//
//  LarkNSExtensionCalendarProcessor.swift
//  LarkNotificationServiceExtension
//
//  Created by heng zhu on 2020/1/4.
//

import Foundation
import NotificationUserInfo
import UserNotifications

public final class LarkNSExtensionCalendarProcessor: LarkNSExtensionContentProcessor {
    public init() {}

    public func transformNotificationExtra(with content: UNNotificationContent) -> Extra? {
        guard let extra = LarkNSECalendarExtra.getCalendarExtra(from: content.userInfo),
            let newMessageData = extra.data as? LarkNSECalendarExtra.NewMessageData else {
                return nil
        }

        /// 打开日程详情
        return Extra(type: .calendar, content: CalendarContent(calendarId: newMessageData.calendarId,
                                                               key: newMessageData.key,
                                                               originalTime: newMessageData.originalTime,
                                                               eventId: 0,
                                                               alarmString: ""))
    }

    public func transformNotificationAlter(with content: UNNotificationContent) -> Alert? {
        return Alert(title: content.title, subtitle: content.subtitle, body: content.body)
    }
}

protocol LarkNSECalendarData {

}

// MARK: - LarkNSECalendarExtra
struct LarkNSECalendarExtra {
    struct NewMessageData: LarkNSECalendarData {
        let calendarId: String
        let key: String
        let originalTime: Int64
    }

    var data: LarkNSECalendarData?

    public init?(dict: [String: Any]) {
        if let calendarId = dict["CalendarId"] as? String,
            let key = dict["Uid"] as? String {
            let originalTime = dict["OriginalTime"] as? String ?? "0"
            self.data = NewMessageData(calendarId: calendarId,
                                       key: key,
                                       originalTime: Int64(originalTime) ?? 0)
        }
    }

    static func getCalendarExtra(from userInfo: [AnyHashable: Any]) -> LarkNSECalendarExtra? {
        /// get extra_str
        guard let extraString = LarkNSEExtra.getExtraDict(from: userInfo)?.extraString else {
            return nil
        }
        /// get Calendar extra
        if let data = extraString.data(using: .utf8) {
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    return nil
                }
                return LarkNSECalendarExtra(dict: dict)
            } catch {
            }
        }
        return nil
    }
}
