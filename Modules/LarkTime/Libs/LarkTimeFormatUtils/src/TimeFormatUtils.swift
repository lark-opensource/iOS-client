//
//  TimeFormatUtils.swift
//  LarkTimeFormatUtils
//
//  Created by Miao Cai on 2020/9/7.
//

import Foundation
import LarkLocalizations

/// Lark time format utility
/// Interface design document: https://bytedance.feishu.cn/docs/doccnNM4RKsOadEtm5TMkIatUQf
/// Guidebook: https://bytedance.feishu.cn/wiki/wikcncomscp8CYMBjCfFG3HVIMf
public struct TimeFormatUtils {

    /// 返回当前 App 使用的语言，默认英文兜底
    public static var languageIdentifier: String {
        let currentLanguage = LanguageManager.currentLanguage
        let hasSupportCurrentLanguage = LanguageManager.supportLanguages.contains(currentLanguage)
        return hasSupportCurrentLanguage ? currentLanguage.localeIdentifier : Lang.en_US.localeIdentifier
    }

    /// 记录 上/下午 为前缀的语言
    public static let languagesListForAheadMeridiemIndicator: [Lang] = [.zh_CN, .ja_JP, .ko_KR]

    /// 默认配置
    public static var defaultOptions: Options {
        return Options(
            timeZone: currentTimeZone,
            is12HourStyle: false,
            shouldShowGMT: false,
            timeFormatType: .long,
            timePrecisionType: .hour
        )
    }

    static var currentTimeZone: TimeZone {
        return TimeZone.current
    }

    // MARK: - Meridiem Format

    /// Return only meridiem of the selection date.
    /// ```
    /// let date = Date() // 2020-07-08 03:45:57 +0000
    /// let option = Options(timeZone: TimeZone(identifier: "Asia/Shanghai")!)
    /// print(TimeFormatUtils.formatMeridiem(date: date), option)) // AM
    /// ```
    /// - Parameter date: An instance from struct Date
    public static func formatMeridiem(from date: Date, with options: Options = defaultOptions) -> String {
        var calendar = Calendar.gregorianCalendar
        let formatter = DateFormatter()
        formatter.dateFormat = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MeridiemFormat(lang: options.lang)
        formatter.locale = Locale(identifier: options.lang?.identifier ?? languageIdentifier)
        formatter.calendar = calendar
        formatter.timeZone = options.timeZone
        return formatter.string(from: date)
    }

    // MARK: - Weekday Format

    /// Return weekday by the specific date and options.
    ///
    /// Three types have been provided:
    /// - min
    ///     - e.g., "一、二、三" in Chinese
    /// - short
    ///     - e.g, "周一、周二、周三" in Chinese
    /// - long
    ///     - e.g., "Monday, Tuesday, Wednesday" in English
    ///
    /// - Parameter date: An instance from struct Date
    /// - Parameter options: The options to configure the specific type and also timezone.
    public static func formatWeekday(from date: Date, with options: Options = defaultOptions) -> String {
        let dateComponents = Calendar.gregorianCalendar.dateComponents(
            in: options.timeZone,
            from: date
        )
        let weekdayIndex = dateComponents.weekday ?? date.weekday
        switch options.timeFormatType {
        case .min:
            return weekdayAbbrString(weekday: weekdayIndex, lang: options.lang)
        case .short:
            return weekdayShortString(weekday: weekdayIndex, lang: options.lang)
        case .long:
            return weekdayFullString(weekday: weekdayIndex, lang: options.lang)
        }
    }

    // MARK: - Month Format

    /// Return month by the specific date and options.
    ///
    /// Two types have been provided:
    /// - short
    ///     - e.g, Jan, Feb, Mar...
    /// - long
    ///     - e.g., January, January, March...
    ///
    /// - Parameter date: An instance from struct Date.
    /// - Parameter options: The options to configure the specific type and also timezone.
    /// - Warning: Min type of time format will be forced to cast as long type in runtime.
    public static func formatMonth(from date: Date, with options: Options = defaultOptions) -> String {
        let dateComponents = Calendar.gregorianCalendar.dateComponents(
            in: options.timeZone,
            from: date
        )
        let monthIndex = dateComponents.month ?? date.month
        switch options.timeFormatType {
        case .short:
            return monthAbbrString(month: monthIndex, lang: options.lang)
        case .long:
            return monthFullString(month: monthIndex, lang: options.lang)
        default:
            assertionFailure("Invalid time format type in request.")
            // 兜底走 long 类型
            return monthFullString(month: monthIndex, lang: options.lang)
        }
    }

