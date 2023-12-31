//
//  RectSortPage.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/14.
//

import Foundation

class RectSortPage {
    private let firstPageSize: Int
    private var items: [RectPageItem]
    private var lastRankItemInFirstPage: GridSortInputEntry?

    var lastSortRankInFirstPage: Int {
        lastRankItemInFirstPage?.rank ?? .max
    }

    init(initialCapacity: Int, firstPageSize: Int) {
        self.firstPageSize = firstPageSize
        self.items = Array(repeating: .none, count: initialCapacity)
    }

    var normalized: [GridSortInputEntry] {
        enumerated(in: 0..<items.count).map { $0.1 }
    }

    func enumerated(in range: Range<Int>) -> [(Int, GridSortInputEntry)] {
        range.clamped(to: 0..<items.count).compactMap { (index: Int) -> (Int, GridSortInputEntry)? in
            if case .grid(let item) = items[index] {
                return (index, item)
            } else {
                return nil
            }
        }
    }

    /// 将给定宫格数组从前往后依次添加到所有空位中，如果前面全都已有宫格，则剩余的添加到最后一个宫格的后面。可能改变 items 的容量
    func insertOnNull(_ inputItems: [GridSortInputEntry]) {
        guard !inputItems.isEmpty else { return }
        var inputIndex = 0
        for i in 0..<items.count {
            let top = inputItems[inputIndex]
            if insertIfNull(top, at: i) {
                inputIndex += 1
                guard inputIndex < inputItems.count else { return }
            }
        }
        items.append(contentsOf: inputItems[inputIndex...].map { .grid($0) })
    }

    /// 将特定位置的宫格替换为所制定的宫格，返回被替换的原始宫格（如果有）。O(1)
    func replace(_ item: GridSortInputEntry, at index: Int) -> GridSortInputEntry? {
        guard index >= 0 && index < items.count else { return nil }
        var removed: GridSortInputEntry?
        if case .grid(let original) = items[index] {
            removed = original
        }
        items[index] = .grid(item)
        if index < firstPageSize {
            resetLastRanks()
        }
        return removed
    }

    /// 给定位置如果为空，则插入给定宫格，否则什么都不做，返回是否成功插入。O(1)
    func insertIfNull(_ item: GridSortInputEntry, at index: Int) -> Bool {
        guard index >= 0 && index < items.count else { return false }
        if case .none = items[index] {
            items[index] = .grid(item)
            if index < firstPageSize {
                resetLastRanks()
            }
            return true
        }
        return false
    }

    /// 在指定范围内保证一定插入给定宫格，返回该范围内被替换出去的原始宫格（如果有）。O(k), k = size of range
    func insertOrReplace(_ item: GridSortInputEntry, in range: Range<Int>) -> GridSortInputEntry? {
        // 1. 尝试寻找空位插入
        for i in range where i < items.count {
            if insertIfNull(item, at: i) {
                return nil
            }
        }
        // 2. 如果给定 range 超过当前的 capacity，则可以继续往后添加
        if items.count < range.endIndex {
            items.append(.grid(item))
            if range.overlaps(0..<firstPageSize) {
                resetLastRanks()
            }
            return nil
        }
        // 3. 指定范围内没有空位，寻找最小权重的人进行替换
        var minIndex = range.upperBound - 1
        for i in range {
            if case .grid(let left) = items[i], case .grid(let right) = items[minIndex], right < left && !left.shouldStayInFirstPage {
                minIndex = i
            }
        }
        let removed = items[minIndex].item
        items[minIndex] = .grid(item)

        if range.overlaps(0..<firstPageSize) {
            resetLastRanks()
        }
        return removed
    }

    func swapAt(_ i: Int, j: Int) {
        guard i < items.count && j < items.count else { return }
        items.swapAt(i, j)
        if (i < firstPageSize && j >= firstPageSize) || (i >= firstPageSize && j < firstPageSize) {
            resetLastRanks()
        }
    }

    func remove(at i: Int) -> GridSortInputEntry? {
        if i < items.count, case .grid(let item) = items[i] {
            items[i] = .none
            if i < firstPageSize {
                resetLastRanks()
            }
            return item
        }
        return nil
    }

    func index(where block: (GridSortInputEntry) -> Bool, in range: Range<Int>? = nil) -> Int? {
        var clampedRange = 0..<items.count
        if let range = range {
            clampedRange = clampedRange.clamped(to: range)
        }
        for i in clampedRange {
            if case .grid(let item) = items[i], block(item) {
                return i
            }
        }
        return nil
    }

    func index(of pid: ByteviewUser) -> Int? {
        for i in 0..<items.count {
            if case .grid(let item) = items[i], item.pid == pid {
                return i
            }
        }
        return nil
    }

    func resetLastRanks() {
        var last: GridSortInputEntry?
        for i in 0 ..< min(items.count, firstPageSize) {
            if case .grid(let item) = items[i] {
                if item.shouldStayInFirstPage { continue }
                if let l = last, l < item {
                    last = item
                } else if last == nil {
                    last = item
                }
            }
        }
        lastRankItemInFirstPage = last
    }

    private enum RectPageItem {
        case none
        case grid(GridSortInputEntry)

        var item: GridSortInputEntry? {
            switch self {
            case .grid(let item): return item
            case .none: return nil
            }
        }
    }
}
