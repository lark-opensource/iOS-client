//
//  CalendarManager.swift
//  Calendar
//
//  Created by zhuheng on 2021/8/16.
//

import Foundation
import RxSwift
import LarkSetting
import CalendarFoundation
import LarkContainer
import RxRelay
import RustPB
import LKCommonsLogging
import LKCommonsTracker
import ThreadSafeDataStructure

/// 设计文档：https://bytedance.feishu.cn/docs/doccnXhyLazpTsuWcKunAVYl4Sd#
final class CalendarManager: UserResolverWrapper {
    /// 日历可见性变更
    let rxCalendarVisibilityUpdated = PublishSubject<Void>()

    private let lock = NSLock()
    /// 日历变更
    let rxCalendarUpdated = PublishSubject<Void>()

    /// 主日历 ID
    var primaryCalendarID: String {
        primaryCalendar.serverId
    }

    /// 主日历
    var primaryCalendar: CalendarModel {
        guard let calendar = rustCalendarMap.values.first(where: { (model) -> Bool in
            return model.isAvailablePrimaryCalendar()
        }) else {
            return remotePrimaryCalendar ?? CalendarModelFromPb(pb: Calendar_V1_Calendar())
        }

        return calendar
    }

    private(set) var eventViewStartTime: Int64 = 0
    private(set) var eventViewEndTime: Int64 = 0

    @ScopedInjectedLazy var calendarSubscribeTracer: CalendarSubscribeTracer?
    // 通过 getRemotePrimaryCalendar 获取的主日历，作为兜底数据，不持久化到磁盘
    private var remotePrimaryCalendar: CalendarModel?

    // 与对应主日历冲突的 exchange 日历 id（仅用于 exchange 日程同步去重）
    var conflictExchangeCalendarIDs: [String] {
        var ids: [String] = []
        let priVisibleUIDs = allCalendars.filter { $0.getCalendarPB().type == .primary && $0.isVisible }.map { $0.userId }
        if !priVisibleUIDs.isEmpty {
            ids = allCalendars
                .filter {
                    let isConflictType = $0.isExchangeCalendar() || $0.isGoogleCalendar()
                    let isPrimaryShow = priVisibleUIDs.contains($0.userId)
                    // 共享来的三方日历（主日历和公共日历）上的日程不算冲突（此次新增，FG 内生效）
                    let isSharedThird = (!$0.isPrimary && calendarDependency.currentUser.id == $0.userId) && FG.syncDeduplicationOpen
                    return isConflictType && $0.isVisible && isPrimaryShow && !isSharedThird
                }.map { $0.serverId }
        }
        return ids
    }

    // 包括他人的主日历
    var primaryCalendarIDsAndUserIDsDic: [String: String] {
        return allCalendars.filter { $0.getCalendarPB().type == .primary && $0.isVisible }
            .reduce(into: [String: String]()) { dic, calendar in
                dic[calendar.serverId] = calendar.userId
            }
    }

    /// 本地日历 + Lark日历
    var allCalendars: [CalendarModel] {
        if let primaryCalendar = remotePrimaryCalendar, rustCalendarMap.isEmpty {
            return [primaryCalendar] + Array(localCalendarMap.values)
        }
        return Array(self.rustCalendarMap.values) + Array(self.localCalendarMap.values)
    }

    /// 可见日历
    var visibleCalendarsIDs: [String] {
        return allCalendars.filter { (calendar) -> Bool in
            return calendar.isVisible && !calendar.isLoading(eventViewStartTime: eventViewStartTime,
                                                             eventViewEndTime: eventViewEndTime)
        }.map { (calendar) -> String in
            return calendar.serverId
        }
    }

    /// Lark calendar 是否未初始化
    var isRustCalendarEmpty: Bool {
        return rustCalendarMap.isEmpty
    }

