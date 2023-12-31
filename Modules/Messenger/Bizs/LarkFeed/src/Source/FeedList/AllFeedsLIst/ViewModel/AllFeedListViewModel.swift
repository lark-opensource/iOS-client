//
//  AllFeedListViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/25.
//

import Foundation
import RxSwift
import RustPB
import LarkSDKInterface
import RxDataSources
import AnimatedTabBar
import RxCocoa
import ThreadSafeDataStructure
import LarkNavigation
import LarkModel
import LarkTab
import LarkMonitor
import LarkAccountInterface
import LarkOpenFeed

final class AllFeedListViewModel: FeedListViewModel {

    // 用来更新主Tab上的bagde
    lazy var tabEntry: FeedTab? = {
        TabRegistry.resolve(Tab.feed) as? FeedTab
    }()

    /* 首屏渲染完成信号，有两个用途:
        1. 通知过渡图消失
        2. 通知Tab首屏渲染完成 */
    let firstScreenRenderedFinish = BehaviorRelay(value: false)

    // 冷启动，数据未拉回来时，过渡图消失，需要显示loading
    var shouldShowLoading: Bool = true

    // feeds更新信号：目前用来更新shortcut
    let feedPreviewSubject = PublishSubject<[FeedPreview]>()

    let allFeedsDependency: AllFeedsDependency

    // 获取首个tab类型值
    var firstTab: Feed_V1_FeedFilter.TypeEnum {
        return Self.getFirstTab(showMute: allFeedsDependency.showMute)
    }
    var pushFeedPreview: PushFeedPreview?

    var userId: String { userResolver.userID }
    static private(set) weak var feedCardModuleManager: FeedCardModuleManager?

    init(allFeedsDependency: AllFeedsDependency,
         dependency: FeedListViewModelDependency,
         baseDependency: BaseFeedsViewModelDependency,
         feedContext: FeedContextService) {
        let userResolver = baseDependency.userResolver
        let userId = userResolver.userID
        FeedContext.log.info("feedlog/life/init. userId: \(userId)")
        Feed.Feature.feedInit(userResolver: userResolver)
        self.allFeedsDependency = allFeedsDependency
        let showMute = allFeedsDependency.showMute
        let filterType = Self.getFirstTab(showMute: showMute)
        Self.feedCardModuleManager = baseDependency.feedCardModuleManager
        super.init(filterType: filterType,
                   dependency: dependency,
                   baseDependency: baseDependency,
                   feedContext: feedContext)

        NotificationCenter.default.rx.notification(
            FeedNotification.needReloadMsgFeedList)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .reset)
                self.reset(trace: trace)
            }).disposed(by: disposeBag)
    }

    deinit {
        FeedContext.log.info("feedlog/life/deinit. userId: \(userId)")
    }

    private func setup() {
        baseDependency.pushFeedPreview
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (pushFeedPreview) in
            guard let self = self else { return }
            self.updatePushFeed(pushFeedPreview)
        }).disposed(by: disposeBag)
        pullConfig()
        bindTabMuteBadge()
        bindAiOnboardingState()
    }

    /// 监听 MyAI 初始化状态，如果初始化完成，刷新列表
    private func bindAiOnboardingState() {
        myAIService?.enable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] value in
                guard let self = self else { return }
                FeedContext.log.info("feedlog/myai/onboarding - enabled: \(value)")
                self.updateFeeds([], renderType: .reload, trace: .genDefault())
            }).disposed(by: disposeBag)
        myAIService?.needOnboarding
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] value in
                guard let self = self else { return }
                FeedContext.log.info("feedlog/myai/onboarding - needOnboarding: \(value)")
                self.updateFeeds([], renderType: .reload, trace: .genDefault())
            }).disposed(by: disposeBag)
    }

    override func getFeedCards() {
        setup()
        loadFeedsCache()
        preloadGetFeeds()
    }

    override func updateFeeds(_ feeds: [FeedPreview], renderType: FeedRenderType, trace: FeedListTrace) {
        updateShortcut(feeds)
        super.updateFeeds(feeds, renderType: renderType, trace: trace)
        // 拿到数据 取消Loading
        shouldShowLoading = false
        feedContext.listeners
            .filter { $0.needListenFeedData }
            .map { $0.feedDataChanged(feeds: feeds, context: nil) }
    }

    override func handleBadgeStyle() {
        super.handleBadgeStyle()
        if let pushFeedPreview = getPushFeed() {
            updateMainTabBadge(pushFeedPreview: pushFeedPreview)
        }
    }

    override func handleCustomFeedSort(items: [FeedCardCellViewModel], dataStore: SectionHolder, trace: FeedListTrace) -> [FeedCardCellViewModel] {
        if filterType == .inbox || (filterType == .message && Feed.Feature(userResolver).groupSettingEnable) {
            return _handleCustomBoxFeedSort(items: items, dataStore: dataStore, trace: trace)
        }
        return items
    }

    override func authData(verifyKey: String, trace: FeedListTrace) -> Bool {
        guard Feed.Feature(userResolver).groupSettingEnable else { return true }
        guard filterType == .message else { return true }
        let authKey = dependency.currentFeedRuleMd5
        guard !verifyKey.isEmpty, verifyKey != authKey else { return true }
        let errorMsg = "\(listBaseLog), \(trace.description), authKey: \(authKey), verifyKey: \(verifyKey)"
        let info = FeedBaseErrorInfo(type: .error(track: false), errorMsg: errorMsg)
        FeedExceptionTracker.DataStream.authData(node: .verifyKey, info: info)
        return false
    }
}
