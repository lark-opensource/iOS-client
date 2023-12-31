//
//  BaseFeedsViewController+DiffReload.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/20.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import EENavigator
import RxDataSources
import LarkSDKInterface
import LarkMessengerInterface
import LarkSwipeCellKit
import UniverseDesignToast
import LKCommonsLogging
import LarkKeyCommandKit
import LarkPerf
import AppReciableSDK
import LarkZoomable
import LarkModel
import LarkSceneManager
import UniverseDesignEmpty

extension BaseFeedsViewController {
    static let diffMaxCount = 50
    func diff(section: SectionHolder, renderType: UITableView.RowAnimation?) {
        let traceInfo = "\(self.feedsViewModel.listContextLog), \(section.trace.description)"
        guard preJudgeShouldDiff(traceInfo: traceInfo) else {
            self.setItems([section], originalRenderType: section.renderType)
            return
        }
        let oldItems = feedsViewModel.allItems()
        var oldSection = SectionHolder()
        oldSection.items = oldItems
        do {
            let diffs = try Diff.differencesForSectionedView(initialSections: [oldSection], finalSections: [section])
            guard !diffs.isEmpty else {
                FeedContext.log.info("feedlog/dataStream/render/diff/empty. \(traceInfo)")
                return
            }
            for diff in diffs {
                // diffs可能有多次，需要注意finalSections可能与传入的section不一致，
                // 更新数据源应取finalSections，否则会造成动画crash
                let newData = diff.finalSections
                // 思考: 是否将shouldDiff放在updateBlock里更合适，或者在updateBlock再做一次检查
                guard let result = shouldDiff(diff: diff, traceInfo: traceInfo) else {
                    self.setItems(newData, originalRenderType: section.renderType)
                    continue
                }
                self.trace = section.trace
                self.feedsViewModel.tracklogDiffRender(diffResult: result, diff: diff, traceInfo: traceInfo)
                let renderType = renderType ?? .none
                let updateBlock = { [weak self] in
                    guard let self = self else { return }
                    self.feedsViewModel.setItems(newData)
                    self.tableView.deleteRows(at: result.deletedItems, with: renderType)
                    self.tableView.insertRows(at: result.insertedItems, with: renderType)
                    self.tableView.reloadRows(at: result.updatedItems, with: renderType)
                    result.movedItems.forEach { (from, to) in
                        self.tableView.moveRow(at: IndexPath(item: from.itemIndex, section: from.sectionIndex), to: IndexPath(item: to.itemIndex, section: to.sectionIndex))
                    }
                }
                if section.renderType == .none {
                    // 去掉隐式动画，即使设置RowAnimation为none，还是会有动画
                    UIView.performWithoutAnimation { self.tableView.performBatchUpdates(updateBlock, completion: nil) }
                } else {
                    self.tableView.performBatchUpdates(updateBlock, completion: nil)
                }
                self.feedsViewModel.feedsUpdated.onNext(())
            }
        } catch let error {
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: traceInfo, error: error)
            FeedExceptionTracker.DataStream.render(node: .diff, info: info)
            self.setItems([section], originalRenderType: section.renderType)
        }
    }

    private func preJudgeShouldDiff(traceInfo: String) -> Bool {
        let isForbidiff = feedsViewModel.isForbidiff
        if isScrolling || isForbidiff {
           FeedContext.log.info("feedlog/dataStream/render/diff/forbid. \(traceInfo), isScrolling: \(isScrolling), isForbidiff: \(isForbidiff)")
           return false
       }
       return true
   }

    private func shouldDiff(diff: Changeset<SectionHolder>, traceInfo: String) -> SectionHolderDiff? {
        if !isDiffValid(diff: diff, traceInfo: traceInfo) {
            // Diff非法，直接reload
            return nil
        }

        guard let result = self.getDiffResult(diff: diff, traceInfo: traceInfo) else {
            return nil
        }
        return result
    }

    // 需要确保insert/delete之后的cell count和finalSection数量相等，否则performBatchUpdates会crash
    // NSInternalInconsistencyException: Invalid update
    private func isDiffValid(diff: Changeset<SectionHolder>, traceInfo: String) -> Bool {
        let newSection = diff.finalSections
        let newSectionCount = newSection.count
        let oldSectionCount = self.tableView.numberOfSections
        guard newSectionCount == oldSectionCount else {
            let errorMsg = "invalid1 \(traceInfo), \(newSectionCount) -> \(oldSectionCount)"
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
            FeedExceptionTracker.DataStream.render(node: .diff, info: info)

            return false
        }
        for index in 0..<newSectionCount {
            let change = diff.insertedItems.count - diff.deletedItems.count
            if newSection[index].items.count != self.tableView.numberOfRows(inSection: index) + change {
                let errorMsg = "invalid2 \(traceInfo), \(diff) -> \(self.tableView.numberOfRows(inSection: index))"
                let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
                FeedExceptionTracker.DataStream.render(node: .diff, info: info)
                return false
            }
        }
        return true
    }

    private func getDiffResult(diff: Changeset<SectionHolder>, traceInfo: String) -> SectionHolderDiff? {
        let deletedItems = diff.deletedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) }
        let insertedItems = diff.insertedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) }
        let updatedItems = diff.updatedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) }
        let deletedCount = deletedItems.count
        let insertCount = insertedItems.count
        let updateCount = updatedItems.count
        let moveCount = diff.movedItems.count
        let state: Bool
        var logInfo = "delete: \(deletedItems.count), "
            + "insert: \(insertedItems.count), "
            + "update: \(updatedItems.count), "
            + "move: \(diff.movedItems.count)"
        defer {
            FeedContext.log.info("feedlog/dataStream/render/diff/\(state ? "success" : "giveup"). \(traceInfo), \(logInfo)")
        }
        if deletedCount > Self.diffMaxCount || insertCount > Self.diffMaxCount || updateCount > Self.diffMaxCount || moveCount > Self.diffMaxCount {
            state = false
            return nil
        }
        state = true
        var result = SectionHolderDiff()
        result.insertedItems = insertedItems
        result.deletedItems = deletedItems
        result.updatedItems = updatedItems
        result.movedItems = diff.movedItems
        return result
    }
}
