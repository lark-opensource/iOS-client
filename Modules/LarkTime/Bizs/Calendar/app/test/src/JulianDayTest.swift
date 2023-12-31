//
//  JulianDayTest.swift
//  CalendarDemoEEUnitTest
//
//  Created by heng zhu on 2020/2/28.
//

import XCTest

@testable import Calendar
@testable import CalendarFoundation
class JulianDayTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testChangeJulianDay() {

        var date = Date()
        for i in 1...400 * 24 {
            date.addTimeInterval(TimeInterval(i * 60 * 60))
            let testDay = getDate(julianDay: getJulianDay(date: date))

            XCTAssert(date.isInSameDay(testDay), "error")
        }

    }

}
