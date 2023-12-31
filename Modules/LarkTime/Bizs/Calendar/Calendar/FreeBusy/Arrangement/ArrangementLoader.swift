//
//  ArragementDataLoader.swift
//  Calendar
//
//  Created by zhouyuan on 2019/3/21.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import LarkContainer

typealias FilterParam = (serverId: String, key: String, originalTime: Int64)
typealias InstanceMap = [String: [DaysInstanceViewContent]]
typealias WorkHourMap = [String: SettingModel.WorkHourSetting]

struct ServerInstanceData {
    var instanceMap: InstanceMap = [:]
    var timezoneMap: [String: String] = [:]
    var workHourMap: WorkHourMap = [:]
    /// 透传后端定义，map 中只含 privateCalendar，且 value 全为 true（将 map 当 array 使用）
    var privateCalMap: [String: Bool] = [:]
}

protocol ArrangementDataLoaderProtocol: AnyObject {
    var currentUserCalendarId: String { get }
    var calendarApi: CalendarRustAPI? { get }
    var calendar: Calendar { get }
    var calendarManager: CalendarManager? { get }
    var meetingRoom: Rust.MeetingRoom? { get }
    var layoutAlgorithm: LayoutAlgorithm? { get }
    var semaphore: DispatchSemaphore { get }
    var eventViewSettingGetter: () -> EventViewSetting { get }

    func filterInstance(_ instance: CalendarEventInstanceEntity, date: Date, calendar: Calendar) -> Bool
}

extension ArrangementDataLoaderProtocol {

    func syncLoadInstanceDate(calendarIds: [String],
                              date: Date,
                              panelSize: CGSize,
                              timeZoneId: String,
                              disposeBag: DisposeBag) throws -> ServerInstanceData {
        var result = ServerInstanceData()
        var error: Error?
        loadInstanceData(calendarIds: calendarIds,
                         date: date,
                         panelSize: panelSize,
                         timeZoneId: timeZoneId)
            .collectSlaInfo(.FreeBusyInstance, action: "load_instance", source: "profile")
            .subscribe(onNext: { serverInstanceData in
                result = serverInstanceData
            }, onError: { (err) in
                error = err
            }, onDisposed: { [weak self] in
                self?.semaphore.signal()
            }).disposed(by: disposeBag)
        semaphore.wait()
        if let error = error {
            throw CError.sdk(error: error, msg: "free busy event error")
        }
        return result
    }

    func loadInstanceData(calendarIds: [String],
                          date: Date,
                          panelSize: CGSize,
                          timeZoneId: String
    ) -> Observable<ServerInstanceData> {
        let calendar = TimeZoneUtil.getCalendar(timeZoneId: timeZoneId)
        let startTime = Int64(date.dayStart(calendar: calendar).timeIntervalSince1970)
        let endTime = Int64(date.dayEnd(calendar: calendar).timeIntervalSince1970)
        let layoutDay = getJulianDay(date: date, calendar: calendar)
        
        guard let calendarApi = calendarApi, let layoutAlgorithm = layoutAlgorithm else {
            return .just(ServerInstanceData())
        }
        
        if let meetingRoom = meetingRoom {
            return calendarApi.getMeetingRoomInstances(meetingRooms: [meetingRoom], startTime: date.dayStart(calendar: calendar), endTime: date.dayEnd(calendar: calendar))
                .map { [weak self] response -> ServerInstanceData in
                    guard let self = self else { return ServerInstanceData() }
                    let instanceMap = self.groupingInstanceToContent(calendarIds: [meetingRoom.calendarID],
                                                                     instances: response[meetingRoom] ?? [],
                                                                     date: date,
                                                                     calendar: calendar)
                    return ServerInstanceData(instanceMap: instanceMap)
                }
                .map { [weak self] result -> ServerInstanceData in
                    guard let self = self else { return ServerInstanceData() }
                    let group = result.instanceMap
                    var instancesResult = InstanceMap()
                    var instanceTotalCount = 0
                    for calendarId in calendarIds {
                        if let contents = group[calendarId] {
                            instanceTotalCount += contents.count
                            let layoutResult = layoutAlgorithm([layoutDay: contents],
                                                                    false,
                                                                    panelSize,
                                                                    [layoutDay])
                            if let resultLayout = layoutResult[layoutDay] {
                                instancesResult[calendarId] = resultLayout
                            } else { assertionFailureLog() }
                        } else { assertionFailureLog() }
                    }
                    CalendarMonitorUtil.endTrackFreebusyViewInstanceTime(calNum: calendarIds.count, instanceNum: instanceTotalCount)

                    return ServerInstanceData(instanceMap: instancesResult,
                                              timezoneMap: result.timezoneMap,
                                              workHourMap: result.workHourMap)
                }
        } else {
            return calendarApi.getArangementInstance(calendarIds: calendarIds,
                                                     startTime: startTime,
                                                     endTime: endTime,
                                                     timeZone: timeZoneId)
                .map { [weak self] response -> ServerInstanceData in
                    guard let self = self else { return ServerInstanceData() }
                    let instanceMap = self.groupingInstanceToContent(calendarIds: calendarIds,
                                                                     instances: response.instances,
                                                                     date: date,
                                                                     calendar: calendar)
                    return ServerInstanceData(instanceMap: instanceMap,
                                              timezoneMap: response.timezoneMap,
                                              workHourMap: response.workHourMap,
                                              privateCalMap: response.privateCalMap)
                }
                .map { [weak self] result -> ServerInstanceData in
                    guard let self = self else { return ServerInstanceData() }
                    let group = result.instanceMap
                    var instancesResult = InstanceMap()
                    var instanceTotalCount = 0
                    for calendarId in calendarIds {
                        if let contents = group[calendarId] {
                            instanceTotalCount += contents.count
                            let layoutResult = layoutAlgorithm([layoutDay: contents],
                                                                    false,
                                                                    panelSize,
                                                                    [layoutDay])
                            if let resultLayout = layoutResult[layoutDay] {
                                instancesResult[calendarId] = resultLayout
                            } else { assertionFailureLog() }
                        } else { assertionFailureLog() }
                    }

                    var timeZoneMap = result.timezoneMap
                    if timeZoneMap.keys.contains(self.currentUserCalendarId) {
                        timeZoneMap[self.currentUserCalendarId] = TimeZone.current.identifier
                    }
                    CalendarMonitorUtil.endTrackFreebusyViewInstanceTime(calNum: calendarIds.count, instanceNum: instanceTotalCount)

                    return ServerInstanceData(instanceMap: instancesResult,
                                              timezoneMap: timeZoneMap,
                                              workHourMap: result.workHourMap,
                                              privateCalMap: result.privateCalMap)
                }
        }
    }

