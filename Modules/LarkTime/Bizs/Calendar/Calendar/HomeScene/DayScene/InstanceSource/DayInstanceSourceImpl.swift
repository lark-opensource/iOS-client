//
//  DayInstanceSourceImpl.swift
//  Calendar
//
//  Created by 张威 on 2020/9/3.
//

import UIKit
import EventKit
import RxSwift
import RxRelay
import RustPB
import ThreadSafeDataStructure
import CTFoundation

/// 为 DayScene 提供 Instance
///

final class DayInstanceSourceImpl {

    // 用于获取 instance
    private let instanceService: InstanceService
    // 用于获取时间块数据
    private let timeDataService: TimeDataService
    // 用于获取非全天 instance 的 layout
    private let calendarApi: CalendarRustAPI
    // 每周的第一天。`DayInstanceSourceImpl` 请求 instance 是以周为单位拉取的，`rxFirstWeekday` 辅助计算对应周的 dayRange
    private let rxFirstWeekday: BehaviorRelay<EKWeekday>
    // cache latest request，提升对 response 的利用率
    private let requestCache = LRUCache<String, ReplaySubject<CAValue<DayInstanceMap>>>(capacity: 20, useLock: true)
    // 当收到 instanceService.update 通知，计数 +1
    private var updatedCounter: Int64 = 0
    // 通知
    private let rxUpdate = (allDay: PublishSubject<Void>(), nonAllDay: PublishSubject<Void>())
    // 描述是否是日视图（日视图和三日/周视图的 layout 计算结果不一样）
    private let isSingleDay: Bool
    // 冷启动
    private var coldLaunch = (context: HomeScene.ColdLaunchContext, request: ReplaySubject<CAValue<DayInstanceMap>>?)?.none
    private let disposeBag = DisposeBag()
    /// 构造 DayInstanceSourceImpl
    ///
    /// - Parameters:
    ///   - instanceService: 拉取 rust instance
    ///   - calendarApi: 用于拉取 instance 的 layout
    ///   - daysPerScene: 每一屏有几天
    ///   - rxFirstWeekday: 每周的第一天
    init(
        instanceService: InstanceService,
        calendarApi: CalendarRustAPI,
        timeDataService: TimeDataService,
        daysPerScene: Int,
        rxFirstWeekday: BehaviorRelay<EKWeekday>,
        coldLaunchContext: HomeScene.ColdLaunchContext? = nil
    ) {
        self.instanceService = instanceService
        self.calendarApi = calendarApi
        self.timeDataService = timeDataService
        self.isSingleDay = daysPerScene <= 1
        self.rxFirstWeekday = rxFirstWeekday
        if let coldLaunchContext = coldLaunchContext {
            self.coldLaunch = (context: coldLaunchContext, request: nil)
        } else {
            self.coldLaunch = nil
        }

        instanceService.instanceUpdated
            .do(onNext: { [weak self] in
                guard let self = self else { return }
                OSAtomicIncrement64(&self.updatedCounter)
            })
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.rxUpdate.allDay.onNext(())
                self.rxUpdate.nonAllDay.onNext(())
            })
            .disposed(by: disposeBag)
    }

    // MARK: Private Methods

    #if DEBUG
    private var makeRequestCounts = (hitCache: 0, total: 0)
    #endif
    private func makeRequest(
        for dayRangeWrapper: CAValue<JulianDayRange>,
        in timeZone: TimeZone,
        source: String
    ) -> RxReturn<CAValue<DayInstanceMap>> {
        let dayRange = DayScene.julianDayRange(inWeeksAs: dayRangeWrapper.value, with: rxFirstWeekday.value)
        let loggerModel = dayRangeWrapper.loggerModel
        let counter = updatedCounter
        let key = "\(dayRange.lowerBound)_\(dayRange.upperBound)_\(counter)_\(timeZone.identifier)"
        #if DEBUG
        makeRequestCounts.total += 1
        defer {
            let radio = Float(makeRequestCounts.hitCache) / Float(makeRequestCounts.total)
            print("DayInstanceSourceImpl request 命中率: \(radio). key: \(key), source: \(source)")
        }
        #endif
        // 使用requestCache来避免同一时段重复请求
        if let request = requestCache.value(forKey: key) {
            #if DEBUG
            makeRequestCounts.hitCache += 1
            #endif
            EffLogger.log(model: loggerModel, toast: "hit requestCache")
            DayScene.logger.info("hit requestCache")
            return .rxValue(request.asSingle().do(onError: { _ in
                EffLogger.log(model: loggerModel, toast: "request.asSingle error")
            }))
        }

        let subject = ReplaySubject<CAValue<DayInstanceMap>>.create(bufferSize: 1)
        subject.subscribe(onError: { [weak self, weak subject] error in
            guard let subject = subject else { return }
            EffLogger.log(model: loggerModel, toast: "subject error")
            DayScene.logger.error("subject error", error: error)
            self?.requestCache.removeValue(forKey: key, while: { subject === $0 })
        }).disposed(by: disposeBag)

        EffLogger.log(model: loggerModel, toast: "getRxInstance")
        DayScene.logger.info("getRxInstance")
        let rxGroupedInstances: Observable<CAValue<DayInstanceMap>>
        switch instanceService.rxInstance(for: .init(dayRange, loggerModel), in: timeZone) {
        case .value(let groupedInstances):
            rxGroupedInstances = .just(groupedInstances)
        case .rxValue(let _rxGroupedInstances):
            rxGroupedInstances = _rxGroupedInstances.asObservable()
        }
        rxGroupedInstances
            .collectSlaInfo(.CalendarView, action: "load_instance")
            .subscribe(subject).disposed(by: disposeBag)
        requestCache.setValue(subject, forKey: key)
        if dayRange.count > 7 && dayRange.count % 7 == 0 {
            // dayRange 可能跨多个星期，将之分为多个块，以期充分使用
            var lowerBound = dayRange.lowerBound
            while lowerBound < dayRange.upperBound {
                let key = "\(lowerBound)_\(lowerBound + 7)_\(counter)_\(timeZone.identifier)"
                requestCache.setValue(subject, forKey: key)
                lowerBound += 7
            }
        }

        return .rxValue(subject.asSingle())
    }
}

