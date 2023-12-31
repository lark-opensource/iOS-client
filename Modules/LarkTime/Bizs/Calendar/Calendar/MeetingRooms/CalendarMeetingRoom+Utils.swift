//
//  CalendarMeetingRoom+Utils.swift
//  Calendar
//
//  Created by LiangHongbin on 2022/4/11.
//

import Foundation
import LarkTimeFormatUtils
import CalendarFoundation
import RustPB

// MeetingRoom rules & alerts text
extension CalendarMeetingRoom {

    /// 预定时间信息文案（会议室状态 - 已被预订时间段）
    /// e.g. 4 月12 日（明天）11:00 - 12:00
    /// - Parameters:
    ///   - startTime: 日程开始时间
    ///   - endTime: 日程结束时间
    ///   - isAllday: Bool
    static func scheduledTimeText(startTime: TimeInterval,
                                  endTime: TimeInterval,
                                  isAllday: Bool) -> String {
        let customOptions = Options(
            is12HourStyle: SettingService.shared().is12HourStyle.value,
            timePrecisionType: .minute,
            datePrecisionType: .day
        )
        let start = Date(timeIntervalSince1970: startTime)
        let end = Date(timeIntervalSince1970: endTime)
        return CalendarTimeFormatter.formatFullDateTimeRange(
            startFrom: start,
            endAt: end,
            isAllDayEvent: isAllday,
            shouldTextInOneLine: true,
            shouldShowTailingGMT: false,
            with: customOptions
        )
    }

    /// 会议室在时间范围内被征用文案
    /// e.g. isReason = true -- 会议室在2022年4月12日10:22至2023年3月10日10:21被禁用（包含永久禁用）
    ///    isReason = false -- 禁用时段：2022年4月12日10:22 - 2023年3月10日10:21（包含永久禁用）
    /// - Parameters:
    ///   - requiStartTime: 征用开始时间
    ///   - requiEndTime: 征用结束时间
    ///   - eventTimeZoneId: 日程时区 id
    ///   - meetingRoomTimeZoneId: 会议室时区 id
    ///   - isReason: 文案是否为「不可预订原因」场景（false -> 会议室规则场景）
    static func requisitionText(requiStartTime: TimeInterval,
                                requiEndTime: TimeInterval,
                                eventTimeZoneId: String,
                                meetingRoomTimeZoneId: String,
                                isReason: Bool = true) -> String {

        let customOptions = Options(
            timeZone: TimeZone(identifier: eventTimeZoneId) ?? .current,
            is12HourStyle: SettingService.shared().is12HourStyle.value,
            timeFormatType: .long,
            timePrecisionType: .minute,
            datePrecisionType: .day
        )

        let startDate = Date(timeIntervalSince1970: requiStartTime)
        let endDate = Date(timeIntervalSince1970: requiEndTime)

        let startStr = TimeFormatUtils.formatDateTime(from: startDate, with: customOptions)
        let endStr = TimeFormatUtils.formatDateTime(from: endDate, with: customOptions)

        if isReason {
            return requiEndTime == 0 ? BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomInactiveForeverCantReserve(StartTime: startStr) :
            BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomInactiveCantReserve(StartTime: startStr, EndTime: endStr)
        } else {
            return requiEndTime == 0 ?
            BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomInactiveForever(StartTime: startStr) :
            BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomInactive(StartTime: startStr, EndTime: endStr)
        }
    }

