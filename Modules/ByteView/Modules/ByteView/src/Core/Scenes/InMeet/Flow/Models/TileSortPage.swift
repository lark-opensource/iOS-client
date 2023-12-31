//
//  TileSortPage.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/14.
//

import Foundation
import ByteViewNetwork

class TileSortItem: GridSortInputEntry {
    fileprivate let weight: Int
    fileprivate var column = 0
    fileprivate weak var row: TileSortRow?
    let isRoom: Bool

    override init(participant: Participant, role: GridSortInputEntry.Role, rank: Int, action: CandidateAction) {
        self.isRoom = participant.gridType == .room
        self.weight = self.isRoom ? 2 : 1
        super.init(participant: participant, role: role, rank: rank, action: action)
    }

    convenience init(item: GridSortInputEntry) {
        self.init(participant: item.participant, role: item.role, rank: item.rank, action: item.action)
    }

    func removeFromRow() {
        _ = row?.remove(with: pid)
    }

    fileprivate var siblings: Int {
        column == 0 ? 1 : 0
    }
}

private class TileSortRow {
    static let column = 2
    lazy var items = [TilePageItem](repeating: .none, count: Self.column)
    var gridItems: [TileSortItem] { items.compactMap { $0.item } }

    @discardableResult func insertAtEmpty(_ item: TileSortItem) -> Bool {
        if let index = items.firstIndex(where: { $0 == .none }) {
            return tryInsert(item, at: index)
        }
        return false
    }

    @discardableResult func tryInsert(_ item: TileSortItem, at index: Int) -> Bool {
        guard index < items.count, items[index] == .none, max(totalWeight, index) + item.weight <= Self.column else {
            return false
        }
        item.column = index
        item.row = self
        items[index] = .grid(item)
        return true
    }

    /// 将当前 row 中的元素 `item` 用 `other` 替换
    @discardableResult func replace(_ item: TileSortItem, with other: TileSortItem) -> Bool {
        if item === other { return true }
        guard item.row === self && other.weight <= item.weight else { return false }

        other.removeFromRow()
        other.column = item.column
        other.row = self
        items[item.column] = .grid(other)

        item.removeFromRow()
        return true
    }

    func remove(with pid: ByteviewUser) -> TileSortItem? {
        guard let removedIndex = items.firstIndex(where: { $0.item?.pid == pid }) else { return nil }
        return remove(at: removedIndex)
    }

    func pop() -> TileSortItem? {
        if let i = items.firstIndex(where: { $0 != .none }) {
            return remove(at: i)
        }
        return nil
    }

    fileprivate func remove(at index: Int) -> TileSortItem? {
        guard index < items.count, case .grid(let item) = items[index] else { return nil }
        item.row = nil
        items[index] = .none
        return item
    }

    func reset(to item: TileSortItem) {
        gridItems.forEach { $0.row = nil }
        items = [TilePageItem](repeating: .none, count: Self.column)
        insertAtEmpty(item)
    }

    var isRoom: Bool {
        items.first { $0.item?.isRoom ?? false } != nil
    }

    var isFull: Bool {
        totalWeight == Self.column
    }

    private var totalWeight: Int {
        gridItems.map(\.weight).reduce(0, +)
    }
}


class TileSortPage {
    static let row = 3
    static let column = 2
    fileprivate var rows: [TileSortRow] = []
    private var lastRankItem: TileSortItem?
    private var secondLastRankItem: TileSortItem?

    var isFull: Bool {
        rows.allSatisfy { $0.isFull }
    }

    var count: Int {
        rows.map { $0.gridItems.count }.reduce(0, +)
    }

    init() {
        for _ in 0..<Self.row {
            self.rows.append(TileSortRow())
        }
    }

    var enumerated: [TileSortItem] {
        rows.flatMap { $0.gridItems }
    }

    // 将 room 放到参会人下面，空白（如果有，例如最后一页不满时）放到最后
    //    Room           P  P
    //    P  ∅  ------>  Room
    //    ∅  P           ∅  ∅
    func normalized() -> TileSortPage {
        var items = rows.filter { !$0.isRoom }.flatMap { $0.gridItems }
        items.append(contentsOf: rows.filter { $0.isRoom }.flatMap { $0.gridItems })
        let page = TileSortPage()
        for item in items {
            // 同一页调整顺序，insert 一定成功
            _ = page.insert(item)
        }
        return page
    }

