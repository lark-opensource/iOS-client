//
//  TimeFormatSingleDateTests+FormatDate.swift
//  CalendarDemoEEUnitTest
//
//  Created by 蔡妙 on 2020/7/20.
//

import XCTest
@testable import LarkTimeFormatUtils
import LarkLocalizations

extension TimeFormatSingleDateTests {
    func testFormatDate() {
        /// - Remark: TimeZone * datePrecisionType * timeFormatType * dateStatusType = 16 cases

        // MARK: - en_US
        LanguageManager.setCurrent(language: .en_US, isSystem: false)
        // MARK: - 静态日期格式
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 2020", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1, 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30, 2020", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("July", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("June", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Yesterday", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tomorrow", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sep 1", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Oct 30, 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Yesterday", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tomorrow", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Aug 31", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Oct 29, 2021", expectedResult)

        // MARK: - zh_CN
        LanguageManager.setCurrent(language: .zh_CN, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年7月", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年6月", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年7月1日", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年6月30日", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7月", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7月1日", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("昨天", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("今天", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("明天", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("9月1日", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2021年10月30日", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("昨天", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("今天", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("明天", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("8月31日", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2021年10月29日", expectedResult)

        // MARK: - ja_JP
        LanguageManager.setCurrent(language: .ja_JP, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年7月", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年6月", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年7月1日", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年6月30日", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7月", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7月1日", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("昨日", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("今日", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("明日", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("9月1日", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2021年10月30日", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("昨日", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("今日", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("明日", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("8月31日", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2021年10月29日", expectedResult)

        // MARK: - de_DE
        LanguageManager.setCurrent(language: .de_DE, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Juli 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Juni 2020", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1. Juli 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30. Juni 2020", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Juli", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Juni", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1. Juli", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30. Juni", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Gestern", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Heute", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Morgen", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1. Sept.", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("30. Okt. 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Gestern", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Heute", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Morgen", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("31. Aug.", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("29. Okt. 2021", expectedResult)

        // MARK: - es_ES
        LanguageManager.setCurrent(language: .es_ES, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("julio de 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("junio de 2020", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 de julio de 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 de junio de 2020", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("julio", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("junio", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 de julio", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 de junio", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Ayer", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("hoy", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Mañana", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 de septiembre", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("30 de octubre de 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Ayer", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("hoy", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mañana", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("31 de agosto", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("29 de octubre de 2021", expectedResult)

        // MARK: - fr_FR
        LanguageManager.setCurrent(language: .fr_FR, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("juil. 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("juin 2020", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 juil. 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 juin 2020", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("juillet", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("juin", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 juil.", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 juin", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Hier", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Aujourd’hui", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Demain", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 sept.", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("30 oct. 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Hier", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Aujourd’hui", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Demain", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("31 août", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("29 oct. 2021", expectedResult)

        // MARK: - hi_IN
        LanguageManager.setCurrent(language: .hi_IN, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("जुल॰ 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("जून 2020", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 जुल॰ 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 जून 2020", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("जुलाई", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("जून", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 जुल॰", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 जून", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("कल", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("आज", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("कल", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 सित॰", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("30 अक्तू॰ 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("कल", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("आज", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("कल", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("31 अग॰", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("29 अक्तू॰ 2021", expectedResult)

        // MARK: - id_ID
        LanguageManager.setCurrent(language: .id_ID, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 2020", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 Jul 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 Jun 2020", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Juli", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Juni", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 Jul", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 Jun", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Kemarin", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Hari Ini", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Besok", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 Sep", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("30 Okt 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Kemarin", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Hari Ini", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Besok", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("31 Agu", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("29 Okt 2021", expectedResult)

        // MARK: - it_IT
        LanguageManager.setCurrent(language: .it_IT, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("lug 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("giu 2020", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 lug 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 giu 2020", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("luglio", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("giugno", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 lug", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 giu", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Ieri", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Oggi", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Domani", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 set", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("30 ott 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Ieri", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Oggi", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Domani", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("31 ago", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("29 ott 2021", expectedResult)

        // MARK: - ko_KR
        LanguageManager.setCurrent(language: .ko_KR, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020년 7월", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020년 6월", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020년 7월 1일", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020년 6월 30일", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7월", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6월", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7월 1일", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6월 30일", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("어제", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오늘", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("내일", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("9월 1일", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2021년 10월 30일", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("어제", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오늘", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("내일", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("8월 31일", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2021년 10월 29일", expectedResult)

        // MARK: - pt_BR
        LanguageManager.setCurrent(language: .pt_BR, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("julho de 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("junho de 2020", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 de julho de 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 de junho de 2020", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("julho", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("junho", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 de julho", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 de junho", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Ontem", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Hoje", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Amanhã", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 de setembro", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("30 de outubro de 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Ontem", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Hoje", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Amanhã", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("31 de agosto", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("29 de outubro de 2021", expectedResult)

        // MARK: - ru_RU
        LanguageManager.setCurrent(language: .ru_RU, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("июля 2020 г.", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("июня 2020 г.", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 июля 2020 г.", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 июня 2020 г.", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("июль", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("июнь", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 июля", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 июня", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Вчера", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Сегодня", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Завтра", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 сентября", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("30 октября 2021 г.", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Вчера", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Сегодня", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Завтра", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("31 августа", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("29 октября 2021 г.", expectedResult)

        // MARK: - th_TH
        LanguageManager.setCurrent(language: .th_TH, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("ก.ค. 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("มิ.ย. 2020", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 ก.ค. 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 มิ.ย. 2020", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("กรกฎาคม", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("มิถุนายน", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 ก.ค.", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 มิ.ย.", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("เมื่อวานนี้", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("วันนี้", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("พรุ่งนี้", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 ก.ย.", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("30 ต.ค. 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("เมื่อวานนี้", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("วันนี้", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("พรุ่งนี้", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("31 ส.ค.", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("29 ต.ค. 2021", expectedResult)

        // MARK: - vi_VN
        LanguageManager.setCurrent(language: .vi_VN, isSystem: false)
        // MARK: - 静态日期格式
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("tháng 7, 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("tháng 6, 2020", expectedResult)
        /// - Precondition: timeFormatType = .long, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 tháng 7, 2020", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 tháng 6, 2020", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .month
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("tháng 7", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .month
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("tháng 6", expectedResult)
        /// - Precondition: timeFormatType = .short, datePrecisionType = .day
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 tháng 7", expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.datePrecisionType = .day
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("30 tháng 6", expectedResult)

        // MARK: - 动态日期格式，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Hôm qua", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Hôm nay", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Ngày mai", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("1 tháng 9", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("30 tháng 10, 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Hôm qua", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Hôm nay", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Ngày mai", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("31 tháng 8", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("29 tháng 10, 2021", expectedResult)
    }
    //    func testFormatDateException() {
    //        /// - Note: 默认英文环境下测，这部分测试不需要考虑语言的因素
    //        /// - Warning: 必失败，确认是否走到预期路径
    //        LanguageManager.setCurrent(language: .en_US, isSystem: false)
    //        optionsOfShanghaiTimeZone.timeFormatType = .min
    //        expectedResult = TimeFormatUtils.formatDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
    //    }

}