    /// 有编辑权限的日历
    var allEditableCalendars: [CalendarModel] {
        return allCalendars.filter({ (item) -> Bool in
            if item.isLocalCalendar() {
                return false
            }

            if (item.isGoogleCalendar() || item.isExchangeCalendar()) &&
                !(KVValues.getExternalCalendarVisible(accountName: item.externalAccountName)
                    && item.externalAccountValid) {
                return false
            }

            return true
        }).sorted(by: { (a0, a1) -> Bool in
            // 排序规则：
            //  1. lark > google > exchange
            //  2. primary > non-primary
            let (larkTag, googleTag, exchangeTag) = (3, 2, 1)
            let a0TypeTag = a0.isExchangeCalendar() ? exchangeTag : (a0.isGoogleCalendar() ? googleTag : larkTag)
            let a1TypeTag = a1.isExchangeCalendar() ? exchangeTag : (a1.isGoogleCalendar() ? googleTag : larkTag)
            if a0TypeTag != a1TypeTag {
                return a0TypeTag > a1TypeTag
            }
            if a0.isPrimary != a1.isPrimary {
                return a0.isPrimary
            }
            return a0.localizedSummary.localizedCompare(a1.localizedSummary) == .orderedAscending
        })
    }

    let calendarDependency: CalendarDependency
    let pushService: RustPushService
    let localRefreshService: LocalRefreshService
    let rustAPI: CalendarRustAPI

