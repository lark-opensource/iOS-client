
//  TimeDataService.swift
//  Calendar
//
//  Created by JackZhao on 2023/11/13.
//

import RxRelay
import RxSwift
import Foundation
import CryptoSwift
import LarkStorage
import CTFoundation
import LarkContainer
import LKCommonsLogging
import CalendarFoundation
import UniverseDesignToast
import ThreadSafeDataStructure

// 视图页时间容器的服务
/// 时间块数据三级缓存：
/// - Request Cache
/// - Memory Cache
/// - Disk Cache
class TimeDataServiceImpl: TimeDataService, UserResolverWrapper {
    static let logger = Logger.log(TimeDataServiceImpl.self, category: "lark.calendar")
    typealias TimeBlockCacheModel = (timeBlockModelMap: TimeBlockModelMap, containersSet: Set<String>)
    lazy var taskInCalendarFG: Bool = {
        #if DEBUG
        return true
        #else
        return FeatureGating.taskInCalendar(userID: self.userResolver.userID)
        #endif
    }()

    // 外部服务
    let userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy var timeBlockAPI: TimeBlockAPI?
    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var dependency: TimeBlockDependency?
    @ScopedInjectedLazy var timeContainerAPI: TimeContainerAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    private(set) var bag = DisposeBag()
    private let queue = DispatchQueue(label: "TimeDataServiceImpl.serialQueue", qos: .default)
    private lazy var queueScheduler = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: queue.label)

    // MARK: timeblock memory cache
    // 时间块请求缓存
    private static let maxCacheCount = 20
    // 当收到时间快改变通知，计数 +1
    private var updatedCounter: Int64 = 0
    private let timeBlockDataCache: SafeDictionary<String, TimeBlockCacheModel> = [:] + .readWriteLock
    private var timeBlockDataCacheIsDirty: SafeAtomic<Bool> = false + .readWriteLock
    private let requestCache = LRUCache<String, ReplaySubject<TimeBlockModelMap>>(capacity: maxCacheCount, useLock: true)
    
    // MARK: 时间容器相关
    /// 时间容器变更信号 - 用于端上场景通知
    let timeContainerChanged = PublishRelay<Void>()
    var rxTimeBlocksChange: Observable<Void> {
        rxTimeBlocksChangeSubject.asObservable()
    }
    private let rxTimeBlocksChangeSubject = PublishSubject<Void>()
    /// 时间容器 Map 数据
    private var timeContainersMap: [String: TimeContainerModel] = [:]
    /// 时间容器 Vec 数据
    private var timeContainers: [TimeContainerModel] {
        Array(timeContainersMap.values)
    }
    
    // MARK: timeblock disk cache
    private(set) lazy var aesCipher: CryptoSwift.Cipher? = {
        guard let user = self.calendarDependency?.currentUser else { return nil }
        let cipher = CalendarCipher(userId: user.id, tenentId: user.tenantId)
        do {
            let aesCipher = try cipher.generateAES()
            return aesCipher
        } catch {
            Self.logger.error("generate cipher error")
            return nil
        }
    }()
    static let timeBlockSplit: String = "_"
    var diskTimeBlockHash: Int = 0
    private(set) lazy var cacheDir: IsoPath? = {
        guard let calendarDependency else { return nil }
        return calendarDependency.userLibraryPath() + "home"
    }()
    private(set) lazy var cachePath: IsoPath? = {
        guard let cacheDir else { return nil }
        return cacheDir + "timeBlock"
    }()
    let debouncer = Debouncer(delay: 1, queue: DispatchQueue.global())
    private var timeBlockDiskCache: TimeBlockModelMap {
        guard let data = try? timeBlockDiskDataSubject.value() else { return [:] }
        return data
    }
    // 记录磁盘缓存是否是最新数据： dirty表示否
    private var diskDataIsDirty: SafeAtomic<Bool> = true + .readWriteLock
    private(set) var timeBlockDiskDataSubject = BehaviorSubject<TimeBlockModelMap>(value: [:])

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        observeDataChange()
    }
    
    private func observeDataChange() {
        guard taskInCalendarFG else { return }
        pushService?.rxTimeBlocksChange
            .throttle(.milliseconds(300), scheduler: queueScheduler)
            .subscribe(onNext: { [weak self] ids in
                guard let self else { return }
                let set = Set(ids)
                // 移除data cache
                let removeKeys = self.timeBlockDataCache.compactMap { item in
                    if !item.value.containersSet.union(set).isEmpty { return item.key }
                    return nil
                }
                for key in removeKeys {
                    self.timeBlockDataCache.removeValue(forKey: key)
                }
                OSAtomicIncrement64(&self.updatedCounter)
                self.diskDataIsDirty.value = true
                Self.logger.info("rxTimeBlocksChangeSubject")
                rxTimeBlocksChangeSubject.onNext(())
            }).disposed(by: self.bag)
        
        pushService?.rxTimeContainerChanged
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                /// 收到push，暂时全量刷新，不精细化刷新
                self.fetchTimeContainers()
            })
            .disposed(by: self.bag)
    }
    
    func getTimeBlockDataBy(range: JulianDayRange,
                            timezone: TimeZone,
                            scene: TimeDataFetchScene) -> (TimeBlockModelMap, TimeDataFetchResult) {
        guard taskInCalendarFG else { return ([:], .all) }
        let dataKey = getDataKey(range: range, timezone: timezone)
        // 判断数据缓存
        if let cache = timeBlockDataCache[dataKey] {
            let isDirty = timeBlockDataCacheIsDirty.value
            DayScene.logger.info("timeblock hit dataCache, cache.isDirty = \(isDirty)")
            return (cache.timeBlockModelMap, isDirty ? .part : .all)
        }
        // 判断磁盘缓存
        var result: TimeDataFetchResult = .all
        let cache = self.timeBlockDiskCache
        var map = TimeBlockModelMap()
        for i in range {
            if let v = cache[i] {
                map[i] = v
            } else {
                result = .part
            }
        }
        if map.isEmpty {
            result = .none
        }
        if diskDataIsDirty.value, result == .all {
            result = .part
        }
        if result != .none {
            DayScene.logger.info("timeblock hit diskCache")
        } else {
            DayScene.logger.info("⚠️timeblock not hit any cache")
        }
        return (map, result)
    }
    
    func fetchTimeBlockDataBy(range: JulianDayRange,
                              timezone: TimeZone,
                              scene: TimeDataFetchScene) -> Observable<TimeBlockModelMap> {
        fetchTimeBlockDataBy(range: range, timezone: timezone, strategy: .normal, scene: scene)
    }

    // 先判断请求缓存，再判断内存缓存，都没有再去Rust获取
    //获取时间块 starage指缓存策略，例如月视图会缓存左右各1个月；需要做request缓存
    func fetchTimeBlockDataBy(range: JulianDayRange,
                              timezone: TimeZone,
                              strategy: TimeDataFetchStrategy,
                              scene: TimeDataFetchScene) -> Observable<TimeBlockModelMap> {
        guard taskInCalendarFG else { return .just([:]) }
        switch strategy {
        case .coldLaunch:
            return processColdLaunchFetch()
        case .normal:
            return processNormalFetch()
        case .forceFetch:
            return processForceFetch()
        }

        func processColdLaunchFetch() -> Observable<TimeBlockModelMap> {
            if !timeBlockDiskCache.isEmpty {
                Self.logger.info("timeBlock hit DiskCache, count = \(timeBlockDiskCache.count), scene = \(scene)")
                return .just(timeBlockDiskCache)
            }
            Self.logger.info("⚠️timeBlock not hit DiskCache, scene = \(scene)")
            // TODO @jack: 解决无法触发subscribe的问题
            return .just([:])
//            return timeBlockDiskDataSubject.asObservable()
        }

        func processNormalFetch() -> Observable<TimeBlockModelMap> {
            let reqKey = getRequestKey()
            // 使用requestCache来避免同一时段重复请求
            if let request = requestCache.value(forKey: reqKey) {
                Self.logger.info("timeblock hit requestCache, scene = \(scene)")
                return request
            }
            
            let dataKey = getDataKey(range: range, timezone: timezone)
            // 判断数据缓存
            if let cache = timeBlockDataCache[dataKey], !timeBlockDataCacheIsDirty.value {
                DayScene.logger.info("timeblock hit dataCache, scene = \(scene)")
                return .just(cache.0)
            }
            let res = processForceFetch()
            return res
        }
        
        func processForceFetch() -> Observable<TimeBlockModelMap> {
            Self.logger.info("timeblock force fetch start dayRange = \(range), scene = \(scene)")
            let reqKey = getRequestKey()
            let dataKey = getDataKey(range: range, timezone: timezone)
            let timestamps = Self.requestTimestamps(for: range, in: timezone)
            guard let timeBlockAPI = self.timeBlockAPI else { return .empty() }
            let subject = ReplaySubject<TimeBlockModelMap>.create(bufferSize: 1)
            subject.subscribe(onError: { [weak self] _ in
                self?.requestCache.removeValue(forKey: reqKey)
            }).disposed(by: bag)
            
            timeBlockAPI
                .fetchTimeBlock(startTime: timestamps.startTime,
                                endTime: timestamps.endTime,
                                timezone: timezone.identifier,
                                needContainer: true)
                .map({ [weak self] res -> TimeBlockModelMap in
                    let timeBlocks = res.timeBlocks.map({ block in
                        let container = res.containers[block.containerIDOnDisplay]
                        if container == nil {
                            Self.logger.info("container is nil, blockID = \(block.blockID), scene = \(scene)")
                        }
                        return TimeBlockModel(pbModel: block, container: container)
                    })
                    Self.logger.info("fetch timeblock, count = \(timeBlocks.count), scene = \(scene)")
                    let map = Self.groupedByDay(from: timeBlocks, for: range)
                    let containerIds = res.timeBlocks.map { $0.containerIDOnDisplay }
                    let model: TimeBlockCacheModel = (timeBlockModelMap: map, containersSet: Set(containerIds))
                    self?.timeBlockDataCache[dataKey] = model
                    self?.timeBlockDataCacheIsDirty.value = false
                    self?.timeBlockDiskDataSubject.onNext(map)
                    self?.writeToDiskIfNeeded(timeBlocks: res.timeBlocks, timeContainer: res.containers.map({ $0.value }), dayRange: range)
                    self?.diskDataIsDirty.value = false
                    return map
                }).subscribe(subject).disposed(by: self.bag)
            requestCache.setValue(subject, forKey: reqKey)
            return subject.asObservable().timeout(.seconds(5), scheduler: queueScheduler)
        }
        
        func getRequestKey() -> String {
            let reqKey = "\(range.lowerBound)_\(range.upperBound)_\(updatedCounter)_\(timezone.identifier)"
            return reqKey
        }
        
    }

    func getDataKey(range: JulianDayRange, timezone: TimeZone) -> String {
        let dataKey = "\(range.lowerBound)_\(range.upperBound)_\(timezone.identifier)"
        return dataKey
    }

    func fetchTimeBlockById(_ id: String, 
                            containerIDOnDisplay: String,
                            timezone: TimeZone) -> Observable<TimeBlock> {
        guard taskInCalendarFG else { return .empty() }
        return self.timeBlockAPI?.fetchTimeBlockById(id, containerIDOnDisplay: containerIDOnDisplay, timezone: timezone).map { $0.timeBlock } ?? .empty()
    }
    
    func forceUpdateTimeBlockData() {
        guard taskInCalendarFG else { return }
        self.timeBlockDataCacheIsDirty.value = true
        OSAtomicIncrement64(&self.updatedCounter)
        self.diskDataIsDirty.value = true
        Self.logger.info("forceUpdateTimeBlockData")
        rxTimeBlocksChangeSubject.onNext(())
    }
}