    /// 会议室不可预订范围文案
    /// e.g. isReason = true -- 预订时段仅限于：08:00 - 20:00
    ///    isReason = false -- 每日可被预订时段 08:00 - 20:00
    /// - Parameters:
    ///   - eventStartDate: 日程开始时间
    ///   - dailyStartTime: 每日开始预定时间（seconds）
    ///   - dailyEndTime: 每日结束预订时间（seconds）
    ///   - eventTimeZoneId: 日程时区ID
    ///   - meetingRoomTimeZoneId: 会议室时区ID
    ///   - isReason: 文案是否为「不可预订原因」场景（false -> 会议室规则场景）
    static func usableTimeText(eventStartDate: Date,
                               dailyStartTime: TimeInterval,
                               dailyEndTime: TimeInterval,
                               eventTimeZoneId: String,
                               meetingRoomTimeZoneId: String,
                               isReason: Bool = true) -> String {
        let eventTimeZone = TimeZone(identifier: eventTimeZoneId) ?? .current
        let meetingRoomTimeZone = TimeZone(identifier: meetingRoomTimeZoneId) ?? .current

        let customOptions = Options(
            timeZone: eventTimeZone,
            is12HourStyle: SettingService.shared().is12HourStyle.value,
            timePrecisionType: .minute
        )

        // 会议室状态显示日程开始时间对应时区，会议室详情显示系统时区
        let timeIntervalRanges = availableTimeIntervalRanges(
            by: eventStartDate,
            dailyStartTime,
            dailyEndTime,
            eventTimeZone, meetingRoomTimeZone, customOptions.is12HourStyle
        )
        let comma = BundleI18n.Calendar.Calendar_Common_Comma
        let timeStr = timeIntervalRanges.reduce("", { result, range in
            let str = CalendarTimeFormatter.formatOneDayTimeRange(
                startFrom: range.startDate,
                endAt: range.endDate,
                with: customOptions
            )
            return result + str + (range == timeIntervalRanges.last ? "" : comma)
        })
        if isReason {
            return BundleI18n.Calendar.Calendar_MeetingView_ReservationsNotOpenYet(AvailableTimePeriod: timeStr)
        } else {
            return BundleI18n.Calendar.Calendar_MeetingView_DailyOpenTime(AvailableTimePeriod: timeStr)
        }

    }

    /// 会议室单次预订最大时长文案
    /// e.g. isReason = true -- 单次最长可预定 2 小时
    ///    isReason = false -- 预订时长不可超过 2 小时
    /// - Parameters:
    ///   - seconds: 单次最大预订时长（seconds）
    ///   - isReason: 文案是否为「不可预订原因」场景（false -> 会议室规则场景）
    static func maxDurationText(fromSeconds seconds: Int32, isReason: Bool = true) -> String {
        // 单次可预定时间不跨天，目前只支持两个刻度: 分钟, 小时
        let oneMinute: Int32 = 60
        let oneDay: Int32 = 86_400
        guard seconds > oneMinute || seconds < oneDay else {
            assertionFailure("Available time period is invaild")
            return ""
        }
        let hours = seconds / (oneMinute * 60)
        let isIntHour = (seconds % (oneMinute * 60)) == 0
        let timeStr: String
        // 60 分钟整数倍显示小时，否则显示分钟
        if isIntHour {
            timeStr = BundleI18n.Calendar.Calendar_Plural_CommonHrs(number: hours)
        } else {
            let minutes = seconds / oneMinute
            timeStr = BundleI18n.Calendar.Calendar_Plural_CommonMins(number: minutes)
        }

        if isReason {
            return BundleI18n.Calendar.Calendar_Edit_MeetingRoomReserveMaxDuration(TimeLimit: timeStr)
        } else {
            return BundleI18n.Calendar.Calendar_MeetingView_MaxDurationRoom(duration: timeStr)
        }
    }

    /// 最早可预订时间 alert 文案
    /// e.g. 仅支持于 2022 年 4 月 14日 08:00 后预定
    /// - Parameters:
    ///   - hoursInSeconds: 开放预订当天时间（in seconds）
    ///   - meetingRoomTimeZone: 会议室所在时区
    static func earliestBookTimeText(regularReservableTime hoursInSeconds: TimeInterval,
                                     meetingRoomTimeZone: String) -> String {
        let is12HourStyle = SettingService.shared().is12HourStyle.value
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = TimeZone(identifier: meetingRoomTimeZone) ?? .current
        let regularBookTime = Date().dayStart(calendar: calendar).addingTimeInterval(hoursInSeconds)
        let timeInCurrentTZ = TimeFormatUtils.formatDateTime(from: regularBookTime,
                                                             with: Options(is12HourStyle: is12HourStyle, timePrecisionType: .minute))
        return BundleI18n.Calendar.Calendar_MeetingView_OpenReservationWhen(date: timeInCurrentTZ)
    }