// MARK: - AllDay

extension DayInstanceSourceImpl: DayAllDayInstanceSource {
    var rxAllDayInstanceUpdated: PublishSubject<Void> { rxUpdate.allDay }

    func rxAllDayInstances(for dayRangeWrapper: CAValue<JulianDayRange>,
                           in timeZone: TimeZone,
                           fromColdLaunch: Bool) -> RxReturn<[DayAllDayLayoutedInstance]> {
        let dayRange = dayRangeWrapper.value
        var rxReturn: RxReturn<CAValue<DayInstanceMap>>?
        if fromColdLaunch {
            rxReturn = makeColdLaunchRequest(for: dayRangeWrapper, in: timeZone)
        }
        if rxReturn == nil {
            rxReturn = makeRequest(for: dayRangeWrapper, in: timeZone, source: "allDay")
        }

        guard let rxReturn = rxReturn else {
            assertionFailure()
            return .value([])
        }

        let startTime: CFTimeInterval = fromColdLaunch ? CACurrentMediaTime() : 0
        let newDayRange = DayScene.julianDayRange(inWeeksAs: dayRange, with: rxFirstWeekday.value)
        let strategy: TimeDataFetchStrategy = fromColdLaunch ? .coldLaunch : .normal
        let getTimeBlockMap = timeDataService.fetchTimeBlockDataBy(range: newDayRange, timezone: timeZone, strategy: strategy, scene: .allDay).catchErrorJustReturn([:])
        // 合并日程和时间块的数据
        let zipObservable = Observable.zip(rxReturn.asObservable(), getTimeBlockMap)
        let result = zipObservable.map { (groupedInstances, timeBlocksMap) -> [DayAllDayLayoutedInstance] in
            // 埋点统计冷启动请求 allDay instance 的耗时
            if fromColdLaunch {
                let cost = CACurrentMediaTime() - startTime
                HomeScene.coldLaunchTracker?.addStage(.requestAllDayInstance, with: cost)
            }

            let instances = groupedInstances.value.values
                .flatMap { $0 }
                .lf_unique(by: { $0.uniqueId })
            var ret = [DayAllDayLayoutedInstance]()
            for instance in instances {
                guard instance.shouldTreatedAsAllDay() else { continue }
                let instanceDayRange = instance.dayRange(in: timeZone)
                guard instanceDayRange.overlaps(dayRange) else { continue }
                ret.append(DayAllDayLayoutedInstance(instance: instance, dayRange: instanceDayRange))
            }
            let timeBlocks = timeBlocksMap.values
                .flatMap { $0 }
                .lf_unique(by: { $0.id })
            for timeBlock in timeBlocks {
                guard timeBlock.shouldTreatedAsAllDay() else { continue }
                let instanceDayRange = timeBlock.dayRange(in: timeZone)
                guard instanceDayRange.overlaps(dayRange) else { continue }
                ret.append(DayAllDayLayoutedInstance(instance: timeBlock, dayRange: instanceDayRange))
            }
            return ret
        }
        return .rxValue(result.asSingle())
    }
}

