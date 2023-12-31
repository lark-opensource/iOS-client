//
//  TimeFormatCombineRangeTests.swift
//  CalendarDemoEEUnitTest
//
//  Created by 蔡妙 on 2020/7/11.
//

import XCTest
@testable import LarkTimeFormatUtils
import LarkLocalizations

class TimeFormatCombineRangeTests: XCTestCase {

    /// - Note: 影响到时间名词展示的变量有 time zone 和 locale

    var optionsOfShanghaiTimeZone: Options!
    var optionsOfLosAngelesTimeZone: Options!
    var expectedResult: String!

    /// Today
    // Wed, 1 Jul, 2020, 02:00:00 GMT
    let todayStartTimeInHourInAM = Date(timeIntervalSince1970: 1_593_568_800)
    // Wed, 1 Jul, 2020, 7:00:00 GMT
    let todayStartTimeInHourInPM = Date(timeIntervalSince1970: 1_593_586_800)
    // Wed, 1 Jul, 2020, 03:00:00 GMT
    let todayEndTimeInHourInAM = Date(timeIntervalSince1970: 1_593_572_400)
    // Wed, 1 Jul, 2020, 10:00:00 GMT
    let todayEndTimeInHourInPM = Date(timeIntervalSince1970: 1_593_597_600)

    // Wed, 1 Jul, 2020, 02:50:00 GMT
    let todayStartTimeInMinuteInAM = Date(timeIntervalSince1970: 1_593_571_800)
    // Wed, 1 Jul, 2020, 07:50:00 GMT
    let todayStartTimeInMinuteInPM = Date(timeIntervalSince1970: 1_593_589_800)
    // Wed, 1 Jul, 2020, 03:50:00 GMT
    let todayEndTimeInMinuteInAM = Date(timeIntervalSince1970: 1_593_575_400)
    // Wed, 1 Jul, 2020, 10:50:00 GMT
    let todayEndTimeInMinuteInPM = Date(timeIntervalSince1970: 1_593_600_600)

    // Wed, 1 Jul, 2020, 02:50:55 GMT
    let todayStartTimeInSecondInAM = Date(timeIntervalSince1970: 1_593_571_855)
    // Wed, 1 Jul, 2020, 07:50:55 GMT
    let todayStartTimeInSecondInPM = Date(timeIntervalSince1970: 1_593_589_855)
    // Wed, 1 Jul, 2020, 03:50:55 GMT
    let todayEndTimeInSecondInAM = Date(timeIntervalSince1970: 1_593_575_455)
    // Wed, 1 Jul, 2020, 10:50:55 GMT
    let todayEndTimeInSecondInPM = Date(timeIntervalSince1970: 1_593_600_655)

    /// Yesterday
    // Tue, 30 Jun, 2020, 02:00:00 GMT
    let yesterdayStartTimeInHourInAM = Date(timeIntervalSince1970: 1_593_482_400)
    // Tue, 30 Jun, 2020, 04:00:00 GMT
    let yesterdayStartTimeInHourInPM = Date(timeIntervalSince1970: 1_593_489_600)
    // Tue, 30 Jun, 2020, 03:00:00 GMT
    let yesterdayEndTimeInHourInAM = Date(timeIntervalSince1970: 1_593_486_000)
    // Tue, 30 Jun, 2020, 10:00:00 GMT
    let yesterdayEndTimeInHourInPM = Date(timeIntervalSince1970: 1_593_511_200)

    // Tue, 30 Jun, 2020, 02:50:00 GMT
    let yesterdayStartTimeInMinuteInAM = Date(timeIntervalSince1970: 1_593_485_400)
    // Tue, 30 Jun, 2020, 04:50:00 GMT
    let yesterdayStartTimeInMinuteInPM = Date(timeIntervalSince1970: 1_593_492_600)
    // Tue, 30 Jun, 2020, 03:50:00 GMT
    let yesterdayEndTimeInMinuteInAM = Date(timeIntervalSince1970: 1_593_489_000)
    // Tue, 30 Jun, 2020, 10:50:00 GMT
    let yesterdayEndTimeInMinuteInPM = Date(timeIntervalSince1970: 1_593_514_200)

