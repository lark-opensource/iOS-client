//
//  FeedListViewModel+DisplayRule.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/10/12.
//

import Foundation
import LarkModel
import LarkUIKit
import RustPB
import LarkSDKInterface
import LarkOpenFeed

// tempIDs的影响updateOrRemove和切分组逻辑，关系到feed是更新还是移除
// 1. 当本地分组列表不存在目标feed时：tempIds或者tempRemoveIds里是否存在该feed，对结果没有影响，因为【本地分组列表存在目标feed】和其他条件是 且 的关系
// 2. 当本地分组列表存在目标feed时：
//     1. 如果tempIds里有不应该存在的feed时：
//         1. 在执行updateOrRemove时，会继续存在，并且错误的继续向TempRemoveIds插值
//         2. 在执行切分组逻辑时：会继续存在 或者 会立即移除
//     2. 如果tempIds里缺失应该存在的feed时：
//         1. 在执行updateOrRemove时，会立即移除
//         2. 在执行切分组逻辑时：会继续存在

// tempIds -> 临时工
// update -> 正式工
// remove -> 被解雇
// updateOrRemove -> 临时继续工作或者立即被解雇
//
// TODO：
// 1. get 接口，需要明确返回 updateIDs

extension FeedListViewModel {
    // 补充注释：需要对顺序进一步说明
    /*
     canTemp ids：
     * insert：
         * canTemp action
         * getFeed.temp
         * getNextUnread.temp
     * delete：
         * update action
         * remove action
         * 切 tab（前置条件：tempOrRemove ids里有，并且端上有这个feed）

     tempOrRemove ids：
     * insert：
         * tempOrRemove action（前置条件：端上有这个feed，并且canTemp Ids里有），才可insert
     * delete：
         * canTemp.insert
         * canTemp.delete
         * 切 tab（前置条件：tempOrRemove ids里有，并且端上有这个feed）
     */
    func handleFeedFromPushFeedByOpt(_ pushFeedPreview: PushFeedPreview) {
        guard authData(verifyKey: pushFeedPreview.feedRuleMd5, trace: pushFeedPreview.trace) else { return }
        let currentType = FeedFilterType.transform(number: filterType.rawValue)
        let updateFeeds = pushFeedPreview.updateFeeds.compactMap({
            if $0.value.types.contains(currentType) {
                return $0.value.feedPreview
            }
            return nil
        })
        let removeFeeds = pushFeedPreview.removeFeeds.filter({ $0.types.contains(currentType) })

        if !updateFeeds.isEmpty {
            let trace = FeedListTrace(traceId: pushFeedPreview.trace.traceId, dataFrom: .pushUpdate)
            self.updateFeeds(updateFeeds, renderType: .none, trace: trace)
        }

        if !removeFeeds.isEmpty {
            let trace = FeedListTrace(traceId: pushFeedPreview.trace.traceId, dataFrom: .pushRemove)
            self.removeFeeds(removeFeeds, renderType: .none, trace: trace)
        }

        if self.isSupportDelayRemove() {
            // 更新透传的feed
            let tempFeeds = pushFeedPreview.tempFeeds.compactMap({
                if $0.value.types.contains(currentType) {
                    return $0.value.feedPreview
                }
                return nil
            })
            if !tempFeeds.isEmpty {
                let trace = FeedListTrace(traceId: pushFeedPreview.trace.traceId, dataFrom: .pushTempUpdate)
                self.updateFeeds(tempFeeds, renderType: .none, trace: trace)
            }

            // 重置为非temp数据(包括 update + remove)
            let traceOfPushUpdate = FeedListTrace(traceId: pushFeedPreview.trace.traceId, dataFrom: .pushUpdate)
            unMarkTempFeed(feedIds: updateFeeds.map({ $0.id }), trace: traceOfPushUpdate, checkExpire: { id in
                self.provider.getItemBy(id: id) != nil
            })
            let traceOfPushRemove = FeedListTrace(traceId: pushFeedPreview.trace.traceId, dataFrom: .pushRemove)
            unMarkTempFeed(feedIds: removeFeeds.map({ $0.feedId }), trace: traceOfPushRemove, checkExpire: { id in
                self.provider.getItemBy(id: id) == nil
            })
            // 记录需要保存的temp数据
            let traceofPushTempUpdate = FeedListTrace(traceId: pushFeedPreview.trace.traceId, dataFrom: .pushTempUpdate)
            markTempfeedIds(ids: tempFeeds.map({ $0.id }), trace: traceofPushTempUpdate)
            // 更新或移除待定的feed
            let updateOrRemoveFeeds = pushFeedPreview.updateOrRemoveFeeds.filter({ $0.value.types.contains(currentType) })
            updateOrRemoveTempFeed(updateOrRemoveFeeds, trace: pushFeedPreview.trace)
        }
    }

