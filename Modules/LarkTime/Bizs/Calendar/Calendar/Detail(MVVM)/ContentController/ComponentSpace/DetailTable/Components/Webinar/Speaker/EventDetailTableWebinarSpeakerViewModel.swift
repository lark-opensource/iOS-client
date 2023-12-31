//
//  EventDetailTableWebinarSpeakerViewModel.swift
//  Calendar
//
//  Created by tuwenbo on 2022/10/24.
//

import UIKit
import RxSwift
import LarkCombine
import LarkContainer
import LarkLocalizations

final class EventDetailTableWebinarSpeakerViewModel: EventDetailTableWebinarViewModel {

    override func buildWebinarViewData() -> ViewData {

        if webinar?.shouldHideWebinarSpeaker(detailModel: model, for: calendar) ?? false {
            EventDetail.logInfo("Speaker attendees is hidden")
            return .hidden
        }

        let data = buildWebinarSpeakerViewData()
        return .attendee(data)
    }

    override func canViewWebinarAttendees() -> Bool {
        guard let webinar = webinar, let event = model.event else { return false }

        return !webinar.shouldHideWebinarSpeaker(detailModel: model, for: calendar) && webinar.hasVisibleWebinarSpeaker(event: event)
    }

    private func buildWebinarSpeakerViewData() -> EventDetailTableWebinarViewData {

        let attendeeInfo = webinar?.webinarInfo.speakers.eventAttendeeInfo

        let total = attendeeInfo?.totalNo ?? 0
        let accepted = attendeeInfo?.acceptNo ?? 0
        let declined = attendeeInfo?.declineNo ?? 0
        let tentative = attendeeInfo?.tentativeNo ?? 0
        let needAction = attendeeInfo?.needActionNo ?? 0

        let countText = BundleI18n.Calendar.Calendar_Card_NumPanelist(number: total)

        let statusText = getAttendeeStatisticText(acceptedNo: accepted, declinedNo: declined, tentativeNo: tentative, needActionNo: needAction)

        let speakers = sortedWebinarSpeakers
        let avatars = speakers.map { (speaker) -> (Avatar, UIImage?) in
            let image = speaker.getStatusImage()
            return (speaker.avatar, image)
        }

        var withEllipsisIcon = false
        var prefix = Array(avatars.prefix(6))
        if prefix.count == 6 {
            _ = prefix.popLast()
            withEllipsisIcon = true
        }

        EventDetail.logInfo("Speaker attendees, \(countText), \(statusText)")

        return EventDetailTableWebinarViewData(countText: countText,
                                               statusText: statusText,
                                               avatars: prefix,
                                               withEllipsisIcon: withEllipsisIcon)
    }

    private func getPageContext() -> EventAttendeeListViewModel.PaginationContext {
        guard let webinar = webinar, let event = model.event else { return .noMore }

        let speakers = webinar.webinarInfo.speakers

        if speakers.requireMore {
            return .needPagination(token: speakers.syncToken, version: event.version64)
        } else {
            return .noMore
        }
    }

    override func buildAttendeeListViewModel() -> EventAttendeeListViewModel? {
        guard let tenantID = calendarDependency?.currentUser.tenantId,
              let calendarID = calendarManager?.primaryCalendarID else { return nil }
        let viewModel = EventAttendeeListViewModel(
                 userResolver: self.userResolver,
                 attendees: EventEditAttendee.makeAttendees(from: sortedWebinarSpeakers),
                 isLarkEvent: true,
                 currentTenantId: tenantID,
                 currentUserCalendarId: calendarID,
                 organizerCalendarId: model.organizerCalendarId,
                 creatorCalendarId: model.creatorCalendarId,
                 eventTitle: model.displayTitle,
                 rustAllAttendeeCount: Int(webinar?.webinarInfo.speakers.eventAttendeeInfo.totalNo ?? 0),
                 eventTuple: (model.calendarId, model.key, model.originalTime),
                 eventID: model.event?.serverID ?? "",
                 startTime: model.event?.startTime ?? 0,
                 rrule: model.event?.rrule,
                 pageContext: getPageContext(),
                 isDirtyFromDetail: isDirtyFromDetail(),
                 attendeeType: .webinar(.speaker)
             )
        return viewModel
    }

    var sortedWebinarSpeakers: [CalendarEventAttendeeEntity] {
        guard let event = model.event, let webinar = webinar else {
            return []
        }
        return webinar.getSortedWebinarSpeakers(event: event)
    }
}
