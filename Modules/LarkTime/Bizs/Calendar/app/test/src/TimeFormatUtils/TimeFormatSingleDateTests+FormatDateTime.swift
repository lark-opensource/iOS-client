//
//  TimeFormatSingleDateTests+FormatDateTime.swift
//  CalendarDemoEEUnitTest
//
//  Created by 蔡妙 on 2020/7/20.
//

import XCTest
@testable import LarkTimeFormatUtils
import LarkLocalizations

extension TimeFormatSingleDateTests {

    func testFormatDateTime() {
        /// - Note: 默认英文环境下测，这部分测试不需要考虑语言的因素
        /// - Remark: TimeZone * is12HourStyle * timePrecisionType * timeFormatType * shouldRemoveTrailingZeros = 48 cases
        LanguageManager.setCurrent(language: .en_US, isSystem: false)

        // MARK: - 12-hour Time & dateStatusType = .absolute
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: 12 小时制，精确到秒，不需要简化 0，long 类型
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jun 30, 2020, 10:00 AM", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1, 2020, 10:00 AM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 2, 2020, 10:00 AM", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sep 1, 2020, 10:00 AM", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Oct 30, 2021, 10:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 29, 2020, 7:00 PM", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30, 2020, 7:00 PM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jul 1, 2020, 7:00 PM", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Aug 31, 2020, 7:00 PM", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Oct 29, 2021, 7:00 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0，short 类型
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jun 30, 10:00 AM", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1, 10:00 AM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 2, 10:00 AM", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sep 1, 10:00 AM", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Oct 30, 10:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 29, 7:00 PM", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30, 7:00 PM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jul 1, 7:00 PM", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Aug 31, 7:00 PM", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Oct 29, 7:00 PM", expectedResult)

        // MARK: - 24-hour Time & dateStatusType = .absolute
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0，long 类型
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jun 30, 2020, 10:00", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1, 2020, 10:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 2, 2020, 10:00", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sep 1, 2020, 10:00", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Oct 30, 2021, 10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 29, 2020, 19:00", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30, 2020, 19:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jul 1, 2020, 19:00", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Aug 31, 2020, 19:00", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Oct 29, 2021, 19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0，short 类型
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jun 30, 10:00", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1, 10:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 2, 10:00", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sep 1, 10:00", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Oct 30, 10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 29, 19:00", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30, 19:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jul 1, 19:00", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Aug 31, 19:00", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Oct 29, 19:00", expectedResult)

        // MARK: - 12-hour Time & dateStatusType = .relative
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0，long 类型
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Yesterday, 10:00 AM", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tomorrow, 10:00 AM", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sep 1, 10:00 AM", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Oct 30, 2021, 10:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Yesterday, 7:00 PM", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tomorrow, 7:00 PM", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Aug 31, 7:00 PM", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Oct 29, 2021, 7:00 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到分钟，不需要简化 0，short 类型
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Yesterday", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 AM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tomorrow", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sep 1", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Oct 30, 2021", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Yesterday", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00 PM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tomorrow", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Aug 31", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Oct 29, 2021", expectedResult)

        // MARK: - 24-hour Time & dateStatusType = .relative
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0，long 类型
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Yesterday, 10:00", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tomorrow, 10:00", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sep 1, 10:00", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Oct 30, 2021, 10:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Yesterday, 19:00", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tomorrow, 19:00", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Aug 31, 19:00", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Oct 29, 2021, 19:00", expectedResult)

