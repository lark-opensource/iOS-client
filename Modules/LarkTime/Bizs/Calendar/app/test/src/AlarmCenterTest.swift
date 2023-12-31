//
//  AlarmCenterTest.swift
//  CalendarTests
//
//  Created by zhuchao on 2019/1/28.
//  Copyright © 2019 EE. All rights reserved.
//

import XCTest
@testable import Calendar
import EENotification
import NotificationUserInfo

class AlarmCenterTest: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testKey() {
        XCTAssertEqual(CalendarAlarmCenter.sdkReminderKey, "calendarEventReminder")
        XCTAssertEqual(SysAlarm.sysReminderKey, "calendarSystemEventReminder")
    }

    func testNotificationId() {
        let eventId = "123"
        let startTime = "456"
        let minutes = "60"
        let id = CalendarAlarmCenter.notificationId(by: eventId, startTime: startTime)
        XCTAssertEqual(id, "Calendar_\(eventId)_\(startTime)")
        let id2 = CalendarAlarmCenter.notificationId(by: eventId, startTime: startTime, minutes: minutes)
        XCTAssertEqual(id2, "Calendar_\(eventId)_\(startTime)_\(minutes)")

    }

//    func testRemoveNotification() {
//        let sdkRequest = NotificationRequest(group: CalendarAlarmCenter.sdkReminderKey,
//                                             identifier: "",
//                                             userInfo: [:],
//                                             trigger: nil)
//        let localRequest = NotificationRequest(group: CalendarAlarmCenter.sysReminderKey,
//                                               identifier: "",
//                                               userInfo: [:],
//                                               trigger: nil)
//        NotificationManager.shared.addOrUpdateNotifications(requests: [sdkRequest, localRequest])
//        NotificationManager.shared.getAllNotifications { (notifications) in
//            XCTAssertFalse(notifications.isEmpty)
//            XCTAssertNotNil(notifications.first(where: { $0.group == CalendarAlarmCenter.sdkReminderKey }))
//            XCTAssertNotNil(notifications.first(where: { $0.group == CalendarAlarmCenter.sysReminderKey }))
//            CalendarAlarmCenter.removeAllSysNotification()
//            CalendarAlarmCenter.removeAllLocalNotification()
//            NotificationManager.shared.getAllNotifications { (notifications) in
//                XCTAssertTrue(notifications.isEmpty)
//            }
//        }
//    }
}