    // Tue, 30 Jun, 2020, 02:50:55 GMT
    let yesterdayStartTimeInSecondInAM = Date(timeIntervalSince1970: 1_593_485_455)
    // Tue, 30 Jun, 2020, 04:50:55 GMT
    let yesterdayStartTimeInSecondInPM = Date(timeIntervalSince1970: 1_593_492_655)
    // Tue, 30 Jun, 2020, 03:50:55 GMT
    let yesterdayEndTimeInSecondInAM = Date(timeIntervalSince1970: 1_593_489_055)
    // Tue, 30 Jun, 2020, 10:50:55 GMT
    let yesterdayEndTimeInSecondInPM = Date(timeIntervalSince1970: 1_593_514_255)

    /// Tomorrow
    // Thu, 2 Jul, 2020, 02:00:00 GMT
    let tomorrowStartTimeInHourInAM = Date(timeIntervalSince1970: 1_593_655_200)
    // Thu, 2 Jul, 2020, 4:00:00 GMT
    let tomorrowStartTimeInHourInPM = Date(timeIntervalSince1970: 1_593_662_400)
    // Thu, 2 Jul, 2020, 03:00:00 GMT
    let tomorrowEndTimeInHourInAM = Date(timeIntervalSince1970: 1_593_658_800)
    // Thu, 2 Jul, 2020, 10:00:00 GMT
    let tomorrowEndTimeInHourInPM = Date(timeIntervalSince1970: 1_593_684_000)

    // Thu, 2 Jul, 2020, 02:50:00 GMT
    let tomorrowStartTimeInMinuteInAM = Date(timeIntervalSince1970: 1_593_658_200)
    // Thu, 2 Jul, 2020, 04:50:00 GMT
    let tomorrowStartTimeInMinuteInPM = Date(timeIntervalSince1970: 1_593_665_400)
    // Thu, 2 Jul, 2020, 03:50:00 GMT
    let tomorrowEndTimeInMinuteInAM = Date(timeIntervalSince1970: 1_593_661_800)
    // Thu, 2 Jul, 2020, 10:50:00 GMT
    let tomorrowEndTimeInMinuteInPM = Date(timeIntervalSince1970: 1_593_687_000)

    // Thu, 2 Jul, 2020, 02:50:55 GMT
    let tomorrowStartTimeInSecondInAM = Date(timeIntervalSince1970: 1_593_658_255)
    // Thu, 2 Jul, 2020, 04:50:55 GMT
    let tomorrowStartTimeInSecondInPM = Date(timeIntervalSince1970: 1_593_665_455)
    // Thu, 2 Jul, 2020, 03:50:55 GMT
    let tomorrowEndTimeInSecondInAM = Date(timeIntervalSince1970: 1_593_661_855)
    // Thu, 2 Jul, 2020, 10:50:55 GMT
    let tomorrowEndTimeInSecondInPM = Date(timeIntervalSince1970: 1_593_687_055)

    /// otherDayInSameYear
    // Tue, 1 Sep,  2020, 02:00:00 GMT
    let otherDayInSameYearStartTimeInHourInAM = Date(timeIntervalSince1970: 1_598_925_600)
    // Tue, 1 Sep, 2020, 4:00:00 GMT
    let otherDayInSameYearStartTimeInHourInPM = Date(timeIntervalSince1970: 1_598_932_800)
    // Tue, 1 Sep, 2020, 03:00:00 GMT
    let otherDayInSameYearEndTimeInHourInAM = Date(timeIntervalSince1970: 1_598_929_200)
    // Tue, 1 Sep, 2020, 10:00:00 GMT
    let otherDayInSameYearEndTimeInHourInPM = Date(timeIntervalSince1970: 1_598_954_400)

