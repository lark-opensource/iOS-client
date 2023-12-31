//
//  FlagListViewController+iPadDragDrop.swift
//  LarkFlag
//
//  Created by Fan Hui on 2022/6/6.
//

import UIKit
import Foundation
import LarkUIKit
import LarkInteraction
import LarkCore
import LarkOpenFeed

/// For iPad 手势拖拽
extension FlagListViewController {
    /// 设置拖拽手势代理
    func configForPad(tableView: UITableView) {
        guard Display.pad else { return }
        let dropDelegate = TableViewDropDelegate.create(
            itemTypes: ChatInteractionKit.supportTypes,
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
        guard let index = index, self.datasource.count > index.row else {
            return false
        }
        let cellVM = self.datasource[index.row]
        guard cellVM.type == .feed, let feedVM = cellVM as? FeedCardViewModelInterface else {
            return false
        }
        return feedVM.feedPreview.basicMeta.feedPreviewPBType == .chat && feedVM.feedPreview.preview.chatData.chatMode == .default
    }

    private func handleDropResult(index: IndexPath?, values: [DropItemValue]) {
        guard let index = index, self.datasource.count > index.row else {
            return
        }
        let cellVM = self.datasource[index.row]
        guard cellVM.type == .feed else { return }
        ChatInteractionKit.setDropItems(chatID: cellVM.flagId, items: values)
        self.tableView.delegate?.tableView?(self.tableView, didSelectRowAt: index)
    }
}
