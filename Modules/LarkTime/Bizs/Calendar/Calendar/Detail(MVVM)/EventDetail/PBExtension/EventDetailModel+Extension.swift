//
//  EventDetailModel+Extension.swift
//  Calendar
//
//  Created by Rico on 2021/3/25.
//

import Foundation

extension DetailLogicBox where Base == EventDetail.Event {

    var isThirdParty: Bool {
        return source.source == .google || source.source == .exchange
    }

    var isFromGoogle: Bool {
        return source.source == .google
    }

    var isFromExchange: Bool {
        return source.source == .exchange
    }

    var hasVisibleAttendees: Bool {
        return !visibleAttendees.isEmpty
    }

    var visibleAttendees: [EventDetail.Attendee] {
        return source.attendees.filter { !($0.category == .resource) && !($0.status == .removed) }
    }

    var sortedVisibleAttendees: [EventDetail.Attendee] {
        let realOrganizerCalId = source.hasOrganizer ? source.organizerCalendarID : source.creatorCalendarID
        return visibleAttendees.sorted { (lhs, rhs) -> Bool in
            lhs.dt.areInIncreasingOrder(with: rhs.dt, eventDisplayCalId: realOrganizerCalId)
        }
    }

    var displayTitle: String {
        if source.displayType == .full {
            return source.summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : source.summary
        } else if source.displayType == .undecryptable {
            return I18n.Calendar_EventExpired_GreyText
        } else if source.category == .resourceStrategy {
            return BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomCantReservePeriod
        } else if source.category == .resourceRequisition {
            return BundleI18n.Calendar.Calendar_Edit_MeetingRoomInactiveCantReserve
        } else {
            return source.selfAttendeeStatus.freeBusyStatusString
        }
    }

    var isRecurrence: Bool {
        return !source.rrule.isEmpty
    }

    var isException: Bool {
        return source.originalTime != 0
    }

    var meetingRoomCount: Int {
        return source.attendees
            .filter({ $0.category == .resource && $0.status == .accept && !$0.resource.isDisabled })
            .count
    }

    var realOrganizerCalId: String {
        //shared calendars wont have organizer since the "organizer" is not a user
        return source.hasOrganizer ? source.organizerCalendarID : source.creatorCalendarID
    }
}

// Schema
extension DetailLogicBox where Base == EventDetail.Event {

    var schemaCollection: Rust.SchemaCollection? {
        guard source.hasSchema else {
            return nil
        }
        return source.schema
    }

    func isSchemaDisplay(key: Rust.SchemaCollection.SchemaKey) -> Bool? {
        guard
            let schemaCollection = schemaCollection,
            let schema = schemaCollection.schemaEntity(forKey: key),
            schema.hasUiLevel  else {
            return nil
        }
        return schema.uiLevel != .hide
    }

    func schemaLink(key: Rust.SchemaCollection.SchemaKey) -> URL? {
        guard
            let schemaCollection = schemaCollection,
            let schema = schemaCollection.schemaEntity(forKey: key),
            schema.hasAppLink else {
            return nil
        }
        return URL(string: schema.appLink)
    }

    var schemaCompatibleLevel: Rust.IncompatibleLevel? {
        return f_schemaCompatibleLevel(self.schemaCollection)
    }

    func isOnMyPrimaryCalendar(_ primaryCalendarID: String?) -> Bool {
        return source.calendarID == primaryCalendarID
    }

//    var isOnMyPrimaryCalendar: Bool {
//        return source.calendarID == calendarManager?.primaryCalendarID
//    }
}

extension DetailLogicBox where Base == EventDetail.Event {

    /// 我们自己的全天日程 返回的是 utc 时区 0点的时间轴,需要转换成当前时区的时间轴
    func startDate(with time: Int64) -> Date {
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        return source.isAllDay ? date.utcToLocalDate() : date
    }

    func endDate(with time: Int64) -> Date {
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        return source.isAllDay ? date.utcToLocalDate() : date
    }

    func validEndTime(with start: Int64) -> Int64 {
        let duration = source.endTime - source.startTime
        return start + duration
    }
}

