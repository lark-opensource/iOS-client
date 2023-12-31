//
//  DebugMessage.swift
//  
//
//  Created by zhuheng on 2022/4/21.
//

import Foundation
import RustPB
import SwiftProtobuf

protocol DebugMessage: Message {
    func debugInfo() -> [String: String]?
}

extension CalendarEvent: DebugMessage {
    func debugInfo() -> [String: String]? {
        return ["id": id,
                "calendarId": calendarID,
                "key": key,
                "serverID": serverID,
                "creatorCalendarId": creatorCalendarID,
                "organizerCalendarId": organizerCalendarID]
    }
}

extension CalendarEventInstance: DebugMessage {
    func debugInfo() -> [String: String]? {
        return ["id": id,
                "calendarId": calendarID,
                "key": key,
                "serverID": eventServerID,
                "organizerCalendarId": organizerID]
    }
}

enum RustDebug {}

extension RustDebug {
    static func diffRustEventInfo(_ event: Rust.Event, _ originalEvent: Rust.Event?) -> [String: String] {
        let eventEntity = PBCalendarEventEntity(pb: event)
        var originalEventEntity: CalendarEventEntity?

        if let originalEvent = originalEvent {
            originalEventEntity = PBCalendarEventEntity(pb: originalEvent)
        }

        return diffEventInfo(eventEntity, originalEventEntity)
    }

    static func diffEventInfo(_ event: CalendarEventEntity, _ oriEvent: CalendarEventEntity?) -> [String: String] {
        let comparator = FieldComparator()
        comparator.addField(oldValue: event.eventColor, newValue: oriEvent?.eventColor, name: "colorIndex")
        comparator.addField(oldValue: event.summary, newValue: oriEvent?.summary, name: "summary")
        comparator.addField(oldValue: event.description, newValue: oriEvent?.description, name: "description")
        comparator.addField(oldValue: event.isAllDay, newValue: oriEvent?.isAllDay, name: "isAllDay")
        comparator.addField(oldValue: event.startTime, newValue: oriEvent?.startTime, name: "startTime")
        comparator.addField(oldValue: event.startTimezone, newValue: oriEvent?.startTimezone, name: "startTimezone")
        comparator.addField(oldValue: event.endTime, newValue: oriEvent?.endTime, name: "endTime")
        comparator.addField(oldValue: event.endTimezone, newValue: oriEvent?.endTimezone, name: "endTimezone")
        comparator.addField(oldValue: event.status, newValue: oriEvent?.status, name: "status")
        comparator.addField(oldValue: event.rrule, newValue: oriEvent?.rrule, name: "rrule")

        if event.attendees.count != oriEvent?.attendees.count {
            comparator.addField(oldValue: event.attendees.last?.attendeeCalendarId, newValue: oriEvent?.attendees.last?.attendeeCalendarId, name: "attendees")
            comparator.addField(oldValue: event.attendees.count, newValue: oriEvent?.attendees.count, name: "attendeesCount")
        }

        comparator.addField(oldValue: event.location, newValue: oriEvent?.location, name: "location")
        comparator.addField(oldValue: event.reminders, newValue: oriEvent?.reminders, name: "reminders")
        comparator.addField(oldValue: event.displayType, newValue: oriEvent?.displayType, name: "displayType")
        comparator.addField(oldValue: event.visibility, newValue: oriEvent?.visibility, name: "visibility")
        comparator.addField(oldValue: event.isFree, newValue: oriEvent?.isFree, name: "isFree")
        comparator.addField(oldValue: event.type, newValue: oriEvent?.type, name: "type")
        comparator.addField(oldValue: event.docsDescription, newValue: oriEvent?.docsDescription, name: "docsDescription")

        return comparator.getChangeFields()
    }
}
