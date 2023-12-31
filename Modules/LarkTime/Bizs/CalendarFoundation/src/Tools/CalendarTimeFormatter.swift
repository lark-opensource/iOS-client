//
//  CalendarTimeFormatter.swift
//  CalendarFoundation
//
//  Created by Miao Cai on 2020/7/19.
//

import Foundation
import LarkLocalizations
import LarkTimeFormatUtils

// 用于日历实现日历内部对各种场景下时间格式显示的产品(特化)逻辑
// 是 TimeFormatUtils 库能力的扩展
public struct CalendarTimeFormatter {

    // 显示相对日期, 特化点如下:
    // 如果提醒时间和开始时间是同一天的话只需要显示"今天", 否则需要显示完整的日期格式
    public static func formatRelativeFullDate(from date: Date, accordingTo referenceDate: Date = Date(), with options: Options) -> String {
        // 使用设备时区
        let gregorianCalendar = Calendar.gregorianCalendarWithCurrentTimeZone()
        let weekdayIndex = gregorianCalendar.component(.weekday, from: date)
        let relativeDate: String
        // 首先判断是否是今天
        if gregorianCalendar.isDate(date, inSameDayAs: referenceDate) {
            relativeDate = BundleI18n.Calendar.Calendar_StandardTime_RelativeDayToday
            return relativeDate
        } else if gregorianCalendar.isDate(date, inSameDayAs: referenceDate.addingTimeInterval(86_400)) {
            relativeDate = BundleI18n.Calendar.Calendar_StandardTime_RelativeDayTomorrow
        } else if gregorianCalendar.isDate(date, inSameDayAs: referenceDate.addingTimeInterval(-86_400)) {
            relativeDate = BundleI18n.Calendar.Calendar_StandardTime_RelativeDayYesterday
        } else {
            // 否则正常显示星期
            relativeDate = TimeFormatUtils.weekdayShortString(weekday: weekdayIndex, lang: nil)
        }
        let dateString = TimeFormatUtils.formatDate(from: date, with: options)
        return BundleI18n.Calendar.Calendar_StandardTime_DateRelativeDayCombineFormat(relativeDay: relativeDate, date: dateString)
    }

    // 显示相对日期和时间, 特化点如下:
    // 如果提醒时间和开始时间是同一天的话只需要显示"今天"+具体时间, 否则需要显示完整的日期格式+具体时间，还需要显示时区信息
    public static func formatRelativeFullDateTime(from date: Date, accordingTo referenceDate: Date = Date(), with options: Options) -> String {
        // 使用设备时区
        let gregorianCalendar = Calendar.gregorianCalendarWithCurrentTimeZone()
        let weekdayIndex = gregorianCalendar.component(.weekday, from: date)
        let timeString = TimeFormatUtils.formatTime(from: date, with: options)
        let relativeDate: String
        let dateTimeString: String
        // 首先判断是否是今天
        if gregorianCalendar.isDate(date, inSameDayAs: referenceDate) {
            relativeDate = BundleI18n.Calendar.Calendar_StandardTime_RelativeDayToday
            dateTimeString = BundleI18n.Calendar.Calendar_StandardTime_RelativeDateTimeCombineFormat(relativeDate: 
                relativeDate,
                                                                                                     time: timeString
            )
        } else {
            if gregorianCalendar.isDate(date, inSameDayAs: referenceDate.addingTimeInterval(86_400)) {
                relativeDate = BundleI18n.Calendar.Calendar_StandardTime_RelativeDayTomorrow
            } else if gregorianCalendar.isDate(date, inSameDayAs: referenceDate.addingTimeInterval(-86_400)) {
                relativeDate = BundleI18n.Calendar.Calendar_StandardTime_RelativeDayYesterday
            } else {
                // 否则正常显示星期
                relativeDate = TimeFormatUtils.weekdayShortString(weekday: weekdayIndex, lang: nil)
            }
            let dateString = TimeFormatUtils.formatDate(from: date, with: options)
            dateTimeString = BundleI18n.Calendar.Calendar_StandardTime_RelativeDateTimeCombineFormat(relativeDate: 
                                                                                                        BundleI18n.Calendar.Calendar_StandardTime_DateRelativeDayCombineFormat(relativeDay: relativeDate, date: dateString),
                                                                                                     time: timeString
            )
        }

        let formatter = DateFormatter()
        formatter.calendar = gregorianCalendar
        formatter.locale = Locale(identifier: LanguageManager.currentLanguage.identifier)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = BundleI18n.Calendar.Calendar_StandardTime_GMTFormatForiOS
        return BundleI18n.Calendar.Calendar_StandardTime_TimeStringWithGMT(
            timeString: dateTimeString,
            GMT: formatter.string(from: date)
        )
    }

