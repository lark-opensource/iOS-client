//
//  ListSceneViewModel.swift
//  Calendar
//
//  Created by huoyunjie on 2022/7/25.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import CTFoundation
import LarkContainer
import LKCommonsTracker

// 日程列表视图 tableView 刷新方式
enum BlockListRefreshType {
    /// 加载列表顶部数据
    case loadPrevious
    /// 加载列表底部数据
    case loadFollowing
    /// 滚动 tableView 到具体日期
    /// 是否带动画
    /// 是否滚动
    case scrollToDate(Date, Bool, Bool)
    
    var animated: Bool {
        switch self {
        case .loadPrevious, .loadFollowing: return false
        case .scrollToDate(_, let animated, _): return animated
        }
    }
}

class ListSceneViewModel: UserResolverWrapper {

    typealias DayEventListMap = [JulianDay: [BlockListItem]]

    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var timeDataService: TimeDataService?

    let userResolver: UserResolver

    let timeZone: TimeZone = .current

    // 日程视图相关设置
    lazy var rxViewSetting: BehaviorRelay<EventViewSetting> = initRxViewSetting()

    // instance 数据加载中心
    let instanceService: InstanceService

    // cache Manager
    private lazy var cache = {
        (
        /// instance viewData 缓存
        instance: LRUCache<String, (Int, DayEventListMap)>(capacity: 20, useLock: true),
        /// instance request 请求缓存
        requestCache: LRUCache<String, ReplaySubject<DayEventListMap>>(capacity: 20, useLock: true)
        )
    }()

    // 目标缓存版本
    var targetInstanceVersion: Int = 0

    // 计算 instance request 请求缓存的命中效果
    private var requestCacheAccessCounts = (hitCache: 0, total: 0)

    let viewDatascheduler = ConcurrentDispatchQueueScheduler(qos: .userInteractive)

    // tableView 数据源，由 instance 和 placeHolder 缓存中获取
    var dayItemsDic: DayEventListMap = [:]

    // tableView 数据源，由 dayItemsDic 转换生成，保持时间顺序
    var itemsSorted: [BlockListItem] = []

    // 异步任务触发的页面刷新资源管理
    var asyncRefreshDisposable: Disposable?

    // 列表视图异步刷新通知
    var rxRefreshSubject = PublishRelay<BlockListRefreshType>()

    // 接收 cellItems 更新值,（数据，刷新方式，显示空白日程的日期，是否reload），reload 会让新数据直接替换旧数据
    let cellItemsWillChangedRelay = PublishRelay<(DayEventListMap, BlockListRefreshType, Date?, Bool)>()

    let disposeBag = DisposeBag()

    // 页面当前的日期
    var currentDate: Date = Date() {
        didSet {
            if !currentDate.isInSameDay(currentDate) {
                CalendarTracer.shared.calMainClick(type: .day_change)
            }
        }
    }

    init(instanceService: InstanceService,
         date: Date,
         userResolver: UserResolver) {
        self.instanceService = instanceService
        self.currentDate = date
        self.userResolver = userResolver

        self.cellItemsWillChangedRelay
            .observeOn(viewDatascheduler)
            .map { [weak self] (items, refreshType, emptyDate, isReload) -> (DayEventListMap, [BlockListItem], BlockListRefreshType) in
                guard let self = self else {
                    return (items, items.transformToArraySorted(), refreshType)
                }

                let startTime1: CFTimeInterval = CACurrentMediaTime()
                TimerMonitorHelper.shared.launchTimeTracer?.handleInstance.start()

                let tuple = self.handleInstance(with: items, emptyDate: emptyDate, isReload: isReload) // 处理 instance

                TimerMonitorHelper.shared.launchTimeTracer?.handleInstance.end()
                HomeScene.coldLaunchTracker?.addStage(.makeListViewData, with: CACurrentMediaTime() - startTime1)

                return (tuple.0, tuple.1, refreshType)
            }
            .subscribeForUI(onNext: { [weak self] (itemsMap, sortedArray, refreshType) in
                self?.dayItemsDic = itemsMap
                self?.itemsSorted = sortedArray
                self?.rxRefreshSubject.accept(refreshType)
            })
            .disposed(by: self.disposeBag)
    }

