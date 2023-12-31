//
//  EventEditViewModel+CheckChanged.swift
//  Calendar
//
//  Created by bytedance on 2022/4/5.
//

import Foundation

// Check Changed for Fields
extension EventEditViewModel {

    func checkChangedForSummary(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        return e0.summary != e1.summary
    }

    func checkChangedForDate(with i0: Rust.Instance, and e1: Rust.Event) -> Bool {
        return i0.isAllDay != e1.isAllDay
            || i0.startTime != e1.startTime
            || i0.endTime != e1.endTime
            || i0.startTimezone != e1.startTimezone
            || i0.endTimezone != e1.endTimezone
    }

    func checkChangedForDate(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        return e0.isAllDay != e1.isAllDay
        || e0.startTime != e1.startTime
        || e0.endTime != e1.endTime
        || e0.startTimezone != e1.startTimezone
        || e0.endTimezone != e1.endTimezone
    }

    func checkChangedForCalendar(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        return e0.calendarID != e1.calendarID
    }

    func checkChangedForColor(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        return e0.colorIndex != e1.colorIndex
    }

    func checkChangedForVisibility(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        return e0.visibility != e1.visibility
    }

    func checkChangedForFreeBusy(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        return e0.isFree != e1.isFree
    }

    func checkChangedForReminders(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        return Set(e0.reminders.map { $0.minutes }) != Set(e1.reminders.map { $0.minutes })
    }

    func checkChangedForLocation(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        return e0.location != e1.location
    }

    func checkChangedForRrule(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        return e0.rrule != e1.rrule
    }

    func comparableStr(for attendee: Rust.Attendee) -> String {
        switch attendee.category {
        case .user:
            return "user_\(attendee.attendeeCalendarID)_\(attendee.status)"
        case .group:
            return "group_\(attendee.attendeeCalendarID)_\(attendee.status)"
        case .thirdPartyUser:
            return "thirdPartyUser_\(attendee.thirdPartyUser.email)_\(attendee.status)"
        case .resource:
            return "resource_\(attendee.id)_\(attendee.status)"
        @unknown default:
            assertionFailure()
            return ""
        }
    }

    func checkChangedForAttendees(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        let str0 = Set(e0.attendees.filter({ $0.category != .resource }).map(comparableStr(for:)))
        let str1 = Set(e1.attendees.filter({ $0.category != .resource }).map(comparableStr(for:)))
        return str0 != str1
    }

    func checkChangedForMeetingRooms(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        let str0 = Set(e0.attendees.filter({ $0.category == .resource }).map(comparableStr(for:)))
        let str1 = Set(e1.attendees.filter({ $0.category == .resource }).map(comparableStr(for:)))
        return str0 != str1
    }

    func checkChangedForAttachments(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        let str0 = Set(e0.attachments.map({ $0.fileToken }))
        let str1 = Set(e1.attachments.map({ $0.fileToken }))
        return str0 != str1
    }

    func checkChangedForNotes(with e0: Rust.Event, and e1: Rust.Event) -> Bool {
        return e0.docsDescription != e1.docsDescription || e0.description_p != e1.description_p
    }
}
