//
//  WikiTreeDraggableViewController+PanelAnimation.swift
//  SpaceKit
//
//  Created by 邱沛 on 2020/7/3.
//

import Foundation
import SKUIKit

extension WikiTreeDraggableViewController {
    class TreeTableViewState {
        // 是否是首次滚动视图
        var isFirstScrollToTop = true
        // tableView 上一次的滚动距离
        var lastPositionY: CGFloat = 0
        // 开始拖动的 ContentOffset
        var currentContentOffset: CGPoint = .zero
        // 开始拖动的面板位置
        var currentContentY: CGFloat = 0
    }

    func treeTableViewWillBeginDragging(_ scrollView: UIScrollView) {
        treeTableViewState.currentContentOffset = scrollView.contentOffset
        treeTableViewState.currentContentY = self.contentView.frame.minY
    }

    func treeTableViewDidScroll(_ scrollView: UIScrollView) {
        let gestureRecognizer = scrollView.panGestureRecognizer

        let yTranslation = gestureRecognizer.translation(in: self.view).y
        let newContentViewY = treeTableViewState.currentContentY + yTranslation

        defer {
            treeTableViewState.lastPositionY = yTranslation
        }

        guard treeTableViewState.isFirstScrollToTop                             // 首次向最大高度滑动
            && yTranslation < self.treeTableViewState.lastPositionY             // 保证是tableView向上滑动才会触发面板的滑动
            && newContentViewY < self.contentView.frame.minY else {                // 保证面板的滑动是向上的
                return
        }

        guard newContentViewY >= self.contentViewMinY else {                    // 不超过面板最高位置
            treeTableViewState.isFirstScrollToTop = false
            if self.contentView.frame.minY > self.contentViewMinY {
                self.contentView.snp.updateConstraints { (make) in
                    make.top.equalTo(self.contentViewMinY)
                }
            }
            return
        }

        self.contentView.snp.updateConstraints { (make) in
            make.top.equalTo(newContentViewY)
        }
        scrollView.contentOffset = treeTableViewState.currentContentOffset
    }
}
