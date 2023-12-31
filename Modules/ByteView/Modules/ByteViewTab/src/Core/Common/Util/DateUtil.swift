//
//  DateUtil.swift
//  ByteViewTab
//
//  Created by kiri on 2021/8/18.
//

import Foundation
import LarkTimeFormatUtils
import LarkLocalizations

final class DateUtil {
    static func formatDuration(_ duration: TimeInterval, concise: Bool = false) -> String {
        if duration < 0 { return "" }
        let hourInterval = 3600
        let minuteInterval = 60
        let interval = Int(duration)
        var hour = 0, min = 0, seconds = 0
        if interval >= hourInterval {
            hour = interval / hourInterval
            min = (interval % hourInterval) / minuteInterval
            seconds = interval % minuteInterval
            return concise ? String(format: "%02d:%02d:%02d", hour, min, seconds) : I18n.View_G_DurationHourMinSecBraces(hour, min, seconds)
        } else if interval >= minuteInterval {
            min = interval / minuteInterval
            seconds = interval % minuteInterval
            return concise ? String(format: "%02d:%02d", min, seconds) : I18n.View_G_DurationMinSecBraces(min, seconds)
        } else {
            return concise ? String(format: "00:%02d", interval) : I18n.View_G_DurationSecBraces(interval)
        }
    }

    /// 返回 HH:MM，是否是十二小时制根据app设置 12小时显示为—>下午2:00      24小时为—>14:00
    static func formatTime(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let is12HourStyle = !is24HourTime
        let option = Options(
            is12HourStyle: is12HourStyle,
            timePrecisionType: .minute
        )
        return TimeFormatUtils.formatTime(from: date, with: option)
    }

    /// 日期转换（1、非时间  2、TimeFormatUtils满足不了需求）
    ///  顺序从上到下，先命中哪个条件就展示哪个：今天(dayAbsolute为14:22)，昨天，xx月xx日，xxxx年x月x日
    static func formatDate(_ timestamp: TimeInterval, showsTimeIfToday: Bool = false) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let is12HourStyle = !is24HourTime
        let currentZone = TimeZone.current

        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = currentZone
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: TimeFormatUtils.languageIdentifier)
        formatter.calendar = calendar
        formatter.timeZone = currentZone

        if showsTimeIfToday && calendar.isDate(Date(), inSameDayAs: date) {
            return formatTime(timestamp)
        } else {
            let option = Options(timeZone: currentZone, is12HourStyle: is12HourStyle, timeFormatType: .short,
                                 datePrecisionType: .day, dateStatusType: .relative)
            return TimeFormatUtils.formatDate(from: date, with: option)
        }
    }

    /// 日期+时间
    static func formatDateTime(_ timestamp: TimeInterval, isRelative: Bool = false) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = TimeZone.current
        if isRelative {
            var option = Options(is12HourStyle: !is24HourTime,
                                 timePrecisionType: .minute,
                                 dateStatusType: .relative)
            option.timeFormatType = .long
            if calendar.isDate(Date(), inSameDayAs: date) {
                // 判断是同天，需要增加“今天”
                var todayStr = formatDate(timestamp, showsTimeIfToday: false)
                if [.en_US, .ru_RU].contains(LanguageManager.currentLanguage) {
                    todayStr.append(",")
                } else if LanguageManager.currentLanguage == .de_DE {
                    todayStr.append(" 'um'")
                }
                return "\(todayStr) \(TimeFormatUtils.formatDateTime(from: date, with: option))"
            } else {
                return TimeFormatUtils.formatDateTime(from: date, with: option)
            }
        } else {
            var option = Options(is12HourStyle: !is24HourTime,
                                 timePrecisionType: .minute,
                                 dateStatusType: .absolute)
            if calendar.isDate(Date(), equalTo: date, toGranularity: .year) {
                // 判断是否是同年，同年不显示年份
                option.timeFormatType = .short
            } else {
                // 跨年日程的需要显示年份
                option.timeFormatType = .long
            }
            return TimeFormatUtils.formatDateTime(from: date, with: option)
        }
    }

    static func formatFullDateTime(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = TimeZone.current
        var option = Options(is12HourStyle: !is24HourTime, timePrecisionType: .minute, dateStatusType: .relative)
        if calendar.isDate(Date(), equalTo: date, toGranularity: .year) {
            // 判断是否是同年，同年不显示年份
            option.timeFormatType = .short
        } else {
            // 跨年日程的需要显示年份
            option.timeFormatType = .long
        }
        return TimeFormatUtils.formatFullDateTime(from: date, with: option)
    }

    static func formatTimeRange(startTime: TimeInterval, endTime: TimeInterval) -> String {
        let start = Date(timeIntervalSince1970: startTime)
        let end = Date(timeIntervalSince1970: endTime)
        let options = Options(is12HourStyle: !is24HourTime, timePrecisionType: .minute, shouldRemoveTrailingZeros: false)
        return TimeFormatUtils.formatTimeRange(startFrom: start, endAt: end, with: options)
    }

    static func formatWeekday(from date: Date) -> String {
        let option = Options(is12HourStyle: !is24HourTime, timeFormatType: .short)
        return TimeFormatUtils.formatWeekday(from: date, with: option)
    }

    static func formatMonth(from date: Date) -> String {
        return TimeFormatUtils.formatMonth(from: date)
    }

    static func formatDateTimeRange(startTime: TimeInterval, endTime: TimeInterval) -> String {
        let start = Date(timeIntervalSince1970: startTime)
        let end = Date(timeIntervalSince1970: endTime)
        let calendar = Calendar.gregorianCalendarWithCurrentTimeZone()
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = calendar
        formatter.timeZone = .current
        if calendar.isDate(start, inSameDayAs: end) {
            let timeRangeString = formatTimeRange(startTime: startTime, endTime: endTime)
            if calendar.isDateInToday(start) {
                return I18n.View_MV_TimeFormatToday.replacingOccurrences(of: "hh:mm", with: timeRangeString)
            } else if calendar.isDateInYesterday(start) {
                return I18n.View_G_TimeFormatYesterday.replacingOccurrences(of: "hh:mm", with: timeRangeString)
            } else {
                let dateString = formatDate(startTime)
                return "\(dateString) \(timeRangeString)"
            }
        } else {
            let startDateString = formatDate(startTime)
            let startTimeString = formatTime(startTime)
            let endDateString = formatDate(endTime)
            let endTimeString = formatTime(endTime)
            return "\(startDateString) \(startTimeString) - \(endDateString) \(endTimeString)"
        }
    }
}

private extension Calendar {
    static let gregorianCalendar = Calendar(identifier: .gregorian)

    static func gregorianCalendarWithCurrentTimeZone() -> Calendar {
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = TimeZone.current
        return calendar
    }
}
