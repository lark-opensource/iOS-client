//
//  EventEditReminder.swift
//  Calendar
//
//  Created by 张威 on 2020/4/30.
//

import Foundation
import RustPB
import LarkTimeFormatUtils

struct EventEditReminder: EventReminderType, PBModelConvertible {
    typealias PBModel = RustPB.Calendar_V1_CalendarEventReminder

    private let pb: PBModel
    let minutes: Int32

    init(from pb: PBModel) {
        self.pb = pb
        self.minutes = pb.minutes
    }

    init(minutes: Int32) {
        var pb = PBModel()
        pb.method = .popup
        pb.minutes = minutes
        pb.calendarEventID = ""
        self.pb = pb
        self.minutes = minutes
    }

    func getPBModel() -> PBModel {
        return pb
    }
}

extension EventEditReminder: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.minutes == rhs.minutes)
    }
}

extension EventEditReminder: CustomDebugStringConvertible {
    var debugDescription: String {
        return "minutes: \(minutes)"
    }
}

extension EventEditReminder {
    static let oneDayMinutes = Int32(24 * 60)

    func toReminderString(isAllDay: Bool, is12HourStyle: Bool) -> String {
        if isAllDay {
            return toAllDayReminderString(is12HourStyle: is12HourStyle)
        } else {
            return toNonAllDayReminderString()
        }
    }

    private func toAllDayReminderString(is12HourStyle: Bool) -> String {
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
            return BundleI18n.Calendar.Calendar_AlertTime_OnThatDay(timeString: startString)
        } else {
            let days = minutes / EventEditReminder.oneDayMinutes + 1
            let mins = minutes - days * EventEditReminder.oneDayMinutes
            let weeks = days / 7
            // 如果天数可以被7整除，说明原提醒时间是以周为单位，否则显示正确的天数
            // e.g., 8 days = 8 days, 14 days = 2 weeks
            let isBelongToWholeWeek = days % 7 == 0
            // 单条全天日程的提醒时间只能是周和天类型中二选一
            let aheadOfDays = isBelongToWholeWeek && weeks > 0 ? BundleI18n.Calendar.Calendar_Plural_ReminderWeek(number: weeks) : BundleI18n.Calendar.Calendar_Plural_ReminderDay(number: days)
            let startDate = Date(timeIntervalSince1970: TimeInterval(-mins * 60))
            let startString = TimeFormatUtils.formatTime(from: startDate, with: customOptions)
            return BundleI18n.Calendar.Calendar_AlertTime_BeforeThatDay(aheadOfDays: aheadOfDays, timeString: startString)
        }
    }

    private func toNonAllDayReminderString() -> String {
        if minutes == 0 {
            return BundleI18n.Calendar.Calendar_AlertTime_AtTimeOfEvent
        }
        let weeks = minutes / 10_080
        let remainderOfWeek = minutes % 10_080
        let days = minutes / EventEditReminder.oneDayMinutes
        let remainderOfDay = minutes % EventEditReminder.oneDayMinutes
        let hours = minutes / 60
        let remainderOfHour = minutes % 60
        // 单条非全天日程的提醒时间只能是分钟/小时/天/周类型中选其一
        // 优先级排序: 周->天->小时->分钟
        // 能被当前级的时间长度整除则用相应的文案: e.g., 14 days = 2 weeks, 24 hours = 1 day, 60 mins = 1 hour, etc.
        // 不能被当前级的时间长度整除则降级用下一级日期显示: e.g., 13 days = 13 days, 46 hours = 46 hours, etc.
        if weeks > 0 && remainderOfWeek == 0 {
            return BundleI18n.Calendar.Calendar_Plural_ReminderWeek(number: weeks)
        } else if days > 0 && remainderOfDay == 0 {
            return BundleI18n.Calendar.Calendar_Plural_ReminderDay(number: days)
        } else if hours > 0 && remainderOfHour == 0 {
            return BundleI18n.Calendar.Calendar_Plural_ReminderHour(number: hours)
        } else {
            return BundleI18n.Calendar.Calendar_Plural_ReminderMinute(number: minutes)
        }
    }
}
