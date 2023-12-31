//
//  FreeBusyUtils.swift
//  Calendar
//
//  Created by pluto on 2023/8/29.
//

import Foundation

struct FreeBusyUtils {}


extension FreeBusyUtils {
    /// 自己排在后面
    static func sortedAttendees(attendees: [CalendarEventAttendeeEntity],
                                calendarId: String) -> [CalendarEventAttendeeEntity] {
        var attendees = attendees
        if let index = attendees.firstIndex(where: { $0.attendeeCalendarId == calendarId }) {
            let attendee = attendees.remove(at: index)
            attendees.append(attendee)
        }
        return attendees
    }
}

