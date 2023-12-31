//
//  FeedHeaderView+Provide.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

// MARK: 供外部使用
import UIKit
import Foundation
extension FeedHeaderView {

    // shortcut执行任务权限
    var isShortcutPresent: Bool {
        guard let shortcutsViewModel = shortcutsViewModel else { return false }
        return !shortcutsViewModel.dataSource.isEmpty && shortcutsView != nil
    }

    // shortcut当前的收起/展开状态
    var shortcutExpanded: Bool {
        self.shortcutsViewModel?.expanded ?? false
    }

    // shortcut是否具备展开功能
    var shortcutExpandable: Bool {
        guard let shortcutsViewModel = shortcutsViewModel else {
            return false
        }

        return shortcutsViewModel.dataSource.count > shortcutsViewModel.itemMaxNumber
    }

    // 是否允许震动的初步基本条件
    var preAllowVibrate: Bool {
        !shortcutExpanded && isShortcutPresent && shortcutExpandable
    }

    /// shortcut包括shortcut以上的高度之和（ shortcut进行收起的临界值）
    var heightAboveShortcut: CGFloat {
        var height: CGFloat = 0
        for viewModel in visibleViewModels {
            height += viewModel.viewHeight
            if viewModel.type == .shortcut {
                return height
            }
        }
        return height
    }

    /// shortcut进行收起的临界值
    var criticalYForCollapse: CGFloat {
        shortcutsView?.frame.maxY ?? 0
    }
}
