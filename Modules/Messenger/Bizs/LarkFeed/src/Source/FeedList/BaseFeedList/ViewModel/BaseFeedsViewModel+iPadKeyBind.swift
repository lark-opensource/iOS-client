//
//  BaseFeedsViewModel+iPadKeyBind.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/8/5.
//

/// For iPad 快捷键绑定
import Foundation
extension BaseFeedsViewModel {
    /// 根据KC方向跳转到下一条Feed
    func findNextFeedForKeyCommand(arrowUp: Bool) -> (String, Int)? {
        let items = allItems()
        let count = items.count
        guard let currentIndex = items.firstIndex(where: { $0.selected }) else {
            return nil
        }
        if arrowUp {
            // search up
            for index in (0 ..< currentIndex).reversed() {
                let feedPreview = items[index].feedPreview
                if feedPreview.basicMeta.feedPreviewPBType != .box {
                    return (feedPreview.id, index)
                }
            }
        } else {
            // search down
            for index in (currentIndex + 1 ..< count) {
                let feedPreview = items[index].feedPreview
                if feedPreview.basicMeta.feedPreviewPBType != .box {
                    return (feedPreview.id, index)
                }
            }
        }
        return nil
    }

    /// 在items中搜索上/下个一未读Feed的信息
    func findUnreadFeedForKeyCommand(arrowUp: Bool) -> (String, Int)? {
        let items = allItems()
        let count = items.count
        guard let currentIndex = items.firstIndex(where: { $0.selected }) else {
            return nil
        }
        let firstRange: StrideTo<Int>
        let secondRange: StrideTo<Int>

        if arrowUp {
            // 向前查找场景
            // 使用过滤器遍历目标下标至起始
            firstRange = stride(from: currentIndex - 1, to: 0, by: -1)
            secondRange = stride(from: count - 1, to: currentIndex, by: -1)
        } else {
            // 向后查找场景
            // 使用过滤器遍历目标下标至末尾
            firstRange = stride(from: currentIndex + 1, to: count - 1, by: 1)
            // 使用过滤器遍历起始至目标下标
            secondRange = stride(from: 0, to: currentIndex, by: 1)
        }

        let checkUnread: (FeedCardCellViewModel) -> Bool = {
            $0.feedPreview.basicMeta.unreadCount > 0 &&
            $0.feedPreview.basicMeta.feedPreviewPBType != .box
        }

        for i in firstRange {
            let item = items[i]
            if checkUnread(items[i]) {
                return (item.feedPreview.id, i)
            }
        }

        // 使用过滤器遍历起始至目标下标
        for i in secondRange {
            let item = items[i]
            if checkUnread(item) {
                return (item.feedPreview.id, i)
            }
        }
        return nil
    }

    /// 在items中搜索上/下个一浏览Feed的记录
    func findFeedRecordForKeyCommand(arrowUp: Bool) -> (String, Int)? {
        guard let feedID = self.selectedRecordID(prev: arrowUp) else {
            return nil
        }
        let items = allItems()
        if let index = items.firstIndex(where: { (cellVM) -> Bool in
            return cellVM.feedPreview.id == feedID
        }) {
            return (feedID, index)
        }
        return nil
    }

    // 获取当前选中 feedCellVM
    func findCurrentSelectedVM() -> FeedCardCellViewModel? {
        let items = allItems()
        guard let currentIndex = items.firstIndex(where: { $0.selected }) else {
            return nil
        }
        return items[currentIndex]
    }
}