    /// 会议室最远可预订预定 alert 文案
    /// e.g. 仅支持预订至 2022 年 4 月 14 日 23:59
    /// - Parameters:
    ///   - furthestTime: 最远可预订到的日期（计算逻辑在 MeetingRoom+ResourceStrategy 中）
    static func furthestBookTimeText(furthestTime: Date) -> String {
        let is12HourStyle = SettingService.shared().is12HourStyle.value
        let customOptions = Options(
            is12HourStyle: is12HourStyle,
            timePrecisionType: .minute,
            datePrecisionType: .day
        )
        let timeStr = TimeFormatUtils.formatDateTime(from: furthestTime, with: customOptions)
        return BundleI18n.Calendar.Calendar_MeetingView_OpenReservationWhenOnly(DueDate: timeStr)
    }

    /// 会议室可提前预定文案
    /// e.g. 可提前 1 天于当天 08:30 开始预定
    /// - Parameters:
    ///   - daysInSeconds: 可提前多少天预订（seconds）
    ///   - hoursInSeconds: 开放预订当天几点可预约（seconds）
    ///   - meetingRoomTimeZone: 会议室时区ID
    static func preReserveRuleText(maxDaysReservable daysInSeconds: TimeInterval,
                                   regularReservableTime hoursInSeconds: TimeInterval,
                                   workDay: Int32,
                                   maxType: RustPB.Calendar_V1_SchemaExtraData.ResourceStrategy.MaxReservableType,
                                   meetingRoomTimeZone: String) -> String {

        let is12HourStyle = SettingService.shared().is12HourStyle.value
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = TimeZone(identifier: meetingRoomTimeZone) ?? .current
        let regularBookTime = Date().dayStart(calendar: calendar).addingTimeInterval(hoursInSeconds)

        let timeInCurrentTZ = TimeFormatUtils.formatTime(from: regularBookTime,
                                                         with: Options(is12HourStyle: is12HourStyle, timePrecisionType: .minute))
        if maxType == .workDay  {
            return BundleI18n.Calendar.Calendar_G_Common_ReserveInAdvance_Desc(number: workDay, time: timeInCurrentTZ)
        } else {
            let daysBefore = Int(daysInSeconds) / (24 * 60 * 60)
            return BundleI18n.Calendar.Calendar_MeetingView_InAdvanceTime_One(number: daysBefore) + BundleI18n.Calendar.Calendar_MeetingView_InAdvanceTime_Two(time: timeInCurrentTZ)
        }
    }

    static func availableTimeIntervalRanges(
        by startDate: Date,
        _ startTime: TimeInterval,
        _ endTime: TimeInterval,
        _ eventTimeZone: TimeZone,
        _ meetingRoomTimeZone: TimeZone,
        _ is12HourStyle: Bool
    ) -> [TimeIntervalRange] {
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = eventTimeZone
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        guard eventTimeZone != meetingRoomTimeZone else {
            // 如果会议室时区和日程时区一致，就不需要时区转换算时间区间了
            return [TimeIntervalRange(
                from: startOfDay.addingTimeInterval(startTime),
                to: startOfDay.addingTimeInterval(endTime)
            )]
        }
        let timeIntervalRange = TimeIntervalRange(
            from: startOfDay,
            to: endOfDay
        )
        return timeIntervalRange.splitedBy(
            startTime: startTime,
            endTime: endTime,
            timeZone: meetingRoomTimeZone
        )
    }
}
