//
//  AIMainChatTableView.swift
//  LarkChat
//
//  Created by Zigeng on 2023/12/1.
//

import Foundation
import UIKit
import LarkUIKit
import LarkMessageBase
import LKCommonsLogging
import LarkMessengerInterface

protocol CanSetClearAnchorTableView {
    func adjustAnchorBottomInset()
    func adjustAnchorBottomInset(anchorCell: UIView, lastCell: UIView)
}

final class AIMainChatTableView: AIChatTableView, PullDownRefreshScrollInsetCustomView, CanSetClearAnchorTableView {
    private(set) lazy var originalContentInset: UIEdgeInsets = UIEdgeInsets(top: contentTopMargin?() ?? 0,
                                                                                   left: 0,
                                                                                   bottom: bottomBaseInset,
                                                                                   right: 0)
    static let setClearAnchorScrollAnimationDuration = 0.25

    var anchorCell: MessageCommonCell?
    var bottomBaseInset: CGFloat { 24 + self.safeAreaInsets.bottom }
    var bottomAnchorInset: CGFloat = 0
    var fixedBottomBaseInset: CGFloat { bottomAnchorInset + bottomBaseInset }
    var contentTopMargin: (() -> CGFloat?)?
    var bottomContentInset: CGFloat {
        get { contentInset.bottom }
        set {
            contentInset = UIEdgeInsets(top: contentInset.top,
                                        left: contentInset.left,
                                        bottom: newValue,
                                        right: contentInset.right)
        }
    }

    override func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition = .top, animated: Bool = false) {
        super.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
        adjustAnchorBottomInset()
    }

    lazy var useNewOnboard: Bool = {
        return userResolver.fg.dynamicFeatureGatingValue(with: "lark.myai.onboard.new")
    }()

    // 非willDIsplay时机可以直接通过visibleCells和cellForRow(at:)方法获取anchorCell和lastCell
    func adjustAnchorBottomInset() {
        /// FG+临时逻辑隔离-分会话和会话不进行处理：
        guard useNewOnboard else { return }
        // 是否之前的willDisplay存储了anchorcell
        var tempAnchorCell: UIView? = anchorCell
        // 若仍未找到anchorCell，屏幕上可能因为旧inset导致visibleCells为空, 将inset修改为base重新layout判断
        if tempAnchorCell == nil {
            if abs(bottomContentInset - bottomBaseInset) > 0.001 {
                bottomContentInset = bottomBaseInset
            }
            // 立刻重新布局，将inset清空
            self.layoutIfNeeded()
            // 重新寻找anchoCell
            tempAnchorCell = anchorCell
        }
        if let anchorCell = tempAnchorCell, let cell = cellForRow(at: IndexPath(row: numberOfRows(inSection: 0) - 1, section: 0)) {
            adjustAnchorBottomInset(anchorCell: anchorCell, lastCell: cell)
        }
    }

    func adjustAnchorBottomInset(anchorCell: UIView, lastCell: UIView) {
        /// FG+临时逻辑隔离-分会话和会话不进行处理：
        guard useNewOnboard else { return }
        let contentTopMargin = (contentTopMargin?() ?? 0)
        let topPadding: CGFloat = 35
        let neededOffset = self.frame.height - (lastCell.frame.maxY - anchorCell.frame.minY) - contentTopMargin - topPadding - 24

        bottomAnchorInset = max(neededOffset, 0)
        // offset 存在diff时再刷新，避免频繁刷新inset. float计算存在精度问题，忽略0.001的计算误差
        if abs(fixedBottomBaseInset - self.contentInset.bottom) > 0.001 {
            ChatTableView.logger.info("Chat trace mainai update inset, fixedBottomBaseInset:\(fixedBottomBaseInset), bottomContentInset: \(self.contentInset.bottom)")
            originalContentInset = UIEdgeInsets(top: contentTopMargin,
                                                left: 0,
                                                bottom: fixedBottomBaseInset,
                                                right: 0)
            bottomContentInset = fixedBottomBaseInset
            self.layoutIfNeeded()
            self.scrollToBottom(animated: false)
        }
    }
}
