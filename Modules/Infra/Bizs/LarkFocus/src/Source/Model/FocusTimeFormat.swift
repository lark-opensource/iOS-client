//
//  FocusTimeFormat.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2022/1/6.
//

import RustPB
import Foundation
import LarkTimeFormatUtils

/// 个人状态生效时间的展示格式
/// ```
/// public struct TimeFormat {
///     var timeUnit: TimeUnit
///     var startEndLayout: StartEndLayout
/// }
/// ```
public typealias TimeFormat = RustPB.Basic_V1_TimeFormat

/// 展示的最小时间尺度（精度）
/// ```
/// public enum TimeUnit: Int {
///     case second = 0
///     case minute = 1
///     case hour   = 2
///     case day    = 3
///     case month  = 4
///     case year   = 5
/// }
/// ```
public typealias TimeUnit = RustPB.Basic_V1_TimeUnit

/// 时间展示样式
/// ```
/// public enum StartEndLayout: Int {
///     case hide      = 0  // 不展示
///     case normal    = 1  // 常规起始都显示
///     case startOnly = 2  // 只显示开始时间
///     case endOnly   = 3  // 只显示结束时间
/// }
/// ```
public typealias StartEndLayout = RustPB.Basic_V1_TimeFormat.StartEndLayout

enum FocusTimePrecision {
    /// 精确到日期
    case dateOnly
    /// 精确到分钟
    case dateTime
}

extension TimeFormat {

    var displayPrecision: FocusTimePrecision {
        switch timeUnit {
        case .second, .minute, .hour:
            return .dateTime
        case .day, .month, .year:
            return .dateOnly
        @unknown default:
            return .dateOnly
        }
    }

    func format(timestamp: Int64, is24Hour: Bool) -> String {
        // NOTE: 服务器下发的系统状态，起止时间为标准时间，不是由客户端指定，直接展示即可，不需要做转换
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        switch displayPrecision {
        case .dateOnly:
            if date.isInCurrentYear {
                // 同一年内，显示月/日
                return getFormattedString(withTime: date, maxTimeUnit: .month, minTimeUnit: .day, is24Hour: is24Hour)
            } else {
                // 不同年份，显示年/月/日
                return getFormattedString(withTime: date, maxTimeUnit: .year, minTimeUnit: .day, is24Hour: is24Hour)
            }
        case .dateTime:
            if date.isInToday {
                // 同一天内，只显示时/分
                return getFormattedString(withTime: date, maxTimeUnit: .hour, minTimeUnit: .minute, is24Hour: is24Hour)
            } else if date.isInCurrentYear {
                // 同一年内，显示月/日/时/分
                return getFormattedString(withTime: date, maxTimeUnit: .month, minTimeUnit: .minute, is24Hour: is24Hour)
            } else {
                // 不同年份，显示年/月/日/时/分
                return getFormattedString(withTime: date, maxTimeUnit: .year, minTimeUnit: .minute, is24Hour: is24Hour)
            }
        }
    }

    func format(startTimestamp: Int64, endTimestamp: Int64, is24Hour: Bool) -> String {
        switch startEndLayout {
        case .hide:         return ""
        case .startOnly:    return format(timestamp: startTimestamp, is24Hour: is24Hour)
        case .endOnly:      return format(timestamp: endTimestamp, is24Hour: is24Hour)
        case .normal:       break  // 正常情况后面处理
        @unknown default:   break
        }
        // NOTE: 服务器下发的系统状态，起止时间为标准时间，不是由客户端指定，直接展示即可，不需要做转换
        let startDate = Date(timeIntervalSince1970: TimeInterval(startTimestamp))
        let endDate = Date(timeIntervalSince1970: TimeInterval(endTimestamp))
        switch displayPrecision {
        case .dateOnly:
            if startDate.isSameTimeUnit(with: endDate, timeUnit: .day) {
                return format(timestamp: startTimestamp, is24Hour: is24Hour)
            } else if startDate.isSameTimeUnit(with: endDate, timeUnit: .year) {
                let start = getFormattedString(withTime: startDate, maxTimeUnit: .month, minTimeUnit: .day, is24Hour: is24Hour)
                let end = getFormattedString(withTime: endDate, maxTimeUnit: .month, minTimeUnit: .day, is24Hour: is24Hour)
                return "\(start)-\(end)"
            } else {
                let start = getFormattedString(withTime: startDate, maxTimeUnit: .year, minTimeUnit: .day, is24Hour: is24Hour)
                let end = getFormattedString(withTime: endDate, maxTimeUnit: .year, minTimeUnit: .day, is24Hour: is24Hour)
                return "\(start)-\(end)"
            }
        case .dateTime:
            // 不必判断和当前年份是否一致，不一致的状态未生效不会显示
            if startDate.isSameTimeUnit(with: endDate, timeUnit: .day) {
                let start = getFormattedString(withTime: startDate, maxTimeUnit: .hour, minTimeUnit: .minute, is24Hour: is24Hour)
                let end = getFormattedString(withTime: endDate, maxTimeUnit: .hour, minTimeUnit: .minute, is24Hour: is24Hour)
                return "\(start)-\(end)"
            } else if startDate.isSameTimeUnit(with: endDate, timeUnit: .year) {
                let start = getFormattedString(withTime: startDate, maxTimeUnit: .month, minTimeUnit: .minute, is24Hour: is24Hour)
                let end = getFormattedString(withTime: endDate, maxTimeUnit: .month, minTimeUnit: .minute, is24Hour: is24Hour)
                return "\(start)-\(end)"
            } else {
                let start = getFormattedString(withTime: startDate, maxTimeUnit: .year, minTimeUnit: .minute, is24Hour: is24Hour)
                let end = getFormattedString(withTime: endDate, maxTimeUnit: .year, minTimeUnit: .minute, is24Hour: is24Hour)
                return "\(start)-\(end)"
            }
        }
        return ""
    }

