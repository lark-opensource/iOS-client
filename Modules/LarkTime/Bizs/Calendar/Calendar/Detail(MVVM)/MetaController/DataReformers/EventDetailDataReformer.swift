//
//  EventDetailDataReformer.swift
//  Calendar
//
//  Created by Rico on 2021/4/8.
//

import Foundation
import LarkContainer
import RxSwift

final class EventDetailDataReformer: UserResolverWrapper {
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    let userResolver: UserResolver

    let key: String
    let calendarId: String
    let originalTime: Int64
    let startTime: Int64?
    let endTime: Int64?
    let actionSource: CalendarTracer.ActionSource
    let scene: EventDetailScene

    init(userResolver: UserResolver,
         key: String,
         calendarId: String,
         originalTime: Int64,
         startTime: Int64? = nil,
         endTime: Int64? = nil,
         actionSource: CalendarTracer.ActionSource,
         scene: EventDetailScene) {
        self.userResolver = userResolver
        self.key = key
        self.calendarId = calendarId
        self.originalTime = originalTime
        self.startTime = startTime
        self.endTime = endTime
        self.actionSource = actionSource
        self.scene = scene
    }
}

extension EventDetailDataReformer {

    var description: String {
        return """
            EventDetailDataReformer:
            key: \(key),
            calendarId: \(calendarId),
            originalTime: \(originalTime),
            startTime: \(String(describing: startTime)),
            endTime: \(String(describing: endTime))
            """
    }

    var debugDescription: String {
        description
    }

    var monitorDescription: String {
        return EventDetailMonitorKeys.Reformer.main.rawValue
    }
}

extension EventDetailDataReformer: EventDetailViewModelDataReformer {
    func reformToViewModelData() -> Single<EventDetailReformedInfo> {
        guard let calendar = calendarManager?.calendar(with: self.calendarId), let rustApi = self.calendarApi else {
            return .error(EventDetailMetaError.couldNotGetCalendar)
        }

        return rustApi.getEventPB(calendarId: self.calendarId,
                                  key: self.key,
                                  originalTime: self.originalTime)
            .map { [weak self] event -> EventDetailReformedInfo in
                guard let self = self else { throw EventDetailMetaError.selfNil }
                let startTime = self.startTime ?? event.startTime
                let endTime = event.dt.validEndTime(with: startTime)
                let instance = event.dt.makeInstance(with: calendar,
                                                     startTime: startTime,
                                                     endTime: endTime)
                let metaData = EventDetailMetaData(model: EventDetailModel.pb(event, instance))
                return EventDetailReformedInfo(metaData: metaData, needRefreshFromServer: true)
            }
            .collectSlaInfo(.EventDetail, action: "load_event", source: "event", additionalParam: ["entity_id": key])
            .asSingle()
    }

    func getTupleDataForTracker() -> (key: String?, calEventID: String?, originalTime: Int64?, actionSource: CalendarTracer.ActionSource) {
        var calEventID: String? = ""
        var key: String? = key
        var originalTime: Int64? = originalTime
        return (key: key, calEventID: calEventID, originalTime: originalTime, actionSource: actionSource)
    }
}
