//
//  TimeFormatUtils+Variables.swift
//  LarkTimeFormatUtils
//
//  Created by Miao Cai on 2020/9/7.
//

import Foundation
import LarkLocalizations

extension TimeFormatUtils {
    // MARK: - 12-Hour Format
    static func twelveHourSecondWithIndicatorFormat(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_TwelveHourSecondFormatWithMeridiemIndicator(lang: lang)
    }

    static func twelveHourSecondWithoutIndicatorFormat(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_TwelveHourSecondFormatWithoutMeridiemIndicator(lang: lang)
    }

    static func twelveHourMinuteWithIndicatorFormat(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_TwelveHourMinuteFormatWithMeridiemIndicator(lang: lang)
    }

    static func twelveHourMinuteWithoutIndicatorFormat(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_TwelveHourMinuteFormatWithoutMeridiemIndicator(lang: lang)
    }

    static func twelveHourOnTheHourWithIndicatorFormat(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_TwelveHourOnTheHourWithMeridiemIndicator(lang: lang)
    }

    static func twelveHourOnTheHourWithoutIndicatorFormat(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_TwelveHourOnTheHourWithoutMeridiemIndicator(lang: lang)
    }

    // MARK: - 24-Hour Format
    static func twentyFourHourSecondFormat(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_TwentyFourHourWithSecond(lang: lang)
    }

    static func twentyFourHourMinuteFormat(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_TwentyFourHourWithMinute(lang: lang)
    }

    // MARK: - Combination Time Format
    static func monthDayCombineFormat(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthDayCombineFormat(lang: lang)
    }

    static func yearMonthDayCombineFormat(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_YearMonthDayCombineFormat(lang: lang)
    }

    static func yesterdayString(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_RelativeDayYesterday(lang: lang)
    }

    static func tomorrowString(lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_RelativeDayTomorrow(lang: lang)
    }

    // MARK: - Combination DateTime Format
    static func combineRelativeDateWithTime(_ dateString: String, _ timeString: String, lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_RelativeDateTimeCombineFormat(
            relativeDate: dateString,
            time: timeString,
            lang: lang
        )
    }

    static func combineRelativeDayWithDate(_ relativeDayString: String, _ dateString: String, lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_DateRelativeDayCombineFormat(
            relativeDay: relativeDayString,
            date: dateString,
            lang: lang
        )
    }

    static func combineTimeStringWithGMT(_ dateTimeString: String, _ timeZoneString: String, lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_TimeStringWithGMT(timeString: dateTimeString, GMT: timeZoneString, lang: lang)
    }

    static func combineDateTimeRange(_ startDateTimeString: String, _ endDateTimeString: String, lang: Lang? = nil) -> String {
        return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap(
            startTime: startDateTimeString,
            endTime: endDateTimeString,
            lang: lang
        )
    }
}
