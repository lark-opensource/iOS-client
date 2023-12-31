//
//  File.swift
//  Calendar
//
//  Created by zoujiayi on 2019/8/19.
//

import Foundation

struct CalendarSearchFilter {
    var calendarIds: [String] = []
    /// may include chatters, groups
    var attendees: [CalendarEventAttendeeEntity] = []
    var realAttendeeCalendarIds: [String] {
        return self.attendees.compactMap { (searchAttendee) -> String? in
            guard !searchAttendee.isGroup && !searchAttendee.isResource else { return nil }
            return searchAttendee.attendeeCalendarId
        }
    }
    var resource: [CalendarMeetingRoom] = []
    var resourceCalendarIds: [String] {
        return self.resource.map { (meetingRoom) -> String in
            return meetingRoom.uniqueId
        }
    }
    var chatIds: [String] {
           return self.attendees.compactMap { (searchAttendee) -> String? in
               guard searchAttendee.isGroup else { return nil }
               return searchAttendee.groupId
           }
       }
    var startTimeStamp: Int64?
    var endTimeStamp: Int64?
}
