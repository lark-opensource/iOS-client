//
//  WorkingHoursAble.swift
//  Calendar
//
//  Created by zhouyuan on 2019/5/21.
//

import Foundation
import CalendarFoundation

struct AttendeeFreeBusyInfo {

    typealias Attendee = (name: String, calendarId: String)

    enum FreeBusy {
        case free
        case maybeFree
        case busy
    }

    let totalCount: Int

    // 忙碌
    let busyAttendees: [Attendee]
    // 空闲
    let freeAttendees: [Attendee]
    // 可能空闲
    let maybeFreeAttendees: [Attendee]

    init() {
        self.init(totalCount: 0, busyAttendees: [], freeAttendees: [], maybeFreeAttendees: [])
    }

    init(totalCount: Int,
        busyAttendees: [Attendee],
        freeAttendees: [Attendee],
        maybeFreeAttendees: [Attendee]) {
        self.totalCount = totalCount
        self.busyAttendees = busyAttendees
        self.freeAttendees = freeAttendees
        self.maybeFreeAttendees = maybeFreeAttendees
        assert(totalCount == busyAttendees.count + freeAttendees.count + maybeFreeAttendees.count, "total count should be equal to sum of different attendees count!")
    }
}

extension AttendeeFreeBusyInfo {

    private var atLeastOne: Bool { totalCount > 0 }

    var isAllFree: Bool {
        return totalCount == freeAttendees.count && atLeastOne
    }

    var isAllBusy: Bool {
        return totalCount == busyAttendees.count && atLeastOne
    }
}

protocol FreebusyCalculation {
    typealias FreeBusyInfo = (count: Int, names: [String], calendarIds: [String])
}

extension FreebusyCalculation {
    func calculationFreeBusyInfo(startTime: Date,
                                 endTime: Date,
                                 calendarInstanceMap: InstanceMap,
                                 attendees: [UserAttendeeBaseDisplayInfo]
        ) -> FreeBusyInfo? {
        if (calendarInstanceMap.isEmpty && !attendees.isEmpty) || startTime >= endTime {
            return nil
        }
        let totalAttendeeCnt = attendees.count
        var conflictIds = [String]()
        calendarInstanceMap.forEach { (calendarId, instances) in
            for instance in instances {
                if !(startTime >= instance.endDate || endTime <= instance.startDate) {
                    conflictIds.append(calendarId)
                    break
                }
            }
        }
        let conflictName = conflictIds.map { (calendarId) -> String in
            if let attendee = attendees.first(where: { calendarId == $0.calendarId }) {
                return attendee.name
            }
            assertionFailureLog()
            return ""
        }
        return (count: totalAttendeeCnt, names: conflictName, calendarIds: conflictIds)
    }

    // 未回复/待定 优化
    func opt_calculationFreeBusyInfo(startTime: Date,
                                     endTime: Date,
                                     calendarInstanceMap: InstanceMap,
                                     attendees: [UserAttendeeBaseDisplayInfo],
                                     privateCalendarIds: [String] = []
    ) -> AttendeeFreeBusyInfo? {

        if (calendarInstanceMap.isEmpty && !attendees.isEmpty) || startTime >= endTime {
            return nil
        }

        var busyIds = [String]()
        var freeIds = [String]()
        var maybeFreeIds = [String]()

        calendarInstanceMap.forEach { (calendarId, instances) in
            // 遍历每一个日历里面，和当前时段有交集的所有Instance
            var calendarFreeBusyResult = AttendeeFreeBusyInfo.FreeBusy.free
            // 私密日历直接当做可能空闲， FG外当做空闲
            if privateCalendarIds.contains(calendarId) {
                calendarFreeBusyResult = .maybeFree
            } else {
                for instance in instances
                where (!(startTime >= instance.endDate || endTime <= instance.startDate)) {
                    if instance.selfAttendeeStatus == .accept {
                        calendarFreeBusyResult = .busy
                        break
                    } else if (instance.selfAttendeeStatus == .needsAction || instance.selfAttendeeStatus == .tentative) && calendarFreeBusyResult != .busy {
                        calendarFreeBusyResult = .maybeFree
                    }
                }
            }
            switch calendarFreeBusyResult {
            case .free: freeIds.append(calendarId)
            case .maybeFree: maybeFreeIds.append(calendarId)
            case .busy: busyIds.append(calendarId)
            }
        }

        let appendName = { (calendarId: String) -> AttendeeFreeBusyInfo.Attendee in
            if let attendee = attendees.first(where: { calendarId == $0.calendarId }) {
                return (attendee.name, calendarId)
            }
            assertionFailureLog()
            return ("", calendarId)
        }

        return AttendeeFreeBusyInfo(totalCount: attendees.count,
                                    busyAttendees: busyIds.map(appendName),
                                    freeAttendees: freeIds.map(appendName),
                                    maybeFreeAttendees: maybeFreeIds.map(appendName))
    }
}

