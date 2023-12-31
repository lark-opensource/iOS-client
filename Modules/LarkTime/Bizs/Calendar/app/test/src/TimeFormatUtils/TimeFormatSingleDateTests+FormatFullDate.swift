//
//  TimeFormatSingleDateTests+FormatFullDate.swift
//  CalendarDemoEEUnitTest
//
//  Created by 蔡妙 on 2020/7/20.
//

import XCTest
@testable import LarkTimeFormatUtils
import LarkLocalizations

extension TimeFormatSingleDateTests {
    func testFormatFullDate() {
        /// - Remark: TimeZone * timeFormatType * DateStatusType = 8 cases

        // MARK: - en_US
        LanguageManager.setCurrent(language: .en_US, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Thu, Jul 2, 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Sep 1, 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sat, Oct 30, 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Jun 29, 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Aug 31, 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Fri, Oct 29, 2021", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Yesterday, Jun 30", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tomorrow, Jul 2", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Tue, Sep 1", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sat, Oct 30, 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Yesterday, Jun 29", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tomorrow, Jul 1", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mon, Aug 31", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Fri, Oct 29, 2021", expectedResult)

        // MARK: - zh_CN
        LanguageManager.setCurrent(language: .zh_CN, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年6月30日 (周二)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年7月1日 (周三)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年7月2日 (周四)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年9月1日 (周二)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2021年10月30日 (周六)", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年6月29日 (周一)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年6月30日 (周二)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年7月1日 (周三)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年8月31日 (周一)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2021年10月29日 (周五)", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("6月30日 (昨天)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7月1日 (今天)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7月2日 (明天)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("9月1日 (周二)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2021年10月30日 (周六)", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月29日 (昨天)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7月1日 (明天)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("8月31日 (周一)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2021年10月29日 (周五)", expectedResult)

        // MARK: - ja_JP
        LanguageManager.setCurrent(language: .ja_JP, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年6月30日 (火曜日)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年7月1日 (水曜日)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年7月2日 (木曜日)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020年9月1日 (火曜日)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2021年10月30日 (土曜日)", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年6月29日 (月曜日)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年6月30日 (火曜日)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年7月1日 (水曜日)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020年8月31日 (月曜日)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2021年10月29日 (金曜日)", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("6月30日 (昨日)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7月1日 (今日)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7月2日 (明日)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("9月1日 (火曜日)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2021年10月30日 (土曜日)", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月29日 (昨日)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今日)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7月1日 (明日)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("8月31日 (月曜日)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2021年10月29日 (金曜日)", expectedResult)

        // MARK: - de_DE
        LanguageManager.setCurrent(language: .de_DE, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Di., 30. Juni 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Mi., 1. Juli 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Do., 2. Juli 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Di., 1. Sept. 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sa., 30. Okt. 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mo., 29. Juni 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Di., 30. Juni 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mi., 1. Juli 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mo., 31. Aug. 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Fr., 29. Okt. 2021", expectedResult)

        // MARK: - es_ES
        LanguageManager.setCurrent(language: .es_ES, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("ma, 30 de junio de 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("mi, 1 de julio de 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("ju, 2 de julio de 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("ma, 1 de septiembre de 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("sá, 30 de octubre de 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("lu, 29 de junio de 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("ma, 30 de junio de 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("mi, 1 de julio de 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("lu, 31 de agosto de 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("vi, 29 de octubre de 2021", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Ayer, 30 de junio", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("hoy, 1 de julio", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Mañana, 2 de julio", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("ma, 1 de septiembre", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("sá, 30 de octubre de 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Ayer, 29 de junio", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("hoy, 30 de junio", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Mañana, 1 de julio", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("lu, 31 de agosto", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("vi, 29 de octubre de 2021", expectedResult)

        // MARK: - fr_FR
        LanguageManager.setCurrent(language: .fr_FR, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("mar. 30 juin 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("mer. 1 juil. 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("jeu. 2 juil. 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("mar. 1 sept. 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("sam. 30 oct. 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("lun. 29 juin 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("mar. 30 juin 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("mer. 1 juil. 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("lun. 31 août 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("ven. 29 oct. 2021", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Hier 30 juin", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Aujourd’hui 1 juil.", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Demain 2 juil.", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("mar. 1 sept.", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("sam. 30 oct. 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Hier 29 juin", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Aujourd’hui 30 juin", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Demain 1 juil.", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("lun. 31 août", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("ven. 29 oct. 2021", expectedResult)

        // MARK: - hi_IN
        LanguageManager.setCurrent(language: .hi_IN, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("मंगल, 30 जून 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("बुध, 1 जुल॰ 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("गुरू, 2 जुल॰ 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("मंगल, 1 सित॰ 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("शनि, 30 अक्तू॰ 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("सोम, 29 जून 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("मंगल, 30 जून 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("बुध, 1 जुल॰ 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("सोम, 31 अग॰ 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("शुक्र, 29 अक्तू॰ 2021", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("कल, 30 जून", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("आज, 1 जुल॰", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("कल, 2 जुल॰", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("मंगल, 1 सित॰", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("शनि, 30 अक्तू॰ 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("कल, 29 जून", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("आज, 30 जून", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("कल, 1 जुल॰", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("सोम, 31 अग॰", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("शुक्र, 29 अक्तू॰ 2021", expectedResult)

        // MARK: - id_ID
        LanguageManager.setCurrent(language: .id_ID, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sel, 30 Jun 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Rab, 1 Jul 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Kam, 2 Jul 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sel, 1 Sep 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sab, 30 Okt 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Sen, 29 Jun 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Sel, 30 Jun 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Rab, 1 Jul 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Sen, 31 Agu 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jum, 29 Okt 2021", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Kemarin, 30 Jun", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Hari Ini, 1 Jul", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Besok, 2 Jul", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sel, 1 Sep", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Sab, 30 Okt 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Kemarin, 29 Jun", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Hari Ini, 30 Jun", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Besok, 1 Jul", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Sen, 31 Agu", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jum, 29 Okt 2021", expectedResult)

        // MARK: - it_IT
        LanguageManager.setCurrent(language: .it_IT, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("mar, 30 giu 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("mer, 1 lug 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("gio, 2 lug 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("mar, 1 set 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("sab, 30 ott 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("lun, 29 giu 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("mar, 30 giu 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("mer, 1 lug 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("lun, 31 ago 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("ven, 29 ott 2021", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Ieri, 30 giu", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Oggi, 1 lug", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Domani, 2 lug", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("mar, 1 set", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("sab, 30 ott 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Ieri, 29 giu", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Oggi, 30 giu", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Domani, 1 lug", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("lun, 31 ago", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("ven, 29 ott 2021", expectedResult)

        // MARK: - ko_KR
        LanguageManager.setCurrent(language: .ko_KR, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020년 6월 30일 (화요일)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020년 7월 1일 (수요일)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020년 7월 2일 (목요일)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2020년 9월 1일 (화요일)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2021년 10월 30일 (토요일)", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020년 6월 29일 (월요일)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020년 6월 30일 (화요일)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020년 7월 1일 (수요일)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2020년 8월 31일 (월요일)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2021년 10월 29일 (금요일)", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("6월 30일 (어제)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7월 1일 (오늘)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("7월 2일 (내일)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("9월 1일 (화요일)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("2021년 10월 30일 (토요일)", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6월 29일 (어제)", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6월 30일 (오늘)", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7월 1일 (내일)", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("8월 31일 (월요일)", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("2021년 10월 29일 (금요일)", expectedResult)

        // MARK: - pt_BR
        LanguageManager.setCurrent(language: .pt_BR, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("ter, 30 de junho de 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("qua, 1 de julho de 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("qui, 2 de julho de 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("ter, 1 de setembro de 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("sáb, 30 de outubro de 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("seg, 29 de junho de 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("ter, 30 de junho de 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("qua, 1 de julho de 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("seg, 31 de agosto de 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("sex, 29 de outubro de 2021", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Ontem, 30 de junho", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Hoje, 1 de julho", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Amanhã, 2 de julho", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("ter, 1 de setembro", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("sáb, 30 de outubro de 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Ontem, 29 de junho", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Hoje, 30 de junho", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Amanhã, 1 de julho", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("seg, 31 de agosto", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("sex, 29 de outubro de 2021", expectedResult)

        // MARK: - ru_RU
        LanguageManager.setCurrent(language: .ru_RU, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("вт, 30 июня 2020 г.", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("ср, 1 июля 2020 г.", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("чт, 2 июля 2020 г.", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("вт, 1 сентября 2020 г.", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("сб, 30 октября 2021 г.", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("пн, 29 июня 2020 г.", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("вт, 30 июня 2020 г.", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("ср, 1 июля 2020 г.", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("пн, 31 августа 2020 г.", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("пт, 29 октября 2021 г.", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Вчера, 30 июня", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Сегодня, 1 июля", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Завтра, 2 июля", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("вт, 1 сентября", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("сб, 30 октября 2021 г.", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Вчера, 29 июня", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Сегодня, 30 июня", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Завтра, 1 июля", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("пн, 31 августа", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("пт, 29 октября 2021 г.", expectedResult)

        // MARK: - th_TH
        LanguageManager.setCurrent(language: .th_TH, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("อังคาร 30 มิ.ย. 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("พุธ 1 ก.ค. 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("พฤหัส 2 ก.ค. 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("อังคาร 1 ก.ย. 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("เสาร์ 30 ต.ค. 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("จันทร์ 29 มิ.ย. 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("อังคาร 30 มิ.ย. 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("พุธ 1 ก.ค. 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("จันทร์ 31 ส.ค. 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("ศุกร์ 29 ต.ค. 2021", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("เมื่อวานนี้ 30 มิ.ย.", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("วันนี้ 1 ก.ค.", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("พรุ่งนี้ 2 ก.ค.", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("อังคาร 1 ก.ย.", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("เสาร์ 30 ต.ค. 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("เมื่อวานนี้ 29 มิ.ย.", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("วันนี้ 30 มิ.ย.", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("พรุ่งนี้ 1 ก.ค.", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("จันทร์ 31 ส.ค.", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("ศุกร์ 29 ต.ค. 2021", expectedResult)

        // MARK: - vi_VN
        LanguageManager.setCurrent(language: .vi_VN, isSystem: false)
        // MARK: - 静态时间，与当前日期无关
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        /// - Precondition: timeFormatType = .long
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("thứ ba, 30 tháng 6, 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("thứ tư, 1 tháng 7, 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("thứ năm, 2 tháng 7, 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("thứ ba, 1 tháng 9, 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("thứ bảy, 30 tháng 10, 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("thứ hai, 29 tháng 6, 2020", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("thứ ba, 30 tháng 6, 2020", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("thứ tư, 1 tháng 7, 2020", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("thứ hai, 31 tháng 8, 2020", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("thứ sáu, 29 tháng 10, 2021", expectedResult)

        // MARK: - 动态时间，与当前日期相关
        optionsOfShanghaiTimeZone.dateStatusType = .relative
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Precondition: 动态时间没有 timeFormatType 的概念，具体情况具体分析
        /// GMT+8 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Hôm qua, 30 tháng 6", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Hôm nay, 1 tháng 7", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Ngày mai, 2 tháng 7", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("thứ ba, 1 tháng 9", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("thứ bảy, 30 tháng 10, 2021", expectedResult)
        /// GMT-7 时区
        /// Yesterday
        expectedResult = TimeFormatUtils.formatFullDate(from: yesterday, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Hôm qua, 29 tháng 6", expectedResult)
        /// Today
        expectedResult = TimeFormatUtils.formatFullDate(from: dateInHour, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Hôm nay, 30 tháng 6", expectedResult)
        /// Tomorrow
        expectedResult = TimeFormatUtils.formatFullDate(from: tomorrow, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Ngày mai, 1 tháng 7", expectedResult)
        /// Other day in the same year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInSameYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("thứ hai, 31 tháng 8", expectedResult)
        /// Other day cross this year
        expectedResult = TimeFormatUtils.formatFullDate(from: otherDayInCrossYear, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("thứ sáu, 29 tháng 10, 2021", expectedResult)
    }

}