    let userResolver: UserResolver

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.snapshot = CalendarSnapshot(userResolver: userResolver) + .readWriteLock
        calendarDependency = try self.userResolver.resolve(assert: CalendarDependency.self)
        pushService = try self.userResolver.resolve(assert: RustPushService.self)
        localRefreshService = try self.userResolver.resolve(assert: LocalRefreshService.self)
        rustAPI = try self.userResolver.resolve(assert: CalendarRustAPI.self)
    }

    private var rustSyncBag: DisposeBag?
    private var localSyncBag: DisposeBag?
    private let bag = DisposeBag()

    private let snapshot: SafeAtomic<CalendarSnapshot>
    private let queue = DispatchQueue(label: "lark.calendar.calanedarManager.queue")

    private var rustCalendarMap: [String: CalendarModel] {
        get {
            queue.sync { [weak self] in
                return self?._rustCalendarMap ?? [:]
            }
        }
        set {
            queue.async(group: nil, qos: .default, flags: .barrier) { [weak self] in
                guard let `self` = self else { return }
                self._rustCalendarMap = newValue
                self._rustCalendarMap.values.forEach { model in
                    if !model.isLoading(eventViewStartTime: self.eventViewStartTime, eventViewEndTime: self.eventViewEndTime) {
                        self.calendarSubscribeTracer?.loadingDone(calendarID: model.serverId)
                    }
                }
            }
        }
    }

    private lazy var _rustCalendarMap: [String: CalendarModel] = {
        let calendarMap = calendarMapFromSnapshot()
        guard calendarMap.isEmpty else {
            return calendarMap
        }

        // https://slardar.bytedance.net/node/app_detail/?aid=1161&os=iOS&region=cn&lang=zh#/event/list/detail_v2/cal_no_primary_calendar_assert?params=%7B%22start_time%22%3A1630219200%2C%22end_time%22%3A1630305600%2C%22granularity%22%3A3600%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%5D%7D%2C%22pgno%22%3A1%2C%22pgsz%22%3A10%7D
        Tracker.post(SlardarEvent(
            name: "cal_no_primary_calendar_assert",
            metric: [:],
            category: [:],
            extra: [:]
        ))
        CalendarManager.logger.error("primaryCalendar is empty")
//        assertionFailure("primaryCalendar is empty")

        updateRustCalendar()
        return [:]
    }()

    private var _localCalendarMap: [String: CalendarModel] = [:]
    private var localCalendarMap: [String: CalendarModel] {
        get {
            queue.sync { [weak self] in
                return self?._localCalendarMap ?? [:]
            }
        }
        set {
            queue.async(group: nil, qos: .default, flags: .barrier) { [weak self] in
                self?._localCalendarMap = newValue
            }
        }
    }

    static let logger = Logger.log(CalendarManager.self, category: "Calendar.Manager")

    func active() {
        registerPushReceiver()
    }

    deinit {
        KVValues.hasCalendarCache = false
    }

    private func calendarMapFromSnapshot() -> [String: CalendarModel] {
        let calendars = snapshot.value.read()
        let calendarModels = setCalendarsParent(calendars: calendars.map { CalendarModelFromPb(pb: $0) })
        return calendarModels.reduce([:], { (result, model) -> [String: CalendarModel] in
            var result = result
            result[model.serverId] = model
            return result
        })
    }

    private func registerPushReceiver() {
        LocalCalendarManager.eventStoreChangedSubject.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.updateLocalCalendar()
            }).disposed(by: bag)

        Observable.of(pushService.rxCalendarSync,
                      localRefreshService.rxCalendarNeedRefresh).merge()
            .throttle(.milliseconds(1000), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.updateRustCalendar()
            }).disposed(by: self.bag)
    }

    func setEventViewRange(start: Date, end: Date) {
        eventViewStartTime = Int64(start.timeIntervalSince1970)
        eventViewEndTime = Int64(end.timeIntervalSince1970) - 1

        CalendarManager.logger.info("displayRangeDidChanged \(eventViewStartTime)-\(eventViewEndTime)")
    }

    // MARK: 日历可见性相关
    func changeExternalAccount(accountName: String, visibility: Bool) {
        allCalendars.forEach { (model) in
            if !accountName.isEmpty, model.externalAccountName == accountName {
                _ = updateRustCalendarVisibility(serverId: model.serverId,
                                             visibility: visibility)
                    .subscribe().disposed(by: self.bag)
            }
        }
    }

    func calendar(with calendarId: String) -> CalendarModel? {
        let calendarModel = allCalendars.first(where: { $0.serverId == calendarId })
        if calendarModel == nil {
            CalendarManager.logger.info("calendar not found \(calendarId)")
        }
        return calendarModel
    }

    func updateCalendarVisibility(serverId: String, visibility: Bool, isLocal: Bool) -> Observable<Bool> {
        if isLocal {
            return updateLocalCalendarVisibility(serverId: serverId, visibility: visibility)
        } else {
            return updateRustCalendarVisibility(serverId: serverId, visibility: visibility)
        }
    }

    func updateLocalCalendarVisibility(serverId: String, visibility: Bool) -> Observable<Bool> {
        return LocalCalendarManager.changeCalVisibility(calID: serverId, visible: visibility)
            .observeOn(MainScheduler.instance)
            .map({ [weak self] (success) -> Bool in
                guard let self = self else { return false }
                self.rxCalendarVisibilityUpdated.onNext(())
                self.updateLocalCalendar()
                return success
            })
    }

    func updateRustCalendarVisibility(serverId: String, visibility: Bool) -> Observable<Bool> {
        return rustAPI
            .updateUpdateCalendarVisibility(calendarId: serverId, visibility: visibility)
            .observeOn(MainScheduler.instance)
            .map({ [weak self] (success) -> Bool in
                guard let self = self else { return false }
                self.rxCalendarVisibilityUpdated.onNext(())
                self.updateRustCalendar()
                return success
            })
    }

    /// 更新所有日历
    func updateAllCalendar() {
        DispatchQueue.global().async {
            self.updateRustCalendar()
        }
        updateLocalCalendar()
    }

    /// 更新本地日历
    func updateLocalCalendar() {
        let disposeBag = DisposeBag()
        localSyncBag = disposeBag

        LocalCalendarManager.getAllLocalCalendars()
            .subscribe(onNext: { [weak self] (localCalendars) in
                guard let self = self else { return }
                let localCalendarMap = localCalendars.reduce([:], { (result, model) -> [String: CalendarModel] in
                    var result = result
                    result[model.serverId] = model
                    return result
                })

                self.localCalendarMap = localCalendarMap
                self.rxCalendarUpdatedOnNext()
            }).disposed(by: disposeBag)
    }
    
    @inline(__always)
    private func rxCalendarUpdatedOnNext() {
        defer { lock.unlock() }
        lock.lock()
        rxCalendarUpdated.onNext(())
    }

    /// 磁盘缓存无效时，拉一次主日历
    func loadPrimaryCalendarIfNeeded() -> Observable<Void> {
        // 避免冷启动读磁盘损耗性能，使用 userDefault 判断是否有磁盘缓存
        if KVValues.hasCalendarCache {
            return .just(())
        } else {
            return rustAPI.getPrimaryCalendar()
                .do(onNext: { [weak self] (primaryCalendar) in
                    guard let self = self else { return }
                    self.remotePrimaryCalendar = primaryCalendar
                    self.rxCalendarUpdatedOnNext()
                    CalendarManager.logger.info("loadPrimaryCalendar success")
                }).map { _ in () }
        }
    }

    /// 更新 lark 日历
    func updateRustCalendar() {
        let disposeBag = DisposeBag()
        rustSyncBag = disposeBag
        var retryCount = 0 /// 只重试5次
        CalendarManager.logger.info("update rust calendar begin")
        rustAPI.getUserCalendars()
            .catchErrorJustReturn([])
            .map({ [weak self] (calendars) -> [CalendarModel] in
                guard let `self` = self, retryCount < 5 else {
                    return [CalendarModel]()
                }
                retryCount += 1
                if calendars.isEmpty {
                    throw CError.custom(message: "retry")
                }
                return self.setCalendarsParent(calendars: calendars)
            })
            .retryWhen({ _ -> Observable<Int> in
                return Observable<Int>.interval(.milliseconds(2000), scheduler: MainScheduler.instance)
            })
            .map({ (calendars) -> [String: CalendarModel] in
                return Dictionary(calendars.map { ($0.serverId, $0) }) { $1 }
            })
            .subscribe(onNext: { [weak self] (rustCalendarMap) in
                guard let self = self else { return }
                self.rustCalendarMap = rustCalendarMap
                self.rxCalendarUpdatedOnNext()
                // use safeWrite to access writeToDisk func
                self.snapshot.safeWrite { shot in
                    if shot.writeToDisk(calendars: rustCalendarMap.values.map { $0.getCalendarPB() }) {
                        CalendarManager.logger.info("writeToDisk sucess")
                        KVValues.hasCalendarCache = true
                    }
                }

                CalendarManager.logger.info("update rust calendar end. count: \(rustCalendarMap.count)")
            }).disposed(by: disposeBag)
    }

    private func setCalendarsParent(calendars: [CalendarModel]) -> [CalendarModel] {
        return calendars.reduce([], { (result, m) -> [CalendarModel] in
            var r = result
            var m = m
            guard m.isGoogleCalendar() || m.isExchangeCalendar(),
                  !m.userId.isEmpty && m.userId != "0" else {
                r.append(m)
                return r
            }
            let whereExpr = { (cal: CalendarModel) -> Bool in
                return cal.userId == m.userId && cal.type == .primary
            }
            if let parent = calendars.first(where: whereExpr) {
                m.parentCalendarPB = parent.getCalendarPB()
            }
            r.append(m)
            return r
        })
    }

}