protocol WorkingHoursCalculation {
}

extension WorkingHoursCalculation {
    func getWorkingHousTimeRangsMap(date: Date,
                                    workHourSettingMap: WorkHourMap,
                                    timezoneMap: [String: String],
                                    uiTimeZoneId: String
        ) -> [String: [WorkingHoursTimeRange]] {

        var resultMap: [String: [WorkingHoursTimeRange]] = [:]
        workHourSettingMap.forEach { (calendarId, workHourSetting) in
            if workHourSetting.enableWorkHour {
                var timezone: TimeZone {
                    if let timezoneString = timezoneMap[calendarId] {
                        return TimeZone(identifier: timezoneString) ?? TimeZone.current
                    } else {
                        assertionFailureLog("cannot get timezone, will use default timezone")
                        return TimeZone.current
                    }
                }
                if let timeRanges = getWorkingHoursTimeRanges(date: date,
                                                              workHourSetting: workHourSetting,
                                                              timezone: timezone,
                                                              uiTimeZoneId: uiTimeZoneId) {
                    resultMap[calendarId] = timeRanges
                }
            }
        }
        return resultMap
    }

    func getWorkHourConflictCalendarIds(
        startTime: Date,
        endTime: Date,
        workingHoursTimeRangeMap: [String: [WorkingHoursTimeRange]],
        timeZoneId: String) -> [String] {

        if workingHoursTimeRangeMap.isEmpty || startTime >= endTime {
            return []
        }
        let calendar = TimeZoneUtil.getCalendar(timeZoneId: timeZoneId)
        let startMinute = startTime.minutesSince(date: startTime.dayStart(calendar: calendar))
        let endMinute = endTime.minutesSince(date: startTime.dayStart(calendar: calendar))
        var conflictIds = [String]()
        workingHoursTimeRangeMap.forEach { (calendarId, timeRanges) in
            var isInworkHour = false
            for timeRange in timeRanges {
                if startMinute >= timeRange.startMinute && endMinute <= timeRange.endMinute {
                    isInworkHour = true
                }
            }
            if !isInworkHour {
                conflictIds.append(calendarId)
            }
        }
        return conflictIds
    }

