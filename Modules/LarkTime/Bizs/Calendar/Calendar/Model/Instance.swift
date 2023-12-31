//
//  Instance.swift
//  Calendar
//
//  Created by 张威 on 2020/9/6.
//

import Foundation
import CTFoundation

/// Instance

enum Instance {
    case rust(Rust.Instance)
    case local(Local.Instance)
}

struct ViewPageInfo {
    static let secondOfOneDay = Int64(86_400)
    static let secondOf23Hours = Int64(86_340)
}

extension Instance {

    var selfAttendeeStatus: Rust.Attendee.Status {
        switch self {
        case .local(let localInstance): return localInstance.selfAttendeeStatus
        case .rust(let rustInstance): return rustInstance.selfAttendeeStatus
        }
    }

    var displayType: CalendarEvent.DisplayType {
        switch self {
        case .local(let localInstance): return localInstance.displayType
        case .rust(let rustInstance): return rustInstance.displayType
        }
    }

    var disableEncrypt: Bool {
        switch self {
        case .local(let localInstance): return false
        case .rust(let rustInstance): return rustInstance.disableEncrypt
        }
    }

    var title: String {
        switch self {
        case .local(let localInstance): return localInstance.title
        case .rust(let rustInstance): return rustInstance.summary
        }
    }

    var canEdit: Bool {
        switch self {
        case .local(let localInstance): return localInstance.canEdit
        case .rust(let rustInstance): return rustInstance.canEdit
        }
    }

    var isThirdPartyType: Bool {
        switch self {
        case .local: return false
        case .rust(let rustInstance):
            return rustInstance.isExchangeType || rustInstance.isGoogleType
        }
    }

    var isEditable: Bool {
        switch self {
        case .local(let localInstance): return localInstance.isEditable
        case .rust(let rustInstance): return rustInstance.isEditable
        }
    }

    var isWebinar: Bool {
        switch self {
        case .local(let localInstance): return false
        case .rust(let rustInstance): return rustInstance.category == .webinar
        }
    }

    var eventColor: ColorIndex {
        switch self {
        case .local(let localInstance): return localInstance.eventColor
        case .rust(let rustInstance): return rustInstance.colorIndex.isNoneColor ? rustInstance.calColorIndex : rustInstance.colorIndex
        }
    }

    var startTime: Int64 {
        switch self {
        case .local(let localInstance):
            let startDate = localInstance.startDate ?? Date()
            return Int64(startDate.timeIntervalSince1970)
        case .rust(let rustInstance):
            return rustInstance.startTime
        }
    }

    var endTime: Int64 {
        switch self {
        case .local(let localInstance):
            let endDate = localInstance.endDate ?? Date()
            return Int64(endDate.timeIntervalSince1970)
        case .rust(let rustInstance):
            return rustInstance.endTime
        }
    }

    var uniqueId: String {
        switch self {
        case .local(let localInstance):
            return String(localInstance.hashValue)
        case .rust(let rustInstance):
            return rustInstance.quadrupleStr
        }
    }

    var calColor: ColorIndex {
        switch self {
        case .local(let localInstance): return localInstance.calColor
        case .rust(let rustInstance): return rustInstance.calColorIndex
        }
    }

    var calAccessRole: AccessRole {
        switch self {
        case .local(let localInstance):
            return localInstance.calendar.allowsContentModifications ? .writer : .unknownAccessRole
        case .rust(let rustInstance):
            return rustInstance.calAccessRole
        }
    }

    func getStartDay(in timeZone: TimeZone = .current) -> JulianDay {
        switch self {
        case .local(let localInstance):
            return JulianDayUtil.julianDay(from: localInstance.startDate ?? Date(), in: timeZone)
        case .rust(let rustInstance):
            return Int(rustInstance.startDay)
        }
    }

    func getEndDay(in timeZone: TimeZone = .current) -> JulianDay {
        switch self {
        case .local(let localInstance):
            // endDate 所在的JulianDay 并不一定能代表 instance 的 endJulianDay
            // 例如: 日程时间为 23:30 - 24: 00, 用 endDate 计算，endJulianDay = startJulianDay + 1
            // 同样时间的 SDK 日程 endDay = startDay。已经规避了这种情况
            // 为了避免这种情况，在 endDay 与 startDay 不在同一天时，对 endDate 减一秒进行计算
            // 非跨天日程不能减一秒计算。因为会存在 00: 00 的 0 分钟日程
            let endDate: Date
            if localInstance.startDate.isInSameDay(localInstance.endDate) {
                endDate = localInstance.endDate ?? Date()
            } else {
                endDate = localInstance.endDate.addingTimeInterval(-1) ?? Date()
            }
            return JulianDayUtil.julianDay(from: endDate, in: timeZone)
        case .rust(let rustInstance):
            return Int(rustInstance.endDay)
        }
    }

