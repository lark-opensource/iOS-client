//
//  EventModel.swift
//  CalendarEvent
//
//  Created by zhuchao on 13/12/2017.
//  Copyright © 2017 EE. All rights reserved.
//

import RustPB
import Foundation
import CalendarFoundation

public typealias AccessRole = RustPB.Calendar_V1_Calendar.AccessRole

protocol CalendarEventInstanceEntity: BlockDataProtocol {
    var id: String { get }
    var eventId: String { get }
    var calendarId: String { get }
    var key: String { get }
    var organizerId: String { get }
    var startTime: Int64 { get }
    var endTime: Int64 { get }
    var startDay: Int32 { get }
    var endDay: Int32 { get }
    var startMinute: Int32 { get }
    var endMinute: Int32 { get }
    var originalTime: Int64 { get }
    var summary: String { get }
    var isAllDay: Bool { get }
    var selfAttendeeStatus: CalendarEventAttendeeEntity.Status { get }
    var isFree: Bool { get }
    // 会议室限时
    var isCreatedByMeetingRoom: (strategy: Bool, requisition: Bool) { get }
    var calAccessRole: AccessRole { get }
    var eventServerId: String { get }
    /// 权限 是否达到可以编辑日程的时间的程度
    var isEditable: Bool { get }
    var location: String { get }
    var address: String { get }
    var displayType: CalendarEvent.DisplayType { get }
    var meetingRomes: [String] { get }
    var eventColor: ColorIndex { get }
    var calColor: ColorIndex { get }
    var source: CalendarEvent.Source { get }
    var startDate: Date { get }
    var endDate: Date { get }
    var isOverOneDay: Bool { get }
    var importanceScore: String { get }
    var uniqueId: String { get }
    var isSyncFromLark: Bool { get }

    // 是否为会议室视图的instance
    var isMeetingRoomViewInstance: Bool { get }
    var isFakeInstance: Bool { get }
    var meetingRoom: Rust.MeetingRoom? { get set }

    func isDisplayFull() -> Bool
    func displaySummary() -> String
    /// 日历的 writer 或 owner 权限
    func canEdit() -> Bool
    func getDataSource() -> DataSource
    func toPB() -> CalendarEventInstance
    func originalModel() -> Any
    func shouldShowAsAllDayEvent() -> Bool
}

extension CalendarEventInstanceEntity {
    var type: BlockDataType { .instanceEntity }
    var sortKey: String { uniqueId }
    var title: String { summary }
}

extension CalendarEventInstanceEntity {

    var isMeetingRoomViewInstance: Bool { false }
    var isFakeInstance: Bool { false }
    var meetingRoom: Rust.MeetingRoom? {
        get { nil }
        set { } // do nothing
    }

    func getInstanceDays() -> Set<Int32> {
        var result = Set<Int32>()
        guard startDay <= endDay else {
            return result
        }
        for day in self.startDay...self.endDay {
            result.insert(day)
        }
        return result
    }

    func getInstanceTripleString() -> String {
        return "\(self.calendarId)\(self.key)\(self.originalTime)"
    }

    func getInstanceQuadrupleString() -> String {
        return "\(self.calendarId)\(self.key)\(self.originalTime)\(self.startTime)"
    }

    func getInstanceKeyWithTimeTuple() -> String {
        return "\(self.key)\(self.originalTime)\(self.startTime)"
    }
}

extension CalendarEventUniqueField {
    func getInstanceTripleString() -> String {
        return "\(self.calendarID)\(self.key)\(self.originalTime)"
    }
}

private let secondOfOneDay = 86_400
private let secondOf23Hours = 86_340

extension CalendarEventInstanceEntity {
    /// 全天日程 或超过24小时的夸天日程
    func isMoreThan24Hours() -> Bool {
        return (self.isAllDay || (self.endTime - self.startTime >= secondOfOneDay))
    }

    /// 全天日程 或超过24小时的夸天日程 或 开始时间是一天的开始且结束时间在当天的 23:59分之后的 非全天日程的
    func shouldShowAsAllDayEvent() -> Bool {
        return isMoreThan24Hours()
            || (self.startTime == Int64(self.startDate.dayStart().timeIntervalSince1970)
                && (self.endTime - self.startTime) >= secondOf23Hours
                && (self.endTime - self.startTime) < secondOfOneDay)
    }

    func isGoogleEvent() -> Bool {
        return self.source == .google
    }

    func isExchangeEvent() -> Bool {
        return self.source == .exchange
    }

    func isEmailEvent() -> Bool {
        return self.source == .email
    }

    /// 是否是本地日程
    func isLocalEvent() -> Bool {
        return self.getDataSource() == .system
    }

    func isBelongsTo(startTime: Date, endTime: Date) -> Bool {
        if self.startDate >= startTime, self.startDate < endTime {
            return true
        }

        if self.endDate > startTime, self.endDate <= endTime {
            return true
        }
        return (self.startDate < startTime) && (self.endDate > endTime)
    }

}

