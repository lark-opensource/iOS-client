//
//  TimeFormatSingleDateTests.swift
//  CalendarDemoEEUnitTest
//
//  Created by Cai Miao on 2020/7/11.
//

import XCTest
@testable import LarkTimeFormatUtils
import LarkLocalizations

class TimeFormatSingleDateTests: XCTestCase {

    /// - Note: 影响到时间名词展示的变量有 time zone 和 locale

    var optionsOfShanghaiTimeZone: Options!
    var optionsOfLosAngelesTimeZone: Options!
    var expectedResult: String!
    // Wed, 1 Jul, 2020, 02:00:00 GMT
    let dateInHour = Date(timeIntervalSince1970: 1_593_568_800)
    // Wed, 1 Jul, 2020, 02:50:00 GMT
    let dateInMinute = Date(timeIntervalSince1970: 1_593_571_800)
    // Wed, 1 Jul, 2020, 02:50:55 GMT
    let dateInSecond = Date(timeIntervalSince1970: 1_593_571_855)

    // Tue, 30 Jun, 2020, 02:00:00 GMT
    let yesterday = Date(timeIntervalSince1970: 1_608_608_505)
    // Thu, 2 Jul, 2020, 02:00:00 GMT
    let tomorrow = Date(timeIntervalSince1970: 1_593_655_200)
    // Tue, 1 Sep, 2020, 02:00:00 GMT
    let otherDayInSameYear = Date(timeIntervalSince1970: 1_598_925_600)
    // Sat, 30 Oct, 2021, 02:00:00 GMT
    let otherDayInCrossYear = Date(timeIntervalSince1970: 1_635_559_200)

    // 上海 - GMT+8
    let timeZoneInShanghai = TimeZone(identifier: "Asia/Shanghai")!
    // 洛杉矶 - GMT-7
    let timeZoneInLosAngeles = TimeZone(identifier: "America/Los_Angeles")!

    override func setUp() {
        super.setUp()
        LanguageManager.supportLanguages = [
            .zh_CN,
            .en_US,
            .ja_JP,
            .de_DE,
            .es_ES,
            .fr_FR,
            .hi_IN,
            .id_ID,
            .it_IT,
            .ko_KR,
            .pt_BR,
            .ru_RU,
            .th_TH,
            .vi_VN
        ]
        optionsOfShanghaiTimeZone = Options(
            timeZone: timeZoneInShanghai
        )
        optionsOfLosAngelesTimeZone = Options(
            timeZone: timeZoneInLosAngeles
        )
    }

    func testFormatTime() {
        /// - Remark: TimeZone * is12HourStyle * timePrecisionType * shouldRemoveTrailingZeros = 24 cases

        // MARK: - en_US
        LanguageManager.setCurrent(language: .en_US, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - zh_CN
        LanguageManager.setCurrent(language: .zh_CN, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:00", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10点", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10点", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10点", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7点", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7点", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7点", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10点", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7点", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50:55", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10点", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7点", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50:55", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - ja_JP
        LanguageManager.setCurrent(language: .ja_JP, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:00", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10時", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10時", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10時", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7時", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7時", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7時", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:50", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10時", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7時", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:50", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:50:55", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10時", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7時", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後7:50:55", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - de_DE
        LanguageManager.setCurrent(language: .de_DE, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - es_ES
        LanguageManager.setCurrent(language: .es_ES, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 a. m.", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 p. m.", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 a. m.", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 p. m.", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 a. m.", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 p. m.", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 a. m.", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 p. m.", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 a. m.", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 p. m.", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 a. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 a. m.", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 p. m.", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 p. m.", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - Français
        LanguageManager.setCurrent(language: .fr_FR, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - हिन्दी
        LanguageManager.setCurrent(language: .hi_IN, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 पू", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 अ", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 पू", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 अ", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 पू", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 अ", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 पू", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 अ", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 पू", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 अ", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 पू", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 पू", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 अ", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 अ", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - id_ID
        LanguageManager.setCurrent(language: .id_ID, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - it_IT
        LanguageManager.setCurrent(language: .it_IT, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - ko_KR
        LanguageManager.setCurrent(language: .ko_KR, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:00", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10시", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10시", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10시", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7시", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7시", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7시", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:50", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10시", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7시", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:50", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:50:55", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10시", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전 10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7시", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후 7:50:55", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - pt_BR
        LanguageManager.setCurrent(language: .pt_BR, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - ru_RU
        LanguageManager.setCurrent(language: .ru_RU, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - th_TH
        LanguageManager.setCurrent(language: .th_TH, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 PM", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        // MARK: - vi_VN
        LanguageManager.setCurrent(language: .vi_VN, isSystem: false)
        // MARK: - 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 SA", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 CH", expectedResult)

        /// - Precondition: 12 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 SA", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 CH", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 SA", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 CH", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 SA", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 CH", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 SA", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 CH", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 SA", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 SA", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 CH", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 CH", expectedResult)

        // MARK: - 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到小时，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到小时，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .hour
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .hour
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        expectedResult = TimeFormatUtils.formatTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInMinute, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTime(from: dateInSecond, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55", expectedResult)
    }
}
