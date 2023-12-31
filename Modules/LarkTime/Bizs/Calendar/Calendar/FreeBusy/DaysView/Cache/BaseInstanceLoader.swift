//
//  BaseInstanceLoader.swift
//  Calendar
//
//  Created by zhuheng on 2020/7/14.
//

import Foundation
import CalendarFoundation
import RxSwift
import ThreadSafeDataStructure
import CTFoundation
import LarkContainer
import LKCommonsLogging

class BaseInstanceLoader: UserResolverWrapper {
    enum ActiveStatus {
        case active
        case inactive
    }

    enum DataStatus {
        case clean
        case dirty
    }

    let logger = Logger.log(BaseInstanceLoader.self, category: "Calendar.InstanceLoader")

    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarSelectTracer: CalendarSelectTracer?
    @ScopedInjectedLazy var timeDataService: TimeDataService?

    private(set) var activeStatus: SafeAtomic<ActiveStatus> = .inactive + .readWriteLock
    private(set) var dataStatus: SafeAtomic<DataStatus> = .dirty + .readWriteLock
    private var timeZoneIdGetter: () -> String
    let calendarApi: CalendarRustAPI
    private let visibleCalendarsIDs: () -> [String]
    private(set) var loadingJulianDays: SafeSet<Int32> = SafeSet<Int32>([], synchronization: .semaphore) // 避免重复调用getInstance
    private var cacheHitCount = 0
    private var requestCount = 0
    var cache: InstanceCacheOld
    var instanceSnapshot: InstanceSnapshot
    let blockOnReady = PublishSubject<Void>()
    let disposeBag = DisposeBag()

    let userResolver: UserResolver

    init(cache: InstanceCacheOld,
         instanceSnapshot: InstanceSnapshot,
         calendarApi: CalendarRustAPI,
         userResolver: UserResolver,
         timeZoneIdGetter: @escaping () -> String,
         visibleCalendarsIDs: @escaping () -> [String]) {
        self.timeZoneIdGetter = timeZoneIdGetter
        self.calendarApi = calendarApi
        self.visibleCalendarsIDs = visibleCalendarsIDs
        self.cache = cache
        self.userResolver = userResolver

        self.instanceSnapshot = instanceSnapshot

        guard let calendarManager = self.calendarManager,
              let localRefreshService = self.localRefreshService,
              let pushService = self.pushService else {
            logger.error("can not get service from larkcontainer!!!!")
            return
        }

        let calVisibilitySubject = calendarManager.rxCalendarVisibilityUpdated
        let rxInnerEventChanged = localRefreshService.rxEventNeedRefresh.map { _ in
            return
        }

        let allChangePush = Observable.of(
            calVisibilitySubject, // 日历可见性变化
            calendarManager.rxCalendarUpdated, // 刷新 instance 的 push 不收敛，接入 rxCalendarUpdated 可能导致重复刷新；不接导致 calendars 更新不及时
            LocalCalendarManager.eventStoreChangedSubject, // 本地日历改变，Todo：本地日历改变后续不应该全量getInstance，要与lark getinstance解耦
            pushService.rxCalendarRefresh.map({ (_) -> Void in
                return
            }),
            timeDataService?.rxTimeBlocksChange.map { _ in } ?? .empty(),
            rxInnerEventChanged).merge()

        addPushListener(allChangedPush: allChangePush)
        addPushListener(refineChangedPush: pushService.rxCalendarEventChanged)
    }

