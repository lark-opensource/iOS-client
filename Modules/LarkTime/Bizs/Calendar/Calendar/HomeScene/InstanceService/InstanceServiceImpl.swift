//
//  InstanceServiceImp.swift
//  Calendar
//
//  Created by zhuheng on 2020/8/27.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import RxCocoa
import ThreadSafeDataStructure
import LKCommonsLogging
import LarkExtensions
import EventKit
import CTFoundation
import LarkContainer

/// Implementation for InstanceService

private let launchTracer = TimerMonitorHelper.shared.launchTimeTracer?.getInstance

final class InstanceServiceImpl: InstanceService, UserResolverWrapper {
    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var calendarSelectTracer: CalendarSelectTracer?

    /// 局部更新（精细化更新）
    typealias PartialUpdatePayload = Rust.CalendarEventChanged

    static let logger = Logger.log(InstanceServiceImpl.self, category: "Calendar.Instance.Service")

    let instanceUpdated = PublishSubject<Void>()

    /// 根据 timeZone 和 dayRange 更新缓存
    var cacheStrategy: InstanceCacheStrategy? {
        didSet {
            schedulers.accessData.schedule(()) { [weak self] _ -> Disposable in
                guard let strategy = self?.cacheStrategy else {
                    return Disposables.create()
                }
                self?.memoryCache.trimItems(with: .init(
                    activeTimeZone: strategy.timeZone,
                    activeDays: strategy.memoryCacheDays
                ))
                self?.rxUpdateSnapshot.onNext(())
                return Disposables.create()
            }.disposed(by: disposeBag)
        }
    }

    /// schedulers 说明：
    ///   - requestApi: 访问外部数据
    ///   - accessData: 访问内部数据（包括 cache 和相关 properties），串行队列
    ///   - updateNoti: 发布 update 通知，主线程触发
    lazy var schedulers = {
        let schedulers = InstanceServiceCache.schedulers()
        return (
            requestApi: schedulers.requestApi,
            accessData: schedulers.accessData,
            updateNoti: schedulers.updateNoti
        )
    }()
    private let accessDataQueue = InstanceServiceCache.accessDataQueue
    private let rxUpdateSnapshot = PublishSubject<Void>()

    // memory cache context
    private var cacheContext = (targetVersion: Int(0), latestUpdateInfo: CacheUpdateInfo.fullUpdate)
    // 冷启动数据（主线程访问）
    private var coldLaunchData = (timeZone: TimeZone, rxInstances: BehaviorSubject<ColdLaunchInstances?>)?.none
    private let memoryCache: InstanceMemoryCache
    private let snapshot: InstanceSnapshot
    private let calendarApi: CalendarRustAPI
    private let disposeBag = DisposeBag()
    private var firstRequest = true
    private let visibleCalendarsIDsGetter: () -> [String]
    let userResolver: UserResolver
    init(
        snapshot: InstanceSnapshot,
        localInstanceChangedPush: Observable<Void>,
        calendarApi: CalendarRustAPI,
        userResolver: UserResolver,
        visibleCalendarsIDsGetter: @escaping () -> [String]
    ) {
        self.calendarApi = calendarApi
        self.memoryCache = InstanceMemoryCache(queue: accessDataQueue)
        self.snapshot = snapshot
        self.userResolver = userResolver
        self.visibleCalendarsIDsGetter = visibleCalendarsIDsGetter

        guard let localRefreshService = self.localRefreshService,
              let calendarManager = self.calendarManager,
              let pushService = self.pushService else {
            Self.logger.error("get service from larkcontainer failed! function may not work well")
            return
        }

        let rxInnerEventChanged = localRefreshService.rxEventNeedRefresh.map { _ in
            return
        }
        let calVisibilitySubject = calendarManager.rxCalendarVisibilityUpdated
        let instanceChangePush = Observable.of(
            calVisibilitySubject, // 日历可见性变化
            calendarManager.rxCalendarUpdated, // 刷新 instance 的 push 不收敛，接入 rxCalendarUpdated 可能导致重复刷新；不接导致 calendars 更新不及时
            pushService.rxCalendarRefresh.map({ (_) -> Void in
                return
            }),
            rxInnerEventChanged).merge()

        respondsToFullUpdatePushFromRust(instanceChangePush)
        respondsToPartialUpdatePushFromRust(pushService.rxCalendarEventChanged)
        respondsToUpdatePushFromLocal(localInstanceChangedPush)

        bindUpdateSnapshot()
    }