        /// - Precondition: 24 小时制，精确到分钟，不需要简化 0，short 类型
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Yesterday", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tomorrow", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sep 1", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Oct 30, 2021", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Yesterday", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tomorrow", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Aug 31", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Oct 29, 2021", expectedResult)
    }

    func testFormatFullDateTime() {
        /// - Note: 默认英文环境下测，这部分测试不需要考虑语言的因素
        /// - Remark: TimeZone * is12HourStyle * timePrecisionType * timeFormatType * shouldRemoveTrailingZeros * shouldShowGMT * DateStatusType = 192 cases
        LanguageManager.setCurrent(language: .en_US, isSystem: false)

        // MARK: - 12-hour Time & shouldShowGMT = false
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfShanghaiTimeZone.lang = Lang.zh_CN
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.lang = Lang.zh_CN
        optionsOfShanghaiTimeZone.shouldShowGMT = false
        optionsOfLosAngelesTimeZone.shouldShowGMT = false

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0，long 类型, 静态时间
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 10:00:00 AM", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00:00 AM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Thu, Jul 2, 2020, 10:00:00 AM", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Sep 1, 2020, 10:00:00 AM", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sat, Oct 30, 2021, 10:00:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Jun 29, 2020, 7:00:00 PM", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7:00:00 PM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 7:00:00 PM", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Aug 31, 2020, 7:00:00 PM", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Fri, Oct 29, 2021, 7:00:00 PM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0，动态时间
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Yesterday, Jun 30, 10:00:00 AM", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00:00 AM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tomorrow, Jul 2, 10:00:00 AM", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Sep 1, 10:00:00 AM", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sat, Oct 30, 2021, 10:00:00 AM", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Yesterday, Jun 29, 7:00:00 PM", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:00:00 PM", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tomorrow, Jul 1, 7:00:00 PM", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Aug 31, 7:00:00 PM", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Fri, Oct 29, 2021, 7:00:00 PM", expectedResult)

        // MARK: - 12-hour Time & shouldShowGMT = true
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        optionsOfShanghaiTimeZone.shouldShowGMT = true
        optionsOfLosAngelesTimeZone.shouldShowGMT = true

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0，long 类型, 静态时间
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 10:00:00 AM (GMT+8)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00:00 AM (GMT+8)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Thu, Jul 2, 2020, 10:00:00 AM (GMT+8)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Sep 1, 2020, 10:00:00 AM (GMT+8)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sat, Oct 30, 2021, 10:00:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Jun 29, 2020, 7:00:00 PM (GMT-7)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7:00:00 PM (GMT-7)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 7:00:00 PM (GMT-7)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Aug 31, 2020, 7:00:00 PM (GMT-7)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Fri, Oct 29, 2021, 7:00:00 PM (GMT-7)", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，不需要简化 0，动态时间
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Yesterday, Jun 30, 10:00:00 AM (GMT+8)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00:00 AM (GMT+8)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tomorrow, Jul 2, 10:00:00 AM (GMT+8)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Sep 1, 10:00:00 AM (GMT+8)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sat, Oct 30, 2021, 10:00:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Yesterday, Jun 29, 7:00:00 PM (GMT-7)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:00:00 PM (GMT-7)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tomorrow, Jul 1, 7:00:00 PM (GMT-7)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Aug 31, 7:00:00 PM (GMT-7)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Fri, Oct 29, 2021, 7:00:00 PM (GMT-7)", expectedResult)

        // MARK: - 24-hour Time & shouldShowGMT = false
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false
        optionsOfShanghaiTimeZone.shouldShowGMT = false
        optionsOfLosAngelesTimeZone.shouldShowGMT = false

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0，long 类型, 静态时间
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 10:00:00", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Thu, Jul 2, 2020, 10:00:00", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Sep 1, 2020, 10:00:00", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sat, Oct 30, 2021, 10:00:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Jun 29, 2020, 19:00:00", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 19:00:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 19:00:00", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Aug 31, 2020, 19:00:00", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Fri, Oct 29, 2021, 19:00:00", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0，动态时间
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Yesterday, Jun 30, 10:00:00", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tomorrow, Jul 2, 10:00:00", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Sep 1, 10:00:00", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sat, Oct 30, 2021, 10:00:00", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Yesterday, Jun 29, 19:00:00", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 19:00:00", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tomorrow, Jul 1, 19:00:00", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Aug 31, 19:00:00", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Fri, Oct 29, 2021, 19:00:00", expectedResult)

        // MARK: - 24-hour Time & shouldShowGMT = true
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false
        optionsOfShanghaiTimeZone.shouldShowGMT = true
        optionsOfLosAngelesTimeZone.shouldShowGMT = true

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0，long 类型, 静态时间
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 10:00:00 (GMT+8)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00:00 (GMT+8)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Thu, Jul 2, 2020, 10:00:00 (GMT+8)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Sep 1, 2020, 10:00:00 (GMT+8)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sat, Oct 30, 2021, 10:00:00 (GMT+8)", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Jun 29, 2020, 19:00:00 (GMT-7)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 19:00:00 (GMT-7)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 19:00:00 (GMT-7)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Aug 31, 2020, 19:00:00 (GMT-7)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Fri, Oct 29, 2021, 19:00:00 (GMT-7)", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，不需要简化 0，动态时间
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Yesterday, Jun 30, 10:00:00 (GMT+8)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00:00 (GMT+8)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tomorrow, Jul 2, 10:00:00 (GMT+8)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Sep 1, 10:00:00 (GMT+8)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sat, Oct 30, 2021, 10:00:00 (GMT+8)", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDateTime(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Yesterday, Jun 29, 19:00:00 (GMT-7)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDateTime(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 19:00:00 (GMT-7)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDateTime(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tomorrow, Jul 1, 19:00:00 (GMT-7)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Aug 31, 19:00:00 (GMT-7)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDateTime(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Fri, Oct 29, 2021, 19:00:00 (GMT-7)", expectedResult)
    }

}
