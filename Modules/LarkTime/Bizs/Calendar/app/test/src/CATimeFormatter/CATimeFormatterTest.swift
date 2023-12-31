////
////  CATimeFormatterTest.swift
////  CalendarTests
////
////  Created by jiayi zou on 2018/11/5.
////  Copyright © 2018 EE. All rights reserved.
////
//
//import XCTest
//@testable import Calendar
//import LarkLocalizations
//@testable import CalendarFoundation
//// swiftlint:disable number_separator
//class CATimeFormatterTest: XCTestCase {
//    typealias CATimeFormatterForTest = CATimeFormatter
//
//    ///  这个逻辑极其不完善，仅供测试使用
//    ///
//    /// - Returns: 是否使用英文字符串
//    func shouldUseEnus() -> Bool {
//        return LanguageManager.current == .en_US
//    }
//
//    func normalNonAlldayStringResultString() -> String {
//        if shouldUseEnus() {
//            return "Today, Nov 5, 10:00 - 11:30 (GMT+8)"
//        } else {
//            return "11月5日 (今天) 10:00 - 11:30 (GMT+8)"
//        }
//    }
//
//    func testNormalNonAlldayString() {
//        let startTime = Date(timeIntervalSince1970: 1541383200) // 2018 11 5 10:0:0 GMT+8
//        let endTime = Date(timeIntervalSince1970: 1541388600) //2018 11 5 11:30:00 GMT+8
//        let displayTime = Date(timeIntervalSince1970: 1541410200) //2018 11 5 17:30:00 GMT+8
//        let isAllDay = false
//        let components = CATimeFormatterComponents(startTime: startTime,
//                                                   endTime: endTime,
//                                                   isAllDay: isAllDay,
//                                                   displayTime: displayTime, is12HourStyle: false)
//        let formattedString = CATimeFormatterForTest.startAndEndTimeString(components: components)
//        let resultString = normalNonAlldayStringResultString()
//        XCTAssertEqual(formattedString, resultString)
//    }
//
//    func normalAllDayStringResult() -> String {
//        if shouldUseEnus() {
//            return "Today, Nov 5"
//        } else {
//            return "11月5日 (今天)"
//        }
//    }
//
//    func testNormalAllDayString() {
//        let startTime = Date(timeIntervalSince1970: 1541347200) // 2018 11 5 0:0:0 GMT+8
//        let endTime = Date(timeIntervalSince1970: 1541433599) //2018 11 5 23:59:59 GMT+8
//        let displayTime = Date(timeIntervalSince1970: 1541410200) //2018 11 5 17:30:00 GMT+8
//        let isAllDay = true
//        let components = CATimeFormatterComponents(startTime: startTime,
//                                                   endTime: endTime,
//                                                   isAllDay: isAllDay,
//                                                   displayTime: displayTime, is12HourStyle: false)
//        let formattedString = CATimeFormatterForTest.startAndEndTimeString(components: components)
//        let resultString = normalAllDayStringResult()
//        XCTAssertEqual(formattedString, resultString)
//    }
//
//    func moreThanOneDayNonAllDayStringResult() -> String {
//        if shouldUseEnus() {
//            return "Today, Nov 5, 10:00 - \nTomorrow, Nov 6, 11:30 (GMT+8)"
//        } else {
//            return "11月5日 (今天) 10:00 - \n11月6日 (明天) 11:30 (GMT+8)"
//        }
//    }
//
//    func testMoreThanOneDayNonAllDayString() {
//        let startTime = Date(timeIntervalSince1970: 1541383200) // 2018 11 5 10:0:0 GMT+8
//        let endTime = Date(timeIntervalSince1970: 1541475000) //2018 11 6 11:30:00 GMT+8
//        let displayTime = Date(timeIntervalSince1970: 1541410200) //2018 11 5 17:30:00 GMT+8
//        let isAllDay = false
//        let components = CATimeFormatterComponents(startTime: startTime,
//                                                   endTime: endTime,
//                                                   isAllDay: isAllDay,
//                                                   displayTime: displayTime, is12HourStyle: false)
//        let formattedString = CATimeFormatterForTest.startAndEndTimeString(components: components)
//        let resultString = moreThanOneDayNonAllDayStringResult()
//        XCTAssertEqual(formattedString, resultString)
//    }
//
//    func moreThanOneDayAllDayStringResult() -> String {
//        if shouldUseEnus() {
//            return "Yesterday, Nov 4 - Tomorrow, Nov 6"
//        } else {
//            return "11月4日 (昨天) - 11月6日 (明天)"
//        }
//    }
//
//    func testMoreThanOneDayAllDayString() {
//        let startTime = Date(timeIntervalSince1970: 1541260800) // 2018 11 4 0:0:0 GMT+8
//        let endTime = Date(timeIntervalSince1970: 1541519999) //2018 11 5 23:59:59 GMT+8
//        let displayTime = Date(timeIntervalSince1970: 1541410200) //2018 11 5 17:30:00 GMT+8
//        let isAllDay = true
//        let components = CATimeFormatterComponents(startTime: startTime,
//                                                   endTime: endTime,
//                                                   isAllDay: isAllDay,
//                                                   displayTime: displayTime, is12HourStyle: false)
//        let formattedString = CATimeFormatterForTest.startAndEndTimeString(components: components)
//        let resultString = moreThanOneDayAllDayStringResult()
//        XCTAssertEqual(formattedString, resultString)
//    }
//
//    func dateBeforeYesterdayAndDateAfterTomorrowResult() -> String {
//        if shouldUseEnus() {
//            return "Sat, Nov 3 - Wed, Nov 7"
//        } else {
//            return "11月3日 (周六) - 11月7日 (周三)"
//        }
//    }
//
//    func testDateBeforeYesterdayAndDateAfterTomorrow() {
//        let startTime = Date(timeIntervalSince1970: 1541174400) // 2018 11 3 0:0:0 GMT+8
//        let endTime = Date(timeIntervalSince1970: 1541606399) //2018 11 7 23:59:59 GMT+8
//        let displayTime = Date(timeIntervalSince1970: 1541410200) //2018 11 5 17:30:00 GMT+8
//        let isAllDay = true
//        let components = CATimeFormatterComponents(startTime: startTime,
//                                                   endTime: endTime,
//                                                   isAllDay: isAllDay,
//                                                   displayTime: displayTime, is12HourStyle: false)
//        let formattedString = CATimeFormatterForTest.startAndEndTimeString(components: components)
//        let resultString = dateBeforeYesterdayAndDateAfterTomorrowResult()
//        XCTAssertEqual(formattedString, resultString)
//    }
//
//    func nonAlldayTodayStartTimeStringResult() -> String {
//        if shouldUseEnus() {
//            return "Today, 10:00 (GMT+8)"
//        } else {
//            return "今天 10:00 (GMT+8)"
//        }
//    }
//
//    func testNonTodayAlldayStartTimeString() {
//        let startTime = Date(timeIntervalSince1970: 1541383200) // 2018 11 5 10:0:0 GMT+8
//        let endTime = Date(timeIntervalSince1970: 1541388600) //2018 11 5 11:30:00 GMT+8
//        let displayTime = Date(timeIntervalSince1970: 1541410200) //2018 11 5 17:30:00 GMT+8
//        let isAllDay = false
//        let components = CATimeFormatterComponents(startTime: startTime,
//                                                   endTime: endTime,
//                                                   isAllDay: isAllDay,
//                                                   displayTime: displayTime, is12HourStyle: false)
//        let formattedString = CATimeFormatterForTest.startTimeString(components: components)
//        let resultString = nonAlldayTodayStartTimeStringResult()
//        XCTAssertEqual(formattedString, resultString)
//    }
//
//    func nonAlldayStartTimeStringResult() -> String {
//        if shouldUseEnus() {
//            return "Tomorrow, Nov 6, 10:00 (GMT+8)"
//        } else {
//            return "11月6日 (明天) 10:00 (GMT+8)"
//        }
//    }
//
//    func testNonAlldayStartTimeString() {
//        let startTime = Date(timeIntervalSince1970: 1541469600) // 2018 11 6 10:0:0 GMT+8
//        let endTime = Date(timeIntervalSince1970: 1541496600) // 2018 11 6 17:30:00 GMT+8
//        let displayTime = Date(timeIntervalSince1970: 1541388600) // 2018 11 5 11:30:00 GMT+8
//        let isAllDay = false
//        let components = CATimeFormatterComponents(startTime: startTime,
//                                                   endTime: endTime,
//                                                   isAllDay: isAllDay,
//                                                   displayTime: displayTime, is12HourStyle: false)
//        let formattedString = CATimeFormatterForTest.startTimeString(components: components)
//        let resultString = nonAlldayStartTimeStringResult()
//        XCTAssertEqual(formattedString, resultString)
//    }
//
//    func alldayStartTimeStringResult() -> String {
//        if shouldUseEnus() {
//            return "Sat, Nov 3"
//        } else {
//            return "11月3日 (周六)"
//        }
//    }
//
//    func testAlldayStartTimeString() {
//        let startTime = Date(timeIntervalSince1970: 1541174400) // 2018 11 3 0:0:0 GMT+8
//        let endTime = Date(timeIntervalSince1970: 1541606399) //2018 11 7 23:59:59 GMT+8
//        let displayTime = Date(timeIntervalSince1970: 1541410200) //2018 11 5 17:30:00 GMT+8
//        let isAllDay = true
//        let components = CATimeFormatterComponents(startTime: startTime,
//                                                   endTime: endTime,
//                                                   isAllDay: isAllDay,
//                                                   displayTime: displayTime, is12HourStyle: false)
//        let formattedString = CATimeFormatterForTest.startTimeString(components: components)
//        let resultString = alldayStartTimeStringResult()
//        XCTAssertEqual(formattedString, resultString)
//    }
//
//    func overYearNonAlldayStringResult() -> String {
//        if shouldUseEnus() {
//            return "Sun, Nov 5, 2017, 10:00 - \nToday, Nov 5, 2018, 11:30 (GMT+8)"
//        } else {
//            return "2017年11月5日 (周日) 10:00 - \n2018年11月5日 (今天) 11:30 (GMT+8)"
//        }
//    }
//
//    func testOverYearNonAlldayString() {
//        let startTime = Date(timeIntervalSince1970: 1509847200) // 2017 11 5 10:0:0 GMT+8
//        let endTime = Date(timeIntervalSince1970: 1541388600) //2018 11 5 11:30:00 GMT+8
//        let displayTime = Date(timeIntervalSince1970: 1541410200) //2018 11 5 17:30:00 GMT+8
//        let isAllDay = false
//        let components = CATimeFormatterComponents(startTime: startTime,
//                                                   endTime: endTime,
//                                                   isAllDay: isAllDay,
//                                                   displayTime: displayTime, is12HourStyle: false)
//        let formattedString = CATimeFormatterForTest.startAndEndTimeString(components: components)
//        let resultString = overYearNonAlldayStringResult()
//        XCTAssertEqual(formattedString, resultString)
//    }
//
//    func overYearNonAlldayStringInOneLineResult() -> String {
//        if shouldUseEnus() {
//            return "Sun, Nov 5, 2017, 10:00 - Today, Nov 5, 2018, 11:30 (GMT+8)"
//        } else {
//            return "2017年11月5日 (周日) 10:00 - 2018年11月5日 (今天) 11:30 (GMT+8)"
//        }
//    }
//
//    func testOverYearNonAlldayInOneLineString() {
//        let startTime = Date(timeIntervalSince1970: 1509847200) // 2017 11 5 10:0:0 GMT+8
//        let endTime = Date(timeIntervalSince1970: 1541388600) //2018 11 5 11:30:00 GMT+8
//        let displayTime = Date(timeIntervalSince1970: 1541410200) //2018 11 5 17:30:00 GMT+8
//        let isAllDay = false
//        let components = CATimeFormatterComponents(startTime: startTime,
//                                                   endTime: endTime,
//                                                   isAllDay: isAllDay,
//                                                   shouldInOneLine: true,
//                                                   displayTime: displayTime, is12HourStyle: false)
//        let formattedString = CATimeFormatterForTest.startAndEndTimeString(components: components)
//        let resultString = overYearNonAlldayStringInOneLineResult()
//        XCTAssertEqual(formattedString, resultString)
//    }
//
//    func overYearAllDayStringResult() -> String {
//        if shouldUseEnus() {
//            return "Yesterday, Nov 4, 2018 - Wed, Nov 6, 2019"
//        } else {
//            return "2018年11月4日 (昨天) - 2019年11月6日 (周三)"
//        }
//    }
//
//    func testOverYearAllDayString() {
//        let startTime = Date(timeIntervalSince1970: 1541260800) // 2018 11 4 0:0:0 GMT+8
//        let endTime = Date(timeIntervalSince1970: 1573055999) //2019 11 6 23:59:59 GMT+8
//        let displayTime = Date(timeIntervalSince1970: 1541410200) //2018 11 5 17:30:00 GMT+8
//        let isAllDay = true
//        let components = CATimeFormatterComponents(startTime: startTime,
//                                                   endTime: endTime,
//                                                   isAllDay: isAllDay,
//                                                   displayTime: displayTime, is12HourStyle: false)
//        let formattedString = CATimeFormatterForTest.startAndEndTimeString(components: components)
//        let resultString = overYearAllDayStringResult()
//        XCTAssertEqual(formattedString, resultString)
//    }
//
//    func test24HourFormat() {
//        let date = Date(timeIntervalSince1970: 0)
//        let a = date.string(with: "HH:mm",
//                            isFor12Hour: false,
//                            localeIdentifier: "en_US",
//                            trimTailingZeros: false) { (formatter) in
//                                formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        }
//        XCTAssertEqual("00:00", a)
//
//        let b = date.string(with: "HH:mm",
//                            isFor12Hour: false,
//                            localeIdentifier: "zh_CN",
//                            trimTailingZeros: false) { (formatter) in
//                                formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        }
//        XCTAssertEqual("00:00", b)
//
//        let c = date.string(with: "HH:mm",
//                            isFor12Hour: false,
//                            localeIdentifier: "ja_JP",
//                            trimTailingZeros: false) { (formatter) in
//                                formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        }
//        XCTAssertEqual("00:00", c)
//
//        let d = date.string(with: "HH:mm",
//                            isFor12Hour: true,
//                            localeIdentifier: "en_US",
//                            trimTailingZeros: false) { (formatter) in
//                                formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        }
//        XCTAssertEqual("12:00 AM", d)
//    }
//
//    func test12HourFormat() {
//        let date = Date(timeIntervalSince1970: 0)
//        let a = date.string(with: "HH:mm",
//                            isFor12Hour: true,
//                            localeIdentifier: "en_US",
//                            trimTailingZeros: false) { (formatter) in
//                                formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        }
//        XCTAssertEqual("12:00 AM", a)
//
//        let b = date.string(with: "HH:mm",
//                            isFor12Hour: true,
//                            localeIdentifier: "zh_CN",
//                            trimTailingZeros: false) { (formatter) in
//                                formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        }
//        XCTAssertEqual("上午12:00", b)
//
//        let c = date.string(with: "HH:mm",
//                            isFor12Hour: true,
//                            localeIdentifier: "ja_JP",
//                            trimTailingZeros: false) { (formatter) in
//                                formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        }
//        XCTAssertEqual("午前12:00", c)
//    }
//
//    func test12HourTrim() {
//        let date = Date(timeIntervalSince1970: 0)
//        let a = date.string(with: "HH:mm",
//                            isFor12Hour: true,
//                            localeIdentifier: "en_US",
//                            trimTailingZeros: true,
//                            tailingClock: "") { (formatter) in
//                                formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        }
//        XCTAssertEqual("12 AM", a)
//
//        let b = date.string(with: "HH:mm",
//                            isFor12Hour: true,
//                            localeIdentifier: "zh_CN",
//                            trimTailingZeros: true,
//                            tailingClock: "点") { (formatter) in
//                                formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        }
//        XCTAssertEqual("上午12点", b)
//
//        let c = date.string(with: "HH:mm",
//                            isFor12Hour: true,
//                            localeIdentifier: "ja_JP",
//                            trimTailingZeros: true,
//                            tailingClock: "時") { (formatter) in
//                                formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        }
//        XCTAssertEqual("午前12時", c)
//    }
//
//    func testMeasure12HourTrim() {
//        let date = Date(timeIntervalSince1970: 0)
//        measure {
//            _ = date.string(with: "HH:mm",
//                                isFor12Hour: true,
//                                localeIdentifier: "zh_CN",
//                                trimTailingZeros: true,
//                                tailingClock: "点") { (formatter) in
//                                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
//            }
//        }
//    }
//}
