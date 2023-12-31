//
//  BaseFeedsViewController+iPadDragDrop.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/8/5.
//

import UIKit
import Foundation
import LarkUIKit
import LarkInteraction

/// For iPad 手势拖拽
extension BaseFeedsViewController {
    /// 设置拖拽手势代理
    func configForPad(tableView: UITableView) {
        guard Display.pad else { return }
        let dropDelegate = TableViewDropDelegate.create(
            itemTypes: feedDependency.supportTypes,
            canHanleIndex: { [weak self] (indexPath) -> Bool in
                return self?.canHandleDrop(indexPath) ?? false
            },
            resultCallback: { [weak self] (indexPath, values) in
                self?.handleDropResult(index: indexPath, values: values)
            })
        tableView.lkTableDropDelegate = dropDelegate
    }

    private func canHandleDrop(_ index: IndexPath?) -> Bool {
        // 判断是否满足支持的类型以及是否是 chat 会话
        guard let index = index, self.feedsViewModel.allItems().count > index.row else {
            return false
        }
        let cellVM = self.feedsViewModel.allItems()[index.row]
        return cellVM.feedPreview.basicMeta.feedPreviewPBType == .chat && cellVM.feedPreview.preview.chatData.chatMode == .default
    }

    private func handleDropResult(index: IndexPath?, values: [DropItemValue]) {
        guard let index = index, self.feedsViewModel.allItems().count > index.row else {
            return
        }
        let cellVM = self.feedsViewModel.allItems()[index.row]
        guard cellVM.feedPreview.basicMeta.feedPreviewPBType == .chat else { return }
        /// 把 value 存储到 cache
        feedDependency.setDropItemsFromLarkCoreModel(chatID: cellVM.feedPreview.id, items: values)
        self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: index)
        feedsViewModel.setSelected(feedId: cellVM.feedPreview.id)
    }
}
