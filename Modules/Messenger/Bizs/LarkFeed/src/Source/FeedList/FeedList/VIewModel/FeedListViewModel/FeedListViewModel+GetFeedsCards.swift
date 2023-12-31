//
//  FeedListViewModel+GetFeedsCards.swift
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

extension FeedListViewModel {

    func subscribePushFeedPreview() {
        baseDependency.pushFeedPreview.subscribe(onNext: { [weak self, userResolver] (pushFeedPreview) in
            if Feed.Feature(userResolver).groupSettingEnable {
                self?.handleFeedFromPushFeedByOpt(pushFeedPreview)
            } else {
                self?.handleFeedFromPushFeedByDefault(pushFeedPreview)
            }
        }).disposed(by: disposeBag)
    }

    func _getFeedCards() {
        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .refresh)
        dependency.getFeedCards(filterType: self.filterType,
                                cursor: nil,
                                spanID: nil,
                                count: loadConfig.refresh,
                                traceId: trace.traceId)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                guard self.checkFilterType(result.filterType, currentFilterType: self.filterType) else {
                    return
                }
                self.handleFeedFromGetFeed(result, trace: trace)
            }).disposed(by: disposeBag)
    }

    ///
    /// 加载到的response，用于更新缓存的数据
    ///
    func handleFeedFromGetFeed(_ result: GetFeedCardsResult,
                               trace: FeedListTrace) {
        guard authData(verifyKey: result.feedRuleMd5, trace: trace) else { return }
        self.tryUpdateNextCursor(nextCursor: result.nextCursor, timecost: result.timeCost, trace: trace)
        self.updateFeeds(result.feeds, renderType: .reload, trace: trace)
        if Feed.Feature(userResolver).groupSettingEnable {
            markTempfeedIds(ids: result.tempFeedIds, trace: trace)
        } else {
            unMarkDirtyFeed(result.feeds, trace: trace) // 重置为非脏数据
        }
    }

    func _loadMore(trace: FeedListTrace) -> Observable<Bool> {
        // 如果nextCursor不存在，或者 nextCursor == 0，则不再触发loadMore的请求
        guard hasMoreFeeds() else {
            return Observable<Bool>.create { observer -> Disposable in
                observer.onError(NSError(domain: "Invalid nextCursor state", code: -1, userInfo: nil))
                return Disposables.create()
            }
        }

        if self.bizType == .inbox || self.bizType == .done {
            isRecordLoadMore = true // 设置允许为loadmore打点
        }
        return dependency.getFeedCards(filterType: self.filterType,
                                       cursor: getLocalCursor(),
                                       spanID: nil,
                                       count: loadConfig.loadMore,
                                       traceId: trace.traceId).map({ [weak self] (result) -> Bool in
            guard let self = self else { return false }
            guard self.checkFilterType(result.filterType, currentFilterType: self.filterType) else {
                return false
            }
            self.handleFeedFromGetFeed(result, trace: trace)
            return self.checkHasMoreFeeds(cursor: result.nextCursor)
        }).do(onNext: { _ in
        }, onError: { (error) in
            if let error = error.underlyingError as? APIError {
                FeedPerfTrack.trackFeedLoadMoreError(error)
            }
        })
    }

    func checkFilterType(_ filterType: Feed_V1_FeedFilter.TypeEnum,
                         currentFilterType: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        guard filterType == currentFilterType else {
            // 这种case只会发生在 同一个FeedListVM中，filterType有切换的场景下，比如 【消息】tab、【at】tab，未来会避免复用同一个vm，而是新建一个vm，避免窜数据
            let errorMsg = "currentFilterType: \(currentFilterType), result's filterType: \(filterType)"
            let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
            FeedExceptionTracker.DataStream.filter(node: .checkFilterType, info: info)
            return false
        }
        return true
    }
}
