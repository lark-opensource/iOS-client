//
//  FeedListViewModel+Cursor.swift
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

typealias FeedCursor = Feed_V1_FeedCursor
extension FeedCursor {
    static var min: FeedCursor = {
        var cursor = FeedCursor()
        cursor.rankTime = 0
        cursor.id = 0
        return cursor
    }()
}

extension FeedListViewModel {
    func tryUpdateNextCursor(nextCursor: FeedCursor,
                             timecost: TimeInterval? = nil,
                             trace: FeedListTrace) {
        commit { [weak self] in
            guard let self = self else { return }
            if let cost = timecost {
                self.recordTimeCost(cost)
            }
            if self.isShouldUpdateCursor(nextCursor, trace: trace) {
                self.updateNextCursor(nextCursor, trace: trace)
            }
        }
    }

    func updateNextCursor(_ nextCursor: FeedCursor?, trace: FeedListTrace) {
        self.nextCursor = nextCursor
        // 如果nextCursor发生更新，通知外部是否需要增加LoadMore菊花
        let hasLoadMore = checkHasMoreFeeds(cursor: nextCursor)
        feedLoadMoreRelay.accept(hasLoadMore)
        let traceInfo = "\(self.listBaseLog), \(trace.description)"
        FeedContext.log.info("feedlog/dataStream/nextCursor/update. \(traceInfo), \(nextCursor?.description ?? "nil")")
        if !hasLoadMore {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.trackListBadgeWhenLoadAllFeed()
            }
        }
    }

    func getLocalCursor() -> FeedCursor? {
        return nextCursor
    }

    func isShouldUpdateCursor(_ newCursor: FeedCursor, trace: FeedListTrace) -> Bool {
        let isShouldUpdateCursor: Bool
        if let localCursor = self.getLocalCursor() {
            // 【小于等于】这句写的不好
            if newCursor.rankTime <= localCursor.rankTime {
                isShouldUpdateCursor = true
            } else {
                let traceInfo = "\(self.listBaseLog), \(trace.description)"
                let errorMsg = "\(traceInfo), newCursor: \(newCursor.description), localCursor: \(localCursor.description)"
                let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
                FeedExceptionTracker.DataStream.nextCursor(node: .isShouldUpdateCursor, info: info)
                isShouldUpdateCursor = false
            }
        } else {
            isShouldUpdateCursor = true
        }
        return isShouldUpdateCursor
    }
}
