//
//  MyAIMainViewController.swift
//  LarkChat
//
//  Created by ByteDance on 2023/11/15.
//

import Foundation
import LarkUIKit
import LarkMessageBase
/// MyAI主会场
class MyAIMainViewController: MyAIChatViewController {

    // 添加消息清屏逻辑
    var aiMainTableView: AIMainChatTableView? { tableView as? AIMainChatTableView }
    override var fixedBottomBaseInset: CGFloat { aiMainTableView?.fixedBottomBaseInset ?? super.fixedBottomBaseInset }
    /// Myai主会场是否使用端上mock消息样式的新引导卡片
    var useNewOnboard: Bool {
        return self.myAIPageService?.useNewOnboard ?? false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addAnchorClearObserver()
        aiMainTableView?.contentTopMargin = { [weak self] in
            guard let self = self else { return nil }
            return (self.chatMessageBaseDelegate?.contentTopMargin ?? 0)
        }
    }

    override func uiBusinessAfterMessageRender() {
        super.uiBusinessAfterMessageRender()
        tableView.draggingDriver
            .skip(1)
            .distinctUntilChanged({ status1, status2 -> Bool in
                return status1.0 == status2.0
            })
            .drive(onNext: { [weak self] (dragging, _) in
                guard let `self` = self else { return }
                // 多选和使用iPad的时候不隐藏bar
                if self.multiSelecting || Display.pad { return }
                if dragging {
                    self.chatOpenService?.setTopContainerShowDelay(false)
                } else {
                    self.chatOpenService?.setTopContainerShowDelay(true)
                }
            }).disposed(by: disposeBag)
    }

    func addAnchorClearObserver() {
        guard useNewOnboard else { return }
        self.tableView.willDisplayCell({ [weak self] event in
            guard let self = self, let aiMainTableView = self.aiMainTableView else { return }
            /// 没有anchorId将底部inset清零
            guard let anchorId = (chatMessageViewModel as? CanSetClearAnchorVM)?.anchorCellId else {
                aiMainTableView.bottomContentInset = aiMainTableView.bottomBaseInset
                return
            }
            /// 如果willdisplay的cell恰好是清屏锚点时，保存状态
            /// 通过此手段保存状态的原因是，cell的willdisplay方法无法通过visibleCells相关方法获取cell，
            /// 而在非willtdisplay时机读取tableView.visibleCells会造成列表卡顿
            if let thisCell = event.cell as? MessageCommonCell,
               !thisCell.cellId.isEmpty && anchorId == thisCell.cellId {
                aiMainTableView.anchorCell = thisCell
            }
            /// 没有指定需要清屏的锚点cell，直接return
            guard let anchorCell = aiMainTableView.anchorCell else { return }
            // 若为其他cell则跳过本次Inset重置环节
            if event.indexPath.row != self.tableView.numberOfRows(inSection: 0) - 1 {
                return
            }
            aiMainTableView.adjustAnchorBottomInset(anchorCell: anchorCell, lastCell: event.cell)
        })
        self.tableView.didEndDisplayingCell({ [weak self] event in
            guard let aiMainTableView = self?.aiMainTableView else { return }
            if event.cell === aiMainTableView.anchorCell {
                aiMainTableView.anchorCell = nil
            }
        })
    }
}