extension Array where Element == CalendarModel {
    func allCreatableCalendars() -> [CalendarModel] {
        return self.filter({ (item) -> Bool in
            if item.isLocalCalendar() {
                return false
            }

            if !item.hasSubscribed {
                return false
            }

            if (item.isGoogleCalendar() || item.isExchangeCalendar()) &&
                !(KVValues.getExternalCalendarVisible(accountName: item.externalAccountName)
                  && item.externalAccountValid) {
                return false
            }

            return true
        }).sorted(by: { (a0, a1) -> Bool in
            // 排序规则：
            //  1. lark > google > exchange
            //  2. primary > non-primary
            let (larkTag, googleTag, exchangeTag) = (3, 2, 1)
            let a0TypeTag = a0.isExchangeCalendar() ? exchangeTag : (a0.isGoogleCalendar() ? googleTag : larkTag)
            let a1TypeTag = a1.isExchangeCalendar() ? exchangeTag : (a1.isGoogleCalendar() ? googleTag : larkTag)
            if a0TypeTag != a1TypeTag {
                return a0TypeTag > a1TypeTag
            }
            if a0.isPrimary != a1.isPrimary {
                return a0.isPrimary
            }
            return a0.localizedSummary.localizedCompare(a1.localizedSummary) == .orderedAscending
        })
    }
}

extension CalendarManager {
    func getShouldSwitchToOAuthExchangeAccounts() -> Observable<[String: String]> {
        return self.rustAPI.getShouldSwitchToOAuthExchangeAccounts()
    }
}
