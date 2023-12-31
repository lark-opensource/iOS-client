//
//  BaseFeedsViewModel+iPadSelection.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/8/3.
//

import Foundation
import RxSwift
import LarkUIKit

/// For iPad
extension BaseFeedsViewModel {
    /// iPad对cellVM的特殊配制
    func configureCellVMForPad(_ cellViewModel: FeedCardCellViewModel) {
        guard Display.pad else { return }
        if let feedId = baseDependency.getSelected(),
            cellViewModel.feedPreview.id == feedId {
            cellViewModel.selected = true
        }
    }

    /// 设置Feed选中
    func setSelected(feedId: String?) {
        self.baseDependency.setSelected(feedId: feedId)
    }

    /// 选择上一次/下一次记录
    func selectedRecordID(prev: Bool) -> String? {
        return self.baseDependency.selectedRecordID(prev: prev)
    }

    /// iPad选中态监听
    func observeSelect() -> Observable<String?> {
        self.baseDependency.observeSelect()
    }

    /// 是否需要跳过: 避免重复跳转
    func shouldSkip(feedId: String, traitCollection: UIUserInterfaceSizeClass?) -> Bool {
        return false
    }

    /// try to find next selectable row:
    /// 1. check next row in down direction, if type is feedbox, continue check next ⬇
    /// 2. if next row not exist, turn up direction ⬆
    /// 3. check next row in up direction, if type is feedbox, continue check next ⬆
    /// 4. when up direction ⬆ out of range, return nil, no valid selectable row.
    func findNextSelectFeed(feedId: String) -> String? {
        let items = allItems()
        let count = items.count
        // 无效feedId, return nil
        guard let currentIndex = items.firstIndex(where: { $0.feedPreview.id == feedId }) else {
            return nil
        }
        // search down
        if currentIndex < count - 1 {
            for item in items[(currentIndex + 1 ..< count)] where item.feedPreview.basicMeta.feedPreviewPBType != .box {
                return item.feedPreview.id
            }
        }

        // search up
        if currentIndex > 0, currentIndex <= count - 1 {
            for item in items[(0 ..< currentIndex)].reversed() where item.feedPreview.basicMeta.feedPreviewPBType != .box {
                return item.feedPreview.id
            }
        }

        // no vaild result
        return nil
    }
}
