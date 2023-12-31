//
//  testString+Calendar.swift
//  CalendarTests
//
//  Created by jiayi zou on 2018/5/29.
//  Copyright © 2018年 EE. All rights reserved.
//

import XCTest
@testable import Calendar

//class testString_Calendar: XCTestCase {
//    override func setUp() {
//        super.setUp()
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        super.tearDown()
//    }
//
//    func testGetTimeString() {
//        let date = Date(timeIntervalSince1970: 1527580010)
//        let dateTwo = date.addingTimeInterval(86401)
//        let dateThree = date.addingTimeInterval(60)
//        var isAllDay = true
//        var string = getTimeString(startDate: date, endDate: dateTwo, isAllDayEvent: isAllDay)
//        XCTAssertEqual(string, "2018 May 29 Tue - 2018 May 30 Wed")
//        string = getTimeString(startDate: date, endDate: dateThree, isAllDayEvent: isAllDay)
//        XCTAssertEqual(string, "2018 May 29 Tue")
//        isAllDay = false
//        string = getTimeString(startDate: date, endDate: dateTwo, isAllDayEvent: isAllDay)
//        XCTAssertEqual(string, "2018 May 29 Tue 15:46 - 2018 May 30 Wed 15:46 (GMT+8)")
//        string = getTimeString(startDate: date, endDate: dateThree, isAllDayEvent: isAllDay)
//        XCTAssertEqual(string, "2018 May 29 Tue 15:46 - 15:47 (GMT+8)")
//    }
//
//}