    // Tue, 1 Sep, 2020, 02:50:00 GMT
    let otherDayInSameYearStartTimeInMinuteInAM = Date(timeIntervalSince1970: 1_598_928_600)
    // Tue, 1 Sep, 2020, 04:50:00 GMT
    let otherDayInSameYearStartTimeInMinuteInPM = Date(timeIntervalSince1970: 1_598_935_800)
    // Tue, 1 Sep, 2020, 03:50:00 GMT
    let otherDayInSameYearEndTimeInMinuteInAM = Date(timeIntervalSince1970: 1_598_932_200)
    // Tue, 1 Sep, 2020, 10:50:00 GMT
    let otherDayInSameYearEndTimeInMinuteInPM = Date(timeIntervalSince1970: 1_598_957_400)

    // Tue, 1 Sep, 2020, 02:50:55 GMT
    let otherDayInSameYearStartTimeInSecondInAM = Date(timeIntervalSince1970: 1_598_928_655)
    // Tue, 1 Sep, 2020, 04:50:55 GMT
    let otherDayInSameYearStartTimeInSecondInPM = Date(timeIntervalSince1970: 1_598_935_855)
    // Tue, 1 Sep, 2020, 03:50:55 GMT
    let otherDayInSameYearEndTimeInSecondInAM = Date(timeIntervalSince1970: 1_598_932_255)
    // Tue, 1 Sep, 2020, 10:50:55 GMT
    let otherDayInSameYearEndTimeInSecondInPM = Date(timeIntervalSince1970: 1_598_957_455)

    /// otherDayInCrossYear
    // Sat, 30 Oct, 2021, 02:00:00 GMT
    let otherDayInCrossYearStartTimeInHourInAM = Date(timeIntervalSince1970: 1_635_559_200)
    // Sat, 30 Oct, 2021, 4:00:00 GMT
    let otherDayInCrossYearStartTimeInHourInPM = Date(timeIntervalSince1970: 1_604_030_400)
    // Sat, 30 Oct, 2021, 03:00:00 GMT
    let otherDayInCrossYearEndTimeInHourInAM = Date(timeIntervalSince1970: 1_604_026_800)
    // Sat, 30 Oct, 2021, 10:00:00 GMT
    let otherDayInCrossYearEndTimeInHourInPM = Date(timeIntervalSince1970: 1_604_052_000)

    // Sat, 30 Oct, 2021, 02:50:00 GMT
    let otherDayInCrossYearStartTimeInMinuteInAM = Date(timeIntervalSince1970: 1_604_026_200)
    // Sat, 30 Oct, 2021, 04:50:00 GMT
    let otherDayInCrossYearStartTimeInMinuteInPM = Date(timeIntervalSince1970: 1_604_033_400)
    // Sat, 30 Oct, 2021, 03:50:00 GMT
    let otherDayInCrossYearEndTimeInMinuteInAM = Date(timeIntervalSince1970: 1_604_029_800)
    // Sat, 30 Oct, 2021, 10:50:00 GMT
    let otherDayInCrossYearEndTimeInMinuteInPM = Date(timeIntervalSince1970: 1_604_055_000)

    // Sat, 30 Oct, 2021, 02:50:55 GMT
    let otherDayInCrossYearStartTimeInSecondInAM = Date(timeIntervalSince1970: 1_604_026_255)
    // Sat, 30 Oct, 2021, 04:50:55 GMT
    let otherDayInCrossYearStartTimeInSecondInPM = Date(timeIntervalSince1970: 1_604_033_455)
    // Sat, 30 Oct, 2021, 03:50:55 GMT
    let otherDayInCrossYearEndTimeInSecondInAM = Date(timeIntervalSince1970: 1_604_029_855)
    // Sat, 30 Oct, 2021, 10:50:55 GMT
    let otherDayInCrossYearEndTimeInSecondInPM = Date(timeIntervalSince1970: 1_604_055_055)

    // 上海 - GMT+8
    let timeZoneInShanghai = TimeZone(identifier: "Asia/Shanghai")!
    // 洛杉矶 - GMT-7
    let timeZoneInLosAngeles = TimeZone(identifier: "America/Los_Angeles")!

