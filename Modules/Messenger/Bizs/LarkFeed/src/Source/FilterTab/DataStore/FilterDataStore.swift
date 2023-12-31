//
//  FilterDataStore.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/8/18.
//

import Foundation
import RxSwift
import RxCocoa
import RustPB
import RunloopTools
import LarkContainer

public final class FilterDataStore: UserResolverWrapper {
    public var userResolver: UserResolver { dependency.userResolver }
    let dependency: FilterDataDependency
    var pushFeedPreview: PushFeedPreview?
    let queue = FeedDataQueue(.filterData)
    let disposeBag = DisposeBag()

    // 业务触发刷新数据源
    var FilterReloadRelay = BehaviorRelay<Void>(value: ())
    var filterReloadObservable: Driver<Void> {
        return FilterReloadRelay.asDriver()
    }

    // 分组侧栏数据源
    private var usedFiltersDSRelay = BehaviorRelay<[FilterItemModel]>(value: [])
    var usedFiltersDSDriver: Driver<[FilterItemModel]> {
        return usedFiltersDSRelay.asDriver()
    }
    var usedFiltersDS: [FilterItemModel] {
        assert(Thread.isMainThread, "usedFiltersDS is only available on main thread")
        return usedFiltersDSRelay.value
    }

    // 常用栏数据源
    private var commonlyFiltersDSRelay = BehaviorRelay<[FilterItemModel]>(value: [])
    var commonlyFiltersDSDriver: Driver<[FilterItemModel]> {
        return commonlyFiltersDSRelay.asDriver()
    }
    var commonlyFiltersDS: [FilterItemModel] {
        assert(Thread.isMainThread, "commonlyFiltersDS is only available on main thread")
        return commonlyFiltersDSRelay.value
    }

    // 分组集合=分组侧栏+常用栏
    private var allFiltersDSRelay = BehaviorRelay<[FilterItemModel]>(value: [])
    var allFiltersDSDriver: Driver<[FilterItemModel]> {
        return allFiltersDSRelay.asDriver()
    }
    var allFiltersDS: [FilterItemModel] {
        assert(Thread.isMainThread, "allFiltersDS is only available on main thread")
        return allFiltersDSRelay.value
    }

    var feedRuleMd5: String {
        get {
            pthread_rwlock_rdlock(&rwLock)
            defer {
                pthread_rwlock_unlock(&rwLock)
            }
            return _feedRuleMd5
        }
        set {
            pthread_rwlock_wrlock(&rwLock)
            defer {
                pthread_rwlock_unlock(&rwLock)
            }
            _feedRuleMd5 = newValue
        }
    }
    private var _feedRuleMd5: String = ""
    private var rwLock = pthread_rwlock_t()
    var version: Int64 = -1

    // 消息分组设置信息
    private var displayRuleMapRelay = BehaviorRelay<[Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem]>(value: [:])
    var displayRuleMapDriver: Driver<[Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem]> {
        return displayRuleMapRelay.asDriver()
    }
    var displayRuleMap: [Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem] {
        assert(Thread.isMainThread, "displayRuleMap is only available on main thread")
        return displayRuleMapRelay.value
    }

    // 缓存
    var dataCacheInChildThread = [FilterItemModel]()
    var fixedDataInChildThread = [FilterItemModel]()
    var mapsInChildThread = [Feed_V1_FeedFilter.TypeEnum: FilterItemModel]()
    var displayRuleMapInChildThread = [Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem]()

    private(set) var isFirstLoad: Bool = true

    init(dependency: FilterDataDependency) {
        pthread_rwlock_init(&self.rwLock, nil)
        self.dependency = dependency
        self.feedRuleMd5 = dependency.getFeedRuleMd5FromDisk() ?? ""
        RunloopDispatcher.shared.addTask(priority: .emergency) {
            self.bind()
        }
        getFilters(tryLocal: true)
        getFilters(tryLocal: false)
    }

    deinit {
        pthread_rwlock_destroy(&self.rwLock)
    }

    func refresh(_ usedFiltersDS: [FilterItemModel],
                 _ commonlyFiltersDS: [FilterItemModel],
                 _ allFiltersDS: [FilterItemModel],
                 _ displayRuleMap: [Feed_V1_FeedFilter.TypeEnum: FeedMsgDisplayFilterItem]? = nil) {
        FeedDataQueue.executeOnMainThread { [weak self] in
            guard let self = self else { return }

            let isNeedReload = self.isNeedReload(usedFiltersDS, self.usedFiltersDS)
            if isNeedReload {
                self.usedFiltersDSRelay.accept(usedFiltersDS)
            }

            let needReloadFixedData = self.isNeedReload(commonlyFiltersDS, self.commonlyFiltersDS)
            if needReloadFixedData {
                self.commonlyFiltersDSRelay.accept(commonlyFiltersDS)
            }

            if isNeedReload || needReloadFixedData {
                self.allFiltersDSRelay.accept(allFiltersDS)
            }

            if self.isFirstLoad {
                FeedTracker.Main.View(filtersCount: usedFiltersDS.count, isFilterShow: !usedFiltersDS.isEmpty)
                self.isFirstLoad = false
            }

            if let displayRuleMap = displayRuleMap {
                self.displayRuleMapRelay.accept(displayRuleMap)
            }
        }
    }

    func localChangeCommonlyFilters(_ filters: [FilterItemModel]) {
        commonlyFiltersDSRelay.accept(filters)
    }
}

extension FilterDataStore {
    func getUnreadCount(_ filter: Feed_V1_FeedFilter.TypeEnum) -> Int? {
        assert(Thread.isMainThread, "dataSource is only available on main thread")
        return pushFeedPreview?.filtersInfo[filter]?.unread
    }

    func getMuteUnreadCount(_ filter: Feed_V1_FeedFilter.TypeEnum) -> Int? {
        assert(Thread.isMainThread, "dataSource is only available on main thread")
        return pushFeedPreview?.filtersInfo[filter]?.muteUnread
    }

    func getShowMute() -> Bool {
        return dependency.getShowMute()
    }
}