    private static var leadingZeroFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.gregorianCalendarWithCurrentTimeZone()
        formatter.locale = Locale(identifier: LanguageManager.currentLanguage.identifier)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = BundleI18n.Calendar.Calendar_StandardTime_DayWithLeadingZero
        return formatter
    }()
    // 显示日的格式, 特化点如下:
    // 日的数字显示固定为 2 位: e.g., 01, 28, etc.
    public static func formatDayWithLeadingZero(from date: Date) -> String {
        return leadingZeroFormatter.string(from: date)
    }

    // 显示相对日期, 特化点如下:
    // 对于今天的日程: 1. 全天 - 显示全天文案 2. 非全天 - 显示具体时间
    // 对于昨天/明天的日程: 显示昨天/明天
    // 对于今天/昨天/明天之外的时间都只显示M月d日(星期)的形式，包括跨年。原因: 设计考虑到显示年份的话 label 可能过长。
    public static func formatDate(from date: Date, accordingTo isAllDayEventOfToday: Bool = false, with options: Options) -> String {
        let currentDate = Date()
        // 比较相对时间时是拿当前设备的时区的时间进行比较的
        let gregorianCalendar = Calendar.gregorianCalendarWithCurrentTimeZone()
        if gregorianCalendar.isDate(date, inSameDayAs: currentDate) {
            return isAllDayEventOfToday ? BundleI18n.Calendar.Calendar_StandardTime_RelativeDayToday(lang: options.lang) : TimeFormatUtils.formatTime(from: date, with: options)
        } else if gregorianCalendar.isDate(date, inSameDayAs: currentDate.addingTimeInterval(86_400)) {
            return BundleI18n.Calendar.Calendar_StandardTime_RelativeDayTomorrow(lang: options.lang)
        } else if gregorianCalendar.isDate(date, inSameDayAs: currentDate.addingTimeInterval(-86_400)) {
            return BundleI18n.Calendar.Calendar_StandardTime_RelativeDayYesterday(lang: options.lang)
        } else {
            return TimeFormatUtils.formatFullDate(from: date, with: options)
        }

    }

    // 显示时间跨度在一天内的日程时间, 特化点如下:
    // 24小时制下, 00:00 - 00:00 需要显示成 00:00 - 24:00
    // 12小时制下, 00:00 - 00:00 需要显示成 12:00 AM - 12:00 AM
    public static func formatOneDayTimeRange(startFrom startDate: Date, endAt endDate: Date, with options: Options) -> String {
        let currentLang = LanguageManager.currentLanguage
        let startTimeString = TimeFormatUtils.formatTime(from: startDate, with: options)
        var endTimeString = TimeFormatUtils.formatTime(from: endDate, with: options)
        if !options.is12HourStyle, endTimeString == "00:00" {
                endTimeString = "24:00"
        }
        return BundleI18n.Calendar.Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap(startTime: startTimeString, endTime: endTimeString)
    }

    // 显示相对日期, 特化点如下:
    // 可以指定参考日期
    public static func formatRelativeDate(from date: Date, accordingTo referenceDate: Date) -> String {
        // 使用设备时区
        let gregorianCalendar = Calendar.gregorianCalendarWithCurrentTimeZone()
        if gregorianCalendar.isDate(date, inSameDayAs: referenceDate) {
            return BundleI18n.Calendar.Calendar_StandardTime_RelativeDayToday
        } else if gregorianCalendar.isDate(date, inSameDayAs: referenceDate.addingTimeInterval(86_400)) {
            return BundleI18n.Calendar.Calendar_StandardTime_RelativeDayTomorrow
        } else if gregorianCalendar.isDate(date, inSameDayAs: referenceDate.addingTimeInterval(-86_400)) {
            return BundleI18n.Calendar.Calendar_StandardTime_RelativeDayYesterday
        } else {
            return TimeFormatUtils.weekdayShortString(weekday: date.weekday, lang: nil)
        }
    }

    // 显示带有一定条件的时间跨度, 特化点如下:
    // 2. 非全天日程且日程起始和结束时间不在同一天的需要手动将这两段时间格式换行
    // 3. 非全天日程需要显示时区，全天日程不显示时区
    public static func formatFullDateTimeRange(startFrom startDate: Date,
                                               endAt endDate: Date,
                                               accordingTo referenceDate: Date = Date(),
                                               isAllDayEvent: Bool,
                                               shouldTextInOneLine: Bool = false,
                                               shouldShowTailingGMT: Bool = true,
                                               with options: Options) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "UTC")!
        let isEndDateBeTheStartOfDay = calendar.startOfDay(for: endDate) == endDate
        var startDate = startDate
        var endDate = endDate
        if isAllDayEvent, isEndDateBeTheStartOfDay {
            // 结束时间是当天的开始时间，则结束时间需要-1秒再 Format
            startDate = startDate.utcToLocalDate(TimeZone.current)
            endDate = endDate.utcToLocalDate(TimeZone.current) - 1
        }
        // 切换为当前设备时区
        calendar.timeZone = TimeZone.current
        let isInSameDay = calendar.isDate(startDate, equalTo: endDate, toGranularity: .day)
        let isInSameYear = calendar.isDate(startDate, equalTo: referenceDate, toGranularity: .year) && calendar.isDate(endDate, equalTo: referenceDate, toGranularity: .year)
        let dateTimeRangeString: String

        var options = options
        // 跨年选长类型的时间格式 - 显示年月日信息
        options.timeFormatType = isInSameYear ? .short : .long

        let startFullDateFormatString = BundleI18n.Calendar.Calendar_StandardTime_DateRelativeDayCombineFormat(
            relativeDay: formatRelativeDate(from: startDate, accordingTo: referenceDate),
            date: TimeFormatUtils.formatDate(from: startDate, with: options)
        )

        let endFullDateFormatString = BundleI18n.Calendar.Calendar_StandardTime_DateRelativeDayCombineFormat(
            relativeDay: formatRelativeDate(from: endDate, accordingTo: referenceDate),
            date: TimeFormatUtils.formatDate(from: endDate, with: options)
        )

        // 全天日程不显示时区信息
        if isAllDayEvent {
            if isInSameDay {
                // 如果已知是全天非跨天日程，则不关心结束时间，只显示起始日期
                return startFullDateFormatString
            }
            // 已知是全天跨天日程
            return BundleI18n.Calendar.Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap(startTime: 
                startFullDateFormatString,
                                                                                             endTime: endFullDateFormatString
            )
        }

        // 非全天日程需要考虑是否要换行显示,默认跨天日程是需要跨行
        let shouldWrapText = !isInSameDay && !shouldTextInOneLine
        // 非全天日程考虑是否跨令时，跨令时起止时间分属不同时区
        let overDaylightChange = shouldShowTailingGMT && TimeZone.current.isDaylightSavingTime(for: startDate) != TimeZone.current.isDaylightSavingTime(for: endDate)

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: LanguageManager.currentLanguage.identifier)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = BundleI18n.Calendar.Calendar_StandardTime_GMTFormatForiOS

        var startTime = TimeFormatUtils.formatTime(from: startDate, with: options)
        var endTime = TimeFormatUtils.formatTime(from: endDate, with: options)

        if overDaylightChange {
            startTime = BundleI18n.Calendar.Calendar_StandardTime_TimeStringWithGMT(timeString: startTime, GMT: formatter.string(from: startDate))
            endTime = BundleI18n.Calendar.Calendar_StandardTime_TimeStringWithGMT(timeString: endTime, GMT: formatter.string(from: endDate))
        }

        let rangeFormatter = shouldWrapText ? BundleI18n.Calendar.Calendar_StandardTime_GeneralDateTimeRangeWithWrap :
            BundleI18n.Calendar.Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap

        if isInSameDay {
            // 非跨天非全天日程
            var timeFormatString = overDaylightChange ? rangeFormatter(startTime, endTime, options.lang) : TimeFormatUtils.formatTimeRange(startFrom: startDate, endAt: endDate, with: options)
            dateTimeRangeString = BundleI18n.Calendar.Calendar_StandardTime_RelativeDateTimeCombineFormat(relativeDate: 
                startFullDateFormatString,
                                                                                                          time: timeFormatString
            )
        } else {
            // 跨天非全天日程
            let startDateTimeString = BundleI18n.Calendar.Calendar_StandardTime_RelativeDateTimeCombineFormat(relativeDate: 
                startFullDateFormatString,
                                                                                                              time: startTime
            )

            let endDateTimeString = BundleI18n.Calendar.Calendar_StandardTime_RelativeDateTimeCombineFormat(relativeDate: 
                endFullDateFormatString,
                                                                                                            time: endTime
            )
            dateTimeRangeString = rangeFormatter(startDateTimeString, endDateTimeString, options.lang)
        }

        // 非全天日程-时区信息
        if !shouldShowTailingGMT || overDaylightChange {
            return dateTimeRangeString
        } else {
            return BundleI18n.Calendar.Calendar_StandardTime_TimeStringWithGMT(
                timeString: dateTimeRangeString,
                GMT: formatter.string(from: startDate)
            )
        }
    }

    /// mirrorTimezone 是用来判断的格式的， options 里面的 timezone 是真正用来格式化的
    /// 如果两个时区的时间区间在同一天，则只显示：时间 - 时间 （时区）；
    /// 如果两个时区的时间区间分别在单独的一天，则显示：日期 时间 - 时间 （时区）；
    /// 否则，显示：日期 时间 - 日期 时间 （时区）
    /// 跨令时的话，开始和结束时间都有时区
    public static func formatTimeOrDateTimeRange(startFrom startDate: Date,
                                                 endAt endDate: Date,
                                                 mirrorTimezone: TimeZone,
                                                 with options: Options,
                                                 shouldTextInOneLine: Bool = false) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = options.timeZone

        let referenceDate = Date()
        let isInSameDay = calendar.isDate(startDate, equalTo: endDate, toGranularity: .day)
        let isInSameYear = calendar.isDate(startDate, equalTo: referenceDate, toGranularity: .year) &&
                            calendar.isDate(endDate, equalTo: referenceDate, toGranularity: .year)

        var options = options
        // 跨年选长类型的时间格式 - 显示年月日信息
        options.timeFormatType = isInSameYear ? .short : .long

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: LanguageManager.currentLanguage.identifier)
        formatter.timeZone = options.timeZone
        formatter.dateFormat = BundleI18n.Calendar.Calendar_StandardTime_GMTFormatForiOS

        // 非全天日程考虑是否跨令时，跨令时起止时间分属不同时区
        let overDaylightChange = options.shouldShowGMT && options.timeZone.isDaylightSavingTime(for: startDate) != options.timeZone.isDaylightSavingTime(for: endDate)

        let dates = [(startDate, mirrorTimezone), (endDate, mirrorTimezone), (startDate, options.timeZone), (endDate, options.timeZone)]
        // 如果两个时区的时间区间都是在同一天，那就只返回时间区间（时区），没有日期
        if !overDaylightChange && areDatesInOneDay(dates) {
            let timeRangeString = TimeFormatUtils.formatTimeRange(startFrom: startDate, endAt: endDate, with: options)
            if options.shouldShowGMT {
                return BundleI18n.Calendar.Calendar_StandardTime_TimeStringWithGMT(timeString: timeRangeString, GMT: formatter.string(from: startDate))
            }
            return timeRangeString
        }

        var startTime = TimeFormatUtils.formatTime(from: startDate, with: options)
        var endTime = TimeFormatUtils.formatTime(from: endDate, with: options)

        // 跨令时的话，时间的后面分别要加上时区
        if overDaylightChange {
            startTime = BundleI18n.Calendar.Calendar_StandardTime_TimeStringWithGMT(timeString: startTime, GMT: formatter.string(from: startDate))
            endTime = BundleI18n.Calendar.Calendar_StandardTime_TimeStringWithGMT(timeString: endTime, GMT: formatter.string(from: endDate))
        }

        // 非全天日程需要考虑是否要换行显示,默认跨天日程是需要跨行
        let shouldWrapText = !isInSameDay && !shouldTextInOneLine

        let rangeFormatter = shouldWrapText ? BundleI18n.Calendar.Calendar_StandardTime_GeneralDateTimeRangeWithWrap :
            BundleI18n.Calendar.Calendar_StandardTime_GeneralDateTimeRangeWithoutWrap

        let startDateFormatString = TimeFormatUtils.formatDate(from: startDate, with: options)
        let endDateFormatString = TimeFormatUtils.formatDate(from: endDate, with: options)
        let dateTimeRangeString: String

        if isInSameDay {
            // 非跨天非全天日程
            let timeFormatString = overDaylightChange ? rangeFormatter(startTime, endTime, options.lang) : TimeFormatUtils.formatTimeRange(startFrom: startDate, endAt: endDate, with: options)
            dateTimeRangeString = BundleI18n.Calendar.Calendar_StandardTime_RelativeDateTimeCombineFormat(relativeDate: startDateFormatString,
                                                                                                          time: timeFormatString)
        } else {
            // 跨天非全天日程
            let startDateTimeString = BundleI18n.Calendar.Calendar_StandardTime_RelativeDateTimeCombineFormat(relativeDate: startDateFormatString,
                                                                                                              time: startTime)
            let endDateTimeString = BundleI18n.Calendar.Calendar_StandardTime_RelativeDateTimeCombineFormat(relativeDate: endDateFormatString,
                                                                                                            time: endTime)
            dateTimeRangeString = rangeFormatter(startDateTimeString, endDateTimeString, options.lang)
        }

        // 非全天日程-时区信息
        if !options.shouldShowGMT || overDaylightChange {
            return dateTimeRangeString
        } else {
            return BundleI18n.Calendar.Calendar_StandardTime_TimeStringWithGMT(
                timeString: dateTimeRangeString,
                GMT: formatter.string(from: startDate)
            )
        }
    }

    private static func areDatesInOneDay(_ dates: [(date: Date, timezone: TimeZone)]) -> Bool {
        var dateStringSet: Set<String> = .init()
        for (date, timezone) in dates {
            dateStringSet.insert(date.toTimezoneString(with: timezone))
        }
        return dateStringSet.count == 1
    }
}


fileprivate extension Foundation.Date {
    func toTimezoneString(with timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.locale = Locale(identifier: LanguageManager.currentLanguage.identifier)
        formatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
        return formatter.string(from: self)
    }
}
