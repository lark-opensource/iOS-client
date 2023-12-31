//
//  ShortcutsCollectionView+Reload.swift
//  LarkFeed
//
//  Created by bitingzhu on 2020/7/10.

import UIKit
import Foundation

extension ShortcutsCollectionView {
    /// 对collectionView执行更新
    func applyUpdate(_ update: ShortcutViewModelUpdate) {
        guard let viewReloadCommand = update.viewReloadCommand else {
            FeedContext.log.info("feedlog/shortcut/dataflow/render/nofound")
            return
        }

        // 根据不同的刷新命令执行对应的刷新逻辑
        switch viewReloadCommand {
        case .full:
            // 全量刷新
            self.performBatchUpdates({ [weak self] in
                self?.fullReload()
            }, completion: nil)
        case .skipped:
            FeedContext.log.info("feedlog/shortcut/dataflow/render/skip")
            // 无需刷新
            break
        case let .partial(changeset):
            guard !self.indexPathsForVisibleItems.isEmpty else {
                // 兜底逻辑：当UI列表没有cell时，numberOfItems计算会错误，会调用UICollectionViewDataSource里的numberOfItemsInSection方法，而不是真正的获取UI列表上的cells个数
                FeedContext.log.info("feedlog/shortcut/dataflow/render/partial. invalid diff, falling back to full reload")
                // 兜底全量刷新
                self.performBatchUpdates({ [weak self] in
                    self?.fullReload()
                }, completion: nil)
                return
            }

            UIView.performWithoutAnimation {
                // 某类型操作为空则跳过
                self.performBatchUpdates({
                    // 确认Diff操作过后数据源数量前后一致, 兜底逻辑
                    guard isValidDiff(update: update, changeset: changeset) else {
                        // 兜底全量刷新
                        fullReload()
                        return
                    }
                    configureSkipIndexPaths()
                    if !changeset.delete.isEmpty {
                        self.deleteItems(at: changeset.delete)
                    }
                    if !changeset.reload.isEmpty {
                        self.reloadItems(at: changeset.reload)
                    }
                    if !changeset.insert.isEmpty {
                        self.insertItems(at: changeset.insert)
                    }
                }, completion: nil)
            }
        }
    }

    /// 通用的全量刷新逻辑
    func fullReload() {
        /*
        直接调用reload时，cell会有个隐式动画效果，打算使用禁止动画的api，但发现使用后引入了新的闪烁问题。

        下面列出了四种禁止动画的api
         * performWithoutAnimation，不起作用，闪烁非常明显；
         * UIView.setAnimationsEnabled(false)，不起作用，闪烁非常明显；
         * UIView.animate(withDuration: 0)，不闪烁了，但是完全没有动画，很生硬；
         * CATransaction.setDisableActions(true)，可以解决这个问题
         * 不使用这些api，cell会有个隐式动画效果，没有引入新的闪烁问题
         */

        //CATransaction.begin() // 加上这个会闪烁。。
        CATransaction.setDisableActions(true)
        // 在这里执行不希望有动画效果的代码
        self.configureSkipIndexPaths()
        self.collectionViewLayout.invalidateLayout()
        self.reloadSections(IndexSet(integer: 0))
        CATransaction.commit()

        FeedContext.log.info("feedlog/shortcut/dataflow/render/full. skipIndexPaths: \(self.moveLayout.skipIndexPaths)")
    }

    /// 设置空白逻辑
    private func configureSkipIndexPaths() {
        self.moveLayout.skipIndexPaths =
             self.viewModel.expanded ? [IndexPath(row: self.viewModel.itemMaxNumber - 1, section: 0)] : [] // 设置空白，取决于是否超出一行
    }

    /// 判断对原数据执行diff操作后, 数量符合预期, 等于最新数据量
    func isValidDiff(update: ShortcutViewModelUpdate,
                     changeset: ShortcutViewModelUpdate.Changeset) -> Bool {
        // UI展示的老数据个数
        let formerCount = numberOfItems(inSection: 0)
        // 将要展示的新数据个数
        let currentCount = ShortcutsViewModel.computeVisibleCount(update.snapshot.count,
                                                                  expanded: viewModel.expanded,
                                                                  itemMaxNumber: viewModel.itemMaxNumber)

        let isValidDiff = formerCount - changeset.delete.count + changeset.insert.count == currentCount
        FeedContext.log.info("feedlog/shortcut/dataflow/render/partial. "
                             + "isValidDiff: \(isValidDiff), "
                             + "former count: \(formerCount), "
                             + "current count: \(currentCount), "
                             + "changeset: [delete \(changeset.delete.count), reload \(changeset.reload.count), insert \(changeset.insert.count)]")
        return isValidDiff
    }
}