    func contains(where block: (TileSortItem) -> Bool) -> Bool {
        rows.contains(where: { $0.gridItems.contains(where: block) })
    }

    func resetLastRanks() {
        var last: TileSortItem?
        var secondLast: TileSortItem?
        for row in rows {
            for item in row.gridItems {
                if item.shouldStayInFirstPage { continue }
                if last == nil {
                    last = item
                } else if let l = last, l < item {
                    secondLast = last
                    last = item
                } else if secondLast == nil {
                    secondLast = item
                } else if let l = secondLast, l < item {
                    secondLast = item
                }
            }
        }
        lastRankItem = last
        secondLastRankItem = secondLast
    }

    var lastSortRank: Int {
        lastRankItem?.rank ?? .max
    }

    /// 尝试将目标插入到指定位置，不会引起宫格顺序变动，也不会出现替换宫格行为
    @discardableResult func insert(_ item: TileSortItem, at coordinate: GridCoordinate) -> Bool {
        guard coordinate.row < rows.count else { return false }
        let result = rows[coordinate.row].tryInsert(item, at: coordinate.column)
        resetLastRanks()
        return result
    }

    func replace(_ item: TileSortItem, at coordinate: (Int, Int)) -> [TileSortItem] {
        guard coordinate.0 < rows.count else { return [] }
        if item.isRoom && coordinate.1 != 0 {
            return []
        }

        // 1. 待插入的 item 从原来的 row 中移除
        item.removeFromRow()
        // 2. 目标位置原来的 items 移除并保存
        var result: [TileSortItem] = []
        let row = rows[coordinate.0]
        let siblings = coordinate.1 == 0 ? 1 : 0
        if let removed = row.remove(at: coordinate.1) {
            // 目标位置原来被占用，先移除
            result.append(removed)
        }
        // 目标位置或待插入元素是 room，则目标位置的同桌也要被移除
        if row.isRoom || item.isRoom, let another = row.remove(at: siblings) {
            result.append(another)
        }
        // 3. 插入 item
        row.tryInsert(item, at: coordinate.1)
        resetLastRanks()

        return result
    }

    func pop() -> TileSortItem? {
        for row in rows {
            if let removed = row.pop() {
                resetLastRanks()
                return removed
            }
        }
        return nil
    }

    func remove(with pid: ByteviewUser) -> TileSortItem? {
        for row in rows {
            if let removed = row.remove(with: pid) {
                resetLastRanks()
                return removed
            }
        }
        return nil
    }

    /// 尝试插入目标宫格到当前页，可能导致宫格排序有变动（比如通过调整位置让 room 宫格插入），但不会出现替换宫格的行为，返回是否成功插入
    func insert(_ item: TileSortItem) -> Bool {
        // 只有当前页不满才有可能插入
        guard !isFull else { return false }

        let onInsertSuccess = {
            // 插入完成以后维护最小和次小宫格
            self.resetLastRanks()
        }

        // 1. 尝试各行直接插入
        for row in rows where row.insertAtEmpty(item) {
            onInsertSuccess()
            return true
        }

        // 2. 当前页没满但无法插入目标宫格，说明目标宫格是 room，此时只有至少两行有空余宫格时，才有可能成功插入

        guard let lastUnfullIndex = rows.lastIndex(where: { !$0.isFull }), let firstUnfullIndex = rows.firstIndex(where: { !$0.isFull }), lastUnfullIndex != firstUnfullIndex, let lower = rows[lastUnfullIndex].pop() else { return false }

        // 3. 下面一行中的元素移动到上面一行，将待插入 room 填充到下面一行
        rows[firstUnfullIndex].insertAtEmpty(lower)
        rows[lastUnfullIndex].insertAtEmpty(item)
        onInsertSuccess()
        return true
    }