// MARK: - NonAllDay

extension DayInstanceSourceImpl: DayNonAllDayInstanceSource {

    var rxNonAllDayInstanceUpdated: PublishSubject<Void> { rxUpdate.nonAllDay }

    func rxNonAllDayInstances(
        for dayRangeWrapper: CAValue<JulianDayRange>,
        in timeZone: TimeZone,
        fromColdLaunch: Bool) -> RxReturn<CAValue<[JulianDay: [DayNonAllDayLayoutedInstance]]>> {
        let dayRange = dayRangeWrapper.value
        let loggerModel = dayRangeWrapper.loggerModel
        var rxGroupedInstances: Observable<CAValue<DayInstanceMap>>?
        if fromColdLaunch {
            EffLogger.log(model: loggerModel, toast: "fromColdLaunch try makeColdLaunchRequest")
            DayScene.logger.info("fromColdLaunch try makeColdLaunchRequest")
            rxGroupedInstances = makeColdLaunchRequest(for: dayRangeWrapper, in: timeZone)?.asObservable()
        }
        if rxGroupedInstances == nil {
            EffLogger.log(model: loggerModel, toast: "makeRequest exected")
            DayScene.logger.info("makeRequest exected")
            switch makeRequest(for: dayRangeWrapper, in: timeZone, source: "nonAllDay") {
            case .value(let groupedInstances):
                rxGroupedInstances = .just(groupedInstances)
            case .rxValue(let _rxGroupedInstances):
                rxGroupedInstances = _rxGroupedInstances.asObservable()
            }
        } else {
            EffLogger.log(model: loggerModel, toast: "use ColdLaunchData")
            DayScene.logger.info("use ColdLaunchData")
        }

        guard let rxGroupedInstances = rxGroupedInstances else {
            assertionFailure()
            return .value(CAValue([:], .init()))

        }

        let startTime1: CFTimeInterval = fromColdLaunch ? CACurrentMediaTime() : 0
        let newDayRange = DayScene.julianDayRange(inWeeksAs: dayRangeWrapper.value, with: rxFirstWeekday.value)
        let strategy: TimeDataFetchStrategy = fromColdLaunch ? .coldLaunch : .normal
        let getTimeBlockMap = timeDataService.fetchTimeBlockDataBy(range: newDayRange, timezone: timeZone, strategy: strategy, scene: .nonAllDay).catchErrorJustReturn([:])
        // 合并日程和时间块的数据
        let zipObservable = Observable.zip(rxGroupedInstances, getTimeBlockMap)
        let start = CACurrentMediaTime()
        let rxValue = zipObservable
            .flatMap { [weak self] (groupedInstancesWrapper, timeBlocksMap) -> Observable<CAValue<[JulianDay: [DayNonAllDayLayoutedInstance]]>> in
                let loggerModel = groupedInstancesWrapper.loggerModel
                if fromColdLaunch {
                    // 埋点统计冷启动请求 nonAllDay instance 的耗时
                    let cost = CACurrentMediaTime() - startTime1
                    HomeScene.coldLaunchTracker?.addStage(.requestNonAllDayInstance, with: cost)
                }
                guard let self = self else { return .just(CAValue([:], .init())) }
                // 过滤全天日程
                let groupedInstances = groupedInstancesWrapper.value.filter { dayRange.contains($0.key) }
                    .mapValues { instances -> [Instance] in
                        return instances.filter { !$0.shouldTreatedAsAllDay() }
                    }
                let filterTimeBlocksMap = timeBlocksMap.filter { dayRange.contains($0.key) }
                    .mapValues { models -> [TimeBlockModel] in
                        return models.filter { !$0.shouldTreatedAsAllDay() }
                    }
                let layoutContext = DayInstanceLayoutUtil.prepareLayoutContexts(from: groupedInstances,
                                                                                timeBlocksMap: filterTimeBlocksMap,
                                                                                in: timeZone)
                let reqModel = loggerModel.createNewModelByTask(.request)
                EffLogger.log(model: reqModel, toast: "envoke GetInstancesLayoutRequest")
                let request = self.calendarApi.asyncGetInstancesLayoutRequest(daysInstanceSlotMetrics:isSingleDay:)

                let startTime2: CFTimeInterval = fromColdLaunch ? CACurrentMediaTime() : 0
                return request(layoutContext.slotMetrics, self.isSingleDay)
                    .map { response -> CAValue<[JulianDay: [DayNonAllDayLayoutedInstance]]> in
                        let resModel = reqModel.createNewModelByTask(.response)
                        resModel.log("GetInstancesLayoutRequest callback")
                        if fromColdLaunch {
                            // 埋点统计冷启动请求 nonAllDay layouted instance 的耗时
                            let cost1 = CACurrentMediaTime() - startTime1
                            HomeScene.coldLaunchTracker?.addStage(.requestNonAllDayLayoutedInstance, with: cost1)

                            // 埋点统计冷启动请求 layout 的耗时
                            let cost2 = CACurrentMediaTime() - startTime2
                            HomeScene.coldLaunchTracker?.addStage(.requestNonAllDayInstanceLayout, with: cost2)
                        }
                        var ret = [JulianDay: [DayNonAllDayLayoutedInstance]]()
                        response.daysInstanceLayout.forEach { dayItem in
                            let day = JulianDay(dayItem.layoutDay)
                            ret[day] = dayItem.instancesLayout.compactMap {
                                if let instance = layoutContext.instances2DMap[day]?[$0.id] {
                                    return DayNonAllDayLayoutedInstance(instance: instance, layout: $0)
                                }
                                if let timeBlock = layoutContext.timeBlocks2DMap[day]?[$0.id] {
                                    return DayNonAllDayLayoutedInstance(instance: timeBlock, layout: $0)
                                }
                                return nil
                            }
                            assert(ret[day]?.count == layoutContext.instances2DMap[day]?.count)
                        }
                        assert(Set(ret.keys) == Set(dayRange))
                        return .init(ret, resModel.createNewModelByTask(.process))
                    }
            }
            .asSingle().do(onError: { error in
                EffLogger.log(model: loggerModel, toast: "asSingle do error", error: error)
            })
        return .rxValue(rxValue)
    }
}

