//  SectionHolder.swift
//  LarkFeed
//
//  Created by bytedance on 2020/6/5.
//

import Foundation
import RxDataSources

/// Diff需要的数据源
struct SectionHolder: AnimatableSectionModelType {
    // MARK: Protocol required
    var identity: String = "FeedCardCellViewModel"

    var items: [FeedCardCellViewModel] = [] // 所有的feed
    var renderType: FeedRenderType = .ignore // 渲染方式
    var dataCommand: DataCommand = .none
    var changedIds: [String] = [] // update 或者 remove的 id
    var indexMap: [String: Int] = [:] // feedId：index
    var tempTopIds: [String] = [] // 临时置顶的ids

    var trace: FeedListTrace = FeedListTrace.genDefault() // 来源

    init() {}

    init(original: SectionHolder, items: [FeedCardCellViewModel]) {
        self = original
        self.items = items
    }

    enum DataCommand {
        case none
        case insertOrUpdate
        case remove
    }

    var description: String {
        return "totalCount: \(items.count), "
        + "renderType: \(renderType), "
        + "dataCommand: \(dataCommand), "
        + "changedIdsCount: \(changedIds.count)"
    }
}

struct SectionHolderDiff {
    var deletedItems: [IndexPath] = []
    var insertedItems: [IndexPath] = []
    var updatedItems: [IndexPath] = []
    var movedItems: [(from: Differentiator.ItemPath, to: Differentiator.ItemPath)] = []
}