    func rxInstance(for dayRange: CAValue<JulianDayRange>, in timeZone: TimeZone) -> RxReturn<CAValue<DayInstanceMap>> {
        rxInstance(for: dayRange, in: timeZone, ignoreLocal: shouldIgnoreLocal())
    }

    private func rxInstance(for dayRangeWrapper: CAValue<JulianDayRange>, in timeZone: TimeZone, ignoreLocal: Bool) -> RxReturn<CAValue<DayInstanceMap>> {
        let dayRange = dayRangeWrapper.value
        let loggerModel = dayRangeWrapper.loggerModel
        let single = Observable<CAValue<DayInstanceMap>>.create { [weak self] subscriber -> Disposable in
            guard let self = self else {
                subscriber.onNext(.init([:], .init()))
                subscriber.onCompleted()
                return Disposables.create()
            }
            EffLogger.log(model: loggerModel, toast: "rxInstance ignoreLocal: \(ignoreLocal)")
            Self.logger.info("rxInstance ignoreLocal: \(ignoreLocal)")
            let rxInstancesFromRust = self.rxRustInstance(for: dayRangeWrapper, in: timeZone)
                .map { grouped -> DayInstanceMap in
                    return grouped.mapValues { rustInstanceArray in
                        rustInstanceArray
                            .map { Instance.rust($0) }
                            .lf_unique(by: { $0.uniqueId })
                    }
                }
            if ignoreLocal {
                return rxInstancesFromRust.asObservable().map({ CAValue<DayInstanceMap>($0, loggerModel) }).subscribe(subscriber)
            }

            let rxInstancesFromLocal = self.rxLocalInstance(for: dayRange, in: timeZone)
                .map { grouped -> DayInstanceMap in
                    return grouped.mapValues { localInstanceArray in
                        localInstanceArray
                            .map { Instance.local($0) }
                            .lf_unique(by: { $0.uniqueId })
                    }
                }

            let zipedInstance = Observable.zip(rxInstancesFromRust.asObservable(), rxInstancesFromLocal.asObservable())
                .map { (fromRust, fromLocal) -> DayInstanceMap in
                    assert(Set(fromRust.keys) == Set(dayRange))
                    assert(Set(fromLocal.keys) == Set(dayRange))
                    var merged = DayInstanceMap()
                    dayRange.forEach { merged[$0] = [] }
                    fromRust.forEach { merged[$0.key]?.append(contentsOf: $0.value) }
                    fromLocal.forEach { merged[$0.key]?.append(contentsOf: $0.value) }
                    return merged
                }
                .map({ CAValue<DayInstanceMap>($0, loggerModel) })

            return zipedInstance.subscribe(subscriber)
        }
        .subscribeOn(schedulers.accessData)
        .asSingle()
        return .rxValue(single)
    }

    // 是否该忽略 Local 日程
    private func shouldIgnoreLocal() -> Bool {
        return false
    }

    // 拉取 Local.Instance
    private func rxLocalInstance(
        for dayRange: JulianDayRange,
        in timeZone: TimeZone
    ) -> Single<[JulianDay: [Local.Instance]]> {
        return fetchInstanceFromLocal(for: dayRange, in: timeZone).asSingle()
    }

    // 拉取 Rust.Instance
    private func rxRustInstance(
        for dayRange: CAValue<JulianDayRange>,
        in timeZone: TimeZone
    ) -> Single<DayRustInstanceMap> {
        defer { firstRequest = false }

        return checkCacheVersion(for: dayRange, in: timeZone)
            .flatMap { [weak self] _ -> Single<DayRustInstanceMap> in
                return self?._rxRustInstance(for: dayRange, in: timeZone)
                    ?? Single<DayRustInstanceMap>.just([:])
            }
    }

    #if DEBUG
    private var memoryAccessCounts = (hitCache: 0, total: 0)
    #endif

