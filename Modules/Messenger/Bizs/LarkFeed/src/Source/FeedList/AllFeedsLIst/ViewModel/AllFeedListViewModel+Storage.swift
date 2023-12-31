//
//  AllFeedListViewModel+Storage.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import Foundation
import RunloopTools

extension AllFeedListViewModel {

    func loadFeedsCache() {
        guard let feeds = FeedKVStorage(userId: userId).getLocalFeeds() else { return }
        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .updateCache)
        updateFeeds(feeds, renderType: .reload, trace: trace)
    }

    func saveFeeds() {
        FeedKVStorage(userId: userId).saveFeeds(allItems())
    }

    // 数据清洗：为了不污染接口返回的数据，需要清除缓存里可能存在的垃圾数据
    func removeJunkCache(trace: FeedListTrace) {
        commit { [weak self] in
            guard let self = self else { return }
            guard let removeFeeds = self.getJunkCache(trace: trace), !removeFeeds.isEmpty else {
                return
            }
            let trace = FeedListTrace(traceId: trace.traceId, dataFrom: .deleteCache)
            FeedContext.log.info("feedlog/dataStream/cache/remove. \(self.listBaseLog), \(trace.description), removeIds: \(removeFeeds.map({ $0.feedId }))")
            self.removeFeeds(removeFeeds, renderType: .reload, trace: trace)
        }
    }

    // 必须在queue里执行，否则会有时序问题导致没有删除成功
    func getJunkCache(trace: FeedListTrace) -> [PushRemoveFeed]? {
        let removeds = provider.getItemsArray().filter { $0.feedPreview.basicMeta.updateTime == FeedLocalCode.feedKVStorageFlag }
        FeedContext.log.info("feedlog/dataStream/cache/getJunkCache. \(self.listBaseLog), \(trace.description), removeIds: \(removeds.map({ $0.feedPreview.id }))")
        guard !removeds.isEmpty else {
            return nil
        }
        return removeds.map({ feed in
            let feedPreview = feed.feedPreview
            let removeFeeds = PushRemoveFeed(feedId: feedPreview.id, updateTime: feedPreview.basicMeta.updateTime)
            return removeFeeds
        })
    }

    func saveFeedShowMuteState() {
        let isOpenedMute = allFeedsDependency.showMute
        FeedKVStorage(userId: userId).saveFeedShowMuteState(isOpenedMute)
    }
}
