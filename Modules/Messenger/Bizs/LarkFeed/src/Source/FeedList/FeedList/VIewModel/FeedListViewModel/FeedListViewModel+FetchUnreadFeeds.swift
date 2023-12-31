//
//  FeedListViewModel+FetchUnreadFeeds.swift
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
    // MARK: PreloadUnread
    /// 发起拉取预加载下条未读的请求
    func getNextUnreadFeeds(by cursor: FeedCursor) {
        guard !isFetchUnreading else {
            return
        }
        isFetchUnreading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + Cons.delaySecond) {
            let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .getUnread)
            let currentFilterType = self.filterType
            FeedContext.log.info("feedlog/findUnread/get/start. filterType: \(currentFilterType), cursor: \(cursor.description)")
            self.dependency.getNextUnreadFeedCardsBy(filterType: currentFilterType, cursor: cursor, traceId: trace.traceId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] result in
                    guard let self = self else { return }
                    guard self.checkFilterType(result.filterType, currentFilterType: self.filterType) else {
                        return
                    }
                    FeedContext.log.info("feedlog/findUnread/get/end. filterType: \(currentFilterType), nextCursor: \(result.nextCursor), count: \(result.previews.count)")
                    self.handleFeedFromGetUnreadFeed(result, trace: trace)
                    self.isFetchUnreading = false
                    if AllFeedListViewModel.getFirstTabs().contains(currentFilterType) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            let allFeeds = self.allItems()
                            let filterBadgeCount = self.dependency.getUnreadCount(currentFilterType)
                            FeedDataSyncTracker.trackFindUnreadFeed(
                                filterType: currentFilterType,
                                allFeeds: allFeeds,
                                response: result,
                                filterBadgeCount: filterBadgeCount)
                        }
                    }
                }, onError: { _ in
                    self.isFetchUnreading = false
                }).disposed(by: self.disposeBag)
        }
    }

    /// 处理拉到的预加载下条未读数据
    private func handleFeedFromGetUnreadFeed(_ result: NextUnreadFeedCardsResult, trace: FeedListTrace) {
        guard authData(verifyKey: result.feedRuleMd5, trace: trace) else { return }
        if result.nextCursor.rankTime > 0 {
            self.tryUpdateNextCursor(nextCursor: result.nextCursor, trace: trace)
        } else {
            let traceInfo = "\(self.listBaseLog), \(trace.description)"
            let errorMsg = "\(traceInfo), nextCursor: \(result.nextCursor.description)"
            let info = FeedBaseErrorInfo(type: .error(track: false), errorMsg: errorMsg)
            FeedExceptionTracker.DataStream.findUnread(node: .updateNextCursor, info: info)
        }
        self.updateFeeds(result.previews, renderType: .reload, trace: trace)
        if Feed.Feature(userResolver).groupSettingEnable {
            markTempfeedIds(ids: result.tempFeedIds, trace: trace)
        } else {
            unMarkDirtyFeed(result.previews, trace: trace) // 重置为非脏数据
        }
    }

    enum Cons {
        static let delaySecond: CGFloat = 0.25
    }
}