    // 取消标记透出的feed。当执行 update ｜ remove 操作时，之前被标记为temp的feed，需要取消temp记录，即从tempIds+tempRemoveIds里删除
    private func unMarkTempFeed(feedIds: [String], trace: FeedListTrace, checkExpire: @escaping ((String) -> Bool)) {
        guard !feedIds.isEmpty else { return }
        let task = { [weak self] in
            // 防止有过期数据，需要先判断下本地是否有
            let ids = feedIds.filter({ checkExpire($0) })
            self?.removeTempIds(ids, trace: trace)
        }
        commit(task)
    }

    // 标记透出的feed。前提条件：本地存在（防止本次是过期数据），记录透出的feed
    func markTempfeedIds(ids: [String], trace: FeedListTrace) {
        guard self.isSupportDelayRemove() else { return }
        guard !ids.isEmpty else { return }
        let task = { [weak self] in
            guard let self = self else { return }
            self.insertTempIds(ids, trace: trace)
        }
        commit(task)
    }

    // 1. 本地feed列表不存在该feed：空操作
    // 2. 本地feed列表存在该feed：
    //    2.1 如果tempIds里有，则继续更新，并向tempRemoveIds插入值
    //    2.2 如果tempIds里没有，则立即删除，并从tempIds+tempRemoveIds里删除
    private func updateOrRemoveTempFeed(_ updateOrRemoveFeeds: [String: PushFeedInfo], trace: FeedListTrace) {
        guard !updateOrRemoveFeeds.isEmpty else { return }
        let task = { [weak self] in
            guard let self = self else { return }
            var temps = [FeedPreview]()
            var removeds: [PushRemoveFeed] = []
            updateOrRemoveFeeds.forEach { (_, pushFeed) in
                let feedId = pushFeed.feedPreview.id
                // 本地feed列表不存在该feed：空操作
                guard self.provider.getItemBy(id: feedId)?.feedPreview != nil else { return }
                if self.isActive && self.dirtyFeeds.contains(feedId) {
                    temps.append(pushFeed.feedPreview)
                } else {
                    let removeFeed = PushRemoveFeed(feedId: feedId, updateTime: pushFeed.feedPreview.basicMeta.updateTime)
                    removeds.append(removeFeed)
                }
            }
            if !temps.isEmpty {
                let trace = FeedListTrace(traceId: trace.traceId, dataFrom: .pushUpdateByTemp)
                self.insertTempRemoveIds(temps.map({ $0.id }), trace: trace)
                self.updateFeeds(temps, renderType: .none, trace: trace)
            }
            if !removeds.isEmpty {
                let trace = FeedListTrace(traceId: trace.traceId, dataFrom: .pushRemoveByTemp)
                self.removeTempIds(removeds.map { $0.feedId }, trace: trace)
                self.removeFeeds(removeds, renderType: .none, trace: trace)
            }
        }
        commit(task)
    }