    override func setUp() {
        super.setUp()
        LanguageManager.supportLanguages = [.en_US, .zh_CN]
        optionsOfShanghaiTimeZone = Options(
            timeZone: timeZoneInShanghai
        )
        optionsOfLosAngelesTimeZone = Options(
            timeZone: timeZoneInLosAngeles
        )
    }

    func testTimeRange() {
        /// - Note: 默认是同天日程
        /// - Remark: TimeZone * is12HourStyle * timePrecisionType * shouldRemoveTrailingZeros = 24 cases

        // MARK: - English
        LanguageManager.setCurrent(language: .en_US, isSystem: false)
        /// - Important: 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// 1. 同上午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 - 11:00:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 - 11:50:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 - 11:50:55 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:00:00 - 8:00:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:00 - 8:50:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 - 8:50:55 PM", expectedResult)
        /// 2. 同下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("3:00:00 - 6:00:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("3:50:00 - 6:50:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("3:50:55 - 6:50:55 PM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("12:00:00 - 3:00:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("12:50:00 - 3:50:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("12:50:55 - 3:50:55 AM", expectedResult)
        /// 3. 跨上下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 AM - 6:00:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 AM - 6:50:00 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM - 6:50:55 PM", expectedResult)
        /// GMT-7 时区 - 跨天
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:00:00 PM - Tomorrow, Jul 1, 3:00:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:50:00 PM - Tomorrow, Jul 1, 3:50:00 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:50:55 PM - Tomorrow, Jul 1, 3:50:55 AM", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        /// 1. 同上午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 - 11 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 - 11:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 - 11:50:55 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7 - 8 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50 - 8:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("7:50:55 - 8:50:55 PM", expectedResult)
        /// 2. 同下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("3 - 6 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("3:50 - 6:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("3:50:55 - 6:50:55 PM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("12 - 3 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("12:50 - 3:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("12:50:55 - 3:50:55 AM", expectedResult)
        /// 3. 跨上下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10 AM - 6 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 AM - 6:50 PM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 AM - 6:50:55 PM", expectedResult)
        /// GMT-7 时区 - 跨天
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7 PM - Tomorrow, Jul 1, 3 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:50 PM - Tomorrow, Jul 1, 3:50 AM", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:50:55 PM - Tomorrow, Jul 1, 3:50:55 AM", expectedResult)

        /// - Important: 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false
        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// 1. 同上午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 - 11:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 - 11:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 - 11:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00 - 20:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00 - 20:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55 - 20:50:55", expectedResult)
        /// 2. 同下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:00:00 - 18:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:50:00 - 18:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:50:55 - 18:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:00:00 - 03:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:50:00 - 03:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:50:55 - 03:50:55", expectedResult)
        /// 3. 跨上下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 - 18:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 - 18:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 - 18:50:55", expectedResult)
        /// GMT-7 时区 - 跨天
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 19:00:00 - Tomorrow, Jul 1, 03:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 19:50:00 - Tomorrow, Jul 1, 03:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 19:50:55 - Tomorrow, Jul 1, 03:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        /// 1. 同上午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 - 11:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 - 11:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 - 11:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00 - 20:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50 - 20:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55 - 20:50:55", expectedResult)
        /// 2. 同下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:00 - 18:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:50 - 18:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:50:55 - 18:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:00 - 03:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:50 - 03:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:50:55 - 03:50:55", expectedResult)
        /// 3. 跨上下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 - 18:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 - 18:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 - 18:50:55", expectedResult)
        /// GMT-7 时区 - 跨天
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 19:00 - Tomorrow, Jul 1, 03:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 19:50 - Tomorrow, Jul 1, 03:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 19:50:55 - Tomorrow, Jul 1, 03:50:55", expectedResult)

