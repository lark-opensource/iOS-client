//
//  EventDetailFourFoldTuplesDataReformer.swift
//  Calendar
//
//  Created by Rico on 2021/9/23.
//

import Foundation
import RxSwift
import LarkContainer
import RustPB

final class EventDetailFourFoldTuplesDataReformer: UserResolverWrapper {

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    let userResolver: UserResolver
    let key: String
    let calendarId: String
    let originalTime: Int64
    let startTime: Int64?
    let source: String?
    let actionSource: CalendarTracer.ActionSource
    let scene: EventDetailScene

    init(userResolver: UserResolver,
         key: String,
         calendarId: String,
         originalTime: Int64,
         startTime: Int64? = nil,
         source: String? = nil,
         actionSource: CalendarTracer.ActionSource,
         scene: EventDetailScene) {
        self.userResolver = userResolver
        self.key = key
        self.calendarId = calendarId
        self.originalTime = originalTime
        self.startTime = startTime
        self.source = source
        self.actionSource = actionSource
        self.scene = scene
    }
}

extension EventDetailFourFoldTuplesDataReformer {

    var description: String {
        return """
            EventDetailFourFoldTuplesDataReformer:
            key: \(key),
            calendarId: \(calendarId),
            originalTime: \(originalTime),
            startTime: \(String(describing: startTime))
            """
    }

    var debugDescription: String {
        description
    }

    var monitorDescription: String {
        return EventDetailMonitorKeys.Reformer.fourTuple.rawValue
    }
}

extension EventDetailFourFoldTuplesDataReformer: EventDetailViewModelDataReformer {

    func reformToViewModelData() -> Single<EventDetailReformedInfo> {
        return calendarApi?.getAuthorizedEventByUniqueField(calendarID: calendarId,
                                                           key: key,
                                                           originalTime: originalTime,
                                                           startTime: startTime)
            .map { [weak self] response -> EventDetailReformedInfo in
                guard let self = self else { throw EventDetailMetaError.selfNil }
                let event = response.event
                if let source = self.source,
                   source == CalendarAssembly.AppLinkFromApproval,
                   event.creatorCalendarID != self.calendarManager?.primaryCalendarID {
                    // 来自大人数日程审批页的日程链接，非日程创建者无权限打开日程链接
                    throw EventDetailMetaError.noPermission
                }
                let startTime = response.fixedStartTime
                let endTime = event.dt.validEndTime(with: startTime)
                let instance = event.dt.makeInstance(with: self.calendarManager?.calendar(with: event.calendarID),
                                                     startTime: startTime,
                                                     endTime: endTime)
                let metaData = EventDetailMetaData(model: .pb(event, instance))
                let needRefresh = response.source == .local
                return EventDetailReformedInfo(metaData: metaData, needRefreshFromServer: needRefresh)
            }
            .collectSlaInfo(.EventDetail, action: "load_server_event", source: "applink", additionalParam: ["entity_id": key])
            .asSingle() ?? .error(CError.userContainer("can not get calendarApi from container"))
    }

    func getTupleDataForTracker() -> (key: String?, calEventID: String?, originalTime: Int64?, actionSource: CalendarTracer.ActionSource) {
        var calEventID: String? = ""
        var key: String? = key
        var originalTime: Int64? = originalTime
        return (key: key, calEventID: calEventID, originalTime: originalTime, actionSource: actionSource)
    }
}
