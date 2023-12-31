//
//  ReminderTest.swift
//  CalendarTests
//
//  Created by zhouyuan on 2018/11/26.
//  Copyright © 2018 EE. All rights reserved.
//

import XCTest
@testable import Calendar
import RustPB

func getMockCalendarEventReminder() -> CalendarEventReminder {
    var calendarEventReminder = CalendarEventReminder()
    calendarEventReminder.minutes = 15
    calendarEventReminder.calendarEventID = "123"
    calendarEventReminder.method = .popup
    return calendarEventReminder
}

class ReminderTest: XCTestCase {

    var calendarEventReminder: CalendarEventReminder!
    override func setUp() {
        super.setUp()
        calendarEventReminder = getMockCalendarEventReminder()
    }

    override func tearDown() {
        super.tearDown()
        calendarEventReminder = nil
    }

    func testNormal() {
        do {
            calendarEventReminder.minutes = 0
            let reminder = Reminder(pb: calendarEventReminder, isAllDay: false)
            XCTAssertEqual(CalendarEventReminder.Method.popup, reminder.toPB().method)
            XCTAssertEqual(BundleI18n.Calendar.Calendar_AlertTime_AtTimeOfEvent,
                           reminder.reminderString(is12HourStyle: false))
        }
        do {
            let reminder = Reminder(minutes: 30, isAllDay: false)
            let pb = reminder.toPB()
            XCTAssertEqual(30, pb.minutes)
            XCTAssertEqual(CalendarEventReminder.Method.popup, pb.method)
            XCTAssertEqual("", pb.calendarEventID)
        }
    }

}