// MARK: - Cold Launch

extension DayInstanceSourceImpl {

    private func _makeColdLaunchRequest(
        for dayRangeWrapper: CAValue<JulianDayRange>,
        in timeZone: TimeZone
    ) -> RxReturn<CAValue<DayInstanceMap>>? {
        let dayRange = dayRangeWrapper.value
        guard let context = coldLaunch?.context else {
            assertionFailure("coldLaunchContext should not be nil")
            return nil
        }
        guard context.dayRange == dayRange, context.timeZone.identifier == timeZone.identifier else {
            assertionFailure("cold launch error: dayRange and timeZone is not matched")
            return nil
        }
        if let request = coldLaunch?.request {
            return .rxValue(request.asSingle())
        }
        let subject = ReplaySubject<CAValue<DayInstanceMap>>.create(bufferSize: 1)
        let rxColdLaunchInstances: Observable<CAValue<ColdLaunchInstances>>
        switch instanceService.rxColdLaunchInstance(for: dayRangeWrapper, in: timeZone) {
        case .value(let coldLaunchInstancesWrapper):
            rxColdLaunchInstances = .just(coldLaunchInstancesWrapper)
        case .rxValue(let _rxGroupedInstances):
            rxColdLaunchInstances = _rxGroupedInstances.asObservable()
        }

        let coldLaunchTracker = HomeScene.coldLaunchTracker
        rxColdLaunchInstances
            .do(onNext: { coldLaunchInstancesWrapper in
                let coldLaunchInstances = coldLaunchInstancesWrapper.value
                var instanceCount = 0
                coldLaunchInstances.instanceMap.values.forEach { instanceCount += $0.count }
                coldLaunchTracker?.setValue(instanceCount, forMetricKey: .instanceCount)

                let instanceSource: String
                if coldLaunchInstances.isFromRust {
                    instanceSource = HomeScene.ColdLaunchCategory.instanceSourceValues.fromRust
                } else {
                    instanceSource = HomeScene.ColdLaunchCategory.instanceSourceValues.fromSnapshot
                }
                coldLaunchTracker?.setValue(instanceSource, forCategory: .instanceSource)
            })
                .map { .init($0.value.instanceMap, $0.loggerModel) }
            .subscribe(subject).disposed(by: disposeBag)
        self.coldLaunch?.request = subject
        return .rxValue(subject.asSingle())
    }

