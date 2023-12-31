//
//  FeedListViewModel+DirtyFeed.swift
//  LarkFeed
//
//  Created by 袁平 on 2021/1/21.
//

import Foundation
import LarkModel
import LarkUIKit
import RustPB
import LarkSDKInterface
import LarkOpenFeed

// 当某条消息变成已读后暂时保留，用户离开当前tab后再回来才自动清除

extension FeedListViewModel {
    func handleFeedFromPushFeedByDefault(_ pushFeedPreview: PushFeedPreview) {
        var updateFeeds = [FeedPreview]()
        var missedFeeds = [String: PushFeedInfo]()
        var removeFeeds = pushFeedPreview.removeFeeds
        let currentType = FeedFilterType.transform(number: filterType.rawValue)
        let isMessage = currentType == .message
        pushFeedPreview.updateFeeds.forEach { (_: String, pushFeedInfo: PushFeedInfo) in
            let feed = pushFeedInfo.feedPreview
            if pushFeedInfo.types.contains(currentType) {
                updateFeeds.append(feed)
            } else {
                missedFeeds[feed.id] = pushFeedInfo
            }
        }
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
        // 重置为非脏数据
        unMarkDirtyFeed(updateFeeds, trace: pushFeedPreview.trace)
        // 记录临时需要保存的脏数据
        markDirtyFeed(missedFeeds, trace: pushFeedPreview.trace)
    }

    // 当来了新的push&update时，之前被标记为dirty的feed，需要取消dirty记录
    func unMarkDirtyFeed(_ updateFeeds: [FeedPreview], trace: FeedListTrace) {
        let task = { [weak self] in
            guard let self = self else { return }
            guard self.isNeedMarkDirty() else { return }
            var logInfo: [String] = []
            updateFeeds.forEach { feed in
                if self.dirtyFeeds.remove(feed.id) != nil {
                    logInfo.append(feed.id)
                }
            }
            if !logInfo.isEmpty {
                FeedContext.log.info("feedlog/dataStream/dirtyFeed/unMarkDirtyFeed. \(self.listBaseLog), \(trace.description), \(logInfo)")
            }
        }
        commit(task)
    }

    // 记录不立即移除的feeds。条件为 inbox + 存在于当前filter下的列表中
    func markDirtyFeed(_ removeFeeds: [String: PushFeedInfo], trace: FeedListTrace) {
        let task = { [weak self] in
            guard let self = self else { return }
            var insertDirtyInfo = ""
            var removedFeedsInfo = ""
            var removeds = [String]()
            var updates = [FeedPreview]()
            let currentFilterType = self.filterType
            let isNeedMarkDirty = self.isNeedMarkDirty()
            removeFeeds.forEach { (_: String, feedInfo: PushFeedInfo) in
                var feed = feedInfo.feedPreview
                var isStillToUpdate = self.checkUpdate(isNeedMarkDirty: isNeedMarkDirty,
                                                       currentFilterType: currentFilterType,
                                                       feedPreview: feed,
                                                       feedInfo: feedInfo)

                if isStillToUpdate && currentFilterType == .message {
                    feed = self.tryUpdateHighPriorityField(feed: feed, trace: trace)
                }

                if isStillToUpdate {
                    // 不立即移除应该移除的feed，将待移除的feed存放在集合里，切tab时再移除
                    insertDirtyInfo.append("\(feed.id), ")
                    self.dirtyFeeds.insert(feed.id)
                    // dirty的Feed因为不能及时移除，需要照常更新
                    updates.append(feed)
                } else {
                    // 需要立即移除
                    if self.provider.getItemBy(id: feed.id) != nil {
                        removedFeedsInfo.append("\(feed.id), ")
                        removeds.append(feed.id)
                    }
                }
            }
            if !updates.isEmpty {
                let traceInfo = "\(self.listBaseLog), \(trace.description)"
                FeedContext.log.info("feedlog/dataStream/dirtyFeed/markDirtyFeed/insertDirtyFeeds. \(traceInfo), \(insertDirtyInfo)")
                let trace = FeedListTrace(traceId: trace.traceId, dataFrom: .pushTempUpdate)
                self.updateFeeds(updates, renderType: .none, trace: trace)
            }
            if !removeds.isEmpty {
                let traceInfo = "\(self.listBaseLog), \(trace.description)"
                FeedContext.log.info("feedlog/dataStream/dirtyFeed/markDirtyFeed/removeFeeds. \(traceInfo), \(removedFeedsInfo)")
                let trace = FeedListTrace(traceId: trace.traceId, dataFrom: .pushRemoveByTemp)
                self.removeFeedsOfUnsafe(removeds, renderType: .none, trace: trace)
            }
        }
        commit(task)
    }

    private func checkUpdate(isNeedMarkDirty: Bool,
                             currentFilterType: Feed_V1_FeedFilter.TypeEnum,
                             feedPreview: FeedPreview,
                             feedInfo: PushFeedInfo) -> Bool {
        var isStillToUpdate = false
        // 初步判断条件
        isStillToUpdate = isNeedMarkDirty
            && feedPreview.basicMeta.feedCardBaseCategory == .inbox
            && feedPreview.basicMeta.parentCardID.isEmpty

        guard isStillToUpdate, let localFeed = provider.getItemBy(id: feedPreview.id)?.feedPreview else {
            isStillToUpdate = false
            return isStillToUpdate
        }

        // 进一步判断unread的逻辑
        if currentFilterType == .unread {
            // 如果unread里，有未开启消息提醒的，需要立马移除
            isStillToUpdate = feedPreview.basicMeta.isRemind
        }
        return isStillToUpdate
    }

    private func tryUpdateHighPriorityField(feed: FeedPreview, trace: FeedListTrace) -> FeedPreview {
        guard let localFeed = self.provider.getItemBy(id: feed.id)?.feedPreview else {
            let traceInfo = "\(self.listBaseLog), \(trace.description)"
            let errorMsg = "local feed isn't exist. \(traceInfo), \(feed.description)"
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
            FeedExceptionTracker.DataStream.dirtyFeed(node: .tryUpdateHighPriorityField, info: info)
            return feed
        }
        // 继续在message列表里更新逻辑：意味着之前的feed，是在message列表透出来的，此时需要继续更新这个feed，不能从message列表里移除，并且需要将atInfo或者urgentInfo赋值给新的feed
        let newFeed = feed
        return newFeed
    }

    // 当某条消息变成已读后暂时保留，用户离开当前tab后再回来才自动清除
    func removeDirtyFeed() {
        let task = { [weak self] in
            guard let self = self else { return }
            guard !self.isActive && self.isSupportDelayRemove() else { return }
            guard !self.dirtyFeeds.isEmpty else { return }
            let dirtyFeedIds = self.dirtyFeeds.map({ $0 })
            let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .switchGroup)
            let traceInfo = "\(self.listBaseLog), \(trace.description)"
            FeedContext.log.info("feedlog/dataStream/dirtyFeed/removeDirtyFeed. \(traceInfo), \(dirtyFeedIds)")
            self.removeFeedsOfUnsafe(dirtyFeedIds, renderType: .none, trace: trace)
            self.dirtyFeeds.removeAll()
        }
        commit(task)
    }

    private func isNeedMarkDirty() -> Bool {
        if isActive && isSupportDelayRemove() {
            return true
        }
        return false
    }
}
