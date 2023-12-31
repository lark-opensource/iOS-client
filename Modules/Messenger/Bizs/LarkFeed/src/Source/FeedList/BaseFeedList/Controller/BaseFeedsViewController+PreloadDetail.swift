//
//  BaseFeedsViewController+PreloadDetail.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/20.
//

import Foundation
import LarkOpenFeed
import Dispatch

extension BaseFeedsViewController {
    // 当前预加载Chat和Docs：viewDidAppear + 滑动停止 + 切换筛选器后
    func sendFeedListState(state: FeedListState) {
        let listeners = feedsViewModel.feedContext.listeners
            .filter { $0.needListenListState }
        if !listeners.isEmpty {
            let context = self.feedsViewModel.feedContext
            let feedPreviews = self.tableView.visibleCells.compactMap({
                ($0 as? FeedCardCellWithPreview)?.feedPreview
            })
            guard !feedPreviews.isEmpty else { return }
            DispatchQueue.global().async {
                listeners.forEach { $0.feedListStateChanged(feeds: feedPreviews,
                                                            state: state,
                                                            context: context)
                }
            }
        }
    }

    // 可视区域最底部 Cell 在列表中的 index 值
    func findLastVisibleCellIndex() -> Int? {
        var position: Int?
        if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows,
           let lastIndexPath = indexPathsForVisibleRows.last {
            position = lastIndexPath.row
        }
        return position
    }
}