    // MARK: - Time Format

    /// Return time string that follows the specific time precision.
    ///
    /// Three types of time precision have been provided: second/minute/hour.
    ///
    /// Can be combined with `truncatingZeroTail` in option configuration:
    /// ```
    /// // Wed, 1 Jul, 2020, 02:00:00 GMT
    /// let date = Date(timeIntervalSince1970: 1593568800)
    /// let option = Options(
    ///    timeZone: TimeZone(identifier: "Asia/Shanghai")!,
    ///    is12HourStyle: true,
    ///    timePrecisionType: .hour,
    ///    shouldRemoveTrailingZeros: false
    /// )
    /// print(TimeFormatUtils.formatTime(date: date, option)) // 10:00 AM
    /// option.shouldRemoveTrailingZeros = true
    /// print(TimeFormatUtils.formatTime(date: date, option)) // 10 AM
    /// ```
    /// - Parameter date: An instance from struct Date.
    /// - Parameter options: The options to configure the specific type, timezone and also 12-hour time.
    public static func formatTime(from date: Date, with options: Options = defaultOptions) -> String {
        return formatTimeString(date: date, shouldRemoveMeridiemIndicator: false, options)
    }

    // MARK: - Date Format

    /// Return date string that follows the specific requirements.
    ///
    /// Three types of date precision have been provided: day/month.
    ///
    /// Two types of time format have been provided: short/long.
    ///
    /// Two types of date status have been provided: static/relative.
    /// ```
    /// // Wed, 1 Jul, 2020, 02:00:00 GMT
    /// let date = Date(timeIntervalSince1970: 1593568800)
    /// var option = Options(datePrecisionType: .month, timeFormatType: .short)
    /// print(TimeFormatUtils.formatDate(date), option)) // July
    /// option.timeFormatType = .long
    /// print(TimeFormatUtils.formatDate(date), option)) // Jul 2020
    /// option.datePrecisionType = .day
    /// print(TimeFormatUtils.formatDate(date), option)) // Jul 1, 2020
    /// option.timeFormatType = .short
    /// print(TimeFormatUtils.formatDate(date), option)) // Jul 1
    /// option.dateStatusType = .relative
    /// print(TimeFormatUtils.formatDate(date), option)) // Today
    /// ```
    /// - Parameter date: An instance from struct Date.
    /// - Parameter options: The options to configure the specific type and also timezone.
    /// - Warning: Min type of time format will be forced to cast as long type in runtime.
    public static func formatDate(from date: Date, with options: Options = defaultOptions) -> String {
        var option = options
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = options.timeZone
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: options.lang?.identifier ?? languageIdentifier)
        formatter.calendar = calendar
        formatter.timeZone = option.timeZone

        func getStaticDateString() -> String {
            switch (option.datePrecisionType, option.timeFormatType) {
            case (.month, .short):
                // 对应的是月份的全写，需要更新 type 为 long 再调用 formatMonth 方法
                option.timeFormatType = .long
                return TimeFormatUtils.formatMonth(from: date, with: option)
            case (.month, .long):
                formatter.dateFormat = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_YearMonthCombineFormat(lang: options.lang)
                return formatter.string(from: date)
            case (.day, .short):
                formatter.dateFormat = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthDayCombineFormat(lang: options.lang)
                return formatter.string(from: date)
            case (.day, .long):
                formatter.dateFormat = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_YearMonthDayCombineFormat(lang: options.lang)
                return formatter.string(from: date)
            default:
                assertionFailure("Invalid type combination in request.")
                // 兜底走 month & long 类型
                formatter.dateFormat = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_YearMonthCombineFormat(lang: options.lang)
                return formatter.string(from: date)
            }
        }

