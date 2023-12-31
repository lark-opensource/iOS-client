//
//  GridSorter.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/14.
//

import Foundation
import ByteViewNetwork

enum SortResult: Equatable {
    case unchanged
    case sorted([GridSortOutputEntry])
}

/// 排序中使用到的“一屏”定义
enum GridVisibleRange: Equatable {
    /// Phone 1:1 Layout 优化需求引入的新布局中，一屏为特定的一页，
    /// tile sorter 排序内部会维护每个排好序的宫格所在的页数即其位置，视图层提供页数即可还原上次排序结果中该页数上的宫格及其所在位置
    case page(index: Int)
    /// 缩略图视图、iPad 宫格视图、Phone 横屏宫格视图时，使用可视范围替代页数的概念，
    /// 视图层计算当前用户看到的宫格范围，供 rect sorter 还原指定位置范围内上次排序结果
    case range(start: Int, end: Int, pageSize: Int)

    static func == (lhs: GridVisibleRange, rhs: GridVisibleRange) -> Bool {
        switch (lhs, rhs) {
        case (.page(let left), .page(let right)):
            return left == right
        case (.range(let s1, let e1, let p1), .range(let s2, let e2, let p2)):
            return s1 == s2 && e1 == e2 && p1 == p2
        default:
            return false
        }
    }

    var pageIndex: Int {
        switch self {
        case .page(let i):
            return i
        case .range(let start, _, let pageSize):
            return pageSize == 0 ? 0 : (start / pageSize) + 1
        }
    }
}

struct GridDisplayInfo {
    var visibleRange: GridVisibleRange
    var displayMode: InMeetGridViewModel.ContentDisplayMode
}

protocol GridSorter {
    func sort(participants: [Participant], with context: InMeetGridSortContext) -> SortResult
}
