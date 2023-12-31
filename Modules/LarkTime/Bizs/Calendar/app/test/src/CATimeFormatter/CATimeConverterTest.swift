////
////  CATimeConverterTest.swift
////  CalendarTests
////
////  Created by jiayi zou on 2018/11/8.
////  Copyright © 2018 EE. All rights reserved.
////
//
//import XCTest
//@testable import Calendar
//@testable import CalendarFoundation
//// swiftlint:disable number_separator
//class CATimeConverterTest: XCTestCase {
//
//    func testSDKAllDay() {
//        let startTime = Date(timeIntervalSince1970: 1541635200) // 2018 Nov 8, 0:0:0 GMT
//        let endTime = Date(timeIntervalSince1970: 1541721600) // 2018 Nov 9, 0:0:0 GMT
//        let result = CATimeFormatterComponents.correct(startTime: startTime,
//                                                       endTime: endTime)
//        let expectedResult = (startTime: Date(timeIntervalSince1970: 1541606400), //2018 Nov 8 0:0:0 Asia/ShangHai
//            endTime: Date(timeIntervalSince1970: 1541692799))   //2018 Nov 8 23:59:59 Asia/ShangHai
//        XCTAssertEqual(result.startTime, expectedResult.startTime)
//        XCTAssertEqual(result.endTime, expectedResult.endTime)
//
//        let est = TimeZone(identifier: "EST")
//        let estResult = CATimeFormatterComponents.correct(startTime: startTime,
//                                                   endTime: endTime,
//                                                   to: est!)
//        let expectedEstResult = (startTime: Date(timeIntervalSince1970: 1541653200), //2018 Nov 8 0:0:0 EST
//            endTime: Date(timeIntervalSince1970: 1541739599))   //2018 Nov 8 23:59:59 EST
//        XCTAssertEqual(estResult.startTime, expectedEstResult.startTime)
//        XCTAssertEqual(estResult.endTime, expectedEstResult.endTime)
//    }
//
//    func testiOSAllDay() {
//        let startTime = Date(timeIntervalSince1970: 1541606400) //2018 Nov 8 0:0:0 Asia/ShangHai
//        let endTime = Date(timeIntervalSince1970: 1541692799)   //2018 Nov 8 23:59:59 Asia/ShangHai
//        let result = CATimeFormatterComponents.correct(startTime: startTime,
//                                                       endTime: endTime)
//        let expectedResult = (startTime: Date(timeIntervalSince1970: 1541606400), //2018 Nov 8 0:0:0 Asia/ShangHai
//            endTime: Date(timeIntervalSince1970: 1541692799))   //2018 Nov 8 23:59:59 Asia/ShangHai
//        XCTAssertEqual(result.startTime, expectedResult.startTime)
//        XCTAssertEqual(result.endTime, expectedResult.endTime)
//    }
//}
