//
//  BaseFeedsViewModel+DataHandler.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/24.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import LarkModel
import AppReciableSDK
import LarkOpenFeed
import LarkContainer

// MARK: - 数据源操作
extension BaseFeedsViewModel {

    /// 更新Feed
    /// feeds为[]，将直接触发一次reload
    func _updateFeeds(_ feeds: [FeedPreview], renderType: FeedRenderType, trace: FeedListTrace) {
        commit { [weak self] in
            guard let self = self else { return }
            let filterType = self.getFilterType()
            let traceInfo = "\(self.listBaseLog), \(trace.description)"
            var logInfo = "inputFeedsCount: \(feeds.count), renderType: \(renderType)"
            // 如果feeds为[]，直接触发一次reload
            guard !feeds.isEmpty else {
                FeedContext.log.info("feedlog/dataStream/updateFeeds/empty. \(traceInfo), \(logInfo)")
                self.fireRefresh(renderType: renderType, trace: trace)
                return
            }

            // 更新总数据源
            var updatedVMs = [FeedCardCellViewModel]()
            // 提前为vm数组预留空间, 避免多次空间分配，提高性能
            updatedVMs.reserveCapacity(feeds.count)

            var oldVMs: [String] = []
            var errorVMs: [String] = []
            feeds.forEach { feed in
                if FeedPreviewCheckerService.checkIfInvalidFeed(feed.id, feed.basicMeta.checker, self.userResolver.userID) {
                    errorVMs.append(feed.id)
                    return
                }

                if let oldFeed = self.provider.getItemBy(id: feed.id), feed.basicMeta.updateTime < oldFeed.feedPreview.basicMeta.updateTime {
                    // 如果新到来的feed比端上cache里对应的老feed的updateTime小，则丢弃
                    oldVMs.append(feed.id)
                    return
                }

                if let removeTime = self.removedFeeds[feed.id], feed.basicMeta.updateTime < removeTime {
                    // 如果新到来的feed比端上cache里对应的老feed的updateTime小，则丢弃
                    oldVMs.append(feed.id)
                    return
                }
                guard let cellVM = FeedCardCellViewModel.build(
                                feedPreview: feed,
                                userResolver: self.userResolver,
                                feedCardModuleManager: self.feedCardModuleManager,
                                bizType: self.bizType,
                                filterType: filterType,
                                extraData: [:]) else {
                    return
                }

                // 上报Feed状态更新
                if let oldFeed = self.provider.getItemBy(id: feed.id),
                   feed.basicMeta.updateTime >= oldFeed.feedPreview.basicMeta.updateTime {
                    FeedTracker.Status.update(oldViewModel: oldFeed,
                                              newFeedModel: cellVM,
                                              basicData: cellVM.basicData,
                                              bizData: cellVM.bizData)
                }
                self.configureCellVMForPad(cellVM)
                // 暂存更新的VM, 以供批量更新Provider数据源
                updatedVMs.append(cellVM)
            }

            if !errorVMs.isEmpty {
                let errorMsg = "\(traceInfo), \(logInfo), ids: \(errorVMs)"
                let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
                FeedExceptionTracker.DataStream.updateFeeds(node: .checkErrorFeeds, info: info)
            }

            if !oldVMs.isEmpty {
                let errorMsg = "\(traceInfo), \(logInfo), ids: \(oldVMs)"
                let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
                FeedExceptionTracker.DataStream.updateFeeds(node: .checkOldFeeds, info: info)
            }
            guard !updatedVMs.isEmpty else {
                FeedContext.log.info("feedlog/dataStream/updateFeeds/checkEmpty. \(traceInfo), \(logInfo)")
                return
            }
            logInfo.append(", updateCount: \(updatedVMs.count), \(updatedVMs.map({ $0.feedPreview.id }))")
            let logs = logInfo.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                FeedContext.log.info("feedlog/dataStream/updateFeeds/success/<\(i)>. \(traceInfo), \(log)")
            }
            // 更新数据源项
            self.provider.updateItems(updatedVMs)
            self.fireRefresh(renderType: renderType, dataCommand: .insertOrUpdate, changedIds: updatedVMs.map({ $0.feedPreview.id }), trace: trace)
        }
    }

    /// 删除Feed
    /// ids为[]时，忽略；若要直接触发reload，使用updateFeeds
    func removeFeedsOfUnsafe(_ ids: [String], renderType: FeedRenderType, trace: FeedListTrace) {
        removeFeeds(ids.map({ PushRemoveFeed(feedId: $0) }), renderType: renderType, trace: trace)
    }

    /// feeds为[]时，忽略；若要直接触发reload，使用updateFeeds
    func removeFeeds(_ feeds: [PushRemoveFeed], renderType: FeedRenderType, trace: FeedListTrace) {
        guard !feeds.isEmpty else { return }
        commit { [weak self] in
            guard let self = self else { return }
            var ids: [String] = []
            var removeIds: [String] = []
            var oldIds: [String] = []
            var errorIds: [String] = []

            feeds.forEach { feed in
                ids.append(feed.feedId)
                if FeedPreviewCheckerService.checkIfInvalidFeed(feed.feedId, feed.checker, self.userResolver.userID) {
                    errorIds.append(feed.feedId)
                    tryMarkRemove(id: feed.feedId)
                    return
                }

                if feed.updateTime == FeedLocalCode.invalidUpdateTime {
                    // 旧逻辑直接删除
                    // 暂存删除的ids, 以供批量删除Provider数据源
                    tryMarkRemove(id: feed.feedId)
                } else {
                    // 新逻辑先判断再删除
                    if let oldFeed = self.provider.getItemBy(id: feed.feedId), feed.updateTime < oldFeed.feedPreview.basicMeta.updateTime {
                        // 如果新到来的feed比端上cache里对应的老feed的updateTime小，则丢弃
                        oldIds.append(feed.feedId)
                        return
                    }

                    if let removeTime = self.removedFeeds[feed.feedId], feed.updateTime < removeTime {
                        // 如果新到来的feed比端上cache里对应的老feed的updateTime小，则丢弃
                        oldIds.append(feed.feedId)
                        return
                    }

                    // 暂存删除的ids, 以供批量删除Provider数据源
                    tryMarkRemove(id: feed.feedId)
                    // 更新缓存的数据
                    self.removedFeeds[feed.feedId] = feed.updateTime
                }
            }

            let logInfo = "\(self.listBaseLog), "
                + "\(trace.description), "
                + "renderType: \(renderType), "
                + "originCount: \(ids.count)"

            if !errorIds.isEmpty {
                let errorMsg = "\(logInfo), errorIds: \(errorIds.count), \(errorIds)"
                let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
                FeedExceptionTracker.DataStream.removeFeeds(node: .checkErrorFeeds, info: info)
            }

            if !oldIds.isEmpty {
                let errorMsg = "\(logInfo), oldIds: \(oldIds.count), \(oldIds)"
                let info = FeedBaseErrorInfo(type: .warning(), errorMsg: errorMsg)
                FeedExceptionTracker.DataStream.removeFeeds(node: .checkOldFeeds, info: info)
            }

            func tryMarkRemove(id: String) {
                if self.provider.getItemBy(id: id) != nil {
                    removeIds.append(id)
                }
            }
            guard !removeIds.isEmpty else {
                FeedContext.log.info("feedlog/dataStream/removeFeeds/empty. \(logInfo)")
                return
            }
            FeedContext.log.info("feedlog/dataStream/removeFeeds/success. \(logInfo), removeIdsCount: \(removeIds.count), \(removeIds)")
            // 删除数据源项
            self.provider.removeItems(removeIds)
            self.fireRefresh(renderType: renderType, dataCommand: .remove, changedIds: removeIds, trace: trace)
        }
    }

    /// 删除所有Feed
    func removeAllFeeds(renderType: FeedRenderType, trace: FeedListTrace) {
        commit { [weak self] in
            guard let self = self else { return }
            // 清空数据源
            let logInfo = "\(self.listBaseLog), "
                + "\(trace.description), "
                + "renderType: \(renderType)"
            FeedContext.log.info("feedlog/dataStream/removeFeeds/all. \(logInfo)")
            self.provider.removeAllItems()
            self.fireRefresh(renderType: renderType, trace: trace)
        }
    }

    /// private是因为不希望外部直接使用，要触发Feed更新，都应该通过updateFeeds和removeFeeds
    func fireRefresh(renderType: FeedRenderType, dataCommand: SectionHolder.DataCommand = .none, changedIds: [String] = [], trace: FeedListTrace) {
        // 如果type为ignore，表示只更新总数据源，不刷新UI，也不更新UI数据
        guard renderType != .ignore else {
            let traceInfo = "\(self.listContextLog), "
                + "\(trace.description)"
            let logInfo = "renderType: \(renderType), "
                + "changedIdsCount: \(changedIds.count), "
                + "changedIds: \(changedIds)"
            let logs = logInfo.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                FeedContext.log.info("feedlog/dataStream/output/ignore/<\(i)>. \(traceInfo), \(log)")
            }
            return
        }

        var section = SectionHolder()
        section.renderType = renderType
        section.trace = trace
        section.dataCommand = dataCommand
        section.changedIds = changedIds
        var tempTopIds: [String] = []
        let itemsArray = provider.getItemsArray().filter {
            let isVisible = self.displayFilter($0)
            if isVisible, $0.basicData.isTempTop {
                tempTopIds.append($0.feedPreview.id)
            }
            return isVisible
        }
        section.tempTopIds = tempTopIds
        let items = self.handleCustomFeedSort(items: itemsArray, dataStore: section, trace: trace)
        var indexMap: [String: Int] = [:]
        for i in 0..<items.count {
            let feed = items[i]
            indexMap[feed.feedPreview.id] = i
        }
        section.items = items
        section.indexMap = indexMap
        tracklogForOutput(data: section)
        self.feedsRelay.accept(section)
    }

    func checkHasMoreFeeds(cursor: FeedCursor?) -> Bool {
        // 如果nextCursor还未加载，无任何数据，也不表示有更多feeds，不显示加载更多
        guard let cursor = cursor else { return false }
        return cursor != FeedCursor.min
    }
}
