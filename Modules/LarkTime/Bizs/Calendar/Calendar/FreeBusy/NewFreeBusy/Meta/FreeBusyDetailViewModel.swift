//
//  FreeBusyDetailViewModel.swift
//  Calendar
//
//  Created by pluto on 2023/8/29.
//

import RxRelay
import RxSwift
import Foundation
import LarkContainer
import CalendarFoundation
import LKCommonsLogging

class FreeBusyDetailViewModel: UserResolverWrapper {
    let baseLogger = Logger.log(FreeBusyDetailViewModel.self, category: "Calendar.FreeBusyDetailViewModel")

    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var timeZoneService: TimeZoneService?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    
    let rxIs12HourStyle: BehaviorRelay<Bool> = SettingService.shared().is12HourStyle
    let firstWeekday: DaysOfWeek = SettingService.shared().getSetting().firstWeekday
    let daysInstanceLabelLayout = DaysInstanceLabelLayout()
    let semaphore = DispatchSemaphore(value: 0)
    let disposeBag: DisposeBag = DisposeBag()
    let userResolver: UserResolver
    
    lazy var currentUserCalendarId: String = {
        calendarManager?.primaryCalendarID ?? ""
    }()
    
    // 会议室场景：会影响loadInstance的链路
    var meetingRoom: Rust.MeetingRoom?
    // 安排时间场景： 过滤当前日程
    var filterParam: FilterParam?
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    func defaultDurationGetter() -> Int {
        return Int(SettingService.shared().getSetting().defaultEventDuration)
    }
        
