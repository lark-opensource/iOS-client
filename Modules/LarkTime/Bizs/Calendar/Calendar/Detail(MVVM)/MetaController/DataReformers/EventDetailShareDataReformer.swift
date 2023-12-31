//
//  EventDetailShareDataReformer.swift
//  Calendar
//
//  Created by Rico on 2021/9/23.
//

import Foundation
import RxSwift
import LarkContainer

final class EventDetailShareDataReformer: UserResolverWrapper {

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    let userResolver: UserResolver

    let key: String
    let calendarId: String
    let originalTime: Int64
    let token: String?
    let messageId: String
    let actionSource: CalendarTracer.ActionSource
    let scene: EventDetailScene

    init(userResolver: UserResolver,
         key: String,
         calendarId: String,
         originalTime: Int64,
         token: String?,
         messageId: String,
         actionSource: CalendarTracer.ActionSource,
         scene: EventDetailScene) {
        self.userResolver = userResolver
        self.key = key
        self.calendarId = calendarId
        self.originalTime = originalTime
        self.token = token
        self.messageId = messageId
        self.actionSource = actionSource
        self.scene = scene
    }
}

extension EventDetailShareDataReformer {

    var description: String {
        return """
            EventDetailShareDataReformer:
            key: \(key),
            calendarId: \(calendarId),
            originalTime: \(originalTime),
            token: \(String(describing: token)),
            messageId: \(messageId)
            """
    }

    var debugDescription: String {
        description
    }

    var monitorDescription: String {
        return EventDetailMonitorKeys.Reformer.share.rawValue
    }
}

extension EventDetailShareDataReformer: EventDetailViewModelDataReformer {

    private func createReformedInfo(with event: CalendarEvent, canJoin: Bool) -> EventDetailReformedInfo {
        let instance = event.dt.makeInstance(with: self.calendarManager?.primaryCalendar,
                                             startTime: event.startTime,
                                             endTime: event.dt.validEndTime(with: event.startTime))

        let metaData = EventDetailMetaData(model: .pb(event, instance), payload: .share(canJoin, self.token, self.messageId))
        let needRefresh = event.dt.isOnMyPrimaryCalendar(calendarManager?.primaryCalendarID)

        return EventDetailReformedInfo(metaData: metaData, needRefreshFromServer: needRefresh)
    }

    func reformToViewModelData() -> Single<EventDetailReformedInfo> {
        return calendarApi?.getRemoteEvent(calendarID: calendarId,
                                          key: key,
                                          originalTime: originalTime,
                                          token: token,
                                          messageID: messageId)
            .map { ($0.0.getPBModel(), $0.1) }
            .flatMap { [weak self] (event: CalendarEvent, canJoin: Bool) -> Observable<EventDetailReformedInfo> in
                guard let self = self,
                      let calManager = self.calendarManager,
                      let rustApi = self.calendarApi else { throw EventDetailMetaError.selfNil }
                if event.calendarID == calManager.primaryCalendarID {
                    // 日程存在当前用户的主日历上，使用 GetEvent 数据，对齐 android 逻辑
                    return rustApi.getEventPB(calendarId: event.calendarID, key: event.key, originalTime: event.originalTime).map { self.createReformedInfo(with: $0, canJoin: canJoin) }
                } else {
                    // 不在日程中，使用 sharedEvent 数据
                    return .just(self.createReformedInfo(with: event, canJoin: canJoin))
                }
            }
            .collectSlaInfo(.EventDetail, action: "load_server_event", source: "share", additionalParam: ["entity_id": key])
            .asSingle() ?? .error(CError.userContainer("Can not get calendarApi from container"))

    }

    func getTupleDataForTracker() -> (key: String?, calEventID: String?, originalTime: Int64?, actionSource: CalendarTracer.ActionSource) {
        var calEventID: String? = ""
        var key: String? = key
        var originalTime: Int64? = originalTime
        return (key: key, calEventID: calEventID, originalTime: originalTime, actionSource: actionSource)
    }
}
