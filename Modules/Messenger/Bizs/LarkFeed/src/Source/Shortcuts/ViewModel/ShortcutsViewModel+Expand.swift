//
//  ShortcutsViewModel+Expand.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: 展开
extension ShortcutsViewModel {

    // 展开的数据流
    var expandedObservable: Observable<Bool> {
        return expandMoreViewModel.expandedObservable
    }

    /// 切换展开状态公用逻辑：点击展开/收起/下拉TableView时触发
    func toggleExpandedAndCollapse() {
        self.expanded = !self.expanded
    }

    func fireViewHeight() {
        self.updateHeightRelay.accept(self.viewHeight)
    }

    /// 计算在给定状态下的可见置顶数
    class func computeVisibleCount(_ totalCount: Int, expanded: Bool, itemMaxNumber: Int) -> Int {
        if expanded || totalCount <= itemMaxNumber {
            return totalCount
        }
        if itemMaxNumber > 0 {
            return itemMaxNumber - 1
        }
        return 0
    }
}
