//
//  Utils+Reminder.swift
//  Todo
//
//  Created by 白言韬 on 2020/12/7.
//

import CTFoundation
import LarkTimeFormatUtils

extension Utils {
    struct Reminder { }
}

extension Utils.Reminder {
    static let oneDayMinutes = Int64(1_440)
    static let oneWeekMinutes = Int64(10_080)
    static let utcTimeZone: TimeZone = (TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0))!

    /// 校验任务的提醒时间是不是有效
    /// - Parameters:
    ///   - tuple: dueTime reminder isAllDay
    ///   - timeZone:  用于全天任务转换到当前时区来计算
    static func isReminderInValid(_ tuple: DueRemindTuple, timeZone: TimeZone) -> Bool {
        guard var dueTime = tuple.dueTime else { return false }
        // 没有设置提醒，不需要检验
        guard let reminder = tuple.reminder, case .relativeToDueTime(let offset) = reminder else { return false }
        // 设置为不提醒，不需要检验
        if offset == NonAllDayReminder.noAlert.rawValue { return false }

        let curTime = Int64(Date().timeIntervalSince1970) / 60
        if tuple.isAllDay {
            let julianDay = JulianDayUtil.julianDay(from: dueTime, in: utcTimeZone)
            dueTime = JulianDayUtil.startOfDay(for: julianDay, in: timeZone)
        }
        let remindTime = dueTime / 60 - offset
        return curTime >= remindTime
    }

    /// 根据截止时间调整默认提醒时间
    /// - Parameters:
    ///   - offset: 待调整提醒的 offset，单位是分钟
    static func fixDefaultReminder(by dueTime: Date, offset: Int64) -> Int64 {
        let curTime = Date()
        let curOffset = Int64(dueTime.timeIntervalSince(curTime) / 60)
        return curOffset <= offset ? 0 : offset
    }

    static func fixReminder(by dueTime: Int64, offset: Int64) -> Int64 {
        let curTime = Int64(Date().timeIntervalSince1970)
        let curOffset = Int64((dueTime - curTime) / 60 )
        return curOffset <= offset ? 0 : offset
    }

    static func reminderStr(minutes: Int64, isAllDay: Bool, is12HourStyle: Bool) -> String {
        if minutes == -1 {
            return I18N.Todo_Task_AlertTimeNoAlert
        }
        if isAllDay {
            return toAllDayReminderString(minutes: minutes, is12HourStyle: is12HourStyle)
        } else {
            return toNonAllDayReminderString(minutes: minutes)
        }
    }

    private static func toAllDayReminderString(minutes: Int64, is12HourStyle: Bool) -> String {
        // 场景: 新编辑页-提醒时间-全天日程
        // 上下文: 提醒时间需要使用 UTC format，否则会有各个时区下看到的会不一样。
        let customOptions = Options(
            timeZone: TimeZone(abbreviation: "UTC") ?? TimeZone.current,
            is12HourStyle: is12HourStyle,
            timePrecisionType: .minute
        )

        if minutes < 0 {
            let startDate = Date(timeIntervalSince1970: TimeInterval(-minutes * 60))
            let startString = TimeFormatUtils.formatTime(from: startDate, with: customOptions)
            return I18N.Todo_Task_AlertTimeOnTheDayAt(startString)
        } else {
            let days = minutes / Self.oneDayMinutes + 1
            let mins = minutes - days * Self.oneDayMinutes
            let weeks = days / 7
            // 如果天数可以被7整除，说明原提醒时间是以周为单位，否则显示正确的天数
            // e.g., 8 days = 8 days, 14 days = 2 weeks
            let isBelongToWholeWeek = days % 7 == 0
            // 单条全天日程的提醒时间只能是周和天类型中二选一
            let aheadOfDays = isBelongToWholeWeek && weeks > 0 ? I18N.Todo_Task_AlertTimeNWeeksBefore(weeks) : I18N.Todo_Task_AlertTimeNDaysBefore(days)
            let startDate = Date(timeIntervalSince1970: TimeInterval(-mins * 60))
            let startString = TimeFormatUtils.formatTime(from: startDate, with: customOptions)
            return I18N.Todo_Task_AlertTimeXBeforeAt(aheadOfDays, startString)
        }
    }

    // 只降一级，降级后还是不整除则进一位，例如「1天3小时」降级为「27小时」，「1天3小时10分钟」降级为「28小时」
    private static func toNonAllDayReminderString(minutes: Int64) -> String {
        if minutes == 0 {
            return I18N.Todo_Task_AlertTimeAtTimeOfEvent
        }
        if minutes % oneWeekMinutes == 0 {
            return I18N.Todo_Task_AlertTimeNWeeksBefore(minutes / oneWeekMinutes)
        }
        if minutes % oneDayMinutes == 0 || minutes > oneWeekMinutes {
            var value = minutes / oneDayMinutes
            if minutes % oneDayMinutes != 0 { value += 1 }
            return I18N.Todo_Task_AlertTimeNDaysBefore(value)
        }
        if minutes % 60 == 0 || minutes > oneDayMinutes {
            var value = minutes / 60
            if minutes % 60 != 0 { value += 1 }
            return I18N.Todo_Task_AlertTimeNHoursBefore(value)
        }
        return I18N.Todo_Task_AlertTimeNMinutesBefore(minutes)
    }
}
