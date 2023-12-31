//
//  BoxFeedsViewModel.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/9.
//

import Foundation
import RxCocoa
import RxSwift
import RustPB
import AnimatedTabBar
import LarkSDKInterface
import LarkTab
import LarkModel
import LarkOpenFeed

final class BoxFeedsViewModel: BaseFeedsViewModel {
    override var bizType: FeedBizType {
        return .box
    }

    let dependency: BoxFeedsDependency
    private var nextCursor: FeedCursor?

    init(dependency: BoxFeedsDependency,
         baseDependency: BaseFeedsViewModelDependency,
         feedContext: FeedContextService) {
        self.dependency = dependency
        super.init(baseDependency: baseDependency, feedContext: feedContext)
        subscribe()
        getFeedCards()
    }

    override func hasMoreFeeds() -> Bool {
        return checkHasMoreFeeds(cursor: getLocalCursor())
    }

    override func displayFilter(_ item: FeedCardCellViewModel) -> Bool {
        return item.isShow && Int(item.feedPreview.basicMeta.parentCardID) ?? 0 > 0
    }

    private func subscribe() {
        baseDependency.pushFeedPreview.subscribe(onNext: { [weak self] (feeds) in
            self?.handlePushFeedPreview(feeds)
        }).disposed(by: disposeBag)
    }

    /// PushFeedPreview数据处理
    private func handlePushFeedPreview(_ pushFeedPreview: PushFeedPreview) {
        let handleData: ([FeedPreview], [PushRemoveFeed])
        if Feed.Feature(userResolver).groupSettingEnable {
            handleData = handlePushDataByOpt(pushFeedPreview)
        } else {
            handleData = handlePushDataByDefault(pushFeedPreview)
        }

        let updateFeeds = handleData.0
        let removeFeeds = handleData.1

        // updateFeeds支持传[]触发reload，所以此处需要判空，否则会触发一次无用table更新
        if !updateFeeds.isEmpty {
            let trace = FeedListTrace(traceId: pushFeedPreview.trace.traceId, dataFrom: .pushUpdate)
            self.updateFeeds(updateFeeds, renderType: .none, trace: trace)
        }

        // 需要删除的feed为空则无需调用
        if !removeFeeds.isEmpty {
            let trace = FeedListTrace(traceId: pushFeedPreview.trace.traceId, dataFrom: .pushRemove)
            self.removeFeeds(removeFeeds, renderType: .none, trace: trace)
        }
    }

    private func handlePushDataByDefault(_ pushFeedPreview: PushFeedPreview) -> ([FeedPreview], [PushRemoveFeed]) {
        var updateFeeds = [FeedPreview]()
        var removeFeeds = pushFeedPreview.removeFeeds
        let currentType: FeedFilterType = .box
        pushFeedPreview.updateFeeds.forEach { (_: String, pushFeedInfo: PushFeedInfo) in
            let feed = pushFeedInfo.feedPreview
            if pushFeedInfo.types.contains(currentType) {
                updateFeeds.append(feed)
            } else {
                removeFeeds.append(PushRemoveFeed(feedId: feed.id))
            }
        }
        return (updateFeeds, removeFeeds)
    }

    private func handlePushDataByOpt(_ pushFeedPreview: PushFeedPreview) -> ([FeedPreview], [PushRemoveFeed]) {
        var updateFeeds = [FeedPreview]()
        let currentType: FeedFilterType = .box
        var removeFeeds = pushFeedPreview.removeFeeds.filter({ $0.types.contains(currentType) })
        pushFeedPreview.updateFeeds.forEach { (_: String, pushFeedInfo: PushFeedInfo) in
            let feed = pushFeedInfo.feedPreview
            if pushFeedInfo.types.contains(currentType) {
                updateFeeds.append(feed)
            }
        }
        return (updateFeeds, removeFeeds)
    }

    private func getFeedCards() {
        // 拉取Box数据
        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .refresh)
        dependency.getFeedCards(feedCardID: dependency.boxId,
                                cursor: getLocalCursor(),
                                count: loadConfig.refresh,
                                traceId: trace.traceId)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.updateNextCursor(res.nextCursor)
                self.updateFeeds(res.feeds, renderType: .reload, trace: trace)
            }).disposed(by: disposeBag)
    }

    /// 加载更多
    /// Return: Bool 表示是否有需要继续load more
    override func loadMore(trace: FeedListTrace) -> Observable<Bool> {
        guard hasMoreFeeds() else {
            return Observable.create { (observer) -> Disposable in
                observer.onNext(false)
                return Disposables.create()
            }
        }
        return self.dependency
            .getFeedCards(feedCardID: dependency.boxId,
                          cursor: getLocalCursor(),
                          count: loadConfig.loadMore,
                          traceId: trace.traceId)
            .map { [weak self] (res) -> Bool in
                guard let self = self else { return false }
                self.updateNextCursor(res.nextCursor)
                self.updateFeeds(res.feeds, renderType: .reload, trace: trace)
                return self.checkHasMoreFeeds(cursor: res.nextCursor)
            }
    }

    private func updateNextCursor(_ nextCursor: FeedCursor?) {
        self.nextCursor = nextCursor
        // 如果nextCursor发生更新，通知外部是否需要增加LoadMore菊花
        let hasLoadMore = checkHasMoreFeeds(cursor: nextCursor)
        feedLoadMoreRelay.accept(hasLoadMore)
    }

    private func getLocalCursor() -> FeedCursor? {
        return nextCursor
    }
}
