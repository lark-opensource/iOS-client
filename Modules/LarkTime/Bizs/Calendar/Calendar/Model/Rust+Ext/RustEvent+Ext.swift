//
//  RustEvent+Ext.swift
//  Calendar
//
//  Created by Rico on 2021/5/25.
//

import Foundation

extension Rust.Event {

    // 去除参与人里面的群成员内容，只留群壳子
    func strippedGroupMembers() -> Self {
        var attendees = [Rust.Attendee]()
        self.attendees.forEach { attendee in
            switch attendee.category {
            case .group:
                var newAttendee = attendee
                newAttendee.group.members = []
                attendees.append(newAttendee)
            @unknown default:
                attendees.append(attendee)
            }
        }
        var event = self
        event.attendees = attendees
        return event
    }

    func getScreenShotInfo(scenario: String,
                       instanceStartTime: Int64,
                       eventInstanceEndTime: Int64) -> String {
        var attendeeCalendarIDs: [String] = []
        self.attendees.forEach { (attendee) in
            switch attendee.dependency {
            case .resource(let _):
                attendeeCalendarIDs.append(attendee.attendeeCalendarID)
            @unknown default:
                break
            }
        }

        let infos = "{\"scenario\": \"\(scenario)\", \"calendar_id\": \"\(calendarID)\", \"key\": \"\(key)\", \"original_time\": \(originalTime), \"dirty_type\": \"\(dirtyType)\", \"need_update\": \(needUpdate), \"is_all_day\": \(isAllDay), \"start_time\": \(instanceStartTime), \"start_timezone\": \"\(startTimezone)\", \"endTime\": \(endTime), \"endTimezone\": \"\(endTimezone)\", \"creator_calendar_id\": \"\(creator.attendeeCalendarID)\", \"successor_calendar_id\": \"\(successor.attendeeCalendarID)\", \"organizer_calendar_id\": \"\(organizer.attendeeCalendarID)\", \"resource_calendar_ids\": \(attendeeCalendarIDs)}"
        return infos
    }

    func getWebinarEventAttendeeInfo() -> WebinarEventAttendeeInfo {
        var attendeeInfo = WebinarEventAttendeeInfo()
        attendeeInfo.speaker = self.webinarInfo.speakers.attendees.toWebinarEventSimpleAttendee()
        attendeeInfo.audience = self.webinarInfo.audiences.attendees.toWebinarEventSimpleAttendee()
        attendeeInfo.resourceAttendees = self.attendees.filter({ $0.category == .resource }).map({ $0.toResourceSimpleAttendee() })
        return attendeeInfo
    }
}