/// 通过event和额外参数生成instance
extension DetailLogicBox where Base == EventDetail.Event {
    func makeInstance(with calendar: CalendarModel?,
                      startTime: Int64,
                      endTime: Int64) -> EventDetail.Instance {
        var instance = EventDetail.Instance()
        instance.id = "0"
        instance.eventID = source.id
        instance.calendarID = source.calendarID
        instance.organizerID = source.organizer.id

        instance.startTime = startTime
        instance.endTime = endTime
        let startDate = getDateFromInt64(startTime)
        let endDate = getDateFromInt64(endTime)
        instance.startDay = getJulianDay(date: startDate)
        instance.startMinute = getJulianMinute(date: startDate)
        instance.endDay = getJulianDay(date: endDate)
        instance.endMinute = getJulianMinute(date: endDate)

        instance.startTimezone = source.startTimezone
        instance.endTimezone = source.endTimezone
        instance.key = source.key
        instance.originalTime = source.originalTime
        instance.color = source.color
        instance.summary = source.summary
        instance.isAllDay = source.isAllDay
        instance.status = source.status
        instance.calColorIndex = source.calColorIndex
        instance.colorIndex = source.colorIndex
        instance.selfAttendeeStatus = source.selfAttendeeStatus
        instance.isFree = source.isFree
        instance.eventServerID = source.serverID
        instance.location = source.location
        instance.visibility = source.visibility
        instance.meetingRooms = source.attendees
            .filter { $0.category == .resource }
            .filter { $0.status != .decline && $0.status != .removed }
            .map { $0.displayName }
        instance.displayType = source.displayType
        instance.source = source.source
        instance.isEditable = source.isEditable
        instance.category = source.category

        if let calendar = calendar { instance.calAccessRole = calendar.selfAccessRole }

        return instance
    }
}

// 日志输出，直接输出debugDescription有合规风险

extension DetailLogicBox where Base == EventDetail.Event {

    var debugDescription: String {
        return source.debugDescription
    }

    var description: String {
        return """
            creator_calendar_id: \(source.creatorCalendarID),
            calendar_id: \(source.calendarID),
            organizer_calendar_id: \(source.organizerCalendarID),
            server_id: \(source.serverID),
            self_attendee_status: \(source.selfAttendeeStatus),
            key: \(source.key),
            original_time: \(source.originalTime),
            original_event_key: \(source.originalEventKey),
            original_is_all_day: \(source.originalIsAllDay),
            is_free: \(source.isFree),
            last_date: \(source.lastDate),
            colorIndex: \(source.colorIndex),
            dirty_type: \(source.dirtyType),
            is_all_day: \(source.isAllDay),
            start_time: \(source.startTime),
            start_timezone: \(source.startTimezone),
            end_time: \(source.endTime),
            end_timezone: \(source.endTimezone),
            status: \(source.status),
            rrule: \(source.rrule),
            guest_can_invite: \(source.guestCanInvite),
            guest_can_see_other_guests: \(source.guestCanSeeOtherGuests),
            guest_can_modify: \(source.guestCanModify),
            has_alarm: \(source.hasAlarm_p),
            creator: \(source.creator.dt.description),
            organizer: \(source.organizer.dt.description),
            attendeesCount: \(source.attendees.count),
            reminders: \(source.reminders),
            display_type: \(source.displayType),
            event_color: \(source.eventColor),
            cal_color: \(source.calColor),
            type: \(source.type),
            is_editable: \(source.isEditable),
            is_deletable: \(source.isDeletable),
            sharability: \(source.sharability),
            successor_calendar_id: \(source.successorCalendarID),
            notification_type: \(source.notificationType),
            is_cross_tenant: \(source.isCrossTenant),
            will_creator_attend: \(source.willCreatorAttend),
            will_organizer_attend: \(source.willOrganizerAttend),
            will_successor_attend: \(source.willSuccessorAttend),
            video_meeting_id: \(source.videoMeeting.uniqueID),
            calendar_event_display_info: \(source.calendarEventDisplayInfo),
            schema: \(source.schema),
            """
    }
}
