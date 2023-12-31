//
//  BaseFeedsViewModel.swift
//  LarkFeed
//
//  Created by bytedance on 2020/6/5.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import LarkModel
import AppReciableSDK
import LarkOpenFeed
import LarkContainer

class BaseFeedsViewModel: UserResolverWrapper {
    var userResolver: UserResolver { baseDependency.userResolver }
    private var settingStore: FeedSettingStore
    var bizType: FeedBizType {
        fatalError("Need To Be Override")
    }

    let disposeBag = DisposeBag()

    var isRecordLoadMore = false // 当loadingMore且不会显示菊花时为true，当loadingMore且显示菊花时为false。当true时会打点

    let loadConfig: LoadConfigStorage

    let queue = OperationQueue()
    let logQueue = OperationQueue()

    // BaseFeedsViewModelDependency的引入只是为了提供部分默认实现
    // 不采用Dependency继承的方式是为了避免BaseFeedsViewModelDependency的修改引起过多改动
    let baseDependency: BaseFeedsViewModelDependency

    // 总数据源容器: 其他地方也会调用，对外接口均内置互斥锁
    let provider: FeedProvider

    // 每次调用完刷新方法(reloadData/performBatchUpdates)之后触发一次
    let feedsUpdated = PublishSubject<Void>()

    // 是否展示空态
    let showEmptyViewRelay = BehaviorRelay<Bool>(value: true)
    var showEmptyViewObservable: Observable<Bool> {
        return showEmptyViewRelay.asObservable().distinctUntilChanged()
    }
    var emptyTitle: String {
        let tab = getFilterType()
        if tab == .unread {
            return BundleI18n.LarkFeed.Lark_Core_UnreadFeedFilter_EmptyState
        } else if tab == .atMe {
            return BundleI18n.LarkFeed.Lark_Core_MentionedMeFeedFilter_EmptyState
        }
        return BundleI18n.LarkFeed.Lark_IM_Labels_NoChatsInLabels_EmptyState
    }

    lazy var swipeSettingChanged: Driver<()> = {
        return settingStore.getFeedActionSetting().distinctUntilChanged().map({ _ -> Void in
            FeedContext.log.info("feedlog/actionSetting/getFeedActionSetting baseFeed settingChanged")
            return ()
        }).asDriver { _ in
            return .empty()
        }
    }()

    // UI数据: 只能在主线程更新和访问
    // 目前为单section，支持多section
    var sections = [SectionHolder]()

    // 触发UI刷新，feedsRelay.value与UI数据不严格一致(Queue随时会更新feedsRelay)
    let feedsRelay = BehaviorRelay<SectionHolder>(value: SectionHolder())

    // 是否需要添加LoadMore菊花的flag
    let feedLoadMoreRelay = BehaviorRelay<Bool>(value: false)

    // 打点用
    let recordRelay = BehaviorRelay<TimeInterval>(value: 0)

    // 本地缓存的已删除feeds的辅助信息 [id: updatetime]
    var removedFeeds: [String: Int] = [:]

    // 记录会话盒子的索引信息
    var boxIndexer: FeedBoxIndexer?

    let feedContext: FeedContextService
    let feedCardModuleManager: FeedCardModuleManager
    let isTracklog: Bool
    let isForbidiff: Bool

    init(baseDependency: BaseFeedsViewModelDependency,
         feedContext: FeedContextService) {
        self.loadConfig = LoadConfigStorage.shared
        self.baseDependency = baseDependency
        self.feedContext = feedContext
        self.feedCardModuleManager = baseDependency.feedCardModuleManager
        self.settingStore = baseDependency.actionSettingStore
        let partialSortEnabled = Feed.Feature(baseDependency.userResolver).partialSortEnabled
        self.provider = FeedProvider(partialSortEnabled: partialSortEnabled)
        self.isTracklog = Feed.Feature(baseDependency.userResolver).isTracklog
        self.isForbidiff = Feed.Feature(baseDependency.userResolver).isForbidiff
        setup()
    }

    private func setup() {
        setupQueue()
        subscribeEventHandlers()
    }

    /// 是否有更多feeds需要加载: 默认没有更多feeds
    func hasMoreFeeds() -> Bool {
        return false
    }

    /// 加载更多: 默认不需要继续load more
    /// Return: flag表示是否有需要继续load more
    func loadMore(trace: FeedListTrace) -> Observable<Bool> {
        return .just(false)
    }

    /// 需要在页面展示时，是否要过滤掉: 默认全部过滤
    func displayFilter(_ item: FeedCardCellViewModel) -> Bool {
        return false
    }

    func updateFeeds(_ feeds: [FeedPreview], renderType: FeedRenderType, trace: FeedListTrace) {
        _updateFeeds(feeds, renderType: renderType, trace: trace)
    }

    func handleBadgeStyle() {
        _handleBadgeStyle()
    }

    // 子类重写
    func handleCustomFeedSort(items: [FeedCardCellViewModel], dataStore: SectionHolder, trace: FeedListTrace) -> [FeedCardCellViewModel] {
        return items
    }
}
