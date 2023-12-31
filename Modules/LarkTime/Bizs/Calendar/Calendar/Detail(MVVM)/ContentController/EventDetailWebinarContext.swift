//
//  EventDetailWebinarContext.swift
//  Calendar
//
//  Created by tuwenbo on 2022/12/15.
//

import Foundation

class EventDetailWebinarContext {
    let webinarInfo: EventWebinarInfo

    init(webinarInfo: EventWebinarInfo) {
        self.webinarInfo = webinarInfo
    }

    func shouldHideWebinarSpeaker(detailModel model: EventDetailModel, for calendar: EventDetail.Calendar?) -> Bool {
        let canRead = (calendar?.canRead() ?? false)

        if model.displayType == .limited { return false }
        if canRead && model.calendarId == model.organizerCalendarId {
            return false
        }

        switch webinarInfo.selfWebinarAttendeeType {
        case .audience:
            return !webinarInfo.conf.audienceCanSeeOtherSpeakers
        case .speaker:
            return !webinarInfo.conf.speakerCanSeeOtherSpeakers
        case .unknown:
            return true
        @unknown default:
            return true
        }
    }

    func shouldHideWebinarAudience(detailModel model: EventDetailModel, for calendar: EventDetail.Calendar?) -> Bool {
        let canRead = (calendar?.canRead() ?? false)

        if model.displayType == .limited { return false }
        if canRead && model.calendarId == model.organizerCalendarId {
            return false
        }

        return false
    }

    func getVisibleWebinarSpeakers(event: Rust.Event) -> [CalendarEventAttendeeEntity] {
        let attendees = webinarInfo.speakers.attendees.map {
            PBAttendee(pb: $0, displayOrganizerCalId: event.dt.realOrganizerCalId)
        }
        EventDetail.logInfo("all webinar speaker count: \(attendees.count)")
        return attendees.filter { !$0.isResource && !($0.status == .removed) }
    }

    func getVisibleWebinarAudiences(event: Rust.Event) -> [CalendarEventAttendeeEntity] {
        let attendees = webinarInfo.audiences.attendees.map {
            PBAttendee(pb: $0, displayOrganizerCalId: event.dt.realOrganizerCalId)
        }
        EventDetail.logInfo("all webinar audience count: \(attendees.count)")
        return attendees.filter { !$0.isResource && !($0.status == .removed) }
    }

    func hasVisibleWebinarSpeaker(event: Rust.Event) -> Bool {
        return !getVisibleWebinarSpeakers(event: event).isEmpty
    }

    func hasVisibleWebinarAudience(event: Rust.Event) -> Bool {
        return !getVisibleWebinarAudiences(event: event).isEmpty
    }

    func getSortedWebinarSpeakers(event: Rust.Event) -> [CalendarEventAttendeeEntity] {
        return getVisibleWebinarSpeakers(event: event).sorted {
            type(of: $0).attendeeCompareable($0, $1)
        }
    }

    func getSortedWebinarAudiences(event: Rust.Event) -> [CalendarEventAttendeeEntity] {
        return getVisibleWebinarAudiences(event: event).sorted {
            type(of: $0).attendeeCompareable($0, $1)
        }
    }

    var webinarSpeakerTotalCount: Int32 {
        return self.webinarInfo.speakers.eventAttendeeInfo.totalNo ?? 0
    }

    var webinarAudienceTotalCount: Int32 {
        return self.webinarInfo.audiences.eventAttendeeInfo.totalNo ?? 0
    }
}