    /// 插入或替换目标宫格到当前页，可以保证目标宫格一定会被插入到当前页，返回被替换（移除）的宫格列表，可能为 0-2 个
    func insertOrReplace(_ item: TileSortItem) -> [TileSortItem] {
        defer {
            // 插入完成以后维护最小和次小宫格
            resetLastRanks()
        }

        // 1. 逐行尝试，如果有空间，直接插入
        for row in rows where row.insertAtEmpty(item) {
            return []
        }
        guard let lastRankItem = lastRankItem,
              let lastRankRow = lastRankItem.row,
              let secondLastRankItem = secondLastRankItem,
              let secondLastRankRow = secondLastRankItem.row
            else { return [] }

        // 2. 没有足够的空间，则按照被插入的宫格类型分类处理

        guard item.isRoom else {
            // 3. 被插入的是参会人，直接跟最小权重的宫格替换，此时可能导致当前页不满（被替换的是 room）
            return lastRankRow.replace(lastRankItem, with: item) ? [lastRankItem] : []
        }

        // 4. 被插入的是 room，尝试通过移动当前宫格或替换宫格来处理
        if let lastUnfullIndex = rows.lastIndex(where: { !$0.isFull }), let firstUnfullIndex = rows.firstIndex(where: { !$0.isFull }), let lower = rows[lastUnfullIndex].gridItems.first {
            // 4.1 如果当前页不满，尝试腾出空间
            if lastUnfullIndex == firstUnfullIndex {
                // 4.1.1 只有一行有空余，此时依然容不下待插入 room，将最小的参会人宫格与该行元素替换，然后用 room 替换最小参会人
                let replaced = lastRankItem.isRoom ? secondLastRankItem : lastRankItem
                replaced.row?.replace(replaced, with: lower)
                rows[lastUnfullIndex].reset(to: item)
                return [replaced]
            } else {
                // 4.1.2 至少两行有空余，下面一行中的元素移动到上面一行，将待插入 room 填充到下面一行
                lower.removeFromRow()
                rows[firstUnfullIndex].insertAtEmpty(lower)
                rows[lastUnfullIndex].insertAtEmpty(item)
                return []
            }
        } else {
            // 4.2 当前页已满，尝试寻找待替换宫格
            if lastRankRow.replace(lastRankItem, with: item) {
                // 4.2.1 尝试用最小权重的宫格替代
                return [lastRankItem]
            }
            if secondLastRankRow.replace(secondLastRankItem, with: item) {
                // 4.2.2 最小宫格没法替换新宫格，尝试用次小宫格替代
                return [secondLastRankItem]
            }
            // 4.2.3 最小次小均没法替代新宫格，说明此时最小次小均为参会人，先将这两个参会人的”同桌“放到同一行，然后最小和次小这一行替换为新 room
            lastRankRow.replace(lastRankItem, with: secondLastRankRow.gridItems[secondLastRankItem.siblings])
            secondLastRankRow.reset(to: item)
            return [lastRankItem, secondLastRankItem]
        }
    }
}

struct GridCoordinate {
    let row: Int
    let column: Int
    let pageIndex: Int
}

class TileSortResult {
    let pid: ByteviewUser
    /// 排序后的宫格位置，sorter 内部维护，用于处理首屏和当前屏逻辑，外部不使用
    let coordinate: GridCoordinate

    init(pid: ByteviewUser, coordinate: GridCoordinate) {
        self.pid = pid
        self.coordinate = coordinate
    }
}

extension Array where Element == TileSortPage {
    func flatten() -> [TileSortResult] {
        map { $0.normalized() }
            .enumerated()
            .flatMap { (pageIndex, page) in
                page.rows.enumerated().flatMap { (rowIndex, row) in
                    row.gridItems.enumerated().map { (columnIndex, item) in
                        TileSortResult(pid: item.pid, coordinate: GridCoordinate(row: rowIndex, column: columnIndex, pageIndex: pageIndex))
                    }
                }
            }
    }
}

private enum TilePageItem: Equatable {
    case none
    case grid(TileSortItem)

    var item: TileSortItem? {
        switch self {
        case .grid(let item): return item
        case .none: return nil
        }
    }
}
