//
//  EventDetailMeetingRoomLimitDataReformer.swift
//  Calendar
//
//  Created by Rico on 2021/9/23.
//

import Foundation
import RxSwift
import LarkContainer
import RustPB

final class EventDetailMeetingRoomLimitDataReformer: UserResolverWrapper {

    let roomInstance: RoomViewInstance

    let userResolver: UserResolver

    @ScopedInjectedLazy
    var calendarApi: CalendarRustAPI?
    
    let scene: EventDetailScene

    init(roomInstance: RoomViewInstance, userResolver: UserResolver, scene: EventDetailScene) {
        self.roomInstance = roomInstance
        self.userResolver = userResolver
        self.scene = scene
    }
}

extension EventDetailMeetingRoomLimitDataReformer {

    var description: String {
        return """
            EventDetailMeetingRoomLimitDataReformer:
            roomInstance: \(roomInstance.pb.debugDescription)
            """
    }

    var debugDescription: String {
        description
    }

    var monitorDescription: String {
        return EventDetailMonitorKeys.Reformer.roomLimit.rawValue
    }
}

extension EventDetailMeetingRoomLimitDataReformer: EventDetailViewModelDataReformer {

    func reformToViewModelData() -> Single<EventDetailReformedInfo> {
        guard let rustApi = self.calendarApi else { return .error(CError.userContainer("can not get calendarApi from container")) }
        return rustApi.getMeetingRoomDetailInfo(by: [roomInstance.pb.resourceCalendarID])
            .flatMap { [weak self] roomInfo -> Observable<EventDetailReformedInfo> in
                guard let self = self,
                      let first = roomInfo.first else {
                    return .empty()
                }

                var roomInstance = RoomViewInstance(pb: self.roomInstance.pb, buildingName: first.buildingName)
                roomInstance.meetingRoom = self.roomInstance.meetingRoom
                let metaData = EventDetailMetaData(model: .meetingRoomLimit(roomInstance))
                return .just(EventDetailReformedInfo(metaData: metaData))
            }.asSingle()
    }

    func getTupleDataForTracker() -> (key: String?, calEventID: String?, originalTime: Int64?, actionSource: CalendarTracer.ActionSource) {
        var key: String? = roomInstance.key
        var originalTime: Int64? = roomInstance.originalTime
        var calEventID: String? = roomInstance.eventServerId
        return (key: key, calEventID: calEventID, originalTime: originalTime, actionSource: .room)
    }
}