    func registerBlockUpdated() {
        // 监听日程
        self.instanceService.instanceUpdated
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                // instance 目标版本自增 1
                self.targetInstanceVersion += 1
                // 重新获取当前日期数据
                self.updateCellItems(date: self.currentDate, refreshType: .scrollToDate(currentDate, false, true), showEmptyDate: currentDate, isReload: true)
        }).disposed(by: disposeBag)
        
        // 监听时间块更新
        timeDataService?.rxTimeBlocksChange.map { _ in }
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                // instance 目标版本自增 1
                self.targetInstanceVersion += 1
                // 重新获取当前日期数据
                self.updateCellItems(date: self.currentDate, refreshType: .scrollToDate(currentDate, false, false), showEmptyDate: currentDate, isReload: true)
        }).disposed(by: disposeBag)
    }

    // instance 转化为 viewData
    func handleInstance(with items: DayEventListMap, emptyDate: Date?, isReload: Bool = false) -> (DayEventListMap, [BlockListItem]) {
        let newCellItems = self.dayItemsDic.replaceOrAdd(items, replace: isReload)

        let sortedArray = self.addPlaceHolder(
            newCellItems,
            emptyDate: emptyDate ?? Date()
        ).transformToArraySorted()

        return (newCellItems, sortedArray)
    }

    // 初始化 rxViewSetting，能够响应 ViewSetting 的变化
    private func initRxViewSetting() -> BehaviorRelay<EventViewSetting> {
        let rx = BehaviorRelay<EventViewSetting>(value: SettingService.shared().getSetting())
        SettingService.shared().updateViewSettingPublish
            .subscribe(onNext: {
                rx.accept(SettingService.shared().getSetting())
            }).disposed(by: disposeBag)
        return rx
    }

    // 获取 date 所在月及其前后7天范围
    func getDayRange(date: Date) -> JulianDayRange {
        let julianDay = JulianDayUtil.julianDay(from: date, in: timeZone)
        let dayRange = JulianDayUtil.julianDayRange(inSameMonthAs: julianDay)
        return Int(dayRange.lowerBound - 7)..<Int(dayRange.upperBound + 7)
    }

    func scrollToRedLine(animated: Bool) {
        self.didSelectDate(Date(), animated: animated)
    }

    func didSelectDate(_ date: Date, animated: Bool) {
        self.currentDate = date
        self.updateCellItems(date: date, refreshType: .scrollToDate(date, animated, true), showEmptyDate: date)
    }

}

// MARK: TableView DataSource

extension ListSceneViewModel {

    func updateCellItems(date: Date, refreshType: BlockListRefreshType, showEmptyDate: Date? = nil, isReload: Bool = false) {
        updateCellItems(dayRange: getDayRange(date: date),
                        refreshType: refreshType,
                        showEmptyDate: showEmptyDate,
                        isReload: isReload)
    }

    func updateCellItems(dayRange: JulianDayRange, refreshType: BlockListRefreshType, showEmptyDate: Date? = nil, isReload: Bool = false) {
        let instances = getInstance(dayRange: dayRange, fromColdLaunch: false)

        switch instances {
        case .value(let items):
            self.cellItemsWillChangedRelay.accept((items, refreshType, showEmptyDate, isReload))
        case .preparing(let rxfinalItems, let temporaryItems):
            if !isReload {
                // 非 reload 场景才进行临时数据的 UI 刷新，原因是冷启动情况下可能会出现屏幕闪烁现象
                self.cellItemsWillChangedRelay.accept((temporaryItems, refreshType, showEmptyDate, isReload))
            }
            asyncRefreshDisposable?.dispose()
            asyncRefreshDisposable = rxfinalItems.asSingle().subscribe(onSuccess: { [weak self] items in
                self?.cellItemsWillChangedRelay.accept((items, refreshType, showEmptyDate, isReload))
            })
            asyncRefreshDisposable?.disposed(by: self.disposeBag)
        }
    }