        switch option.dateStatusType {
        case .absolute: return getStaticDateString()
        case .relative:
            let currentDate = Date()
            // 首先判断是否是最近三天
            if calendar.isDate(currentDate, inSameDayAs: date) {
                return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_RelativeDayToday(lang: options.lang)
            } else if calendar.isDate(date, inSameDayAs: currentDate.addingTimeInterval(86_400)) {
                return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_RelativeDayTomorrow(lang: options.lang)
            } else if calendar.isDate(date, inSameDayAs: currentDate.addingTimeInterval(-86_400)) {
                return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_RelativeDayYesterday(lang: options.lang)
            } else if calendar.isDate(currentDate, equalTo: date, toGranularity: .year) {
                // 其次判断是否是同年，同年不显示年份
                formatter.dateFormat = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthDayCombineFormat(lang: options.lang)
                return formatter.string(from: date)
            } else {
                // 跨年日程的需要显示年份
                formatter.dateFormat = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_YearMonthDayCombineFormat(lang: options.lang)
                return formatter.string(from: date)
            }
        }
    }

    /// Return full absolute date string that follows the specific time format type,
    /// or the string that combined with relative date and time according to the current date.
    ///
    /// Two types of time format have been provided: short/long.
    ///
    /// Two types of date status have been provided: static/relative.
    /// ```
    /// // Wed, 1 Jul, 2020, 02:00:00 GMT
    /// let date = Date(timeIntervalSince1970: 1593568800)
    /// var option = Options(timeFormatType: .short)
    /// print(TimeFormatUtils.formatDate(date), option)) // Wed, Jul 1
    /// option.timeFormatType = .long
    /// print(TimeFormatUtils.formatDate(date), option)) // Wed, Jul 1, 2020
    /// option.dateStatusType = .relative
    /// print(TimeFormatUtils.formatDate(date), option)) // Today, Jul 1
    /// ```
    /// - Parameter date: An instance from struct Date.
    /// - Parameter options: The options to configure the specific type and also timezone.
    /// - Warning: Min type of time format will be forced to cast as long type in runtime.
    public static func formatFullDate(from date: Date, with options: Options = defaultOptions) -> String {
        var option = options
        var calendar = Calendar.gregorianCalendar
        let dateComponents = calendar.dateComponents(
            in: option.timeZone,
            from: date
        )
        option.datePrecisionType = .day

        switch option.dateStatusType {
        case .absolute:
            if option.timeFormatType == .min {
                assertionFailure("Invalid time format type in request.")
                option.timeFormatType = .long
            }
            let weekdayIndex = dateComponents.weekday ?? date.weekday
            return combineRelativeDayWithDate(
                weekdayShortString(weekday: weekdayIndex, lang: options.lang),
                TimeFormatUtils.formatDate(from: date, with: option),
                lang: options.lang
            )
        case .relative:
            return formatRelativeFullDate(from: date, with: option)
        }
    }

    // MARK: - DateTime Format

    /// Return the string that combined with date and time.
    ///
    /// Two types of time format have been provided: short/long.
    ///
    /// Three types of time precision have been provided: second/minute/hour.
    /// ```
    /// // Wed, 1 Jul, 2020, 02:00:00 GMT
    /// let date = Date(timeIntervalSince1970: 1593568800)
    /// var option = Options(timeFormatType: .short)
    /// print(TimeFormatUtils.formatDate(date), option)) // Wed, Jul 1, 10:00
    /// option.timeFormatType = .long
    /// print(TimeFormatUtils.formatDate(date), option)) // Wed, Jul 1, 2020, 10:00
    /// option.dateStatusType = .relative
    /// print(TimeFormatUtils.formatDate(date), option)) // Today, Jul 1, 10:00
    /// ```
    /// - Parameter date: An instance from struct Date.
    /// - Parameter options: The options to configure the specific type, timezone and also 12-hour time.
    /// - Warning: Min type of time format will be forced to cast as long type in runtime.
    public static func formatDateTime(from date: Date, with options: Options = defaultOptions) -> String {
        let formatter = createDateFormatter(with: options)
        return formatDateTime(from: date, formatter: formatter, options: options)
    }

    /// Return full date and time string that satisfys the specific requirements.
    ///
    /// Three types of time precision have been provided: second/minute/hour.
    ///
    /// Two types of time format have been provided: short/long.
    ///
    /// Two types of date status have been provided: static/relative.
    /// ```
    /// // Wed, 1 Jul, 2020, 02:00:00 GMT
    /// let date = Date(timeIntervalSince1970: 1593568800)
    /// var option = Options(timeFormatType: .short, shouldShowGMT: false)
    /// print(TimeFormatUtils.formatDate(date), option)) // Wed, Jul 1, 10:00
    /// option.shouldShowGMT = true
    /// option.timeFormatType = .long
    /// print(TimeFormatUtils.formatDate(date), option)) // Wed, Jul 1, 2020, 10:00 (GMT+8)
    /// option.dateStatusType = .relative
    /// print(TimeFormatUtils.formatDate(date), option)) // Today, Jul 1, 10:00 (GMT+8)
    /// ```
    /// - Parameter date: An instance from struct Date.
    /// - Parameter options: The options to configure the specific type, timezone and also 12-hour time.
    /// - Warning: Min type of time format will be forced to cast as long type in runtime.
    public static func formatFullDateTime(from date: Date, with options: Options = defaultOptions) -> String {
        var calendar = Calendar.gregorianCalendar
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: options.lang?.identifier ?? languageIdentifier)
        formatter.calendar = calendar
        formatter.timeZone = options.timeZone
        formatter.dateFormat = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_GMTFormatForiOS(lang: options.lang)
        let timeZoneString = formatter.string(from: date)
        let timeFormatString = formatTime(from: date, with: options)
        let relativeDateString = formatFullDate(from: date, with: options)
        let dateTimeString = combineRelativeDateWithTime(relativeDateString, timeFormatString, lang: options.lang)
        return options.shouldShowGMT ? combineTimeStringWithGMT(dateTimeString, timeZoneString, lang: options.lang) : dateTimeString
    }

    // MARK: - Time Format Range

    /// Return time range string that happens in one day. User can choose whether to truncate zero tail or not.
    ///
    /// Three types of time precision have been provided: second/minute/hour.
    /// ```
    /// // Wed, 1 Jul, 2020, 02:00:00 GMT
    /// let startDate = Date(timeIntervalSince1970: 1593568800)
    /// // Wed, 1 Jul, 2020, 03:00:00 GMT
    /// let endDate = Date(timeIntervalSince1970: 1593572400)
    /// var option = Options(
    /// timeFormatType: .short,
    /// shouldShowGMT: false,
    /// timePrecisionType = .minute,
    /// is12HourStyle: true
    /// )
    /// print(TimeFormatUtils.formatTimeRange(startDate: startDate, endDate, option)) // e.g., 10: 00 - 11:00 AM
    /// option.shouldRemoveTrailingZeros = true
    /// print(TimeFormatUtils.formatTimeRange(startDate: startDate, endDate, option)) // e.g., 10 - 11 AM
    /// ```
    /// - Parameter date: An instance from struct Date.
    /// - Parameter options: The options to configure the specific type, timezone and also 12-hour time.
    public static func formatTimeRange(
        startFrom startDate: Date,
        endAt endDate: Date,
        with options: Options = defaultOptions
    ) -> String {
        var option = options
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = option.timeZone
        let isInSameDay = calendar.isDate(startDate, equalTo: endDate, toGranularity: .day)

        func isInSameAMOrPM() -> Bool {
            guard isInSameDay else { return false }
            let startHour = calendar.component(.hour, from: startDate)
            let endHour = calendar.component(.hour, from: endDate)
            let isStartTimeInAM = startHour >= 0 && startHour < 12
            let isEndTimeInAM = endHour >= 0 && endHour < 12
            // 要么全部都发生在上午，要么全部都发生在下午
            return isStartTimeInAM == isEndTimeInAM
        }

        let shouldRemoveOneOfMeridiemIndicators = option.is12HourStyle && isInSameAMOrPM()
        let isMeridiemIndicatorAheadOfTime = languagesListForAheadMeridiemIndicator.contains(LanguageManager.currentLanguage)

        let startTimeString: String
        if shouldRemoveOneOfMeridiemIndicators {
            startTimeString = formatTimeString(
                date: startDate,
                shouldRemoveMeridiemIndicator: !isMeridiemIndicatorAheadOfTime,
                option
            )
        } else {
            startTimeString = formatTime(from: startDate, with: option)
        }
        let endTimeString: String
        if shouldRemoveOneOfMeridiemIndicators {
            endTimeString = formatTimeString(
                date: endDate,
                shouldRemoveMeridiemIndicator: isMeridiemIndicatorAheadOfTime,
                option
            )
        } else {
            endTimeString = formatTime(from: endDate, with: option)
        }

        if isInSameDay {
            return combineDateTimeRange(startTimeString, endTimeString, lang: options.lang)
        } else {
            // 不同天的时间走跨天时间表达的方法
            // 调为动态类型，否则生成的格式可能会过长
            option.dateStatusType = .relative
            return combineDateTimeRange(
                combineRelativeDateWithTime(
                    formatRelativeFullDate(from: startDate, accordingTo: endDate, with: option),
                    startTimeString,
                    lang: options.lang
                ),
                combineRelativeDateWithTime(
                    formatRelativeFullDate(from: endDate, accordingTo: startDate, with: option),
                    endTimeString,
                    lang: options.lang
                ),
                lang: options.lang
            )
        }
    }

    /// Return date range string that happens in different day.
    ///
    /// Two types of time format have been provided: short/long.
    ///
    /// Code example is shown in below:
    /// ```
    /// // Wed, 1 Jul, 2020, 02:00:00 GMT
    /// let startDate = Date(timeIntervalSince1970: 1593568800)
    /// // Thu, 2 Jul, 2020, 02:00:00 GMT
    /// let endDate = Date(timeIntervalSince1970: 1593572400)
    /// var option = Options(timeFormatType = .short)
    /// print(TimeFormatUtils.formatTimeRange(startDate: startDaendDate: endDate, option))
    /// // Jul 1 - Jul 2
    /// option.timeFormatType = .long
    /// option.shouldRemoveTrailingZeros = true
    /// print(TimeFormatUtils.formatTimeRange(startDate: startDaendDate: endDate, option))
    /// // Jul 1, 2020 - Jul 2, 2020
    /// ```
    /// - Parameter date: An instance from struct Date.
    /// - Parameter options: The options to configure the specific type, timezone and also 12-hour time.
    /// - Warning: Min type of time format will be forced to cast as long type in runtime.
    public static func formatDateRange(
        startFrom startDate: Date,
        endAt endDate: Date,
        with options: Options = defaultOptions
    ) -> String {
        var option = options
        // DateRange 是以 absolute & day 为粒度 format 的
        option.datePrecisionType = .day
        option.dateStatusType = .absolute
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = option.timeZone
        let currentDate = Date()
        let isInSameDay = calendar.isDate(startDate, equalTo: endDate, toGranularity: .day)
        let isStartDateInSameYear = calendar.isDate(startDate, equalTo: currentDate, toGranularity: .year)
        let isEndDateInSameYear = calendar.isDate(endDate, equalTo: currentDate, toGranularity: .year)
        let isInSameYear = isStartDateInSameYear && isEndDateInSameYear

        // 如果起始日期和结束日期为同一天,则返回起始日期对应的时间格式
        guard !isInSameDay else { return formatDate(from: startDate, with: option) }
        if option.timeFormatType == .min {
            assertionFailure("Invalid time format type in request.")
            // 兜底走 long 类型
            option.timeFormatType = .long
        }
        // 如果日期跨年的话就算选的是 short 也要强制转换为 long 类型，不然会有语义问题
        if !isInSameYear {
            option.timeFormatType = .long
        }
        let startTime = formatDate(from: startDate, with: option)
        let endTime = formatDate(from: endDate, with: option)

        return combineDateTimeRange(startTime, endTime, lang: options.lang)
    }

    /// Return date and time range string. User can choose whether to truncate zero tail or not.
    /// If user chooses short type but the date duration has crossed a year,
    /// then the result will contain different year information.
    ///
    /// Three types of time precision have been provided: second/minute/hour.
    ///
    /// Two types of time format have been provided: short/long.
    ///
    /// Code example is shown in below:
    /// ```
    /// // Wed, 1 Jul, 2020, 02:00:00 GMT
    /// let startDate = Date(timeIntervalSince1970: 1593568800)
    /// // Wed, 1 Jul, 2020, 03:00:00 GMT
    /// let endDate = Date(timeIntervalSince1970: 1593572400)
    /// var option = Options(timePrecisionType = .minute)
    /// print(TimeFormatUtils.formatTimeRange(startDate: startDate, endDate: endDate, option))
    /// // Jul 1, 2020, 10: 00 AM - Jul 2, 2020, 11:00 AM
    /// option.timeFormatType = .short
    /// option.shouldRemoveTrailingZeros = true
    /// print(TimeFormatUtils.formatTimeRange(startDate: startDate, endDate: endDate, option))
    /// // Jul 1, 10 AM - Jul 2, 11 AM
    /// ```
    /// - Parameter date: An instance from struct Date.
    /// - Parameter options: The options to configure the specific type, timezone and also 12-hour time.
    /// - Warning: Min type of time format will be forced to cast as long type in runtime.
    public static func formatDateTimeRange(
        startFrom startDate: Date,
        endAt endDate: Date,
        with options: Options = defaultOptions
    ) -> String {
        var option = options
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = option.timeZone
        // DateTimeRange 是以 day 为粒度 format 的
        option.datePrecisionType = .day
        let lang = options.lang
        let isInSameDay = calendar.isDate(startDate, equalTo: endDate, toGranularity: .day)
        let currentDate = Date()
        let isStartDateInSameYear = calendar.isDate(startDate, equalTo: currentDate, toGranularity: .year)
        let isEndDateInSameYear = calendar.isDate(endDate, equalTo: currentDate, toGranularity: .year)
        let isInSameYear = isStartDateInSameYear && isEndDateInSameYear
        let dateTimeString: String
        if option.timeFormatType == .min {
            assertionFailure("Invalid time format type in request.")
            // 用 long 类型兜底
            option.timeFormatType = .long
        }

        if isInSameDay {
            // short: Thu, Mar 15, 07:05 - 09:00
            // long: Tomorrow, Mar 15, 2019, 07:05 - 09:00
            let timeFormatString = formatTimeRange(startFrom: startDate, endAt: endDate, with: option)
            let dateFormatString = formatFullDate(from: startDate, with: option)
            dateTimeString = combineRelativeDateWithTime(dateFormatString, timeFormatString, lang: lang)
        } else {
            // 跨天但不跨年的时间范围:
            // - short: Tomorrow, Mar 15, 07:05 - Wed, Mar 16, 09:00
            // - long: Tomorrow, Mar 15, 2019, 07:05 - Wed, Mar 16, 2019, 09:00
            // 跨年的时间范围: Tomorrow, Mar 15, 2019, 07:05 - Wed, Mar 16, 2020, 09:00
            let startTimeFormatString = formatTime(from: startDate, with: option)
            let endTimeFormatString = formatTime(from: endDate, with: option)
            let startDateFormatString: String
            let endDateFormatString: String
            switch option.dateStatusType {
            case .absolute:
                // 需要处理特殊 case: 如果起始日期和结束日期跨年, 就算是 short 类型, 也要显示年份信息
                if !isInSameYear {
                    option.timeFormatType = .long
                }
                startDateFormatString = formatFullDate(from: startDate, with: option)
                endDateFormatString = formatFullDate(from: endDate, with: option)
            case .relative:
                startDateFormatString = formatRelativeFullDate(from: startDate, accordingTo: endDate, with: option)
                endDateFormatString = formatRelativeFullDate(from: endDate, accordingTo: startDate, with: option)
            }

            dateTimeString = combineDateTimeRange(
                combineRelativeDateWithTime(startDateFormatString, startTimeFormatString, lang: lang),
                combineRelativeDateWithTime(endDateFormatString, endTimeFormatString, lang: lang),
                lang: lang
            )
        }
        if option.shouldShowGMT {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: options.lang?.identifier ?? languageIdentifier)
            formatter.calendar = calendar
            formatter.timeZone = option.timeZone
            formatter.dateFormat = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_GMTFormatForiOS(lang: options.lang)
            let timeZoneString = formatter.string(from: startDate)
            return combineTimeStringWithGMT(dateTimeString, timeZoneString, lang: options.lang)
        }
        return dateTimeString
    }

    /// Return the required time string.
    ///
    /// - Parameter date: An instance from struct Date.
    /// - Parameter shouldRemoveMeridiemIndicator:  Check whether to remove meridiem indicator or not.
    /// - Parameter options: The options to configure the specific type, timezone and also 12-hour time.
    private static func formatTimeString(
        date: Date,
        shouldRemoveMeridiemIndicator: Bool,
        _ options: Options
    ) -> String {
        var calendar = Calendar.gregorianCalendar
        let formatter = DateFormatter()
        let lang = options.lang
        formatter.locale = Locale(identifier: options.lang?.identifier ?? languageIdentifier)
        formatter.calendar = calendar
        formatter.timeZone = options.timeZone
        let timeFormat: String
        switch options.timePrecisionType {
        case .second:
            if options.is12HourStyle {
                // 使用 12 小时制格式
                // 是否需要去除不必要的 0, Example: 5:00:00 AM => 5 AM, 5:30:00 AM => 5:30 AM, 5:30:36 AM => 5:30:36 AM
                if date.second | date.minute == 0, options.shouldRemoveTrailingZeros {
                    // 5:00:00 AM => 5 AM
                    formatter.dateFormat = shouldRemoveMeridiemIndicator ?
                        twelveHourOnTheHourWithoutIndicatorFormat(lang: lang) : twelveHourOnTheHourWithIndicatorFormat(lang: lang)
                } else if date.second == 0, options.shouldRemoveTrailingZeros {
                    // 5:30:00 AM => 5:30 AM
                    formatter.dateFormat = shouldRemoveMeridiemIndicator ?
                        twelveHourMinuteWithoutIndicatorFormat(lang: lang) : twelveHourMinuteWithIndicatorFormat(lang: lang)
                } else {
                    formatter.dateFormat = shouldRemoveMeridiemIndicator ?
                        twelveHourSecondWithoutIndicatorFormat(lang: lang) : twelveHourSecondWithIndicatorFormat(lang: lang)
                }
                return formatter.string(from: date)
            } else {
                // 使用 24 小时制格式
                // Example: 17:00:00 => 17:00, 17:30:00 => 17:30, 17:30:36 => 17:30:36
                let needRemoveTrailingZeros = date.second == 0 && options.shouldRemoveTrailingZeros
                formatter.dateFormat = needRemoveTrailingZeros ? twentyFourHourMinuteFormat(lang: lang) : twentyFourHourSecondFormat(lang: lang)
                return formatter.string(from: date)
            }
        case let type:
            // 精度为小时: 抹去分钟数
            // 精度为分钟: 不抹去分钟数
            let isAbleToTruncateZeroTail = (date.minute == 0 && type == .minute) || type == .hour
            let needTruncateZeroTail = options.shouldRemoveTrailingZeros && isAbleToTruncateZeroTail
            let timeInterval = date.minute == 0 || type == .minute ? 0 : -date.minute * 60
            if shouldRemoveMeridiemIndicator {
                // 使用 12 小时制格式时需要关心 shouldRemoveTrailingZeros 的值
                // Example: 5:00 AM => 5, 5:30 AM => 5:00
                let twelveHourTimeString = needTruncateZeroTail ?
                    twelveHourOnTheHourWithoutIndicatorFormat(lang: lang) : twelveHourMinuteWithoutIndicatorFormat(lang: lang)
                // 使用 24 小时制格式时, 不关心 shouldRemoveTrailingZeros 的值
                // Example: 17:00 => 17:00, 17:30 => 17:00
                formatter.dateFormat = options.is12HourStyle ? twelveHourTimeString : twentyFourHourMinuteFormat(lang: lang)
            } else {
                // 使用 12 小时制格式时需要关心化简 0 的问题
                // Example: timePrecisionType = .hour, 5:00 AM => 5 AM, 5:30 AM => 5:00 AM
                let twelveHourTimeString = needTruncateZeroTail ?
                    twelveHourOnTheHourWithIndicatorFormat(lang: lang) : twelveHourMinuteWithIndicatorFormat(lang: lang)
                formatter.dateFormat = options.is12HourStyle ? twelveHourTimeString : twentyFourHourMinuteFormat(lang: lang)
            }
            return formatter.string(from: date.addingTimeInterval(TimeInterval(timeInterval)))
        }
    }

    /// Return the required relative full date string.
    ///
    /// - Parameter targetDate: the start date.
    /// - Parameter referenceDate: the end date.
    /// - Parameter options: The options to configure the specific type, timezone and also 12-hour time.
    private static func formatRelativeFullDate(
        from date: Date,
        accordingTo referenceDate: Date = Date(),
        with options: Options
    ) -> String {
        var option = options
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = options.timeZone
        let dateComponents = calendar.dateComponents(
            in: options.timeZone,
            from: date
        )
        let currentDate = options.relativeDate ?? Date()
        let weekdayIndex = dateComponents.weekday ?? date.weekday
        let isDateInSameYear = calendar.isDate(currentDate, equalTo: date, toGranularity: .year)
        let isReferenceDateInSameYear = calendar.isDate(currentDate, equalTo: referenceDate, toGranularity: .year)
        let isInSameYear = isDateInSameYear && isReferenceDateInSameYear
        let relativeDay: String
        // 首先判断是否是最近三天
        if calendar.isDate(date, inSameDayAs: currentDate) {
            relativeDay = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_RelativeDayToday(lang: options.lang)
        } else if calendar.isDate(date, inSameDayAs: currentDate.addingTimeInterval(86_400)) {
            relativeDay = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_RelativeDayTomorrow(lang: options.lang)
        } else if calendar.isDate(date, inSameDayAs: currentDate.addingTimeInterval(-86_400)) {
            relativeDay = BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_RelativeDayYesterday(lang: options.lang)
        } else {
            // 否则正常显示星期
            relativeDay = weekdayShortString(weekday: weekdayIndex, lang: options.lang)
        }
        // 如果与当前时间不在同一年则需要显示年份信息,否则不显示
        option.timeFormatType = isInSameYear ? .short : .long
        // 获取静态的日期
        option.datePrecisionType = .day
        option.dateStatusType = .absolute
        let fullDate = TimeFormatUtils.formatDate(from: date, with: option)
        return combineRelativeDayWithDate(relativeDay, fullDate, lang: options.lang)
    }
}