    /// 获取 Rust.Instance，优先从 cache 获取
    private func _rxRustInstance(
        for dayRangeWrapper: CAValue<JulianDayRange>,
        in timeZone: TimeZone
    ) -> Single<DayRustInstanceMap> {
        let dayRange = dayRangeWrapper.value
        let loggerModel = dayRangeWrapper.loggerModel
        #if DEBUG
        memoryAccessCounts.total += dayRange.count
        defer {
            let radio = Float(memoryAccessCounts.hitCache) / Float(memoryAccessCounts.total)
        }
        #endif

        let cached = memoryCache.getItems(for: dayRange, in: timeZone, with: cacheContext.targetVersion)
        var maybeHittingDayRange: JulianDayRange?
        let cachedDays = cached.keys.sorted()
        // 获得命中cache策略的数据依据
        if !cachedDays.isEmpty {
            maybeHittingDayRange = cachedDays[0]..<cachedDays[0] + 1
            for i in 1..<cachedDays.count {
                guard cachedDays[i] == cachedDays[0] + i else {
                    // 不连续，不认定为命中
                    maybeHittingDayRange = nil
                    break
                }
                maybeHittingDayRange = cachedDays[0]..<cachedDays[i] + 1
            }
            if dayRange.lowerBound != maybeHittingDayRange?.lowerBound
                && dayRange.upperBound != maybeHittingDayRange?.upperBound {
                // 要么命中前半截，要么命中后半截，否则不认定为命中
                maybeHittingDayRange = nil
            }
            if let hittingDayRange = maybeHittingDayRange, dayRange.clamped(to: hittingDayRange) != hittingDayRange {
                // 确保 hittingDayRange 是 dayRange 的子集
                assertionFailure("hittingDayRange over range")
                maybeHittingDayRange = nil
            }
        }
        guard let hittingDayRange = maybeHittingDayRange else {
            EffLogger.log(model: loggerModel, toast: "missed memory cache absolutely")
            Self.logger.info("missed memory cache absolutely")
            // 完全没命中 memory cache
            return fetchInstanceFromRust(for: dayRangeWrapper, in: timeZone).asSingle()
        }

        #if DEBUG
        memoryAccessCounts.hitCache += hittingDayRange.count
        #endif

        if hittingDayRange == dayRange {
            EffLogger.log(model: loggerModel, toast: "match memory cache absolutely")
            Self.logger.info("match memory cache absolutely")
            // 完全命中 memory cache
            let ret = cached.filter { dayRange.contains($0.key) }
            return .just(ret)
        }

        // 部分命中，请求缺失的数据
        let missingDayRange: JulianDayRange
        let hitPrefix: Bool
        if hittingDayRange.lowerBound == dayRange.lowerBound {
            EffLogger.log(model: loggerModel, toast: "match front part of memory cache")
            Self.logger.info("match front part of memory cache")
            // 命中 dayRange 的前部分
            hitPrefix = true
            missingDayRange = hittingDayRange.upperBound..<dayRange.upperBound
        } else {
            EffLogger.log(model: loggerModel, toast: "match back part of memory cache")
            Self.logger.info("match back part of memory cache")
            // 命中 dayRange 的后部分
            hitPrefix = false
            missingDayRange = dayRange.lowerBound..<hittingDayRange.lowerBound
        }
        assert(missingDayRange.count + hittingDayRange.count == dayRange.count)
        assert(!missingDayRange.overlaps(hittingDayRange))
        let hittingDayInstances = cached.filter { hittingDayRange.contains($0.key) }
        let reqModel = loggerModel.createNewModelByTask(.request)
        EffLogger.log(model: reqModel, toast: "fetchInstanceFromRust")
        return fetchInstanceFromRust(for: .init(missingDayRange, reqModel), in: timeZone)
            .map { missingDayInstances -> DayRustInstanceMap in
                let resModel = reqModel.createNewModelByTask(.request)
                EffLogger.log(model: reqModel, toast: "fetchInstanceFromRust callback")
                var ret = DayRustInstanceMap()
                if hitPrefix {
                    hittingDayInstances.forEach { ret[$0.key] = $0.value }
                    missingDayInstances.forEach { ret[$0.key] = $0.value }
                } else {
                    missingDayInstances.forEach { ret[$0.key] = $0.value }
                    hittingDayInstances.forEach { ret[$0.key] = $0.value }
                }
                return ret
            }
            .asSingle()
    }

}