    // 移除透出的feed。前提条件是本地存在+tempRemoveIds里存在。并且从feed列表移除完后，还需要从tempIDs+tempRemoveIds移除
    func removeTempFeed() {
        guard self.isSupportDelayRemove() else { return }
        let task = { [weak self] in
            guard let self = self, !self.tempRemoveIds.isEmpty else { return }
            let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .switchGroup)
            var tempRemoveIds: [String] = []
            self.tempRemoveIds.forEach { id in
                tempRemoveIds.append(id)
            }
            self.removeTempIds(tempRemoveIds, trace: trace)
            let tempRemoveFeeds = tempRemoveIds.compactMap({ [weak self] feedId -> PushRemoveFeed? in
                if let localFeed = self?.provider.getItemBy(id: feedId)?.feedPreview {
                    return PushRemoveFeed(feedId: feedId, updateTime: localFeed.basicMeta.updateTime)
                }
                return nil
            })
            guard !tempRemoveFeeds.isEmpty else { return }
            self.removeFeeds(tempRemoveFeeds, renderType: .none, trace: trace)
        }
        commit(task)
    }
}

// MARK: 对 tempIds 和 tempRemoveIds 的增删
extension FeedListViewModel {
    private func insertTempIds(_ ids: [String], trace: FeedListTrace) {
        var tempIds: [String] = []
        var tempRemoveIds: [String] = []
        ids.forEach { feedId in
            // 防止tempfeedIds里有过期数据，需要先判断下本地是否有
            if self.provider.getItemBy(id: feedId)?.feedPreview != nil {
                // 避免重复插入
                if !self.dirtyFeeds.contains(feedId) {
                    self.dirtyFeeds.insert(feedId)
                    tempIds.append(feedId)
                }
                if self.tempRemoveIds.remove(feedId) != nil {
                    tempRemoveIds.append(feedId)
                }
            }
        }
        if !tempIds.isEmpty {
            let traceInfo = "\(self.listBaseLog), \(trace.description)"
            FeedContext.log.info("\(logHead)/insertTempIds. \(traceInfo), tempCount: \(self.dirtyFeeds.count), tempIds: \(tempIds)")
        }

        if !tempRemoveIds.isEmpty {
            let traceInfo = "\(self.listBaseLog), \(trace.description)"
            FeedContext.log.info("\(logHead)/insertTempIds/removeTempRemoveIds. \(traceInfo), tempRemoveCount: \(self.tempRemoveIds.count), tempRemoveIds: \(tempRemoveIds)")
        }
    }

    // 从 tempfeedIds 里删除时，也要从tempRemoveIds里删除
    private func removeTempIds(_ ids: [String], trace: FeedListTrace) {
        var tempIds: [String] = []
        var tempRemoveIds: [String] = []
        ids.forEach { id in
            if self.dirtyFeeds.remove(id) != nil {
                tempIds.append(id)
            }
            if self.tempRemoveIds.remove(id) != nil {
                tempRemoveIds.append(id)
            }
        }
        let traceInfo = "\(self.listBaseLog), \(trace.description)"
        if !tempIds.isEmpty {
            FeedContext.log.info("\(logHead)/removeTempIds. \(traceInfo), tempCount: \(self.dirtyFeeds.count), tempIds: \(tempIds)")
        }
        if !tempRemoveIds.isEmpty {
            FeedContext.log.info("\(logHead)/removeTempIds/removeTempRemoveIds. \(traceInfo), tempRemoveCount: \(self.tempRemoveIds.count), tempRemoveIds: \(tempRemoveIds)")
        }
    }

    private func insertTempRemoveIds(_ ids: [String], trace: FeedListTrace) {
        var tempRemoveIds: [String] = []
        ids.forEach { feedId in
            if !self.tempRemoveIds.contains(feedId) {
                self.tempRemoveIds.insert(feedId)
                tempRemoveIds.append(feedId)
            }
        }
        if !tempRemoveIds.isEmpty {
            let traceInfo = "\(self.listBaseLog), \(trace.description)"
            FeedContext.log.info("\(logHead)/insertTempRemoveIds. \(traceInfo), tempRemoveCount: \(self.tempRemoveIds.count), tempRemoveIds: \(tempRemoveIds)")
        }
    }

    var logHead: String {
        return "feedlog/dataStream/tempFeed"
    }
}

extension FeedListViewModel {
    func isSupportDelayRemove() -> Bool {
        guard let removeMode = FeedFilterTabSourceFactory.source(for: filterType)?.removeMode else { return false }
        switch removeMode {
        case .immediate: return false
        case .delay: return true
        }
    }
}