    // 同步接口，优先从缓存池中取，未命中请求SDK
    func getInstance(with julianDays: Set<Int32>, timeZoneID: String) -> [CalendarEventInstanceEntity] {
        defer {
            self.requestCount += 1
            if self.requestCount >= 20 {
                // 20次请求上报一次，服务端做数据计算
                let mode = CalendarDayViewSwitcher().mode
                CalendarTracer.shared.calPerfCacheHitRatio(hitCount: self.cacheHitCount, requestCount: self.requestCount, viewType: CalendarTracer.ViewType(mode: mode).rawValue)
                self.cacheHitCount = 0
                self.requestCount = 0
            }
        }
        let julianDayRange = JulianDayUtil.makeJulianDayRange(min: julianDays.min(), max: julianDays.max())
        if let instance = self.cache.selectInstances(with: julianDayRange, timeZoneId: timeZoneID) {
            self.cacheHitCount += 1
            return instance
        }

        var isLoading = false
        loadingJulianDays.safeRead { (days) in
            if julianDays.isSubset(of: days) {
                isLoading = true
            }
        }

        guard !isLoading else {
            return [CalendarEventInstanceEntity]()
        }

        // 缓存未命中
        self.getInstance(requestDays: julianDays, timeZoneId: timeZoneID)
            .subscribe()
            .disposed(by: disposeBag)
        return [CalendarEventInstanceEntity]()
    }
    
    // 同步接口，优先从缓存池中取，未命中请求SDK
    func getTimeBlock(with julianDays: Set<Int32>, timeZoneID: String) -> [TimeBlockModel] {
        guard let timeDataService = self.timeDataService else { return [] }
        let julianDayRange = JulianDayUtil.makeJulianDayRange(min: julianDays.min(), max: julianDays.max())
        let result = timeDataService.getTimeBlockDataBy(range: julianDayRange, timezone: TimeZone(identifier: timeZoneID) ?? .current, scene: .month)
        var timeBlocks = [TimeBlockModel]()
        var blockSet = Set<String>()
        result.0.forEach { item in
            let map = item.value
            map.forEach { model in
                if !blockSet.contains(model.id) {
                    blockSet.insert(model.id)
                    timeBlocks.append(model)
                }
            }
        }
        if case .all = result.1 {
            return timeBlocks
        }
        timeDataService.fetchTimeBlockDataBy(range: julianDayRange, timezone: TimeZone(identifier: timeZoneID) ?? .current, scene: .month)
            .subscribe(onNext: { [weak self] _ in
                self?.blockOnReady.onNext(())
            })
            .disposed(by: disposeBag)
        return timeBlocks
    }

    // 初始化instance接口。首次getInstances需要在requestScheduler进行，保证已有setting数据
    func load(requestDays: Set<Int32>, nextRequestDays: Set<Int32>? = nil, timeZoneId: String) {
        let expectCachedDays = nextRequestDays ?? requestDays
        self.setLoadingDays(days: expectCachedDays)
        let firstScreenRange = JulianDayUtil.makeJulianDayRange(min: requestDays.min(), max: requestDays.max())
        let expectCachedRange = JulianDayUtil.makeJulianDayRange(min: expectCachedDays.min(), max: expectCachedDays.max())

        self.instanceSnapshot.load(firstScreenDayRange: firstScreenRange,
                                   expectTimeZoneId: timeZoneId)
            .subscribe(onNext: { [weak self] () in
                guard let self = self, let instance = self.instanceSnapshot.firstScreenData?.instance else {
                    return
                }
                let pbInstances = instance.map { CalendarEventInstanceEntityFromPB(withInstance: $0) }
                self.cache.updateCachedInstances(new: pbInstances, range: expectCachedRange, timeZoneId: timeZoneId)
                self.cancelLoadingDays(days: expectCachedDays)
                self.blockOnReady.onNext(())
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(200)) {
                    self.reloadCacheInstance()
                }
            }, onError: { [weak self] (_) in
                guard let self = self else { return }
                self.cancelLoadingDays(days: expectCachedDays)
                TimerMonitorHelper.shared.launchTimeTracer?.getInstance.start()
                self.getInstance(requestDays: requestDays, nextRequestDays: nextRequestDays, timeZoneId: self.timeZoneIdGetter())
                    .subscribeOn(self.calendarApi.requestScheduler)
                    .subscribe(onNext: { (entitys) in
                        TimerMonitorHelper.shared.launchTimeTracer?.getInstance.end(extra: [.firstScreenInstancesLength: entitys.count])
                    }, onError: { (_) in
                        TimerMonitorHelper.shared.launchTimeTracer?.getInstance.end(extra: [.firstScreenInstancesLength: 0])
                    }).disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)

    }