    func getCreateEventCoordinator(
        contextBuilder: (UnsafeMutablePointer<EventCreateContext>) -> Void = { _ in }
    ) -> EventEditCoordinator {
        var createContext = EventCreateContext()
        contextBuilder(&createContext)
        return EventEditCoordinator(
            userResolver: userResolver,
            editInput: .createWithContext(createContext),
            dependency: EventEditCoordinator.DependencyImpl(userResolver: self.userResolver)
        )
    }
    
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
            .subscribe(onNext: {[weak self] serverInstanceData in
                self?.baseLogger.info("loadInstanceData success with: \(serverInstanceData)")
                result = serverInstanceData
            }, onError: { [weak self] (err) in
                self?.baseLogger.error("loadInstanceData error with: \(err)")
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
                          timeZoneId: String) -> Observable<ServerInstanceData> {
        if let meetingRoom = meetingRoom {
            return loadMeetingRoomInstanceData(calendarIds: calendarIds,
                                               date: date,
                                               panelSize: panelSize,
                                               timeZoneId: timeZoneId,
                                               meetingRoom: meetingRoom)
        } else {
            return loadArangementInstanceData(calendarIds: calendarIds,
                                                 date: date,
                                                 panelSize: panelSize,
                                                 timeZoneId: timeZoneId)
        }
    }
    
    private func loadArangementInstanceData(calendarIds: [String],
                                            date: Date,
                                            panelSize: CGSize,
                                            timeZoneId: String) -> Observable<ServerInstanceData> {
        
        guard let calendarApi = calendarApi else {
            self.baseLogger.error("error get calendar api")
            return .just(ServerInstanceData())
        }
        
        let calendar = TimeZoneUtil.getCalendar(timeZoneId: timeZoneId)
        let startTime = Int64(date.dayStart(calendar: calendar).timeIntervalSince1970)
        let endTime = Int64(date.dayEnd(calendar: calendar).timeIntervalSince1970)
        let layoutDay = getJulianDay(date: date, calendar: calendar)
        return calendarApi.getArangementInstance(calendarIds: calendarIds,
                                                 startTime: startTime,
                                                 endTime: endTime,
                                                 timeZone: timeZoneId)
            .map { [weak self] response -> ServerInstanceData in
                guard let self = self else { return ServerInstanceData() }
                self.baseLogger.info("getArangementInstance success with: \(response)")

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
                        let layoutResult = self.layoutInstances(daysInstencesMap: [layoutDay: contents],
                                                                isSingleDay: false,
                                                                panelSize: panelSize,
                                                                daysRange: [layoutDay])
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
    
    
    private func loadMeetingRoomInstanceData(calendarIds: [String],
                                             date: Date,
                                             panelSize: CGSize,
                                             timeZoneId: String,
                                             meetingRoom: Rust.MeetingRoom) -> Observable<ServerInstanceData> {
        
        guard let calendarApi = calendarApi else {
            self.baseLogger.error("error get calendar api")
            return .just(ServerInstanceData())
        }
        
        let calendar = TimeZoneUtil.getCalendar(timeZoneId: timeZoneId)
        let layoutDay = getJulianDay(date: date, calendar: calendar)
        
        return calendarApi.getMeetingRoomInstances(meetingRooms: [meetingRoom], startTime: date.dayStart(calendar: calendar), endTime: date.dayEnd(calendar: calendar))
            .map { [weak self] response -> ServerInstanceData in
                guard let self = self else { return ServerInstanceData() }
                self.baseLogger.info("getMeetingRoomInstances success with: \(response)")
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
                        /// 会议室使用时 isSingleDay 均为 true
                        let layoutResult = self.layoutInstances(daysInstencesMap: [layoutDay: contents],
                                                                isSingleDay: true,
                                                                panelSize: panelSize,
                                                                daysRange: [layoutDay])
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
    }
    
    private func groupingInstanceToContent(calendarIds: [String],
                                           instances: [CalendarEventInstanceEntity],
                                           date: Date,
                                           calendar: Calendar) -> InstanceMap {
        var result = InstanceMap()
        calendarIds.forEach { result[$0] = [] }
        instances.filter {
            if let filterParam = filterParam  {
                return filterInstance($0, date: date, calendar: calendar, filterParam: filterParam)
            } else {
                return filterInstance($0, date: date, calendar: calendar)
            }
        }.forEach { (instanceEntity) in
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
    
    func filterInstance(_ instance: CalendarEventInstanceEntity, date: Date, calendar: Calendar) -> Bool {
        let startTime = date.dayStart(calendar: calendar)
        let endTime = date.dayEnd(calendar: calendar)
        return instance.isBelongsTo(startTime: startTime, endTime: endTime)
    }
    
    func filterInstance(_ instance: CalendarEventInstanceEntity, date: Date, calendar: Calendar, filterParam: FilterParam) -> Bool {
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

// MARK: - Layout Algorithm Calculate
extension FreeBusyDetailViewModel {
    func layoutInstances(daysInstencesMap: DaysInstancesContentMap,
                         isSingleDay: Bool,
                         panelSize: CGSize,
                         daysRange: [Int32]) -> DaysInstancesContentMap {
        var result = [Int32: [DaysInstanceViewContent]]()

        let mappings = daysInstencesMap.mapValues { (instenceContents) -> [String: DaysInstanceViewContent] in
            return Dictionary(uniqueKeysWithValues: instenceContents.enumerated().map { (String($0), $1) })
        }

        let slots = mapInstencesToSlots(instances: daysInstencesMap)

        calendarApi?.getInstancesLayoutRequest(daysInstanceSlotMetrics: slots, isSingleDay: isSingleDay)
            .map({ $0.daysInstanceLayout })
            .subscribe(onNext: { (daysInstanceLayout) in
                daysInstanceLayout.forEach({ (dayInstanceLayout) in
                    let layoutDay = dayInstanceLayout.layoutDay
                    guard let index = daysRange.firstIndex(of: layoutDay),
                        let mapping = mappings[layoutDay] else {
                        assertionFailureLog()
                        return
                    }
                    var r = [DaysInstanceViewContent]()
                    let layoutConvert = InstanceLayoutConvert()
                    dayInstanceLayout.instancesLayout.forEach({ (instanceLayout) in
                        if var i = mapping[instanceLayout.id] {
                            let frame = layoutConvert.layoutToFrame(layout: instanceLayout,
                                                           panelSize: panelSize,
                                                           index: index)
                            i.frame = frame
                            i.instancelayout = instanceLayout
                            i.index = index
                            i.zIndex = Int(instanceLayout.zIndex)
                            let (titleStyle, subTitleStyle) = self.daysInstanceLabelLayout
                                .getLabelStyle(frame: frame, content: i)
                            i.titleStyle = titleStyle
                            i.subTitleStyle = subTitleStyle
                            r.append(i)
                        }
                    })
                    result[layoutDay] = r
                })
            }).disposed(by: disposeBag)
        return result
    }

    private func mapInstencesToSlots(instances: DaysInstancesContentMap) -> [Rust.InstanceLayoutSlotMetric] {
        return instances.reduce([]) { (result, arg1) -> [Rust.InstanceLayoutSlotMetric] in
            var result = result
            let (layoutDay, instanceContents) = arg1
            var slotMetrics = Rust.InstanceLayoutSlotMetric()
            slotMetrics.layoutDay = layoutDay
            slotMetrics.slotMetrics = instanceContents.enumerated().map(instanceToSlotMetric)
            result.append(slotMetrics)
            return result
        }
    }

    private func instanceToSlotMetric(index: Int, instance: DaysInstanceViewContent) -> InstanceSlotMetric {
        var matric = InstanceSlotMetric()
        matric.id = String(describing: index)
        matric.startTime = Int64(instance.startDate.timeIntervalSince1970)
        matric.startDay = instance.startDay
        matric.startMinute = instance.startMinute
        matric.endTime = Int64(instance.endDate.timeIntervalSince1970)
        matric.endDay = instance.endDay
        matric.endMinute = instance.endMinute
        return matric
    }
}
