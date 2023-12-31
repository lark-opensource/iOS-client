//
//  DateTimeTest.swift
//  CalendarTests
//
//  Created by linlin on 2017/12/19.
//  Copyright © 2017年 EE. All rights reserved.
//

import XCTest
@testable import Calendar
@testable import CalendarFoundation
class DateTimeTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGetWholeDayRange() {
        let dayTimeFormatter = DateFormatter()
        dayTimeFormatter.dateFormat = "YYYYMMdd HH:mm:ss"
        let date = dayTimeFormatter.date(from: "20171215 15:00:00")
        XCTAssertNotNil(date)

        let start = date?.dayStart()
        let end = date?.dayEnd()

        XCTAssertNotNil(start)
        XCTAssertNotNil(end)
        let startStr = dayTimeFormatter.string(from: start!)
        let endStr = dayTimeFormatter.string(from: end!)

        XCTAssertEqual(startStr, "20171215 00:00:00")
        XCTAssertEqual(endStr, "20171215 23:59:59")

    }

    func testDateByOffset() {
        let dayTimeFormatter = DateFormatter()
        dayTimeFormatter.dateFormat = "YYYYMMdd HH:mm:ss"

        let date = dayTimeFormatter.date(from: "20171215 00:00:00")

        let result = date! + 1.day
        XCTAssertNotNil(result)

        let offsetDateStr = dayTimeFormatter.string(from: result!)
        XCTAssertEqual(offsetDateStr, "20171216 00:00:00")
    }

    func testGradientTimeByDayTime() {
        let dayTimeFormatter = DateFormatter()
        dayTimeFormatter.dateFormat = "YYYYMMdd HH:mm:ss"
        let currentCalendar = Calendar(identifier: .gregorian)

        let date = dayTimeFormatter.date(from: "20171215 00:00:00")

        let currentDate = dayTimeFormatter.date(from: "20171216 12:25:45")

        let result = gradientTimeBy(day: date!, time: currentDate!)
        let timeCom = currentCalendar.dateComponents([.hour, .minute, .second], from: result)

        XCTAssertNotNil(result)
        XCTAssertEqual(timeCom.minute, 30)
        XCTAssertEqual(timeCom.second, 0)

        let currentDate1 = dayTimeFormatter.date(from: "20171216 12:31:45")
        let result1 = gradientTimeBy(day: date!, time: currentDate1!)
        let timeCom1 = currentCalendar.dateComponents([.hour, .minute, .second], from: result1)

        XCTAssertNotNil(result1)
        XCTAssertEqual(timeCom1.minute, 00)
        XCTAssertEqual(timeCom1.hour, 13)
        XCTAssertEqual(timeCom1.second, 0)

    }

    func testDaysOfWeek() {
        XCTAssertEqual(DaysOfWeek.sunday.next(), DaysOfWeek.monday)
        XCTAssertEqual(DaysOfWeek.monday.next(), DaysOfWeek.tuesday)
        XCTAssertEqual(DaysOfWeek.tuesday.next(), DaysOfWeek.wednesday)
        XCTAssertEqual(DaysOfWeek.wednesday.next(), DaysOfWeek.thursday)
        XCTAssertEqual(DaysOfWeek.thursday.next(), DaysOfWeek.friday)
        XCTAssertEqual(DaysOfWeek.friday.next(), DaysOfWeek.saturday)
        XCTAssertEqual(DaysOfWeek.saturday.next(), DaysOfWeek.sunday)
    }

}