    // 异步接口，直接请求SDK
    private func getInstance(requestDays: Set<Int32>, nextRequestDays: Set<Int32>? = nil, timeZoneId: String) -> Observable<[CalendarEventInstanceEntity]> {
        guard let startDay = requestDays.min(), let endDay = requestDays.max() else {
            return .just([CalendarEventInstanceEntity]())
        }
        let nextRequestDays = nextRequestDays ?? requestDays

        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = TimeZone(identifier: timeZoneId) ?? TimeZone.current
        let startTime = getDate(julianDay: startDay, calendar: calendar).dayStart()
        let endTime = getDate(julianDay: endDay, calendar: calendar).dayEnd()

        self.setLoadingDays(days: nextRequestDays)
        return self.calendarApi.getEventInstances(startTime: Int64(startTime.timeIntervalSince1970),
                                                  endTime: Int64(endTime.timeIntervalSince1970),
                                                  scenarioToken: .readLocalEventInstanceOnEventView,
                                                  ignoreLocal: false,
                                                  filterHidden: true,
                                                  timeZone: timeZoneId)
            .map { [weak self] entitys in
                guard let self = self,
                      let calendarManager = self.calendarManager else { return [] }
                self.calendarSelectTracer?.setDataLength(entitys.count)
                self.calendarSelectTracer?.endIfNeeded(instance: entitys.map { $0.toPB() })

                // 主日历同步到 exchange，若主日历可见，exchange 隐藏（视图上仅显示一个）
                let conflictExchangeCalendarIDs = calendarManager.conflictExchangeCalendarIDs
                let idsDic = calendarManager.primaryCalendarIDsAndUserIDsDic
                let primaryKeys: [String] = FG.syncDeduplicationOpen ? entitys.compactMap {
                    if let userID = idsDic[$0.calendarId] {
                        return $0.getInstanceKeyWithTimeTuple() + userID
                    } else { return nil }
                } : []
                if !conflictExchangeCalendarIDs.isEmpty {
                    return entitys.filter {
                        let key = $0.getInstanceKeyWithTimeTuple() + (calendarManager.calendar(with: $0.calendarId)?.userId ?? "")
                        return !(
                            conflictExchangeCalendarIDs.contains($0.calendarId)
                            && ($0.isSyncFromLark || primaryKeys.contains(key))
                        )
                    }
                } else {
                    return entitys
                }
            }
            .do(afterNext: { [weak self] (entitys) in
                guard let `self` = self else { return }
                let deleteRange = JulianDayUtil.makeJulianDayRange(min: requestDays.min(), max: requestDays.max())

                self.cancelLoadingDays(days: nextRequestDays)
                self.cache.deleteInstances(with: deleteRange, timeZoneId: timeZoneId)
                let updateRange = JulianDayUtil.makeJulianDayRange(min: nextRequestDays.min(), max: nextRequestDays.max())

                self.cache.updateCachedInstances(new: entitys,
                                                range: updateRange,
                                                timeZoneId: timeZoneId)
                self.blockOnReady.onNext(())
                let refidCalendarMap = Dictionary(entitys.map { ($0.eventServerId, $0.calendarId) }) { $1 }

                if requestDays != nextRequestDays {
                    self.getInstance(requestDays: nextRequestDays, timeZoneId: timeZoneId).subscribe().disposed(by: self.disposeBag)
                } else {
                    self.dataStatus.value = .clean
                }
            }, onError: { [weak self] (_) in
                guard let `self` = self else { return }
                self.cancelLoadingDays(days: nextRequestDays)
            })
    }

    func reloadCacheInstance() {
        DispatchQueue.global().async {
            guard !self.cache.isEliminating else {
                self.dataStatus.value = .dirty
                return
            }

            let cacheRange = self.cache.getCacheRange()
            guard !cacheRange.isEmpty else {
                self.blockOnReady.onNext(())
                return
            }

            let julianDaysSet = Set(cacheRange.map { Int32($0) })
            self.getInstance(requestDays: julianDaysSet, timeZoneId: self.timeZoneIdGetter())
                .subscribe()
                .disposed(by: self.disposeBag)
        }
    }

