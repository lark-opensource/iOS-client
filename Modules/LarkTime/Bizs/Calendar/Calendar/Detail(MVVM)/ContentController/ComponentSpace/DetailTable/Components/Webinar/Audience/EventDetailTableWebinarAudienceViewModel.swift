//
//  EventDetailTableWebinarAudienceViewModel.swift
//  Calendar
//
//  Created by tuwenbo on 2022/10/24.
//

import UIKit
import RxSwift
import LarkCombine
import LarkContainer
import LarkLocalizations

final class EventDetailTableWebinarAudienceViewModel: EventDetailTableWebinarViewModel {

    override func buildWebinarViewData() -> ViewData {
        let data = buildWebinarAudienceViewData()
        return .attendee(data)
    }

    override func canViewWebinarAttendees() -> Bool {
        guard let webinar = webinar, let event = model.event else { return false }
        return !webinar.shouldHideWebinarAudience(detailModel: model, for: calendar) && webinar.hasVisibleWebinarAudience(event: event)
    }

    private func buildWebinarAudienceViewData() -> EventDetailTableWebinarViewData {

        let attendeeInfo = webinar?.webinarInfo.audiences.eventAttendeeInfo

        let total = attendeeInfo?.totalNo ?? 0
        let accepted = attendeeInfo?.acceptNo ?? 0
        let declined = attendeeInfo?.declineNo ?? 0
        let tentative = attendeeInfo?.tentativeNo ?? 0
        let needAction = attendeeInfo?.needActionNo ?? 0

        let countText = BundleI18n.Calendar.Calendar_Card_NumAttendees(number: total)

        let statusText = getAttendeeStatisticText(acceptedNo: accepted, declinedNo: declined, tentativeNo: tentative, needActionNo: needAction)

        // 如果要隐藏 audience attendee 列表，则直接取空列表，view 里如果 avatars.count == 0 会自动隐藏这一行
        let audiences = canViewWebinarAttendees() ? sortedWebinarAudiences : []
        let avatars = audiences.map { (audience) -> (Avatar, UIImage?) in
            let image = audience.getStatusImage()
            return (audience.avatar, image)
        }

        var withEllipsisIcon = false
        var prefix = Array(avatars.prefix(6))
        if prefix.count == 6 {
            _ = prefix.popLast()
            withEllipsisIcon = true
        }

        EventDetail.logInfo("Audience attendees, \(countText), \(statusText)")

        return EventDetailTableWebinarViewData(countText: countText,
                                               statusText: statusText,
                                               avatars: prefix,
                                               withEllipsisIcon: withEllipsisIcon)
    }

    private func getPageContext() -> EventAttendeeListViewModel.PaginationContext {
        guard let webinar = webinar, let event = model.event else { return .noMore }

        let audiences = webinar.webinarInfo.audiences
        if audiences.requireMore {
            return .needPagination(token: audiences.syncToken, version: event.version64)
        } else {
            return .noMore
        }
    }

    override func buildAttendeeListViewModel() -> EventAttendeeListViewModel? {
        guard let tenantID = calendarDependency?.currentUser.tenantId,
              let calendarID = calendarManager?.primaryCalendarID else { return nil }
        let viewModel = EventAttendeeListViewModel(
                 userResolver: self.userResolver,
                 attendees: EventEditAttendee.makeAttendees(from: sortedWebinarAudiences),
                 isLarkEvent: true,
                 currentTenantId: tenantID,
                 currentUserCalendarId: calendarID,
                 organizerCalendarId: model.organizerCalendarId,
                 creatorCalendarId: model.creatorCalendarId,
                 eventTitle: model.displayTitle,
                 rustAllAttendeeCount: Int(webinar?.webinarInfo.audiences.eventAttendeeInfo.totalNo ?? 0),
                 eventTuple: (model.calendarId, model.key, model.originalTime),
                 eventID: model.event?.serverID ?? "",
                 startTime: model.event?.startTime ?? 0,
                 rrule: model.event?.rrule,
                 pageContext: getPageContext(),
                 isDirtyFromDetail: isDirtyFromDetail(),
                 attendeeType: .webinar(.audience)
             )
        return viewModel
    }

    var sortedWebinarAudiences: [CalendarEventAttendeeEntity] {
        guard let event = model.event, let webinar = webinar else {
            return []
        }
        return webinar.getSortedWebinarAudiences(event: event)
    }
}