// MARK: - Memory Cache

/// 为了提高 Instance 的使用率，使用 memory cache 对从 Rust 获取的 Instance 进行缓存。
/// 对 memory cache 的访问和管理，基本理念是：围绕 version 进行。
///  - memoryCache.version 和 cacheContext.targetVersion 均用于描述 memory cache 的 version；
///    前者描述 memory cache 的当前 version；后者描述期望的 memory cache 的 version。
///    当 memoryCache.version 低于 cacheContext.targetVersion 时，意味着 memory cache 中的数据过时了。
///
///  - `cacheContext.targetVersion` & `cacheContext.latestUpdateInfo`：
///    当收到 Rust 层的 push 时，更新 cacheContext.targetVersion，即 `+1`；
///    除此之外，还使用 cacheContext.latestUpdateInfo 记录更新源信息。
///
///  - `memoryCache.version`
///    每次访问 cache 前，基于 cacheContext.targetVersion 和 memoryCache.version 进行 check
///     - 当 memoryCache.version 落后于 cacheContext.targetVersion 较多版本时，清除 cache，避免其中的数据被使用
///     - 当 memoryCache.version 落后于 cacheContext.targetVersion 一个版本，且最后一次更新信息是精细化更新；
///       则根据精细化更新信息（cacheContext.latestUpdateInfo），对 cache 内容进行更新
///     - 当 memoryCache.version == cacheContext.targetVersion 时，说明 cache 数据可用
///    当从 Rust 层获取到 Rust.Instance 时，会尝试将相关 Instance 以天为粒度同步到 cache 中；
///    当且 memoryCache.version 与 cacheContext.targetVersion 相等时，才能同步成功

extension InstanceServiceImpl {

    /// 描述 Memory Cache 的更新
    private enum CacheUpdateInfo {
        // 全量更新
        case fullUpdate
        // 局部更新（精细化更新）
        case partialUpdate(needsDelete: [Rust.UniqueField], needsUpdate: [Rust.UniqueField])
    }

    // 根据 version 检查 cache，确保 cache 数据不过时
    private func checkCacheVersion(for dayRangeWrapper: CAValue<JulianDayRange>, in timeZone: TimeZone) -> Single<Void> {
        let (currentVersion, targetVersion) = (memoryCache.version, cacheContext.targetVersion)
        let loggerModel = dayRangeWrapper.loggerModel
        if currentVersion == targetVersion {
            debugPrint("cache is ok")
            EffLogger.log(model: loggerModel, toast: "cache is ok")
            Self.logger.info("cache is ok")
            return .just(())
        }
        assertLog(currentVersion <= targetVersion, "currentVersion > targetVersion")
        guard case .partialUpdate(let needsDelete, let needsUpdate) = cacheContext.latestUpdateInfo else {
            memoryCache.trimAll(withNewVersion: targetVersion)
            EffLogger.log(model: loggerModel, toast: "memoryCache.trimAll by not partialUpdate")
            Self.logger.info("memoryCache.trimAll by not partialUpdate")
            return .just(())
        }
        guard currentVersion + 1 == targetVersion else {
            // 最后一次更新由精细化更新通知触发，但是落后版本较多，直接当全量更新处理
            memoryCache.trimAll(withNewVersion: targetVersion)
            EffLogger.log(model: loggerModel, toast: "memoryCache.trimAll by version outdate more")
            Self.logger.info("memoryCache.trimAll by version outdate more")
            return .just(())
        }
        var items = memoryCache.getAllItems(in: timeZone)
        guard !items.isEmpty else {
            EffLogger.log(model: loggerModel, toast: "memoryCache.trimAll by items isEmpty")
            Self.logger.info("memoryCache.trimAll by items isEmpty")
            memoryCache.trimAll(withNewVersion: targetVersion)
            return .just(())
        }
        let deleteTripleStrs = Set(needsDelete.map { $0.getInstanceTripleString() })
        for key in items.keys {
            items[key]?.removeAll(where: { deleteTripleStrs.contains($0.tripleStr) })
        }
        let days = items.keys.sorted()
        let dayRange = days.first!..<days.last! + 1
        return fetchInstanceFromRust(for: dayRange, in: timeZone, with: needsUpdate)
            .observeOn(schedulers.accessData)
            .do(
                onNext: { [weak self] instances in
                    guard let self = self else { return }
                    guard self.memoryCache.version + 1 == targetVersion else {
                        EffLogger.log(model: loggerModel, toast: "get partial instances succeed. but it is out of date")
                        Self.logger.info("get partial instances succeed. but it is out of date")
                        return
                    }
                    Self.logger.info("fetchInstanceFromRust success")
                    EffLogger.log(model: loggerModel, toast: "fetchInstanceFromRust success")
                    let groupedInstances = Self.dayGroupedInstances(from: instances, for: dayRange, in: timeZone)
                    for (day, instances) in groupedInstances {
                        items[day]?.append(contentsOf: instances)
                    }
                    self.memoryCache.trimAll(withNewVersion: targetVersion)
                    self.memoryCache.updateItems(items, in: timeZone, with: targetVersion)
                    self.rxUpdateSnapshot.onNext(())
                },
                onError: { err in
                    EffLogger.log(model: loggerModel, toast: "fetch partial instances failed. err: \(err), dayRange: \(dayRange), timeZone: \(timeZone.identifier)")
                    Self.logger.error("fetch partial instances failed. err: \(err), dayRange: \(dayRange), timeZone: \(timeZone.identifier)")
                    guard self.memoryCache.version + 1 == targetVersion else { return }
                    self.memoryCache.trimAll(withNewVersion: targetVersion)
                }
            )
            .map { _ in () }
            .catchErrorJustReturn(())
            .asSingle()
    }

}

