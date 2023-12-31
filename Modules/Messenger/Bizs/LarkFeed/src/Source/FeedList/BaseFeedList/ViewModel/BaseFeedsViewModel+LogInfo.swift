//
//  BaseFeedsViewModel+LogInfo.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/12.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import RxDataSources

extension BaseFeedsViewModel {
    var listContextLog: String {
        // 不需要复杂计算，不涉及线程安全，描述列表整体概况
        return "\(listBaseLog), "
        + "hasMore: \(hasMoreFeeds()), "
        + "isSuspendedQueue: \(isQueueSuspended())"
        // + "selectedID: \(getSelectedID()")
    }

    var listBaseLog: String {
        return "filterType: \(getFilterType()), "
        + "isActive: \(getActiveState())"
    }

    func getFilterType() -> Feed_V1_FeedFilter.TypeEnum {
        guard let feedVM = self as? FeedListViewModel else { return .unknown }
        return feedVM.filterType
    }

    func getFeedType() -> Basic_V1_FeedCard.FeedType {
        guard let feedVM = self as? FeedListViewModel else { return .unknown }
        return feedVM.feedType()
    }

    func getUnreadFeeds(_ items: [FeedCardCellViewModel]) -> [FeedCardCellViewModel] {
        return items.filter({ $0.feedPreview.basicMeta.isRemind && $0.feedPreview.basicMeta.unreadCount > 0 })
    }

    func getActiveState() -> Bool {
        guard let feedVM = self as? FeedListViewModel else { return true }
        return feedVM.isActive
    }

    func tracklogForOutput(data: SectionHolder) {
        let changedIds = data.changedIds
        let indexMap = data.indexMap
        let totalItems = data.items
        var logInfo = ""
        var hasError = false
        switch data.dataCommand {
        case .none: break
        case .insertOrUpdate:
            var updateFailedIds: [String] = []
            let changedFeeds = changedIds.compactMap({ id -> String? in
                guard let index = indexMap[id],
                      index < totalItems.count else {
                    updateFailedIds.append(id)
                    return nil
                }
                let f = totalItems[index]
                return f.feedPreview.minDesc
            })
            hasError = !updateFailedIds.isEmpty
            logInfo = "updateFeeds: \(changedFeeds), updateFailedIds: \(updateFailedIds)"
        case .remove:
            var deleteFailedIds: [String] = []
            changedIds.forEach { id in
                if indexMap[id] != nil {
                    deleteFailedIds.append(id)
                    return
                }
            }
            hasError = !deleteFailedIds.isEmpty
            logInfo = "deleteFailedIds: \(deleteFailedIds)"
        }
        let logs = logInfo.logFragment()
        for i in 0..<logs.count {
            let log = logs[i]
            let result = hasError ? "fail" : "success"
            let info = "feedlog/dataStream/output/\(result)<\(i)>. \(listContextLog), \(data.description), \(data.trace.description). \(log)"
            if hasError {
                let errorMsg = "\(result)<\(i)>, \(listContextLog), \(data.description), \(data.trace.description). \(log)"
                let info = FeedBaseErrorInfo(type: .error(track: false), errorMsg: errorMsg)
                FeedExceptionTracker.DataStream.output(node: .tracklogForOutput, info: info)
            } else {
                FeedContext.log.info(info)
            }
        }
    }

    func tracklogDiffRender(diffResult: SectionHolderDiff, diff: Changeset<SectionHolder>, traceInfo: String) {
        guard self.isTracklog else { return }
        guard let dataSource = diff.finalSections.first?.items else {
            let errorMsg = "ignorelog, \(traceInfo)"
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
            FeedExceptionTracker.DataStream.render(node: .diff, info: info)
            return
        }
        let task = {
            let deletedItems = diffResult.deletedItems.compactMap({ indexpath -> String? in
                if indexpath.row < dataSource.count {
                    return dataSource[indexpath.row].feedPreview.id
                }
                return nil
            })

            let insertedItems = diffResult.insertedItems.compactMap({ indexpath -> String? in
                if indexpath.row < dataSource.count {
                    return dataSource[indexpath.row].feedPreview.description
                }
                return nil
            })

            let updatedItems = diffResult.updatedItems.compactMap({ indexpath -> String? in
                if indexpath.row < dataSource.count {
                    return dataSource[indexpath.row].feedPreview.minDesc
                }
                return nil
            })

            let movedItems = diffResult.movedItems.compactMap({ (from: Differentiator.ItemPath, to: Differentiator.ItemPath) -> (String?, String?) in
                let fromIndex = from.itemIndex
                let toIndex = to.itemIndex
                var result: (String?, String?) = (nil, nil)
                if fromIndex < dataSource.count {
                    result.0 = dataSource[fromIndex].feedPreview.id
                }
                if toIndex < dataSource.count {
                    result.1 = dataSource[toIndex].feedPreview.id
                }
                return result
            })
            let logInfo = "deleted: \(deletedItems.count), \(deletedItems); "
            + "inserted: \(insertedItems.count), \(insertedItems); "
            + "moved: \(movedItems.count), \(movedItems); "
            + "updated: \(updatedItems.count), \(updatedItems)"
            let logs = logInfo.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                FeedContext.log.info("feedlog/dataStream/render/diff/success/verbose/<\(i)>. \(traceInfo), \(log)")
            }
        }
        addLogTask(task)
    }

    func tracklogCurrentCell(cell: UIView, indexPath: IndexPath, cellVM: FeedCardCellViewModel?, feedCardVM: FeedCardCellViewModel, trace: FeedListTrace) {
        guard self.isTracklog else { return }
        guard indexPath.row < FeedLogCons.firstPageCount else { return }
        let logInfo = "\(self.listBaseLog), \(trace.description)"
        let task = {
            if let cellVM = cellVM {
                FeedContext.log.info("feedlog/dataStream/onscreen/cellForRow. \(logInfo), row: \(indexPath.row), \(cellVM.feedPreview.simpleDesc)")
            } else {
                let errorMsg = "lose, \(logInfo), row: \(indexPath.row)"
                let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
                FeedExceptionTracker.DataStream.onscreen(node: .cellForRow, info: info)
            }
        }
        addLogTask(task)
    }

    func tracklogVisibleFeeds(_ feeds: [FeedPreview], isUIDataSource: Bool, trace: FeedListTrace) {
        var logInfo = "\(self.listBaseLog), "
        let task = {
            logInfo.append("\(feeds.map({ $0.simpleDesc }))")
            let from: String
            if isUIDataSource {
                from = "visibleCell"
            } else {
                from = "visibleFeeds"
            }
            let logs = logInfo.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                FeedContext.log.info("feedlog/dataStream/onscreen/stopScroll/\(from)/<\(i)>. \(trace.description), \(log)")
            }
        }
        addLogTask(task)
    }

    func addLogTask(_ task: @escaping () -> Void) {
        logQueue.addOperation(task)
    }

    enum FeedLogCons {
        static let firstPageCount: Int = 20 // 首屏feed数估算为20
    }
}
