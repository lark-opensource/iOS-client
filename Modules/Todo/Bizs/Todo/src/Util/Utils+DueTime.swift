//
//  Utils+DueTime.swift
//  Todo
//
//  Created by 张威 on 2020/12/20.
//

import LarkTimeFormatUtils
import CTFoundation
import Darwin

extension Utils {
    struct DueTime { }
    struct TimeFormat { }
}

extension Utils.TimeFormat {

    static let OneHour: TimeInterval = 3_600
    static let HalfDay: TimeInterval = 43_200
    // 千分位
    static let Thousandth: Int64 = 1_000

    /// 全天任务是utc时区的0点0分,在排序分组的时候按照当前时区的最后一秒: 23:59:59
    static func lastSecondForAllDay(_ dueTime: Int64, timeZone: TimeZone) -> Int64 {
        let julianDay = JulianDayUtil.julianDay(from: dueTime, in: timeZone)
        let utc = JulianDayUtil.startOfDay(for: julianDay, in: utcTimeZone)
        let cur = JulianDayUtil.startOfDay(for: julianDay, in: timeZone)
        let offset = Int64(utc - cur)
        return (dueTime - offset) / 3_600 * 3_600 + 3_600 * 24 - 1
    }

    ///  格式化时间
    static func formatDateTimeStr(by timestamp: Int64, timeZone: TimeZone, is12HourStyle: Bool) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let isInSameYear = calendar.isDate(Date(), equalTo: date, toGranularity: .year) && FeatureGating.boolValue(for: .startTime)
        var options = TimeFormatUtils.defaultOptions
        options.is12HourStyle = is12HourStyle
        options.timePrecisionType = .minute
        options.dateStatusType = FeatureGating.boolValue(for: .startTime) ? .absolute : .relative
        options.timeZone = timeZone
        options.timeFormatType = isInSameYear ? .short : .long
        return TimeFormatUtils.formatDateTime(from: date, with: options)
    }

    /// 格式化日期，用于全天任务
    static func formatDateStr(by timestamp: Int64, timeZone: TimeZone) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        var options = TimeFormatUtils.defaultOptions
        options.timeZone = timeZone
        options.dateStatusType = .relative
        return TimeFormatUtils.formatDate(from: date, with: options)
    }

    static func formatTimeStr(by todo: Rust.Todo, timeContext: TimeContext) -> String? {
        var startText: String?, dueText: String?
        if todo.isStartTimeValid && FeatureGating.boolValue(for: .startTime) {
            if todo.isAllDay {
                startText = Self.formatDateStr(
                    by: todo.startTimeForDisplay(timeContext.timeZone),
                    timeZone: timeContext.timeZone
                )
            } else {
                startText = Self.formatDateTimeStr(
                    by: todo.startTimeForFormat,
                    timeZone: timeContext.timeZone,
                    is12HourStyle: timeContext.is12HourStyle
                )
            }
        }
        if todo.isDueTimeValid {
            if todo.isAllDay {
                dueText = Self.formatDateStr(
                    by: todo.dueTimeForDisplay(timeContext.timeZone),
                    timeZone: timeContext.timeZone
                )
            } else {
                dueText = Self.formatDateTimeStr(
                    by: todo.dueTime,
                    timeZone: timeContext.timeZone,
                    is12HourStyle: timeContext.is12HourStyle
                )
            }
        }
        if let startText = startText, let dueText = dueText {
            return "\(startText) - \(dueText)"
        } else if let startText = startText {
            return I18N.Todo_TaskStartsFrom_Text(startText)
        } else if let dueText = dueText {
            return I18N.Todo_Task_TimeDue(dueText)
        }
        return nil
    }

}

extension Utils.DueTime {

    /// 获取 dueTime 格式化字符串
    /// - Parameters:
    ///   - timestamp: 时间戳（单位 - 秒）
    ///   - timeZone: 时区
    ///   - isAllDay: 是否全天任务
    ///   - is12HourStyle: 十二小时制
    static func formatedString(
        from timestamp: Int64,
        in timeZone: TimeZone,
        isAllDay: Bool,
        is12HourStyle: Bool
    ) -> String {
        if isAllDay {
            let time = Utils.TimeFormat.lastSecondForAllDay(timestamp, timeZone: timeZone)
            return Utils.TimeFormat.formatDateStr(by: time, timeZone: timeZone)
        } else {
            return Utils.TimeFormat.formatDateTimeStr(
                by: timestamp,
                timeZone: timeZone,
                is12HourStyle: is12HourStyle
            )
        }
    }

    /// 获取指定天的默认开始/截止时间
    /// - Parameters:
    ///   - offset: 截止日期当天截止时间点，范围[0 * 60, 24 * 60)（单位 - 分钟）
    ///   - date: 指定天，时分秒会被直接抹掉，不被使用
    /// - Returns: 默认截止时间
    static func defaultDaytime(
        byOffset offset: Int64,
        date: Date,
        skipToday: Bool = false,
        timeZone: TimeZone
    ) -> Date {
        let offset = Int(offset)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        if !skipToday, calendar.isDateInToday(date) {
            return todayDuetime(byOffset: offset, timeZone: timeZone)
        }

        var components = getDateComponents(from: date, timeZone: timeZone)
        components.hour = offset / 60
        components.minute = offset % 60
        components.second = 0
        return getDate(from: components, timeZone: timeZone)
    }

    private static func todayDuetime(
        byOffset offset: Int,
        timeZone: TimeZone
    ) -> Date {

        var components = getDateComponents(from: Date(), timeZone: timeZone)
        let boundaryOffset = offset - 60
        guard let hour = components.hour, let minute = components.minute else {
            return Date()
        }
        let currentOffset = hour * 60 + minute
        var resultOffset: Int

        // 需要确保边界值有效
        if boundaryOffset > 0 && currentOffset < boundaryOffset {
            resultOffset = offset
        } else {
            // 当前时间超过边界值以后，抹掉分钟信息，小时数+2处理，需要限定最大值
            resultOffset = (currentOffset / 60 + 2) * 60
            resultOffset = min(resultOffset, 24 * 60 - 1)
        }

        components.hour = resultOffset / 60
        components.minute = resultOffset % 60
        components.second = 0
        return getDate(from: components, timeZone: timeZone)
    }

    private static func getDateComponents(from date: Date, timeZone: TimeZone) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }

    private static func getDate(from dateComponents: DateComponents, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: dateComponents) ?? Date()
    }

}
