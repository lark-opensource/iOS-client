//
//  BaseFeedsViewModel+CustomSort.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/24.
//

import Foundation

struct FeedBoxIndexer {
    var boxItem: FeedCardCellViewModel
    var boxIndex: Int
}

extension BaseFeedsViewModel {
    func _handleCustomBoxFeedSort(items: [FeedCardCellViewModel], dataStore: SectionHolder, trace: FeedListTrace) -> [FeedCardCellViewModel] {
        // 判断本地缓存的 boxfeed 索引值是否正确
        if let boxIndexer = boxIndexer, boxIndexer.boxIndex < items.count {
            let indexItem = items[boxIndexer.boxIndex]
            if indexItem != boxIndexer.boxItem {
                self.boxIndexer = nil
            }
        }
        // 索引值为空时，遍历查找一次 boxfeed
        if boxIndexer == nil {
            for i in 0..<items.count {
                let feed = items[i]
                if feed.feedPreview.basicMeta.feedPreviewPBType == .box {
                    boxIndexer = FeedBoxIndexer(boxItem: feed, boxIndex: i)
                    break
                }
            }
        }
        var changedItems = items
        let sortPosition = FeedSortPosition.boxPreferredRank + dataStore.tempTopIds.count
        if let boxIndexer = boxIndexer {
            if changedItems.count < sortPosition {
                // 列表不足12个且feedbox不在末尾位，则放末尾
                if boxIndexer.boxIndex < changedItems.count - 1 {
                    changedItems.remove(at: boxIndexer.boxIndex)
                    changedItems.append(boxIndexer.boxItem)
                    let traceInfo = "\(self.listBaseLog), \(trace.description)"
                    FeedContext.log.info("feedlog/dataStream/boxPosition. \(traceInfo), changed from \(boxIndexer.boxIndex) to \(changedItems.count - 1)")
                }
            } else if boxIndexer.boxIndex < sortPosition {
                // 在前12位置，需移动到第12的位置
                changedItems.insert(boxIndexer.boxItem, at: sortPosition)
                changedItems.remove(at: boxIndexer.boxIndex)
                let traceInfo = "\(self.listBaseLog), \(trace.description)"
                FeedContext.log.info("feedlog/dataStream/boxPosition. \(traceInfo), changed from \(boxIndexer.boxIndex) to \(sortPosition)")
            }
        }
        return changedItems
    }
}