    private func getFormattedString(withTime time: Date,
                                    maxTimeUnit: Calendar.Component,
                                    minTimeUnit: Calendar.Component,
                                    is24Hour: Bool,
                                    localization: Bool = false) -> String {
        if localization {
            let option = getFormatOption(maxTimeUnit: maxTimeUnit, minTimeUnit: minTimeUnit, is24Hour: is24Hour)
            switch displayPrecision {
            case .dateOnly: return TimeFormatUtils.formatDate(from: time, with: option)
            case .dateTime: return TimeFormatUtils.formatDateTime(from: time, with: option)
            }
        } else {
            let formatter = getFormatRule(maxTimeUnit: maxTimeUnit, minTimeUnit: minTimeUnit)
            return formatDate(time, withFormat: formatter)
        }
    }

    private func getFormatRule(maxTimeUnit: Calendar.Component,
                               minTimeUnit: Calendar.Component) -> String {
        switch (maxTimeUnit, minTimeUnit) {
        case (.hour, .minute):      return "HH:mm"
        case (.month, .minute):     return "MM/dd HH:mm"
        case (.year, .minute):      return "yyyy/MM/dd HH:mm"
        case (.month, .day):        return "MM/dd"
        case (.year, .day):         return "yyyy/MM/dd"
        case (.year, .month):       return "yyyy/MM"
        default:
            assertionFailure("Not supported format")
            return "MM/dd"
        }
    }

    private func getFormatOption(maxTimeUnit: Calendar.Component,
                                 minTimeUnit: Calendar.Component,
                                 is24Hour: Bool) -> Options {
        switch (maxTimeUnit, minTimeUnit) {
        case (.hour, .minute):      // "HH:mm"
            return Options(
                is12HourStyle: !is24Hour,
                timePrecisionType: .minute
            )
        case (.month, .minute):     // "MM/dd HH:mm"
            return Options(
                is12HourStyle: !is24Hour,
                timeFormatType: .short,
                timePrecisionType: .minute,
                datePrecisionType: .day,
                dateStatusType: .absolute,
                shouldRemoveTrailingZeros: false
            )
        case (.year, .minute):      // "yyyy/MM/dd HH:mm"
            return Options(
                is12HourStyle: !is24Hour,
                timeFormatType: .long,
                timePrecisionType: .minute,
                datePrecisionType: .day,
                dateStatusType: .absolute,
                shouldRemoveTrailingZeros: false
            )
        case (.month, .day):        // "MM/dd"
            return Options(
                timeFormatType: .short,
                datePrecisionType: .day,
                dateStatusType: .absolute
            )
        case (.year, .day):         // "yyyy/MM/dd"
            return Options(
                timeFormatType: .long,
                datePrecisionType: .day,
                dateStatusType: .absolute,
                shouldRemoveTrailingZeros: false
            )
        default:
            assertionFailure("Not supported format")
            return Options(
                is12HourStyle: !is24Hour,
                timeFormatType: .long,
                timePrecisionType: .minute,
                datePrecisionType: .day,
                dateStatusType: .absolute,
                shouldRemoveTrailingZeros: false
            )
        }
    }

    private func formatDate(_ date: Date, withFormat formatString: String) -> String {
        let dateMatter = DateFormatter()
        dateMatter.dateFormat = formatString
        return dateMatter.string(from: date)
    }
}

extension Date {

    func isSameTimeUnit(with date: Date, timeUnit: Calendar.Component) -> Bool {
        return calendar.isDate(self, equalTo: date, toGranularity: timeUnit)
    }
}