// MARK: - Responds To Push

extension InstanceServiceImpl {

    // 响应 Local 日程的更新通知
    private func respondsToUpdatePushFromLocal(_ localUpdatePush: Observable<Void>) {
        localUpdatePush
            // 本地日程的通知逻辑，存在冗余，加 debounce 处理一下
            .debounce(.milliseconds(50), scheduler: schedulers.accessData)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.schedulers.updateNoti.schedule(()) { [weak self] _ -> Disposable in
                    Self.logger.info("publish update event for receiving a update push from local")
                    self?.instanceUpdated.onNext(())
                    return Disposables.create()
                }.disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    // 响应 Rust 日程的更新通知（全量更新）
    private func respondsToFullUpdatePushFromRust(_ rustUpdatePush: Observable<Void>) {
        rustUpdatePush
            // rustUpdatePush 可能频繁触发，造成频繁刷新，导致 getInstance 频控
            .throttle(.milliseconds(300), scheduler: schedulers.accessData)
            .observeOn(schedulers.accessData)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.cacheContext.targetVersion += 1
                self.cacheContext.latestUpdateInfo = .fullUpdate
                self.schedulers.updateNoti.schedule(()) { [weak self] _ -> Disposable in
                    Self.logger.info("publish update event for receiving a update push from rust")
                    self?.instanceUpdated.onNext(())
                    return Disposables.create()
                }.disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    // 响应 Rust 日程的更新通知（精细化更新/局部更新）
    private func respondsToPartialUpdatePushFromRust(_ rustPartialUpdatePush: PublishSubject<PartialUpdatePayload>) {
        rustPartialUpdatePush
        // rustUpdatePush 可能频繁触发，造成频繁刷新，导致 getInstance 频控
            .throttle(.milliseconds(300), scheduler: schedulers.accessData)
            .observeOn(schedulers.accessData)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.cacheContext.targetVersion += 1
                self.cacheContext.latestUpdateInfo = .fullUpdate
                self.schedulers.updateNoti.schedule(()) { [weak self] _ -> Disposable in
                    Self.logger.info("publish update event for receiving a update push from rust")
                    self?.instanceUpdated.onNext(())
                    return Disposables.create()
                }.disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

}

// MARK: - Fetch Instance

extension InstanceServiceImpl {

    @inline(__always)
    private func requestTimestamps(
        for dayRange: JulianDayRange,
        in timeZone: TimeZone
    ) -> (startTime: JulianDayUtil.Timestamp, endTime: JulianDayUtil.Timestamp) {
//        let dayRange = DayScene.julianDayRange(from: dayRange)
        let startTime = JulianDayUtil.startOfDay(for: dayRange.lowerBound, in: timeZone)
        let endTime = JulianDayUtil.endOfDay(for: dayRange.upperBound - 1, in: timeZone)
        return (startTime, endTime)
    }

    // 根据 dayRange 和 timeZone 从 Local 获取 Instance
    private func fetchInstanceFromLocal(
        for dayRange: JulianDayRange,
        in timeZone: TimeZone
    ) -> Observable<[JulianDay: [Local.Instance]]> {
        let (startTime, endTime) = requestTimestamps(for: dayRange, in: timeZone)
        return calendarApi.getLocalInstances(
            for: .readLocalEventInstanceOnEventView,
            startTime: startTime,
            endTime: endTime,
            filterHidden: true,
            timeZone: timeZone.identifier
        )
        .subscribeOn(schedulers.requestApi)
        .map { Self.dayGroupedInstances(from: $0, for: dayRange, in: timeZone) }
    }

    // 根据 dayRange 和 timeZone 从 Rust 获取 Instance
    private func fetchInstanceFromRust(
        for dayRangeWrapper: CAValue<JulianDayRange>,
        in timeZone: TimeZone
    ) -> Observable<DayRustInstanceMap> {
        guard let calendarManager = self.calendarManager else {
            Self.logger.error("fetchInstanceFromRust failed, can not get calendarManager from larkcontainer!")
            return .empty()
        }
        let dayRange = dayRangeWrapper.value
        let (startTime, endTime) = requestTimestamps(for: dayRange, in: timeZone)
        let conflictExchangeCalendarIDs = calendarManager.conflictExchangeCalendarIDs
        let idsDic = calendarManager.primaryCalendarIDsAndUserIDsDic
        return calendarApi.getRustInstances(
            startTime: startTime,
            endTime: endTime,
            filterHidden: true,
            timeZone: timeZone.identifier
        )
        .subscribeOn(schedulers.requestApi)
        .do(afterNext: { [weak self] rustInstances in
            guard let self = self else { return }
            self.calendarSelectTracer?.setDataLength(rustInstances.count)
            self.calendarSelectTracer?.endIfNeeded(instance: rustInstances)
            let calendarIds = Set(self.visibleCalendarsIDsGetter())
            let serverIds = rustInstances.compactMap { instance -> String? in
                guard calendarIds.contains(instance.calendarID) else { return nil }
                return instance.eventServerID
            }

            let refidCalendarMap = Dictionary(
                rustInstances.filter { serverIds.contains($0.eventServerID) }
                .map { ($0.eventServerID, $0.calendarID) }) { $1 }

        })
        // Exchange & 对应的 primary 都可见时 -「隐藏(过滤) exchange instances」
        .map {
            if !conflictExchangeCalendarIDs.isEmpty {
                var primaryKeys: [String] = FG.syncDeduplicationOpen ? $0.compactMap {
                    if let userID = idsDic[$0.calendarID] {
                        return $0.keyWithTimeTuple + userID
                    } else { return nil }
                } : []
                return $0.filter {
                    let key = $0.keyWithTimeTuple + (self.calendarManager?.calendar(with: $0.calendarID)?.userId ?? "")
                    return !(
                        conflictExchangeCalendarIDs.contains($0.calendarID)
                        && ($0.isSyncFromLark || primaryKeys.contains(key))
                    )
                }
            } else {
                return $0
            }
        }
        .map { Self.dayGroupedInstances(from: $0, for: dayRange, in: timeZone) }
        .observeOn(schedulers.accessData)
        .do(onNext: { [weak self] grouped in
            guard let self = self,
                self.cacheContext.targetVersion == self.memoryCache.version else {
                return
            }
            assert(Set(grouped.keys) == Set(dayRange))
            self.memoryCache.updateItems(grouped, in: timeZone, with: self.cacheContext.targetVersion)
            self.rxUpdateSnapshot.onNext(())
        })
    }

    // 根据 dayRange 和 timeZone 从 Rust 获取目标三元组的 Instance
    private func fetchInstanceFromRust(
        for dayRange: JulianDayRange,
        in timeZone: TimeZone,
        with uniqueFields: [Rust.UniqueField]
    ) -> Observable<[Rust.Instance]> {
        let (startTime, endTime) = requestTimestamps(for: dayRange, in: timeZone)
        return calendarApi.getInstance(
            eventUniqueFiledId: uniqueFields,
            startTime: startTime,
            endTime: endTime,
            timezone: timeZone.identifier
        )
        .subscribeOn(schedulers.requestApi)
        .map { [weak self] entities -> [Rust.Instance] in
            guard let self = self else { return [] }
            let visiableCalendarIds = self.visibleCalendarsIDsGetter()
            return entities.compactMap { entity in
                guard visiableCalendarIds.contains(entity.calendarId) else { return nil }
                return entity.toPB()
            }
        }
    }

}

// MARK: - Group Instance

extension InstanceServiceImpl {

    private static func dayGroupedInstances(
        from instances: [Local.Instance],
        for dayRange: JulianDayRange,
        in timeZone: TimeZone
    ) -> [JulianDay: [Local.Instance]] {
        return Instance.groupedByDay(from: instances.map { Instance.local($0) }, for: dayRange, in: timeZone)
            .mapValues {
                $0.compactMap { i -> Local.Instance? in
                    guard case .local(let li) = i else { return nil }
                    return li
                }
            }
    }

    private static func dayGroupedInstances(
        from instances: [Rust.Instance],
        for dayRange: JulianDayRange,
        in timeZone: TimeZone
    ) -> DayRustInstanceMap {
        return Instance.groupedByDay(from: instances.map { Instance.rust($0) }, for: dayRange, in: timeZone)
            .mapValues {
                $0.compactMap { i -> Rust.Instance? in
                    guard case .rust(let ri) = i else { return nil }
                    return ri
                }
            }
    }

}

// MARK: Update Snapshot

extension InstanceServiceImpl {

    private func bindUpdateSnapshot() {
        rxUpdateSnapshot.debounce(.milliseconds(500), scheduler: schedulers.accessData)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                guard self.cacheContext.targetVersion == self.memoryCache.version,
                    let strategy = self.cacheStrategy else {
                    DispatchQueue.global().async {
                        self.rxUpdateSnapshot.onNext(())
                    }
                    return
                }

                let instances = self.memoryCache.getItems(
                    for: strategy.diskCacheRange,
                    in: strategy.timeZone,
                    with: self.memoryCache.version
                ).flatMap { $0.value }
                self.snapshot.writeToDiskIfNeeded(
                    instances: instances,
                    timeZoneId: strategy.timeZone.identifier,
                    dayRange: strategy.diskCacheRange
                )
            })
            .disposed(by: disposeBag)
    }

}

// MARK: Cold Launch

extension InstanceServiceImpl {

