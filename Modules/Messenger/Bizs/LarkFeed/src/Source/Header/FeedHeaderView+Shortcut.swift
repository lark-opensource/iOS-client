//
//  FeedHeaderView+Shortcut.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

import UIKit
import Foundation
import RustPB
import LarkModel

extension FeedHeaderView {

    // 开始拖拽
    func scrollViewWillBeginDragging() {
        guard isShortcutPresent else { return }
        // 手指按住，挂起 shortcut 数据处理及发送相关的任务
        self.shortcutsViewModel?.freeze(true)
    }

    // 滚动中
    func scrollViewDidScroll(offsetY: CGFloat) {
        guard isShortcutPresent else { return }
        // 下拉吸顶任务
        snapTopViews(offsetY)
        shortcutCollapse(offsetY: offsetY)
    }

    // 结束拖拽
    func scrollViewDidEndDragging(offsetY: CGFloat) {
        guard isShortcutPresent else { return }
        // 恢复 shortcut 数据处理及发送相关的任务
        self.shortcutsViewModel?.freeze(false)
        // 下拉松手展开任务
        shortcutExpanded(offsetY: offsetY)
    }

    /// 吸顶：让置顶以上（包括置顶）的view的y值往上移动，造成吸住顶部的UI表现。前提条件是置顶收起且向下拉动时
    fileprivate func snapTopViews(_ offsetY: CGFloat) {
        if !(self.shortcutsViewModel?.isNeedSnap(offsetY: offsetY) ?? false) {
            return
        }
        var y = offsetY
        for view in sortedSubViews {
            if view is ShortcutsCollectionView {
                break
            }
            var rect = view.frame
            rect.origin.y = y
            view.frame = rect
            y = rect.maxY
        }
        shortcutsView?.snapLayout(offsetY: offsetY, y: y)
    }

    /// 下拉松手展开任务
    fileprivate func shortcutExpanded(offsetY: CGFloat) {
        self.shortcutsViewModel?.expandIfNecessary(offsetY: offsetY)
    }

    /// 上滑收起任务：当置顶滚动到上方屏幕外时，收起置顶
    func shortcutCollapse(offsetY: CGFloat) {
        guard isShortcutPresent else { return }
        // 上滑收起任务
        shortcutsViewModel?.collapseIfNecessary(offsetY: offsetY, heightAboveShortcut: criticalYForCollapse)
    }

    // Feed Pull/Push的数据，同步更新Shortcut
    func updateShortcut(feeds: [FeedPreview]) {
        shortcutsViewModel?.handleDataFromFeed(feeds)
    }
}