    /// 添加占位cell 及 创建日程cell
    private func addPlaceHolder(
        _ dayEventListMap: DayEventListMap,
        emptyDate: Date
    ) -> DayEventListMap {

        var instances = dayEventListMap

        let firstWeekday = rxViewSetting.value.firstWeekday

        let emptyDay = JulianDayUtil.julianDay(
            from: emptyDate,
            in: timeZone
        )

        let currentDay = JulianDayUtil.julianDay(
            from: Date(),
            in: timeZone
        )

        // 添加 placeHolder
        for (day, ins) in instances {
            let currentDate = JulianDayUtil.date(from: day).dayEnd()
            // 可点击创建日程的空白内容Cell
            if day == emptyDay || day == currentDay,
               ins.isEmpty {
                instances[day]?
                    .append(
                        BlockListItemModel.nullItem(
                            date: currentDate,
                            sysCalendar: Calendar(identifier: .gregorian)
                        )
                    )
            }

            // 一周第一天
            if currentDate.weekday == firstWeekday.rawValue {
                instances[day]?.insert(BlockListItemModel.weekSeparatorItem(with: currentDate, firstWeekday: firstWeekday), at: 0)
            }
            // 本月第一天
            if currentDate.day == 1 {
                instances[day]?.insert(BlockListItemModel.monthSeparatorItem(with: currentDate), at: 0)
            }
        }

        return instances
    }
}

// MARK: Instance Manager
extension ListSceneViewModel {

    enum InstancesReturn {
        // 同步返回的日程元素信息
        case value(DayEventListMap)
        // 异步请求中的 Observable + 同步返回的临时数据
        case preparing(rxFinalData: Observable<DayEventListMap>, temporaryData: DayEventListMap)
    }

    // 获取 date 所在范围内的日程 instance 数据
    func getInstance(dayRange: JulianDayRange, fromColdLaunch: Bool) -> InstancesReturn {
        let targetVersion = targetInstanceVersion
        let instanceCache = cache.instance.value(forKey: dayRange.description)
        // 尝试从 cache.instance 中获取，否则访问 instanceService 获取
        if let (version, dayEventListMap) = instanceCache,
           version == targetVersion {
            // 命中缓存
            return .value(dayEventListMap)
        }

        switch prepareInstance(dayRange: dayRange, version: targetVersion, fromColdLaunch: fromColdLaunch) {
        case .value(let data):
            return .value(data)
        case .rxValue(let single):
            // 尝试使用旧缓存作为临时数据
            let temporaryData = instanceCache?.1 ?? .init(dayRange.map { ($0, []) }) { $1 }
            return .preparing(rxFinalData: single.asObservable(), temporaryData: temporaryData)

        }
    }