    func active() {
        guard activeStatus.value == .inactive else {
            return
        }
        self.activeStatus.value = .active
        self.becomeActive()
    }

    func inactive() {
        self.activeStatus.value = .inactive
    }

    private func addPushListener(allChangedPush: Observable<Void>) {
        allChangedPush
            .throttle(.milliseconds(300), latest: true, scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                if self.activeStatus.value == .active {
                    self.reloadCacheInstance()
                } else {
                    self.dataStatus.value = .dirty
                }
            }).disposed(by: disposeBag)
    }

    private func setLoadingDays(days: Set<Int32>) {
        self.loadingJulianDays.safeWrite(all: { (set) in
            set = set.union(days)
        })
    }

    private func cancelLoadingDays(days: Set<Int32>) {
        self.loadingJulianDays.safeWrite(all: { (set) in
            set = set.subtracting(days)
        })
    }

    private func addPushListener(refineChangedPush: PublishSubject<Rust.CalendarEventChanged>) {
        refineChangedPush
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if self.activeStatus.value == .active {
                    self.reloadCacheInstance()
                } else {
                    self.dataStatus.value = .dirty
                }
            }).disposed(by: disposeBag)
    }

    private func becomeActive() {
        switch dataStatus.value {
        case .dirty:
            self.reloadCacheInstance()
        case .clean:
            return
        }
    }

    private func doRefineChange(updateUniqueFields: [CalendarEventUniqueField],
                                deleteUniqueFields: [CalendarEventUniqueField]) {
        if self.cache.isEmpty {
            self.reloadCacheInstance()
        } else if updateUniqueFields.isEmpty {
            self.cache.deleteInstances(with: deleteUniqueFields, timeZoneId: self.timeZoneIdGetter())
            self.blockOnReady.onNext(())
        } else {
            self.reloadChangedEventCollection(updateUniqueFields: updateUniqueFields,
                                              deleteUniqueFields: deleteUniqueFields,
                                              visibleCalendarsIDs: self.visibleCalendarsIDs)
        }
    }

    private func reloadChangedEventCollection(updateUniqueFields: [CalendarEventUniqueField],
                                              deleteUniqueFields: [CalendarEventUniqueField],
                                              visibleCalendarsIDs: @escaping () -> [String]) {
        DispatchQueue.global().async {
            guard !updateUniqueFields.isEmpty else { return }
            let cachedJulianDays = self.cache.getCacheRange()
            let startDay = cachedJulianDays.lowerBound
            let endDay = cachedJulianDays.upperBound
            let timeZoneId = self.timeZoneIdGetter()
            var calendar = Calendar.gregorianCalendar
            calendar.timeZone = TimeZone(identifier: timeZoneId) ?? TimeZone.current
            let startTime = getDate(julianDay: Int32(startDay), calendar: calendar).dayStart()
            let endTime = getDate(julianDay: Int32(endDay), calendar: calendar)
            self.calendarApi.getInstance(eventUniqueFiledId: updateUniqueFields,
                                    startTime: Int64(startTime.timeIntervalSince1970),
                                    endTime: Int64(endTime.timeIntervalSince1970),
                                    timezone: self.timeZoneIdGetter())
            .subscribe(onNext: { [weak self] (entitys) in
                guard let `self` = self else { return }
                let calendars = visibleCalendarsIDs()
                let needUpdateEntitys = entitys.filter { (entity) -> Bool in
                    return calendars.contains(entity.calendarId)
                }
                let instance = needUpdateEntitys.map { $0.toPB() }
                self.cache.deleteInstances(with: deleteUniqueFields, timeZoneId: timeZoneId)
                let pbInstances = instance.map { CalendarEventInstanceEntityFromPB(withInstance: $0) }
                self.cache.updateCachedInstances(new: pbInstances,
                                                 range: nil,
                                                 timeZoneId: self.timeZoneIdGetter())
                self.blockOnReady.onNext(())

                let refidCalendarMap = Dictionary(needUpdateEntitys.map { ($0.eventServerId, $0.calendarId) }) { $1 }
            }).disposed(by: self.disposeBag)
        }
    }

}