    /// 为冷启动准备数据
    func prepareColdLaunch(with context: HomeScene.ColdLaunchContext) {
        let startTime = CACurrentMediaTime()
        defer {
            // 埋点统计 load instance 的耗时（无论数据来自于 rust 还是 snapshot）
            coldLaunchData?.rxInstances.filter({ $0 != nil }).take(1)
                .subscribe(onNext: { _ in
                    let cost = CACurrentMediaTime() - startTime
                    HomeScene.coldLaunchTracker?.addStage(.prepareInstance, with: cost)
                })
                .disposed(by: disposeBag)
        }

        let (dayRange, timeZone) = (context.dayRange, context.timeZone)
        coldLaunchData = (timeZone: timeZone, rxInstances: .init(value: nil))
        // 从 snapshot 取数据
        snapshot.load(firstScreenDayRange: dayRange, expectTimeZoneId: timeZone.identifier)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    let cost = CACurrentMediaTime() - startTime
                    HomeScene.coldLaunchTracker?.addStage(.prepareInstanceFromSnapshot, with: cost)

                    guard let self = self else { return }
                    guard let firstScreenData = self.snapshot.firstScreenData else {
                        return
                    }
                    if Set(dayRange.map { Int32($0) }).isSubset(of: firstScreenData.julianDays) {
                        // 命中 snapshot 的缓存
                        Self.logger.info("awesome, hit cache from snapshot.")
                        let dayInstanceMap = Self.dayGroupedInstances(
                            from: firstScreenData.instance,
                            for: dayRange,
                            in: timeZone
                        ).mapValues {
                            $0.map({ Instance.rust($0) }).lf_unique(by: { $0.uniqueId })
                        }
                        let value = ColdLaunchInstances(instanceMap: dayInstanceMap, isFromRust: false, loggerModel: context.loggerModel)
                        self.coldLaunchData?.rxInstances.onNext(value)
                        self.coldLaunchData?.rxInstances.onCompleted()
                    } else {
                        Self.logger.info("hit cache in snapshot failed. targetDayRange = \(dayRange), cachedSet: \(firstScreenData.julianDays)")
                    }
                },
                onError: { err in
                    Self.logger.info("load snapshot failed. will load instance from sdk. err: \(err)")
                }
            )
            .disposed(by: disposeBag)