        // MARK: - Chinese
        LanguageManager.setCurrent(language: .zh_CN, isSystem: false)
        /// - Important: 12-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = true
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 12 小时制，精确到秒，不需要简化 0
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// 1. 同上午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:00:00 - 11:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50:00 - 11:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50:55 - 11:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:00:00 - 8:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50:00 - 8:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50:55 - 8:50:55", expectedResult)
        /// 2. 同下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("下午3:00:00 - 6:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("下午3:50:00 - 6:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("下午3:50:55 - 6:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("上午12:00:00 - 3:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("上午12:50:00 - 3:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("上午12:50:55 - 3:50:55", expectedResult)
        /// 3. 跨上下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:00:00 - 下午6:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50:00 - 下午6:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50:55 - 下午6:50:55", expectedResult)
        /// GMT-7 时区 - 跨天
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 下午7:00:00 - 7月1日 (明天) 上午3:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 下午7:50:00 - 7月1日 (明天) 上午3:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 下午7:50:55 - 7月1日 (明天) 上午3:50:55", expectedResult)

        /// - Precondition: 12 小时制，精确到秒，需要简化 0
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        /// 1. 同上午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10点 - 11点", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50 - 11:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50:55 - 11:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7点 - 8点", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50 - 8:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("下午7:50:55 - 8:50:55", expectedResult)
        /// 2. 同下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("下午3点 - 6点", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("下午3:50 - 6:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("下午3:50:55 - 6:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("上午12点 - 3点", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("上午12:50 - 3:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("上午12:50:55 - 3:50:55", expectedResult)
        /// 3. 跨上下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10点 - 下午6点", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50 - 下午6:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("上午10:50:55 - 下午6:50:55", expectedResult)
        /// GMT-7 时区 - 跨天
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 下午7点 - 7月1日 (明天) 上午3点", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 下午7:50 - 7月1日 (明天) 上午3:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 下午7:50:55 - 7月1日 (明天) 上午3:50:55", expectedResult)

        /// - Important: 24-hour Time
        optionsOfShanghaiTimeZone.is12HourStyle = false
        optionsOfLosAngelesTimeZone.is12HourStyle = false
        /// - Precondition: 24 小时制，精确到秒，不需要简化 0
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// 1. 同上午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 - 11:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 - 11:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 - 11:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00:00 - 20:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:00 - 20:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55 - 20:50:55", expectedResult)
        /// 2. 同下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:00:00 - 18:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:50:00 - 18:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:50:55 - 18:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:00:00 - 03:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:50:00 - 03:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:50:55 - 03:50:55", expectedResult)
        /// 3. 跨上下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00:00 - 18:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:00 - 18:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 - 18:50:55", expectedResult)
        /// GMT-7 时区 - 跨天
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 19:00:00 - 7月1日 (明天) 03:00:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 19:50:00 - 7月1日 (明天) 03:50:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 19:50:55 - 7月1日 (明天) 03:50:55", expectedResult)

        /// - Precondition: 24 小时制，精确到秒，需要简化 0
        optionsOfShanghaiTimeZone.timePrecisionType = .second
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        optionsOfLosAngelesTimeZone.timePrecisionType = .second
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        /// 1. 同上午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 - 11:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 - 11:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 - 11:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:00 - 20:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50 - 20:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("19:50:55 - 20:50:55", expectedResult)
        /// 2. 同下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:00 - 18:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:50 - 18:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("15:50:55 - 18:50:55", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInPM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:00 - 03:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInPM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:50 - 03:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInPM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("00:50:55 - 03:50:55", expectedResult)
        /// 3. 跨上下午
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:00 - 18:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50 - 18:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("10:50:55 - 18:50:55", expectedResult)
        /// GMT-7 时区 - 跨天
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 19:00 - 7月1日 (明天) 03:00", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInMinuteInAM, endAt: todayEndTimeInMinuteInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 19:50 - 7月1日 (明天) 03:50", expectedResult)
        expectedResult = TimeFormatUtils.formatTimeRange(startFrom: todayStartTimeInSecondInAM, endAt: todayEndTimeInSecondInPM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("6月30日 (今天) 19:50:55 - 7月1日 (明天) 03:50:55", expectedResult)
    }

    func testDateRange() {
        /// - Note: 默认是同年日程，非同年日程需显示年份
        /// - Remark: TimeZone * timeFormatType = 4 cases
        LanguageManager.setCurrent(language: .en_US, isSystem: false)
        /// - Important: long type
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: todayStartTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1, 2020", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30, 2020", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1, 2020 - Sep 1, 2020", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30, 2020 - Aug 31, 2020", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1, 2020 - Oct 30, 2021", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30, 2020 - Oct 29, 2021", expectedResult)

        /// - Important: short type
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: todayStartTimeInHourInPM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1 - Sep 1", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30 - Aug 31", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Jul 1, 2020 - Oct 30, 2021", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Jun 30, 2020 - Oct 29, 2021", expectedResult)

    }

    func testDateTimeRange() {
        /// - Note: 默认是同年日程，非同年日程需显示年份
        /// - Remark: TimeZone * timeFormatType * dateStatusType * timePrecisionType * shouldShowGMT * trailingZero = 96 cases
        LanguageManager.setCurrent(language: .en_US, isSystem: false)

        // MARK: - Long & Static
        /// - Important: shouldShowGMT = false & trailingZero = false
        optionsOfShanghaiTimeZone.shouldShowGMT = false
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.dateStatusType = .absolute
        optionsOfShanghaiTimeZone.is12HourStyle = true

        optionsOfLosAngelesTimeZone.shouldShowGMT = false
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute
        optionsOfLosAngelesTimeZone.is12HourStyle = true
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00 - 11:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7:00 - 8:00 PM", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00 AM - Tue, Sep 1, 2020, 11:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7:00 PM - Mon, Aug 31, 2020, 8:00 PM", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00 AM - Sat, Oct 30, 2021, 10:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7:00 PM - Fri, Oct 29, 2021, 7:00 PM", expectedResult)

        /// - Important: shouldShowGMT = true & trailingZero = false
        optionsOfShanghaiTimeZone.shouldShowGMT = true
        optionsOfLosAngelesTimeZone.shouldShowGMT = true
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00 - 11:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7:00 - 8:00 PM (GMT-7)", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00 AM - Tue, Sep 1, 2020, 11:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7:00 PM - Mon, Aug 31, 2020, 8:00 PM (GMT-7)", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00 AM - Sat, Oct 30, 2021, 10:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7:00 PM - Fri, Oct 29, 2021, 7:00 PM (GMT-7)", expectedResult)

        /// - Important: shouldShowGMT = false & trailingZero = true
        optionsOfShanghaiTimeZone.shouldShowGMT = false
        optionsOfLosAngelesTimeZone.shouldShowGMT = false
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10 - 11 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7 - 8 PM", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10 AM - Tue, Sep 1, 2020, 11 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7 PM - Mon, Aug 31, 2020, 8 PM", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10 AM - Sat, Oct 30, 2021, 10 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7 PM - Fri, Oct 29, 2021, 7 PM", expectedResult)

        /// - Important: shouldShowGMT = true & trailingZero = true
        optionsOfShanghaiTimeZone.shouldShowGMT = true
        optionsOfLosAngelesTimeZone.shouldShowGMT = true
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10 - 11 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7 - 8 PM (GMT-7)", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10 AM - Tue, Sep 1, 2020, 11 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7 PM - Mon, Aug 31, 2020, 8 PM (GMT-7)", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10 AM - Sat, Oct 30, 2021, 10 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7 PM - Fri, Oct 29, 2021, 7 PM (GMT-7)", expectedResult)

        // MARK: - Long & Dynamic
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.timeFormatType = .long
        optionsOfShanghaiTimeZone.dateStatusType = .relative

        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.timeFormatType = .long
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Important: shouldShowGMT = false & trailingZero = false
        optionsOfShanghaiTimeZone.shouldShowGMT = false
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.shouldShowGMT = false
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00 - 11:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:00 - 8:00 PM", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00 AM - Tue, Sep 1, 11:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:00 PM - Mon, Aug 31, 8:00 PM", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 2020, 10:00 AM - Sat, Oct 30, 2021, 10:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 2020, 7:00 PM - Fri, Oct 29, 2021, 7:00 PM", expectedResult)

        /// - Important: shouldShowGMT = true & trailingZero = false
        optionsOfShanghaiTimeZone.shouldShowGMT = true
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false
        optionsOfLosAngelesTimeZone.shouldShowGMT = true
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00 - 11:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:00 - 8:00 PM (GMT-7)", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00 AM - Tue, Sep 1, 11:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:00 PM - Mon, Aug 31, 8:00 PM (GMT-7)", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 2020, 10:00 AM - Sat, Oct 30, 2021, 10:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 2020, 7:00 PM - Fri, Oct 29, 2021, 7:00 PM (GMT-7)", expectedResult)

        /// - Important: shouldShowGMT = false & trailingZero = true
        optionsOfShanghaiTimeZone.shouldShowGMT = false
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true
        optionsOfLosAngelesTimeZone.shouldShowGMT = false
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10 - 11 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7 - 8 PM", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10 AM - Tue, Sep 1, 11 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7 PM - Mon, Aug 31, 8 PM", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 2020, 10 AM - Sat, Oct 30, 2021, 10 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 2020, 7 PM - Fri, Oct 29, 2021, 7 PM", expectedResult)

        /// - Important: shouldShowGMT = true & trailingZero = true
        optionsOfShanghaiTimeZone.shouldShowGMT = true
        optionsOfLosAngelesTimeZone.shouldShowGMT = true
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10 - 11 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7 - 8 PM (GMT-7)", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10 AM - Tue, Sep 1, 11 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7 PM - Mon, Aug 31, 8 PM (GMT-7)", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 2020, 10 AM - Sat, Oct 30, 2021, 10 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 2020, 7 PM - Fri, Oct 29, 2021, 7 PM (GMT-7)", expectedResult)

        // MARK: - Short & Static
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.dateStatusType = .absolute

        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.dateStatusType = .absolute

        /// - Important: shouldShowGMT = false & trailingZero = false
        optionsOfShanghaiTimeZone.shouldShowGMT = false
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false

        optionsOfLosAngelesTimeZone.shouldShowGMT = false
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 10:00 - 11:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 7:00 - 8:00 PM", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 10:00 AM - Tue, Sep 1, 11:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 7:00 PM - Mon, Aug 31, 8:00 PM", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00 AM - Sat, Oct 30, 2021, 10:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7:00 PM - Fri, Oct 29, 2021, 7:00 PM", expectedResult)

        /// - Important: shouldShowGMT = true & trailingZero = false
        optionsOfShanghaiTimeZone.shouldShowGMT = true
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false

        optionsOfLosAngelesTimeZone.shouldShowGMT = true
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 10:00 - 11:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 7:00 - 8:00 PM (GMT-7)", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 10:00 AM - Tue, Sep 1, 11:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 7:00 PM - Mon, Aug 31, 8:00 PM (GMT-7)", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10:00 AM - Sat, Oct 30, 2021, 10:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7:00 PM - Fri, Oct 29, 2021, 7:00 PM (GMT-7)", expectedResult)

        /// - Important: shouldShowGMT = false & trailingZero = true
        optionsOfShanghaiTimeZone.shouldShowGMT = false
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true

        optionsOfLosAngelesTimeZone.shouldShowGMT = false
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 10 - 11 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 7 - 8 PM", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 10 AM - Tue, Sep 1, 11 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 7 PM - Mon, Aug 31, 8 PM", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10 AM - Sat, Oct 30, 2021, 10 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7 PM - Fri, Oct 29, 2021, 7 PM", expectedResult)

        /// - Important: shouldShowGMT = true & trailingZero = true
        optionsOfShanghaiTimeZone.shouldShowGMT = true
        optionsOfLosAngelesTimeZone.shouldShowGMT = true
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 10 - 11 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 7 - 8 PM (GMT-7)", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 10 AM - Tue, Sep 1, 11 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 7 PM - Mon, Aug 31, 8 PM (GMT-7)", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Wed, Jul 1, 2020, 10 AM - Sat, Oct 30, 2021, 10 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Tue, Jun 30, 2020, 7 PM - Fri, Oct 29, 2021, 7 PM (GMT-7)", expectedResult)

        // MARK: - Short & Dynamic
        optionsOfShanghaiTimeZone.timePrecisionType = .minute
        optionsOfShanghaiTimeZone.timeFormatType = .short
        optionsOfShanghaiTimeZone.dateStatusType = .relative

        optionsOfLosAngelesTimeZone.timePrecisionType = .minute
        optionsOfLosAngelesTimeZone.timeFormatType = .short
        optionsOfLosAngelesTimeZone.dateStatusType = .relative
        /// - Important: shouldShowGMT = false & trailingZero = false
        optionsOfShanghaiTimeZone.shouldShowGMT = false
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false

        optionsOfLosAngelesTimeZone.shouldShowGMT = false
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00 - 11:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:00 - 8:00 PM", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00 AM - Tue, Sep 1, 11:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:00 PM - Mon, Aug 31, 8:00 PM", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 2020, 10:00 AM - Sat, Oct 30, 2021, 10:00 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 2020, 7:00 PM - Fri, Oct 29, 2021, 7:00 PM", expectedResult)

        /// - Important: shouldShowGMT = true & trailingZero = false
        optionsOfShanghaiTimeZone.shouldShowGMT = true
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = false

        optionsOfLosAngelesTimeZone.shouldShowGMT = true
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = false
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00 - 11:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:00 - 8:00 PM (GMT-7)", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10:00 AM - Tue, Sep 1, 11:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7:00 PM - Mon, Aug 31, 8:00 PM (GMT-7)", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 2020, 10:00 AM - Sat, Oct 30, 2021, 10:00 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 2020, 7:00 PM - Fri, Oct 29, 2021, 7:00 PM (GMT-7)", expectedResult)

        /// - Important: shouldShowGMT = false & trailingZero = true
        optionsOfShanghaiTimeZone.shouldShowGMT = false
        optionsOfShanghaiTimeZone.shouldRemoveTrailingZeros = true

        optionsOfLosAngelesTimeZone.shouldShowGMT = false
        optionsOfLosAngelesTimeZone.shouldRemoveTrailingZeros = true
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10 - 11 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7 - 8 PM", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10 AM - Tue, Sep 1, 11 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7 PM - Mon, Aug 31, 8 PM", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 2020, 10 AM - Sat, Oct 30, 2021, 10 AM", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 2020, 7 PM - Fri, Oct 29, 2021, 7 PM", expectedResult)

        /// - Important: shouldShowGMT = true & trailingZero = true
        optionsOfShanghaiTimeZone.shouldShowGMT = true
        optionsOfLosAngelesTimeZone.shouldShowGMT = true
        /// - Precondition: 同天日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10 - 11 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: todayEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7 - 8 PM (GMT-7)", expectedResult)
        /// - Precondition: 同年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 10 AM - Tue, Sep 1, 11 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInSameYearEndTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 7 PM - Mon, Aug 31, 8 PM (GMT-7)", expectedResult)
        /// - Precondition: 跨年日程
        // GMT+8 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfShanghaiTimeZone)
        XCTAssertEqual("Today, Jul 1, 2020, 10 AM - Sat, Oct 30, 2021, 10 AM (GMT+8)", expectedResult)
        /// GMT-7 时区
        expectedResult = TimeFormatUtils.formatDateTimeRange(startFrom: todayStartTimeInHourInAM, endAt: otherDayInCrossYearStartTimeInHourInAM, with: optionsOfLosAngelesTimeZone)
        XCTAssertEqual("Today, Jun 30, 2020, 7 PM - Fri, Oct 29, 2021, 7 PM (GMT-7)", expectedResult)
    }
}