    // 从 InstanceService 请求数据，并将返回的 instance 数据存储在缓存中
    private func prepareInstance(dayRange: JulianDayRange, version: Int, fromColdLaunch: Bool) -> RxReturn<DayEventListMap> {
        ListScene.logInfo("prepare instance, fromColdLaunch is \(fromColdLaunch.description)")
        let requestKey = "\(dayRange.lowerBound)_\(dayRange.upperBound)_\(version)"

        // 每20次上报一下 reqeust cahche 命中率
        if requestCacheAccessCounts.total > 20 {
            let radio = Float(requestCacheAccessCounts.hitCache) / Float(requestCacheAccessCounts.total)
            Tracker.post(SlardarEvent(name: "request_cache_hit_radio",
                                      metric: ["hit_radio": radio],
                                      category: ["home_scene": "list"],
                                      extra: [:]))
            requestCacheAccessCounts.hitCache = 0
            requestCacheAccessCounts.total = 0
        }
        requestCacheAccessCounts.total += 1

        // 尝试从 cache.request 复用请求缓存
        if let request = cache.requestCache.value(forKey: requestKey) {
            // 命中 requestCache 的次数
            requestCacheAccessCounts.hitCache += 1
            ListScene.logInfo("hit instance request cache")
            return .rxValue(request.asSingle())
        }
        ListScene.logInfo("don't hit instance request cache")

        // instance 缓存更新通知，可以作为观察者进行更新缓存任务，也可以作为可观察对象发送方法返回值
        let updateInstanceCache = ReplaySubject<DayEventListMap>.create(bufferSize: 1)
        updateInstanceCache.subscribe(onNext: { [weak self] ins in
            // 缓存 instance 数据
            self?.cache.instance.setValue((version, ins), forKey: dayRange.description)
            // 请求成功返回，删除 request 缓存
            self?.cache.requestCache.removeValue(forKey: requestKey)
        }).disposed(by: disposeBag)

        // 冷启动场景判断
        let requestInstance: RxReturn<DayInstanceMap>
        if fromColdLaunch {
            requestInstance = makeColdLaunchRequest(dayRange: dayRange)
        } else {
            requestInstance = instanceService.rxInstance(for: .init(dayRange, .init()), in: timeZone).map(transform: { $0.value })
        }
        let strategy: TimeDataFetchStrategy = fromColdLaunch ? .coldLaunch : .normal
        let timeBlockObservable = timeDataService?.fetchTimeBlockDataBy(range: dayRange, timezone: timeZone, strategy: strategy, scene: .list).catchErrorJustReturn([:]) ?? .empty()
        let instanceObservable: Observable<DayInstanceMap>
        // 从 instanceService 获取数据，并转换成视图页使用的 DayEventListMap 类型
        let isSetRequestCache: Bool
        switch requestInstance {
        case .value(let groupedInstances):
            instanceObservable = .just(groupedInstances)
            isSetRequestCache = false
        case .rxValue(let rxGroupedInstances):
            instanceObservable = rxGroupedInstances.asObservable()
                .subscribeOn(SerialDispatchQueueScheduler(qos: .userInitiated))
                .collectSlaInfo(.CalendarView, action: "load_instance")
            isSetRequestCache = true
        }
        Observable.zip(instanceObservable, timeBlockObservable)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .userInitiated))
            .map(transformToDayBlockListMap(with: ))
            .subscribe(updateInstanceCache)
            .disposed(by: disposeBag)
        // 添加 request 缓存
        if isSetRequestCache {
            cache.requestCache.setValue(updateInstanceCache, forKey: requestKey)
        }
        return .rxValue(updateInstanceCache.asSingle())
    }

    // 转换 DayInstanceMap 至视图页面使用的 DayEventListMap 类型
    private func transformToDayBlockListMap(with map: (DayInstanceMap, TimeBlockModelMap)) -> DayEventListMap {
        let dayInstanceMap = map.0
        let timeBlockModelMap = map.1
        var result: DayEventListMap = [:]
        let is12HourStyle = SettingService.shared().is12HourStyle.value
        let setting = rxViewSetting.value
        // 将日程和时间块的数据进行合并
        for (day, instances) in dayInstanceMap {
            let currentDate = JulianDayUtil.date(from: day).dayEnd()
            var models: [BlockDataProtocol] = []
            let ins = instances.map({ $0.transformToCalendarEventInstanceEntity() })
            models.append(contentsOf: ins)
            let timeBlocks = timeBlockModelMap[day] ?? []
            models.append(contentsOf: timeBlocks)
            models = models.sorted(by: blockSortRule(_:_:))
            var items: [BlockListItem] = []
            for i in 0..<models.count {
                let eventItem = BlockListItemModel.eventItem(
                    with: models[i],
                    calendar: calendarManager?.calendar(with: (models[i] as? CalendarEventInstanceEntity)?.calendarId ?? "" ),
                    isFirstEventOfDay: i == 0,
                    date: currentDate,
                    sysCalendar: Calendar(identifier: .gregorian),
                    eventViewSetting: setting,
                    is12HourStyle: is12HourStyle)
                items.append(eventItem)
            }
            result[day] = items
        }
        return result
    }

    // block 排序规则
    private func blockSortRule(_ lhs: BlockDataProtocol, _ rhs: BlockDataProtocol) -> Bool {
        TimeBlockUtils.sortBlock(lhs: lhs.transfromToSortModel(), rhs: rhs.transfromToSortModel())
    }
}

fileprivate extension Dictionary where Key == JulianDay, Value == [BlockListItem] {
    func replaceOrAdd(_ items: ListSceneViewModel.DayEventListMap, replace: Bool) -> ListSceneViewModel.DayEventListMap {

        if Set(self.keys).isDisjoint(with: Set(items.keys)) || replace {
            // 两个 dic 代表的事件范围没有交集，即组合在一起的时间会不连续，则返回 items
            // replace 也返回 items 直接替换旧数据
            return items
        }

        return self.merging(items) { $1 }
    }

    func transformToArraySorted() -> [BlockListItem] {
        var itemsSorted: [BlockListItem] = []
        let days = Array(self.keys).sorted()
        for day in days {
            itemsSorted.append(contentsOf: self[day] ?? [])
        }
        return itemsSorted
    }
}
