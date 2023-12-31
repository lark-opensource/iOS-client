//
//  BaseFeedsViewController+LoadMore.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/6/29.
//

import Foundation
import LarkUIKit
import RxSwift

/// 预加载
extension BaseFeedsViewController {

    func loadMore(index: Int) {
        //         为了防止willDisplay造成连续多次预加载，需要等UI上feeds数量增加后再重置信号（preloadEnabled）允许进行下一次预加载
        guard feedsViewModel.hasMoreFeeds(),
              preloadEnabled else {
            return
        }

        // 场景1: 当展示到倒数第50(loadConfig.buffer)个之后，将进行预加载.
        let isReachBottom = index >= (feedsViewModel.allItems().count - feedsViewModel.loadConfig.buffer)

        guard isReachBottom else {
            return
        }
        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .loadMore)
        FeedContext.log.info("feedlog/dataStream/loadMore/trigger. \(self.feedsViewModel.listBaseLog), \(trace.description), reachBottom: \(index), displayedItemsCount: \(feedsViewModel.allItems().count)")
        preloadEnabled = false
        var localBag = DisposeBag()
        Observable.zip(feedsViewModel.loadMore(trace: trace), feedsViewModel.feedsUpdated)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.preloadEnabled = true
                localBag = DisposeBag()
            }).disposed(by: localBag)
    }
}
