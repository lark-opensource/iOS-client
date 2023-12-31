//
//  CalendarContent.swift
//  NotificationUserInfo
//
//  Created by 姚启灏 on 2018/12/18.
//

import Foundation

public struct CalendarContent: PushContent {
    public init?(dict: [String: Any]) {
        guard let url = dict["url"] as? String,
            let key = dict["key"] as? String,
            let calendarId = dict["calendarId"] as? String,
            let originalTime = dict["originalTime"] as? Int64,
            let eventId = dict["eventId"] as? Int32,
            let alarmString = dict["alarmString"] as? String,
            let sysEventIdentifier = dict["sysEventIdentifier"] as? String else {
            return nil
        }

        self.url = url
        self.key = key
        self.calendarId = calendarId
        self.originalTime = originalTime
        self.eventId = eventId
        self.alarmString = alarmString
        self.sysEventIdentifier = sysEventIdentifier
    }

    public func toDict() -> [String: Any] {
        let result: [String: Any] = ["url": url,
                                     "calendarId": calendarId,
                                     "key": key,
                                     "originalTime": originalTime,
                                     "eventId": eventId,
                                     "alarmString": alarmString,
                                     "sysEventIdentifier": sysEventIdentifier]
        return result
    }

    enum CalNotificaionUserInfoError: Error {
        case invaildData
    }

    public var url: String
    public var calendarId: String
    public var key: String
    public var originalTime: Int64
    public var eventId: Int32
    public var alarmString: String
    public var sysEventIdentifier: String

    public init(
        calendarId: String,
        key: String,
        originalTime: Int64,
        eventId: Int32,
        alarmString: String,
        sysEventIdentifier: String = "") {
        //swiftlint:disable line_length
        let urlStr = "//client/calendar/event/detail?calendarId=\(calendarId)&eventKey=\(key)&originalTime=\(originalTime)&sysEventIdentifier=\(sysEventIdentifier)&isFromAPNS=true"
        //swiftlint:enable line_length
        self.url = urlStr
        self.calendarId = calendarId
        self.key = key
        self.originalTime = originalTime
        self.eventId = eventId
        self.alarmString = alarmString
        self.sysEventIdentifier = sysEventIdentifier
    }
}