extension TimeFormatUtils {
    
    public static func createDateFormatter(with options: Options = defaultOptions) -> DateFormatter {
        var calendar = Calendar.gregorianCalendar
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: options.lang?.identifier ?? languageIdentifier)
        formatter.calendar = calendar
        formatter.timeZone = options.timeZone
        return formatter
    }
    
    public static func formatDateTime(from date: Date, formatter: DateFormatter, options: Options = defaultOptions) -> String {
        var option = options
        var calendar = Calendar.gregorianCalendar

        let timeFormatString = formatTime(from: date, with: option)
        let dateFormatString: String
        if option.timeFormatType == .min {
            assertionFailure("Invalid time format type in request.")
        }
        let isShortType = option.timeFormatType == .short
        let lang = options.lang
        switch option.dateStatusType {
        case .absolute:
            // min 和 long 类型都会走 long 的 逻辑
            formatter.dateFormat = isShortType ? monthDayCombineFormat(lang: lang) : yearMonthDayCombineFormat(lang: lang)
            let dateFormatString = formatter.string(from: date)
            return combineRelativeDateWithTime(dateFormatString, timeFormatString, lang: options.lang)
        case .relative:
            let currentDate = Date()
            // 首先判断是否是今天/昨天/明天
            if calendar.isDate(currentDate, inSameDayAs: date) {
                return timeFormatString
            } else if calendar.isDate(date, inSameDayAs: currentDate.addingTimeInterval(-86_400)) {
                // Yesterday 8:16 PM
                return isShortType ? yesterdayString(lang: lang) : combineRelativeDateWithTime(yesterdayString(lang: lang), timeFormatString, lang: lang)
            } else if calendar.isDate(date, inSameDayAs: currentDate.addingTimeInterval(86_400)) {
                // Tomorrow 8:16 PM
                return isShortType ? tomorrowString(lang: lang) : combineRelativeDateWithTime(tomorrowString(lang: lang), timeFormatString, lang: lang)
            } else {
                // 其次判断是否是同年，同年不显示年份
                let isInSameYear = calendar.isDate(currentDate, equalTo: date, toGranularity: .year)
                formatter.dateFormat = isInSameYear ? monthDayCombineFormat(lang: lang) : yearMonthDayCombineFormat(lang: lang)
                let dateString = formatter.string(from: date)
                return isShortType ? dateString : combineRelativeDateWithTime(dateString, timeFormatString, lang: options.lang)
            }
        }
    }
}
