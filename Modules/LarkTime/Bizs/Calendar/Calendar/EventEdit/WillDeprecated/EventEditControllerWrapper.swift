//
//  EventEditControllerWrapper.swift
//  Calendar
//
//  Created by baiyantao on 2020/3/3.
//

import UIKit
import Foundation
import RxSwift
import LarkUIKit
import RoundedHUD
import CalendarFoundation
import LarkContainer
import LKCommonsLogging

typealias EventEditCoordinatorGetter = (
    _ event: CalendarEventEntity,
    _ instance: CalendarEventInstanceEntity
) -> EventEditCoordinator

// 本类逻辑来自于EventEditAble的特化
final class EventEditControllerWrapper: UserResolverWrapper {
    private let logger = Logger.log(EventEditControllerWrapper.self, category: "calendar.EventEditControllerWrapper")

    let userResolver: UserResolver

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    var getEventEditCoordinator: EventEditCoordinatorGetter
    var getCreateEventCoordinator: GetCreateEventCoordinator

    var disposeBag: DisposeBag = DisposeBag()

    init(userResolver: UserResolver,
         getEventEditCoordinator: @escaping EventEditCoordinatorGetter,
         getCreateEventCoordinator: @escaping GetCreateEventCoordinator) {
        self.userResolver = userResolver
        self.getEventEditCoordinator = getEventEditCoordinator
        self.getCreateEventCoordinator = getCreateEventCoordinator
    }

    private func refresh(with editedEvent: CalendarEventEntity) {
        localRefreshService?.rxEventNeedRefresh.onNext(())
    }

    private func eventRemoved() {
        localRefreshService?.rxEventNeedRefresh.onNext(())
    }

    func appLinkEditEvent(calendarId: String,
                          key: String,
                          originalTime: Int64,
                          startTime: Int64?) -> Observable<(UIViewController?, Bool)> {
        guard let rustApi = self.calendarApi, let calManager = self.calendarManager else { return .empty() }
        return rustApi.getEvent(calendarId: calendarId, key: key, originalTime: originalTime)
            .observeOn(MainScheduler.instance)
            .map({ [weak self] (event) -> (UIViewController?, Bool) in
                let startTime = startTime ?? event.startTime
                let endTime = event.endTime
                let calendar = calManager.calendar(with: event.calendarId)
                let instance = event.instance(with: calendar,
                                              instanceStartTime: startTime,
                                              instanceEndTime: endTime,
                                              instanceScore: "")
                let controller = self?.editEvent(event: event, instance: instance)
                return (controller, event.getPBModel().disableEncrypt)
        })
    }
    
    func appLinkEditEvent(token: String) -> Observable<UIViewController?> {
        guard let rustApi = self.calendarApi else { return .empty() }
        return rustApi.loadEventInfoByKeyForMyAIRequest(token: token)
            .flatMap ({ [weak self] (resp) -> Observable<(eventInfo: Server.LoadEventInfoByKeyForMyAIResponse, resouceInfo: Rust.LoadResourcesByCalendarIdsResponse?)> in
                guard let self = self else {
                    return .just((eventInfo: resp, resouceInfo: nil))
                }
                self.logger.info("loadEventInfoByKeyForMyAIRequest success. with uid\(resp.eventInfo.uid)")
                return rustApi.loadResourcesByCalendarIdsRequest(calendarIDs: resp.eventInfo.resourceCalendarIds)
                    .map { resouceInfo in
                        (eventInfo: resp, resouceInfo: resouceInfo)
                    }.catchErrorJustReturn((eventInfo: resp, resouceInfo: nil))
            })
            .observeOn(MainScheduler.instance)
            .map({[weak self] (resp, resouceInfo) -> (UIViewController?) in
                self?.logger.info("loadEventInfoByKeyForMyAIRequest success with buildings count: \(String(describing: resouceInfo?.buildings.count)) with resouces count:\(String(describing: resouceInfo?.resources.count))")
                let eventInfo = resp.eventInfo
                let editCoordinator = self?.getCreateEventCoordinator { context in
                    context.pointee.summary = eventInfo.summary
                    context.pointee.startDate = Date(timeIntervalSince1970: TimeInterval(eventInfo.startTime))
                    context.pointee.endDate = Date(timeIntervalSince1970: TimeInterval(eventInfo.endTime))
                    context.pointee.timeZone = TimeZone(identifier: eventInfo.startTimezone) ?? .current
                    context.pointee.rrule = eventInfo.rrule
                    context.pointee.myAiUid = eventInfo.uid
                    context.pointee.isFromAI = true
                    
                    var meetingRooms: [(fromResource: Rust.MeetingRoom, buildingName: String, tenantId: String)] = []
                    if let resources = resouceInfo {
                        resources.resources.map { item in
                            let meetingRoom = item.value
                            let buildingName = resources.buildings[meetingRoom.buildingID]?.name ?? ""
                            let tenantId = meetingRoom.tenantID
                            meetingRooms.append((fromResource: meetingRoom, buildingName: buildingName, tenantId: tenantId))
                        }
                        context.pointee.meetingRooms = meetingRooms
                    }

                    var attendeeSeeds = [EventAttendeeSeed]()
                    for attendeeId in resp.eventInfo.attendeeUserIds {
                        attendeeSeeds.append(.user(chatterId: attendeeId))
                    }
                    context.pointee.attendeeSeeds = attendeeSeeds
                }
                
                editCoordinator?.autoSwitchToDetailAfterCreate = true
                return editCoordinator?.prepare()
            })
    }

    private func editEvent(event: CalendarEventEntity,
                           instance: CalendarEventInstanceEntity) -> UIViewController? {
        let eventCoordinator = getEventEditCoordinator(
            event, instance
        )
        eventCoordinator.delegate = self
        eventCoordinator.actionSource = .appLink
        return eventCoordinator.prepare()
    }
}

extension EventEditControllerWrapper: EventEditCoordinatorDelegate {
    func coordinator(
        _ coordinator: EventEditCoordinator,
        didSaveEvent pbEvent: Rust.Event,
        span: Span,
        extraData: EventEditExtraData?
    ) {
        refresh(with: PBCalendarEventEntity(pb: pbEvent))
    }

    func coordinator(
        _ coordinator: EventEditCoordinator,
        didDeleteEvent pbEvent: Rust.Event
    ) {
        eventRemoved()
    }
}