    func dayRange(in timeZone: TimeZone = .current) -> JulianDayRange {
        return getStartDay(in: timeZone)..<getEndDay(in: timeZone) + 1
    }

    /// 判断 Instance 是否跨天
    /// - Parameter timeZone: 指定时区，默认本地时区
    /// - Returns: 描述是否跨天
    func isCrossDay(in timeZone: TimeZone = .current) -> Bool {
        let startTimestamp: TimeInterval
        let endTimestamp: TimeInterval
        switch self {
        case .local(let localInstance):
            startTimestamp = (localInstance.startDate ?? Date()).timeIntervalSince1970
            endTimestamp = (localInstance.endDate ?? Date()).timeIntervalSince1970 - 1
        case .rust(let rustInstance):
            startTimestamp = TimeInterval(rustInstance.startTime)
            endTimestamp = TimeInterval(rustInstance.endTime) - 1
        }
        if endTimestamp - startTimestamp > 3600 * 24 {
            return true
        }
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = timeZone
        let startDate = Date(timeIntervalSince1970: startTimestamp)
        let endDate = Date(timeIntervalSince1970: endTimestamp)
        return !calendar.isDate(startDate, inSameDayAs: endDate)
    }

    /// 该被当作全天日程
    func shouldTreatedAsAllDay() -> Bool {
        let (isAllDay, startTime, endTime): (Bool, Int64, Int64)
        switch self {
        case .local(let localInstance):
            isAllDay = localInstance.isAllDay
            startTime = Int64(localInstance.startDate.timeIntervalSince1970)
            endTime = Int64(localInstance.endDate.timeIntervalSince1970)
        case .rust(let rustInstance):
            isAllDay = rustInstance.isAllDay
            startTime = rustInstance.startTime
            endTime = rustInstance.endTime
        }

        if isAllDay { return true }
        if endTime - startTime >= ViewPageInfo.secondOfOneDay { return true }
        guard endTime - startTime >= ViewPageInfo.secondOf23Hours else { return false }
        let startDate = Date(timeIntervalSince1970: TimeInterval(startTime))
        return startTime == Int64(startDate.dayStart().timeIntervalSince1970)
    }

}

// MARK: MeetingRoom

extension Instance {

    var isCreatedByMeetingRoom: (strategy: Bool, requisition: Bool) {
        guard case .rust(let rustInstance) = self else {
            return (false, false)
        }
        return (rustInstance.category == .resourceStrategy, rustInstance.category == .resourceRequisition)
    }
}

// MARK: Group By Day

typealias DayRustInstanceMap = [JulianDay: [Rust.Instance]]
typealias DayInstanceMap = [JulianDay: [Instance]]

extension Instance {

    /// 对 instances 根据 day 进行分组
    ///
    /// - Parameters:
    ///   - instances: 原 instances
    ///   - dayRange: 目标范围
    ///   - timeZone: 时区
    /// - Returns: 被分组的 instances（记为 dict），`Set(dict.keys) == Set(dayRange)`
    static func groupedByDay(
        from instances: [Instance],
        for dayRange: JulianDayRange,
        in timeZone: TimeZone
    ) -> DayInstanceMap {
        var instanceMap = DayInstanceMap()
        dayRange.forEach { instanceMap[$0] = [] }
        for instance in instances {
            let instanceDayRange = instance.getStartDay(in: timeZone)..<instance.getEndDay(in: timeZone) + 1
            guard instanceDayRange.overlaps(dayRange) else { continue }
            for day in dayRange where instanceDayRange.contains(day) {
                instanceMap[day]?.append(instance)
            }
        }
        assert(Set(instanceMap.keys) == Set(dayRange))
        return instanceMap
    }

    func transformToCalendarEventInstanceEntity() -> CalendarEventInstanceEntity {
        switch self {
        case .local(let localEvent):
            return CalendarEventInstanceEntityFromLocal(event: localEvent)
        case .rust(let pbEvent):
            return CalendarEventInstanceEntityFromPB(withInstance: pbEvent)
        }
    }

}

extension Instance: CustomDebugStringConvertible {
    var debugDescription: String {
        return ""
    }
}