// MARK: tool
extension TimeDataServiceImpl {
    static func groupedByDay(
        from models: [TimeBlockModel],
        for dayRange: JulianDayRange) -> TimeBlockModelMap {
        var map = TimeBlockModelMap()
        dayRange.forEach { map[$0] = [] }
        for model in models {
            let range: JulianDayRange = JulianDay(model.startDay)..<JulianDay(model.endDay) + 1
            guard range.overlaps(dayRange) else { continue }
            for day in dayRange where range.contains(day) {
                map[day]?.append(model)
            }
        }
        assert(Set(map.keys) == Set(dayRange))
        return map
    }
    
    // 将JulianDayRange转化为startTime和endTime
    @inline(__always)
    private static func requestTimestamps(
        for dayRange: JulianDayRange,
        in timeZone: TimeZone
    ) -> (startTime: JulianDayUtil.Timestamp, endTime: JulianDayUtil.Timestamp) {
        let startTime = JulianDayUtil.startOfDay(for: dayRange.lowerBound, in: timeZone)
        let endTime = JulianDayUtil.endOfDay(for: dayRange.upperBound - 1, in: timeZone)
        return (startTime, endTime)
    }
}

// MARK: - Time Container
extension TimeDataServiceImpl {
    /// 获取当前用户的时间容器，并缓存，发送变更通知，业务方通过 GetTimeContainers 来获取最新时间容器数据
    @discardableResult
    func fetchTimeContainers() -> Observable<Void> {
        guard taskInCalendarFG, let api = timeContainerAPI else { return .empty() }
        let observable = api.fetchTimeContainers().share()
        observable
            .map { $0.containers }
            .observeOn(SerialDispatchQueueScheduler(qos: .userInitiated)) // 串行写
            .subscribe(onNext: { [weak self] containersMap in
                guard let self = self else { return }
                self.timeContainersMap = containersMap.mapValues({ pb in
                    TimeContainerModel(pb: pb)
                })
                self.timeContainerChanged.accept(())
                TimeContainerLogger.info("fetch time containers success, count: \(containersMap.count)")
            }, onError: { e in
                TimeContainerLogger.error("fetch time containers error, \(e)")
            })
            .disposed(by: bag)
        return observable.map({ _ in })
    }
    