    private func makeColdLaunchRequest(
        for dayRangeWrapper: CAValue<JulianDayRange>,
        in timeZone: TimeZone
    ) -> RxReturn<CAValue<DayInstanceMap>>? {
        if Thread.isMainThread {
            return _makeColdLaunchRequest(for: dayRangeWrapper, in: timeZone)
        } else {
            assertionFailure("You should better call this api in main thread")
            var ret = RxReturn<CAValue<DayInstanceMap>>?.none
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                ret = self._makeColdLaunchRequest(for: dayRangeWrapper, in: timeZone)
                semaphore.signal()
            }
            semaphore.wait()
            return ret
        }
    }

}

// MARK: Utils
class DayInstanceLayoutUtil {

    static func asyncPrepareLayoutInstance(
        layoutRequest: LayoutRequest,
        from groupedInstances: DayInstanceMap,
        isSingleDay: Bool,
        in timeZone: TimeZone
    ) -> Observable<[JulianDay: [DayNonAllDayLayoutedInstance]]> {
        let layoutContext = Self.prepareLayoutContexts(from: groupedInstances, timeBlocksMap: [:], in: timeZone)

        return layoutRequest(layoutContext.slotMetrics, isSingleDay)
            .map { response -> [JulianDay: [DayNonAllDayLayoutedInstance]] in
                var ret = [JulianDay: [DayNonAllDayLayoutedInstance]]()
                response.daysInstanceLayout.forEach { dayItem in
                    let day = JulianDay(dayItem.layoutDay)
                    ret[day] = dayItem.instancesLayout.compactMap {
                        guard let instance = layoutContext.instances2DMap[day]?[$0.id] else { return nil }
                        return .init(instance: instance, layout: $0)
                    }
                    assert(ret[day]?.count == layoutContext.instances2DMap[day]?.count)
                }
//                assert(Set(ret.keys) == Set(dayRange))
                return ret
            }
    }

    static func syncPrepareLayoutInstance(
        layoutRequest: LayoutRequest,
        from groupedInstances: DayInstanceMap,
        isSingleDay: Bool,
        in timeZone: TimeZone
    ) -> [JulianDay: [DayNonAllDayLayoutedInstance]] {
        var res: [JulianDay: [DayNonAllDayLayoutedInstance]] = [:]
        let disposeBag = DisposeBag()
        Self.asyncPrepareLayoutInstance(layoutRequest: layoutRequest,
                                        from: groupedInstances,
                                        isSingleDay: isSingleDay,
                                        in: timeZone)
        .subscribe(onNext: { response in
            res = response
        }).disposed(by: disposeBag)
        return res
    }

