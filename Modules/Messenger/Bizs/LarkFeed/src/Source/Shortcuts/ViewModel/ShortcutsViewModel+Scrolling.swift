//
//  ShortcutsViewModel+Scrolling.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

// MARK: 与 vc 中的 scroll 滑动相关
import UIKit
import Foundation
extension ShortcutsViewModel {

    // 是否支持吸顶
    func isNeedSnap(offsetY: CGFloat) -> Bool {
        expandMoreViewModel.display && !self.expanded && offsetY <= 0
    }

    // 滑动展开
    func expandIfNecessary(offsetY: CGFloat) {
        if expandMoreViewModel.display && !self.expanded && offsetY <= -ShortcutLayout.shortcutsLoadingExpansionTrigger {
            expandCollapseType = .expandByScroll
            toggleExpandedAndCollapse()
        }
    }

    // 滑动收起
    func collapseIfNecessary(offsetY: CGFloat, heightAboveShortcut: CGFloat) {
        if expanded && offsetY >= heightAboveShortcut {
            expandCollapseType = .collapseByScroll
            toggleExpandedAndCollapse()
        }
    }
}
