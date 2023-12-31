//
//  DurationSelectionModeTest.swift
//  CalendarDemoEEUnitTest
//
//  Created by harry zou on 2019/4/29.
//

import XCTest
//@testable import Calendar
//
//class DurationSelectionModeTest: XCTestCase {
//
//    override func setUp() {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//    func testExample() {
//        let startTime: Int = 1_556_528_403  //2019/4/29 17:0:3
//        var endTime: Int = 1_556_531_028 //2019/4/29 17:43:48
//        var model = DurationSelectionModel(startTime: startTime, nextUnavailableTime: endTime)
//        let result: [TimeInterval] = [1_556_530_200, 1_556_531_028]
//        XCTAssertEqual(model.endTimes, result)
//
//        endTime = 1_556_528_405 // 2019/4/29 17:0:5
//        model = DurationSelectionModel(startTime: startTime, nextUnavailableTime: endTime)
//        let result2: [TimeInterval] = [1_556_528_405]
//        XCTAssertEqual(model.reloadEndTimes(), result2)
//
//        endTime = 1_556_529_480 // 2019/4/29 17:18:0
//        model = DurationSelectionModel(startTime: startTime, nextUnavailableTime: endTime)
//        let result3: [TimeInterval] = [1_556_529_480]
//        XCTAssertEqual(model.reloadEndTimes(), result3)
//
//        endTime = 12_345_678_975 // 2361/3/22 3:16:15
//        model = DurationSelectionModel(startTime: startTime, nextUnavailableTime: endTime)
//        XCTAssertEqual(model.reloadEndTimes().count, 27)
//        XCTAssertEqual(model.reloadEndTimes().last, 1_556_553_540) // 2019/4/29 23:59:00
//    }
//}