    /// 需要转换时区
    private func getWorkingHoursTimeRanges(date: Date,
                                           workHourSetting: SettingModel.WorkHourSetting,
                                           timezone: TimeZone,
                                           uiTimeZoneId: String) -> [WorkingHoursTimeRange]? {
        var timeRanges: [WorkingHoursTimeRange] = []
        let currentTimezone = TimeZone(identifier: uiTimeZoneId) ?? TimeZone.current
        let minuteOffset = Int32((timezone.secondsFromGMT(for: date) - currentTimezone.secondsFromGMT(for: date)) / 60)
        let calendar = TimeZoneUtil.getCalendar(timeZoneId: uiTimeZoneId)
        guard let daysOfWeek = DaysOfWeek(rawValue: calendar.dateComponents([.weekday], from: date).weekday!) else {
            assertionFailureLog()
            return nil
        }
        if minuteOffset == 0 { /// 如果在同一个时区 则只需要去当天的
            /// 未设置工作时间 视做都是非工作时间
            guard let workHourItems = workHourSetting.workHourItems["\(daysOfWeek.toPb().rawValue)"] else {
                return timeRanges
            }
            /// 果果设置了 则不需要转换时区世界使用 span 的值
            workHourItems.spans.forEach { (span) in
                let timeRange = WorkingHoursTimeRange(startMinute: span.startMinute,
                                                      endMinute: span.endMinute)
                timeRanges.append(timeRange)
            }
            return timeRanges
        }

        /// 如果不在同一个时区
        return getDifferenceTimezoneTimeRanges(daysOfWeek: daysOfWeek,
                                               minuteOffset: minuteOffset,
                                               workHourSetting: workHourSetting)

    }

    /// 如果不在同一个时区
    private func getDifferenceTimezoneTimeRanges(
        daysOfWeek: DaysOfWeek,
        minuteOffset: Int32,
        workHourSetting: SettingModel.WorkHourSetting
        ) -> [WorkingHoursTimeRange] {
        let oneDayMinute: Int32 = 1440
        var timeRanges: [WorkingHoursTimeRange] = []

        if let workHourItems = workHourSetting.workHourItems["\(daysOfWeek.toPb().rawValue)"] {
            workHourItems.spans.forEach { (span) in
                let startMinute = span.startMinute - minuteOffset
                let endMinute = span.endMinute - minuteOffset
                if startMinute > 0 && endMinute < oneDayMinute { // 偏移时区后没有超出当天
                    let range = WorkingHoursTimeRange(startMinute: startMinute,
                                                      endMinute: endMinute)
                    timeRanges.append(range)
                } else {
                    // 存在超出部分，且是开始时间超出
                    if startMinute < 0 && endMinute > 0 {
                        let range = WorkingHoursTimeRange(startMinute: 0,
                                                          endMinute: endMinute)
                        timeRanges.append(range)
                    }
                    // 存在超出部分，且是结束时间超出
                    if startMinute < oneDayMinute && endMinute > oneDayMinute {
                        let range = WorkingHoursTimeRange(startMinute: startMinute,
                                                          endMinute: oneDayMinute)
                        timeRanges.append(range)
                    }
                }
            }
        }

        if minuteOffset < 0 { /// 比我的时区晚 则还需要计算前一天的工作时间
            if let previousWorkHourItems = workHourSetting.workHourItems["\(daysOfWeek.previous().toPb().rawValue)"] {
                previousWorkHourItems.spans.forEach { (span) in
                    let startMinute = span.startMinute - minuteOffset
                    let endMinute = span.endMinute - minuteOffset
                    // 存在超出部分，且是结束时间超出
                    if endMinute > oneDayMinute {
                        let start = startMinute - oneDayMinute
                        let range = WorkingHoursTimeRange(startMinute: max(start, 0),
                                                          endMinute: endMinute - oneDayMinute)
                        timeRanges.append(range)
                    }

                }
            }
        }

        if minuteOffset > 0 { /// 比我的时区早 则还需要计算后一天的工作时间
            if let nextWorkHourItems = workHourSetting.workHourItems["\(daysOfWeek.next().toPb().rawValue)"] {
                nextWorkHourItems.spans.forEach { (span) in
                    let startMinute = span.startMinute - minuteOffset
                    let endMinute = span.endMinute - minuteOffset
                    // 存在超出部分，且是开始时间超出
                    if startMinute < 0 {
                        let end = endMinute + oneDayMinute
                        let range = WorkingHoursTimeRange(
                            startMinute: startMinute + oneDayMinute,
                            endMinute: min(end, oneDayMinute)
                        )
                        timeRanges.append(range)
                    }
                }
            }
        }
        return timeRanges
    }
}
