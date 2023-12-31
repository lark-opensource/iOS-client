//
//  EventDetailRSVPCommentDataReformer.swift
//  Calendar
//
//  Created by Rico on 2021/9/23.
//

import Foundation
import RxSwift
import LarkContainer

final class EventDetailRSVPCommentDataReformer: UserResolverWrapper {

    @ScopedInjectedLazy var calendarManager: CalendarManager?

    let userResolver: UserResolver

    let event: EventDetail.Event
    let rsvpString: String
    let scene: EventDetailScene

    init(event: EventDetail.Event, rsvpString: String, userResolver: UserResolver, scene: EventDetailScene) {
        self.event = event
        self.rsvpString = rsvpString
        self.userResolver = userResolver
        self.scene = scene
    }
}

extension EventDetailRSVPCommentDataReformer: CustomDebugStringConvertible, CustomStringConvertible {

    var description: String {
        return """
            EventDetailRSVPCommentDataReformer:
            event: \(event.dt.description),
            rsvpString: \(rsvpString)
            """
    }

    var debugDescription: String {
        return """
            EventDetailRSVPCommentDataReformer:
            event: \(event.dt.debugDescription),
            rsvpString: \(rsvpString)
            """
    }

    var monitorDescription: String {
        return EventDetailMonitorKeys.Reformer.rsvp.rawValue
    }
}

extension EventDetailRSVPCommentDataReformer: EventDetailViewModelDataReformer {

    func reformToViewModelData() -> Single<EventDetailReformedInfo> {
        guard let calManager = self.calendarManager else { return .error(CError.userContainer("Can not get calendarManager from container")) }
        let instance = event.dt.makeInstance(with: calManager.primaryCalendar,
                                             startTime: event.startTime,
                                             endTime: event.dt.validEndTime(with: event.startTime))
        let metaData = EventDetailMetaData(model: .pb(event, instance),
                                           payload: .rsvpComment(rsvpString))
        return .just(EventDetailReformedInfo(metaData: metaData))
    }

    func getTupleDataForTracker() -> (key: String?, calEventID: String?, originalTime: Int64?, actionSource: CalendarTracer.ActionSource) {
        return (key: event.key, calEventID: event.serverID, originalTime: event.originalTime, actionSource: .msg_invite)
    }

}