struct CalendarEventInstanceEntityFromPB: CalendarEventInstanceEntity {
    var uniqueId: String {
        return self.getInstanceQuadrupleString()
    }

    var importanceScore: String {
        if Int(originalInstance.importanceScore) ?? 0 <= 0 {
            return ""
        }
        return originalInstance.importanceScore
    }

    func originalModel() -> Any {
        return self.originalInstance
    }

    func getDataSource() -> DataSource {
        return .sdk
    }

    var id: String {
        return originalInstance.id
    }
    var eventId: String {
        return originalInstance.eventID
    }
    var calendarId: String {
        return originalInstance.calendarID
    }
    var key: String {
        return originalInstance.key
    }
    var organizerId: String {
        return originalInstance.organizerID
    }
    var startTime: Int64 {
        return originalInstance.startTime
    }
    var endTime: Int64 {
        return originalInstance.endTime
    }
    var startDay: Int32 {
        return originalInstance.startDay
    }
    var endDay: Int32 {
        return originalInstance.endDay
    }
    var startMinute: Int32 {
        return originalInstance.startMinute
    }
    var endMinute: Int32 {
        return originalInstance.endMinute
    }
    // var key: String
    var originalTime: Int64 {
        return originalInstance.originalTime
    }
    var summary: String {
        return originalInstance.summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : originalInstance.summary
    }
    var isAllDay: Bool {
        return originalInstance.isAllDay
    }

    var selfAttendeeStatus: CalendarEventAttendeeEntity.Status {
        return originalInstance.selfAttendeeStatus
    }

    var isFree: Bool {
        return originalInstance.isFree
    }

    var isCreatedByMeetingRoom: (strategy: Bool, requisition: Bool) {
        let isStrategy = originalInstance.category == .resourceStrategy
        let isRequisition = originalInstance.category == .resourceRequisition
        return (isStrategy, isRequisition)
    }

    var calAccessRole: AccessRole {
        return originalInstance.calAccessRole
    }
    var eventServerId: String {
        return originalInstance.eventServerID
    }
    var isEditable: Bool {
        return originalInstance.isEditable
    }
    var location: String {
        return originalInstance.location.location
    }
    var address: String {
        return originalInstance.location.address
    }
    var displayType: CalendarEvent.DisplayType {
        return originalInstance.displayType
    }

    var meetingRomes: [String] {
        return originalInstance.meetingRooms
    }

    var eventColor: ColorIndex {
        return originalInstance.colorIndex.isNoneColor ? originalInstance.calColorIndex : originalInstance.colorIndex
    }

    var calColor: ColorIndex {
        return originalInstance.calColorIndex
    }

    var source: CalendarEvent.Source {
        return originalInstance.source
    }

    var isSyncFromLark: Bool {
        return originalInstance.isSyncFromLark
    }

    var startDate: Date
    var endDate: Date
    var isOverOneDay: Bool {
        return !Calendar.gregorianCalendar.isDate(startDate, inSameDayAs: endDate - 1)
    }

    private let originalInstance: CalendarEventInstance

    init(withInstance instance: CalendarEventInstance) {
        self.originalInstance = instance
        let startDate = Date(timeIntervalSince1970: TimeInterval(instance.startTime))
        let endDate = Date(timeIntervalSince1970: TimeInterval(instance.endTime))
        /// 我们自己的全天日程 返回的是 utc 时区 0点的时间轴,需要转换成当前时区的时间轴
        if instance.isAllDay {
            self.startDate = startDate.utcToLocalDate()
            self.endDate = endDate.utcToLocalDate()
        } else {
            self.startDate = startDate
            self.endDate = endDate
        }
    }

    func getCreator() -> EventCreator {
        return originalInstance.creator
    }

    func toPB() -> CalendarEventInstance {
        return self.originalInstance
    }

    func isDisplayFull() -> Bool {
        return displayType == .full
    }

    func displaySummary() -> String {
        if !isDisplayFull() {
            return isFree ? BundleI18n.Calendar.Calendar_Detail_Free : selfAttendeeStatus.freeBusyStatusString
        }
        return summary
    }

    func canEdit() -> Bool {
        return calAccessRole == .writer || calAccessRole == .owner
    }
}

extension AccessRole {
    func toLocalString() -> String {
        switch self {
        case .owner:
            return BundleI18n.Calendar.Calendar_Setting_Owner
        case .reader:
            return BundleI18n.Calendar.Calendar_Setting_Reader
        case .writer:
            return BundleI18n.Calendar.Calendar_Setting_Writer
        case .freeBusyReader:
            return BundleI18n.Calendar.Calendar_Setting_FreebusyReader
        case .unknownAccessRole:
            assertionFailureLog()
            return BundleI18n.Calendar.Calendar_Setting_FreebusyReader
        @unknown default:
            return ""
        }
    }
}