        let asyncProcessModel = context.loggerModel.createNewModelByAddAsyncTask(.process)
        // 从 rust 取数据
        fetchInstanceFromRust(for: .init(dayRange, asyncProcessModel), in: timeZone)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] dayRustInstanceMap in
                    let cost = CACurrentMediaTime() - startTime
                    HomeScene.coldLaunchTracker?.addStage(.prepareInstanceFromRust, with: cost)

                    Self.logger.error("prepare cold launch data succeed.")
                    let dayInstanceMap = dayRustInstanceMap.mapValues {
                        $0.map({ Instance.rust($0) }).lf_unique(by: { $0.uniqueId })
                    }
                    let value = ColdLaunchInstances(instanceMap: dayInstanceMap, isFromRust: true, loggerModel: context.loggerModel)
                    self?.coldLaunchData?.rxInstances.onNext(value)
                },
                onError: { err in
                    Self.logger.error("prepare cold launch data from rust failed. err: \(err)")
                    self.coldLaunchData?.rxInstances.onError(err)
                }
            )
            .disposed(by: self.disposeBag)
    }

    /// 为冷启动准备的 instances
    func rxColdLaunchInstance(for dayRangeWrapper: CAValue<JulianDayRange>, in timeZone: TimeZone) -> RxReturn<CAValue<ColdLaunchInstances>> {
        guard let coldLaunchData = coldLaunchData else {
            assertionFailureLog("cold launch data is not prepared")
            EffLogger.log(model: dayRangeWrapper.loggerModel, toast: "cold launch data is not prepared, start rxInstance")
            DayScene.logger.info("cold launch data is not prepared, start rxInstance")
            return rxInstance(for: dayRangeWrapper, in: timeZone, ignoreLocal: true).map {
                let instances = ColdLaunchInstances(instanceMap: $0.value, isFromRust: true, loggerModel: $0.loggerModel)
                return .init(instances, dayRangeWrapper.loggerModel)
            }
        }
        guard coldLaunchData.timeZone.identifier == timeZone.identifier else {
            assertionFailureLog("time zone identifier is not matched")
            EffLogger.log(model: dayRangeWrapper.loggerModel, toast: "time zone identifier is not matched, start rxInstance")
            DayScene.logger.info("time zone identifier is not matched, start rxInstance")
            return rxInstance(for: dayRangeWrapper, in: timeZone, ignoreLocal: true).map {
                let instances = ColdLaunchInstances(instanceMap: $0.value, isFromRust: true, loggerModel: $0.loggerModel)
                return .init(instances, dayRangeWrapper.loggerModel)
            }
        }
        DayScene.logger.info("get coldLaunchData")
        EffLogger.log(model: dayRangeWrapper.loggerModel, toast: "time zone identifier is not matched, start rxInstance")
        if let ret = try? coldLaunchData.rxInstances.value() {
            return .value(.init(ret, dayRangeWrapper.loggerModel))
        }
        return .rxValue(coldLaunchData.rxInstances.compactMap{ $0 }.take(1).map{ .init($0, dayRangeWrapper.loggerModel) }.asSingle())
    }

}
