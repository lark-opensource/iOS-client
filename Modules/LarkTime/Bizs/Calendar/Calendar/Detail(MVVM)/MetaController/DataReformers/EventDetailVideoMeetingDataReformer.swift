//
//  EventDetailVideoMeetingDataReformer.swift
//  Calendar
//
//  Created by Rico on 2021/9/23.
//

import Foundation
import RxSwift
import LarkContainer

final class EventDetailVideoMeetingDataReformer: UserResolverWrapper {

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    let userResolver: UserResolver

    let uniqueId: String
    let startTime: Int64
    let instance_start_time: Int64
    let instance_end_time: Int64
    let original_time: Int64
    let vchat_meeting_id: String
    let key: String
    let scene: EventDetailScene
    init(userResolver: UserResolver, uniqueId: String, startTime: Int64, instance_start_time: Int64, instance_end_time: Int64, original_time: Int64, vchat_meeting_id: String, key: String, scene: EventDetailScene) {
        self.userResolver = userResolver
        self.uniqueId = uniqueId
        self.startTime = startTime
        self.instance_start_time = instance_start_time
        self.instance_end_time = instance_end_time
        self.original_time = original_time
        self.key = key
        self.vchat_meeting_id = vchat_meeting_id
        self.scene = scene
    }
}

extension EventDetailVideoMeetingDataReformer {

    var description: String {
        return """
            EventDetailVideoMeetingDataReformer:
            uniqueId: \(uniqueId),
            startTime: \(startTime)
            """
    }

    var debugDescription: String {
        description
    }

    var monitorDescription: String {
        return EventDetailMonitorKeys.Reformer.videoMeeting.rawValue
    }
}

extension EventDetailVideoMeetingDataReformer: EventDetailViewModelDataReformer {

    func reformToViewModelData() -> Single<EventDetailReformedInfo> {
        guard let rustaApi = self.calendarApi else { return .error(CError.userContainer("can not get calendarApi from container")) }
        return rustaApi.getEvent(uniqueId: uniqueId, instance_start_time: instance_start_time, instance_end_time: instance_end_time, original_time: original_time, vchat_meeting_id: vchat_meeting_id, key: key, startTime: startTime)
            .flatMap { [weak self] resp -> Observable<(CalendarEvent, InstanceTime)> in
                guard let self = self else { throw EventDetailMetaError.selfNil }
                let event = resp.eventEntity.getPBModel()
                return rustaApi.getEventPB(calendarId: event.calendarID, key: event.key, originalTime: event.originalTime)
                    .map { ($0, resp.instanceTime) }
                    .catchErrorJustReturn((resp.eventEntity.getPBModel(), resp.instanceTime))
            }
            .map { [weak self] event, instanceTime -> EventDetailReformedInfo in
                guard let self = self else { throw EventDetailMetaError.selfNil }
                let instance = event.dt.makeInstance(with: self.calendarManager?.calendar(with: event.calendarID),
                                                     startTime: instanceTime.startTime,
                                                     endTime: instanceTime.endTime)
                let metaData = EventDetailMetaData(model: .pb(event, instance))
                return EventDetailReformedInfo(metaData: metaData, needRefreshFromServer: metaData.model.isWebinar)
            }
            .collectSlaInfo(.EventDetail, action: "load_server_event", source: "vc", additionalParam: ["entity_id": uniqueId])
            .asSingle()
    }

    func getTupleDataForTracker() -> (key: String?, calEventID: String?, originalTime: Int64?, actionSource: CalendarTracer.ActionSource) {
        var calEventID: String? = ""
        var key: String? = key
        var originalTime: Int64? = original_time
        return (key: key, calEventID: calEventID, originalTime: originalTime, actionSource: .vc_unique)
    }
}
