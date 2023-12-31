//
//  EventShareContent.swift
//  Pods
//
//  Created by zhu chao on 2018/8/15.
//

import Foundation
import RustPB

// ShareCalendarEventContent

public struct EventShareContent: MessageContent {
    private var pb: Basic_V1_ShareCalendarEventContent
    public init(pb: Basic_V1_ShareCalendarEventContent, messageId: String) {
        self.messageId = messageId
        self.pb = pb
    }

    public var messageId: String

    public var eventID: String {
        return self.pb.calendarEvent.serverID
    }

    public var calendarID: String {
        return self.pb.calendarEvent.calendarID
    }

    public var key: String {
        return self.pb.calendarEvent.key
    }

    public var originalTime: Int {
        return Int(self.pb.calendarEvent.originalTime)
    }

    public var startTime: Int64 {
        return self.pb.calendarEvent.startTime
    }

    public var endTime: Int64 {
        return self.pb.calendarEvent.endTime
    }

    public var isAllDay: Bool? {
        return self.pb.calendarEvent.isAllDay
    }

    public var isShowConflict: Bool {
        return self.pb.conflictType == .normal
    }

    public var isShowRConflict: Bool {
        return self.pb.conflictType == .recurrence
    }

    public var conflictTime: Int64 {
        return self.pb.conflictTime
    }

    public var color: Int32 {
        return self.pb.calendarEvent.eventColor.eventCardColor
    }

    public var title: String {
        return self.pb.calendarEvent.summary
    }

    public var location: String {
        return self.pb.calendarEvent.location.location
    }

    public var meetingRoom: String {
        guard self.pb.calendarEvent.startTime < pb.calendarEvent.endTime else {
            assertionFailure("event.startTime < event.endTime")
            return ""
        }
        let eventRange = self.pb.calendarEvent.startTime..<self.pb.calendarEvent.endTime
        return self.pb.calendarEvent.attendees
            .filter {
                var isAvailable = $0.category == .resource && !$0.resource.isDisabled && $0.status != .decline
                if let bizData = $0.schemaExtraData.bizData.first(where: { $0.type == .resourceRequisition }) {
                    let resourceRequisition = bizData.resourceRequisition
                    let endTime = resourceRequisition.endTime > 0 ? resourceRequisition.endTime : 7258089600
                    let requiRange = resourceRequisition.startTime..<endTime
                    let hasIntersection = eventRange.overlaps(requiRange)
                    isAvailable = isAvailable && !hasIntersection
                }
                return isAvailable
            }
            .map { $0.displayName }
            .joined(separator: ",")
    }

    public var description: String {
        return self.pb.calendarEvent.description_p
    }

    public var rrepeat: String {
        return self.pb.calendarEvent.rrule
    }

    public var isJoined: Bool {
        get { return self.pb.isJoined }
        set { self.pb.isJoined = newValue }
    }

    public var attendeeNames: [String] {
        return self.pb.calendarEvent.attendees
            .filter({ ($0.status != .removed) && (!($0.category == .resource)) })
            .map({ $0.displayName })
    }

    public var isInvalid: Bool {
        get { return !self.pb.isSharable }
        set { self.pb.isSharable = !newValue }
    }

    public var isCrossTenant: Bool {
        return self.pb.calendarEvent.isCrossTenant
    }

    public var isWebinar: Bool {
        return self.pb.calendarEvent.category == .webinar
    }

    public var isMeeting: Bool {
        return self.pb.calendarEvent.type == .meeting
    }

    public var status: RustPB.Calendar_V1_CalendarEventAttendee.Status {
        get { return self.pb.selfAttendeeStatus }
        set { self.pb.selfAttendeeStatus = newValue }
    }

    public var currentUserMainCalendarId: String {
        return self.pb.currentUserCalID
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {}
}