    func getTimeContainers() -> [TimeContainerModel] {
        return self.timeContainers
    }
    
    /// 修改时间容器的信息
    @discardableResult
    func updateTimeContainerInfo(id: String, isVisibile: Bool?, colorIndex: ColorIndex?) -> Observable<Void> {
        guard let api = timeContainerAPI else { return .empty() }
        let observable = api.updateTimeContainerInfo(id: id, isVisibile: isVisibile, colorIndex: colorIndex).share()
        observable
            .subscribe(onNext: { _ in
                TimeContainerLogger.info("update time container info success")
            }, onError: { e in
                TimeContainerLogger.error("update time container info error \(e), update info: \(id), \(isVisibile?.description ?? "none"), \(colorIndex?.rawValue.description ?? "none")")
            })
            .disposed(by: bag)
        return observable.map({ _ in })
    }
    
    /// 仅勾选此时间容器
    func specifyVisibleOnlyTimeContainer(with id: String) -> Observable<Void> {
        guard let api = timeContainerAPI else { return .empty() }
        let observable = Observable.zip(
            api.specifyVisibleOnlyTimeContainer(with: id),
            LocalCalendarManager.hideAllIfVisible()
        ).share()
        observable
            .subscribe(onNext: { _ in
                TimeContainerLogger.info("visible onlty time container success")
            }, onError: { e in
                TimeContainerLogger.error("visible onlty time container error \(e), id: \(id)")
            })
            .disposed(by: bag)
        return observable.map { _ in }
    }
}
