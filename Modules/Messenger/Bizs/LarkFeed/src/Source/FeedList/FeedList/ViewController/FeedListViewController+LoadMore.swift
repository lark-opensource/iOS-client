//
//  FeedListViewController+LoadMore.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/6/29.
//

import Foundation
import LarkUIKit
import RxSwift

/// 预加载
extension FeedListViewController {

    func loadMoreForDiscontinuousWhenScrollStop() {
        guard feedsViewModel.hasMoreFeeds(),
              preloadEnabled else {
            return
        }

        // 场景2: 滚动停止时判断下：ui展示出的最后一个feed的rankTime是否小于nextCursor，如果小于，代表用户看到了断层或者说数据可能出现了断层，则此时拉取一次loadmore接口
        guard
            let lastVisibleCell = tableView.visibleCells.last as? FeedCardCellWithPreview,
            let lastRankTime = lastVisibleCell.feedPreview?.basicMeta.rankTime,
            let nextCursor = self.listViewModel.getLocalCursor() else { return }

        let isDiscontinuous = lastRankTime < Int(nextCursor.rankTime)
        guard isDiscontinuous else {
            return
        }
        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .getDiscontinuous)
        let logInfo = "\(self.feedsViewModel.listBaseLog), \(trace.description)"
        FeedContext.log.info("feedlog/dataStream/loadmore/discontinuous. \(logInfo), displayedItemsCount: \(feedsViewModel.allItems().count), nextCursor: \(nextCursor.description), lastRankTime: \(lastRankTime)")
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
