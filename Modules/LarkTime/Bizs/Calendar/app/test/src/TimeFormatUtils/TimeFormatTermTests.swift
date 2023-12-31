//
//  TimeFormatTermTests.swift
//  CalendarDemoEEUnitTest
//
//  Created by Cai Miao on 2020/7/10.
//

import XCTest
@testable import LarkTimeFormatUtils
import LarkLocalizations

class TimeFormatTermTests: XCTestCase {

    /// - Note: 影响到时间名词展示的变量只有时区

    var optionsOfShanghaiTimeZone: Options!
    var optionsOfLosAngelesTimeZone: Options!
    var expectedResult: String!
    // Thu, 1 Oct, 2020, 00:00:00 GMT
    let date = Date(timeIntervalSince1970: 1_601_510_400)
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

    func testFormatMeridiem() {
        /// 中文 - GMT+8 时区
        LanguageManager.setCurrent(language: .zh_CN, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午", expectedResult)
        /// 中文 - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午", expectedResult)
        /// 英文 - GMT+8 时区
        LanguageManager.setCurrent(language: .en_US, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("AM", expectedResult)
        /// 英文 - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("PM", expectedResult)
        /// 日本語 - GMT+8 时区
        LanguageManager.setCurrent(language: .ja_JP, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("午前", expectedResult)
        /// 日本語 - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("午後", expectedResult)
        /// Deutsch - GMT+8 时区
        LanguageManager.setCurrent(language: .de_DE, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("AM", expectedResult)
        /// Deutsch - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("PM", expectedResult)
        /// Español - GMT+8 时区
        LanguageManager.setCurrent(language: .es_ES, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("a. m.", expectedResult)
        /// Español - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("p. m.", expectedResult)
        /// Français - GMT+8 时区
        LanguageManager.setCurrent(language: .fr_FR, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("AM", expectedResult)
        /// Français - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("PM", expectedResult)
        /// हिन्दी - GMT+8 时区
        LanguageManager.setCurrent(language: .hi_IN, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("पू", expectedResult)
        /// हिन्दी - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("अ", expectedResult)
        /// Bahasa Indonesia - GMT+8 时区
        LanguageManager.setCurrent(language: .id_ID, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("AM", expectedResult)
        /// Bahasa Indonesia - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("PM", expectedResult)
        /// Italiano - GMT+8 时区
        LanguageManager.setCurrent(language: .it_IT, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("AM", expectedResult)
        /// Italiano - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("PM", expectedResult)
        /// 한국어 - GMT+8 时区
        LanguageManager.setCurrent(language: .ko_KR, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("오전", expectedResult)
        /// 한국어 - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("오후", expectedResult)
        /// Português - GMT+8 时区
        LanguageManager.setCurrent(language: .pt_BR, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("AM", expectedResult)
        /// Português - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("PM", expectedResult)
        /// Русский - GMT+8 时区
        LanguageManager.setCurrent(language: .ru_RU, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("AM", expectedResult)
        /// Русский - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("PM", expectedResult)
        /// ภาษาไทย - GMT+8 时区
        LanguageManager.setCurrent(language: .th_TH, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("AM", expectedResult)
        /// ภาษาไทย - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("PM", expectedResult)
        /// Tiếng Việt - GMT+8 时区
        LanguageManager.setCurrent(language: .vi_VN, isSystem: false)
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("SA", expectedResult)
        /// Tiếng Việt - GMT-7 时区
        expectedResult = TimeFormatUtils.formatMeridiem(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("CH", expectedResult)
    }

    func testFormatMinWeekday() {
        expectedResult = TimeFormatUtils.weekdayAbbrString(day: .thursday)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuAbbr, expectedResult)
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .min
        expectedResult = TimeFormatUtils.formatWeekday(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuAbbr, expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .min
        expectedResult = TimeFormatUtils.formatWeekday(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayWedAbbr, expectedResult)
    }

    func testFormatShortWeekday() {
        expectedResult = TimeFormatUtils.weekdayShortString(day: .thursday)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuShort, expectedResult)
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        expectedResult = TimeFormatUtils.formatWeekday(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuShort, expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        expectedResult = TimeFormatUtils.formatWeekday(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayWedShort, expectedResult)
    }

    func testFormatLongWeekday() {
        expectedResult = TimeFormatUtils.weekdayFullString(day: .thursday)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuFull, expectedResult)
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        expectedResult = TimeFormatUtils.formatWeekday(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuFull, expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        expectedResult = TimeFormatUtils.formatWeekday(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayWedFull, expectedResult)
    }

//    func testFormatMinMonth() {
//        /// 要报错，看一下执行的路径是否正确
//        optionsOfShanghaiTimeZone.timeFormatType = .min
//        expectedResult = TimeFormatUtils.formatMonth(date: date, optionsOfShanghaiTimeZone)
//    }

    func testFormatShortMonth() {
        expectedResult = TimeFormatUtils.monthAbbrString(month: .oct)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthOctAbbr, expectedResult)
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .short
        expectedResult = TimeFormatUtils.formatMonth(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthOctAbbr, expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        expectedResult = TimeFormatUtils.formatMonth(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthSeptAbbr, expectedResult)
    }

    func testFormatLongMonth() {
        expectedResult = TimeFormatUtils.monthFullString(month: .oct)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthOctFull, expectedResult)
        /// GMT+8 时区
        optionsOfShanghaiTimeZone.timeFormatType = .long
        expectedResult = TimeFormatUtils.formatMonth(from: date, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthOctFull, expectedResult)
        /// GMT-7 时区
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        expectedResult = TimeFormatUtils.formatMonth(from: date, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual(BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthSeptFull, expectedResult)
    }
}
