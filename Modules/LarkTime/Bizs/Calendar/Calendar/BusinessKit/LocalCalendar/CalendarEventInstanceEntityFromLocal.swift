//
//  CalendarEventInstanceEntityFromLocal.swift
//  Calendar
//
//  Created by jiayi zou on 2018/9/11.
//  Copyright © 2018 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import EventKit
import RustPB

struct CalendarEventInstanceEntityFromLocal: CalendarEventInstanceEntity {
    var importanceScore: String {
        return ""
    }

    var uniqueId: String {
        return self.id
    }

    func toPB() -> CalendarEventInstance {
        assertionFailureLog()
        return CalendarEventInstance()
    }

    func originalModel() -> Any {
        return localEvent
    }

    func getDataSource() -> DataSource {
        return .system
    }

    func isDisplayFull() -> Bool {
        return self.displayType == .full
    }

    func displaySummary() -> String {
        return self.summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : self.summary
    }

    func canEdit() -> Bool {
        return localEvent.calendar.allowsContentModifications || (localEvent.organizer?.isCurrentUser ?? false )
    }

    private var localEvent: EKEvent

    var id: String {
        return String(localEvent.hashValue)
    }
    var eventId: String {
        return localEvent.eventIdentifier ?? ""
    }
    var calendarId: String {
        return localEvent.calendar.calendarIdentifier
    }
    var key: String {
       // assertionFailureLog("you should not use local event instance key")
        return "you should not use local event instance key\(arc4random())"
    }
    var organizerId: String {
        return "\(localEvent.organizer?.hashValue ?? 0)"
    }
    var startTime: Int64 {
        return Int64(localEvent.startDate?.timeIntervalSince1970 ?? 0)
    }

    var endTime: Int64 {
        return Int64(localEvent.endDate?.timeIntervalSince1970 ?? 0)
    }

    var startDay: Int32 {
        return getJulianDay(date: localEvent.startDate ?? Date(), calendar: calendar)
    }
    var endDay: Int32 {
        return getJulianDay(date: localEvent.endDate ?? Date(), calendar: calendar)
    }
    var startMinute: Int32 {
        return getJulianMinute(date: localEvent.startDate ?? Date(), calendar: calendar)
    }
    var endMinute: Int32 {
        return getJulianMinute(date: localEvent.endDate ?? Date(), calendar: calendar)
    }
    //var key: String
    var originalTime: Int64 {
        return Int64(localEvent.occurrenceDate?.timeIntervalSince1970 ?? 0)
    }
    var summary: String {
        return (localEvent.title ?? "").isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : localEvent.title
    }
    var isAllDay: Bool {
        return localEvent.isAllDay
    }

    var selfAttendeeStatus: CalendarEventAttendeeEntity.Status {
        return localEvent.getSelfAttendee()?.participantStatus.toCalendarEvnetAttendeeStatus() ?? .accept
    }
    var isFree: Bool {
        return localEvent.availability == .free
    }
    var isCreatedByMeetingRoom: (strategy: Bool, requisition: Bool) = (false, false)
    var calAccessRole: AccessRole {
        guard let calendar = localEvent.calendar else {
            return .unknownAccessRole
        }
        return calendar.allowsContentModifications ? .writer : .unknownAccessRole
    }
    var eventServerId: String {
        return localEvent.eventIdentifier ?? ""
    }
    /// 是否有完整编辑权限
    var isEditable: Bool {
        //如果一个日程没有organizer，那么大概率是自己创建的日程（小概率是订阅的，但是那样日历不可修改）
        //或者organizer是自身
        //这里暂时先不考虑writer编辑的情况
        if let result = localEvent.value(forKey: "isEditable") as? Bool {
            return result
        }
        guard let calendar = localEvent.calendar else {
            return false
        }
        return calendar.allowsContentModifications &&
            ((localEvent.organizer == nil) || (localEvent.organizer?.isCurrentUser ?? false ))
    }

    var location: String {
        return localEvent.structuredLocation?.title ?? ""
    }
    var address: String {
        return ""
    }
    var displayType: CalendarEvent.DisplayType {
        //目前我没有找到使用caldav方式订阅无权限日历的方法，如果有这里还要改~
        guard let calendar = localEvent.calendar else {
            return .limited
        }
        return calendar.type == .subscription ? .limited : .full
    }

    var meetingRomes: [String] {
        return localEvent.attendees?.compactMap({ (localAttendee) -> String? in
            let attendee = AttendeeFromLocal(localAttendee: localAttendee, organizerHash: "0")
            if attendee.isResource {
                return attendee.localizedDisplayName
            }
            return nil
        }) ?? []
    }

    var eventColor: ColorIndex {
        if let color = localEvent.calendar?.cgColor {
            return LocalCalHelper.getColor(color: color)
        }
        assertionFailureLog()
        return .carmine
    }

    var calColor: ColorIndex {
        if let color = localEvent.calendar?.cgColor {
            return LocalCalHelper.getColor(color: color)
        }
        assertionFailureLog()
        return .carmine
    }

    var source: CalendarEvent.Source {
        return .ios
    }

    var startDate: Date
    var endDate: Date
    var isOverOneDay: Bool {
        return !calendar.isDate(startDate, inSameDayAs: endDate - 1)
    }

    var isSyncFromLark: Bool {
        return false
    }
    let calendar: Calendar

    init(event: EKEvent, calendar: Calendar = Calendar.gregorianCalendar) {
        self.localEvent = event
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.calendar = calendar
    }
}