    static func prepareLayoutContexts(
        from groupedInstances: DayInstanceMap,
        timeBlocksMap: TimeBlockModelMap,
        in timeZone: TimeZone
    ) -> (slotMetrics: [Rust.InstanceLayoutSlotMetric], 
          instances2DMap: [JulianDay: [String: Instance]],
          timeBlocks2DMap: [JulianDay: [String: TimeBlockModel]]) {
        var slotMetricList = [Rust.InstanceLayoutSlotMetric]()
        var instances2DMap = [JulianDay: [String: Instance]]()
        var timeBlocks2DMap = [JulianDay: [String: TimeBlockModel]]()
        for day in groupedInstances.keys.sorted() {
            instances2DMap[day] = [:]
            var slotMetric = Rust.InstanceLayoutSlotMetric()
            slotMetric.layoutDay = Int32(day)
            var layoutSeeds = [Rust.InstanceLayoutSeed]()
            for instance in groupedInstances[day]! {
                let seed = makeInstanceLayoutSeed(from: instance, in: timeZone)
                layoutSeeds.append(seed)
                instances2DMap[day]?[instance.uniqueId] = instance
            }
            // timeblock
            timeBlocks2DMap[day] = [:]
            let entitys = timeBlocksMap[day] ?? []
            for entity in entitys {
                let seed = makeInstanceLayoutSeed(from: entity, in: timeZone)
                layoutSeeds.append(seed)
                timeBlocks2DMap[day]?[entity.id] = entity
            }
            slotMetric.slotMetrics = layoutSeeds
            slotMetricList.append(slotMetric)
        }
        return (slotMetricList, instances2DMap, timeBlocks2DMap)
    }
    
    static func makeInstanceLayoutSeed(
        from model: TimeBlockModel,
        in timeZone: TimeZone
    ) -> Rust.InstanceLayoutSeed {
        var seed = Rust.InstanceLayoutSeed()
        seed.id = model.id
        seed.sortKey = model.title
        seed.startTime = model.startTime
        seed.endTime = model.endTime
        seed.startDay = model.startDay
        seed.startMinute = model.startMinute
        seed.endTime = model.endTime
        seed.endDay = model.endDay
        seed.endMinute = model.endMinute
        return seed
    }

    static func makeInstanceLayoutSeed(
        from instance: Instance,
        in timeZone: TimeZone
    ) -> Rust.InstanceLayoutSeed {
        var seed = Rust.InstanceLayoutSeed()
        seed.id = instance.uniqueId
        seed.sortKey = instance.title
        seed.startTime = instance.startTime
        seed.startDay = Int32(instance.getStartDay(in: timeZone))
        seed.startMinute = Self.getStartMinute(with: instance, in: timeZone)
        seed.endTime = instance.endTime
        seed.endDay = Int32(instance.getEndDay(in: timeZone))
        seed.endMinute = Self.getEndMinute(with: instance, in: timeZone)
        return seed
    }

    // 对于不含夏令时的时区，基于 baseDay 获取 minute，效率更高
    static func optimizedGetMinute(from date: Date, in timeZone: TimeZone) -> Int32 {
        let baseTimeStamp = JulianDayUtil.startOf2000_01_01(in: timeZone)
        let timeStampGap = JulianDayUtil.Timestamp(date.timeIntervalSince1970) - baseTimeStamp
        let secondsOfDay = (timeStampGap % JulianDayUtil.Timestamp(oneDaySeconds))
        let ret = Int32(secondsOfDay / 60)
        #if DEBUG
        // 校验
        let dateComps = Calendar.gregorianCalendar.dateComponents(in: timeZone, from: date)
        let oldRet = Int32(60 * dateComps.hour! + dateComps.minute!)
        assert(ret == oldRet)
        #endif
        return ret
    }

    static func getMinute(from date: Date, in timeZone: TimeZone) -> Int32 {
        if JulianDayUtil.someTimeZoneIdentifiersThatDoNotObserveDaylightSavingTime.contains(timeZone.identifier) {
            // timeZone 没有夏令时，使用更优化的算法计算
            return Self.optimizedGetMinute(from: date, in: timeZone)
        } else {
            let dateComps = Calendar.gregorianCalendar.dateComponents(in: timeZone, from: date)
            return Int32(60 * dateComps.hour! + dateComps.minute!)
        }
    }

    static func getStartMinute(with instance: Instance, in timeZone: TimeZone) -> Int32 {
        switch instance {
        case .local(let localInstance):
            return Self.getMinute(from: localInstance.startDate ?? Date(), in: timeZone)
        case .rust(let rustInstance):
            return rustInstance.startMinute
        }
    }

    static func getEndMinute(with instance: Instance, in timeZone: TimeZone) -> Int32 {
        switch instance {
        case .local(let localInstance):
            return Self.getMinute(from: localInstance.endDate ?? Date(), in: timeZone)
        case .rust(let rustInstance):
            return rustInstance.endMinute
        }
    }

}
