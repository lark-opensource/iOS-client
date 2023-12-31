//
//  EventDetailChatDataReformer.swift
//  Calendar
//
//  Created by Rico on 2021/3/15.
//

import Foundation
import RxSwift
import LarkContainer
import RustPB

final class EventDetailChatDataReformer: UserResolverWrapper {
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    let userResolver: UserResolver

    let chatId: String
    let scene: EventDetailScene
    var meetingId: String?

    init(chatId: String, userResolver: UserResolver, scene: EventDetailScene) {
        self.chatId = chatId
        self.userResolver = userResolver
        self.scene = scene
    }
}

extension EventDetailChatDataReformer {

    var description: String {
        return "EventDetailChatDataReformer chatId: \(chatId)"
    }

    var debugDescription: String {
        description
    }

    var monitorDescription: String {
        return EventDetailMonitorKeys.Reformer.chat.rawValue
    }
}

extension EventDetailChatDataReformer: EventDetailViewModelDataReformer {

    func reformToViewModelData() -> Single<EventDetailReformedInfo> {
        return loadMeeting(by: chatId)
            .flatMap { [weak self] (event, startTime, endTime) -> Observable<EventDetailReformedInfo> in
                guard let self = self else { throw EventDetailMetaError.selfNil }
                return self.getEventFromMeeting(event: event, startTime: startTime, endTime: endTime)
                    .collectSlaInfo(.EventDetail, action: "load_server_event", source: "server", additionalParam: ["entity_id": event?.serverID ?? "none"])
            }
            .asSingle()
    }

    func loadMeeting(by chatId: String) -> Observable<(CalendarEvent?, Int64, Int64)> {
        guard let rustApi = self.calendarApi else { return .error(CError.userContainer("can not get calendarApi from container")) }
        return rustApi.getChatCalendarEventInstanceViewRequest(chatIds: [chatId])
            .flatMap { [weak self] eventInstanceViewResponse -> Observable<(CalendarEvent?, Int64, Int64)> in
                guard let self = self else { throw EventDetailMetaError.selfNil }

                let chatEventInstanceTimeMap = eventInstanceViewResponse.chatEventInstanceTimeMap
                self.meetingId = eventInstanceViewResponse.chatMeetingMap[chatId]?.id
                guard let serverId = chatEventInstanceTimeMap[chatId]?.calendarEventRefID else {
                    EventDetail.logError("failed get serverId")
                    throw EventDetailMetaError.notInEvent
                }

                return rustApi.getServerPBEvent(serverId: serverId)
                    .map {[weak self] event -> (CalendarEvent?, Int64, Int64) in

                        let startTime = chatEventInstanceTimeMap[chatId]?.startTime ?? Int64(0)
                        let endTime = chatEventInstanceTimeMap[chatId]?.endTime ?? Int64(0)

                        return (event, startTime, endTime)
                    }
            }
    }

    private func getEventFromMeeting(event: CalendarEvent?, startTime: Int64, endTime: Int64) -> Observable<EventDetailReformedInfo> {
        guard let event = event else { return .error(EventDetailMetaError.couldNotGetEvent) }

        guard let calendar = calendarManager?.calendar(with: event.calendarID) else {
            return .error(EventDetailMetaError.couldNotGetCalendar)
        }

        let instance = event.dt.makeInstance(with: calendar,
                                             startTime: startTime,
                                             endTime: endTime)
        let model = EventDetailModel.pb(event, instance)
        let metaData = EventDetailMetaData(model: model,
                                           payload: .chat(self.chatId, self.meetingId))
        return .just(EventDetailReformedInfo(metaData: metaData, needRefreshFromServer: true))
    }

    func getTupleDataForTracker() -> (key: String?, calEventID: String?, originalTime: Int64?, actionSource: CalendarTracer.ActionSource) {
        var calEventID: String? = ""
        var key: String? = ""
        var originalTime: Int64? = 0
        return (key: key, calEventID: calEventID, originalTime: originalTime, actionSource: .side_bar)
    }

}