    func groupingInstanceToContent(calendarIds: [String],
                                   instances: [CalendarEventInstanceEntity],
                                   date: Date,
                                   calendar: Calendar
        ) -> InstanceMap {
        var result = InstanceMap()
        calendarIds.forEach { result[$0] = [] }
        instances.filter { filterInstance($0, date: date, calendar: calendar) }
            .forEach { (instanceEntity) in
                if var instances = result[instanceEntity.calendarId] {
                    let calendar = self.calendar(with: instanceEntity.calendarId)
                    var model = ArrangementInstanceModel(instance: instanceEntity,
                        calendar: calendar)
                    model.meetingRoomCategory = instanceEntity.toPB().category
                    if !model.shouldHideSelf {
                        instances.append(model)
                    }
                    result[instanceEntity.calendarId] = instances
                }
            }
        return result
    }

    private func calendar(with id: String) -> CalendarModel? {
        return calendarManager?.calendar(with: id)
    }

}

final class ArrangementLoader: ArrangementDataLoaderProtocol, UserResolverWrapper {
    let meetingRoom: Rust.MeetingRoom? = nil
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    let calendar = Calendar.gregorianCalendar
    let eventViewSettingGetter: () -> EventViewSetting
    lazy var layoutAlgorithm: LayoutAlgorithm? = {
        guard let layoutRequest = calendarApi?.getInstancesLayoutRequest else { return nil}
        return InstancesLayoutAlgorithm(layoutRequest: layoutRequest).layoutInstances(daysInstencesMap:isSingleDay:panelSize:daysRange:)
    }()
    var currentUserCalendarId: String {
        return calendarManager?.primaryCalendarID ?? ""
    }
    let semaphore = DispatchSemaphore(value: 0)
    private let organizerCalendarId: String
    private let filterParam: FilterParam
    let userResolver: UserResolver

    init(userResolver: UserResolver,
         organizerCalendarId: String,
         filterParam: FilterParam) {
        
        self.userResolver = userResolver

        self.organizerCalendarId = organizerCalendarId
        self.filterParam = filterParam
        self.eventViewSettingGetter = { () in
            return SettingService.shared().getSetting()
        }
    }

    func filterInstance(_ instance: CalendarEventInstanceEntity, date: Date, calendar: Calendar) -> Bool {
        let startTime = date.dayStart(calendar: calendar)
        let endTime = date.dayEnd(calendar: calendar)
        if !instance.isBelongsTo(startTime: startTime, endTime: endTime) {
            return false
        }
        return instance.eventServerId != filterParam.serverId
            && (instance.key != filterParam.key
                || instance.originalTime != filterParam.originalTime)
    }

}

/// 忙闲视图的 dataLoader 不需要过滤已存在的日程
final class FreeBusyLoader: ArrangementDataLoaderProtocol,UserResolverWrapper {
    let userResolver: UserResolver
    let meetingRoom: Rust.MeetingRoom?
    let calendarApi: CalendarRustAPI?
    let calendar = Calendar.gregorianCalendar
    let eventViewSettingGetter: () -> EventViewSetting
    let layoutAlgorithm: LayoutAlgorithm?
    let currentUserCalendarId: String
    let semaphore = DispatchSemaphore(value: 0)
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    init(userResolver: UserResolver,
         calendarApi: CalendarRustAPI,
         currentUserCalendarId: String,
         layoutAlgorithm: @escaping LayoutAlgorithm,
         eventViewSettingGetter: @escaping () -> EventViewSetting,
         meetingRoom: Rust.MeetingRoom? = nil) {
        self.userResolver = userResolver
        self.calendarApi = calendarApi
        self.layoutAlgorithm = layoutAlgorithm
        self.eventViewSettingGetter = eventViewSettingGetter
        self.currentUserCalendarId = currentUserCalendarId
        self.meetingRoom = meetingRoom
    }

    func filterInstance(_ instance: CalendarEventInstanceEntity, date: Date, calendar: Calendar) -> Bool {
        let startTime = date.dayStart(calendar: calendar)
        let endTime = date.dayEnd(calendar: calendar)
        return instance.isBelongsTo(startTime: startTime, endTime: endTime)
    }
}
