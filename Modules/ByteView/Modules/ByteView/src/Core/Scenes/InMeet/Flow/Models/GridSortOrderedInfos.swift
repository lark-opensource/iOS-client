//
//  GridSortOrderedInfos.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/14.
//

import Foundation

class GridSortOrderedInfos {
    private var infos: [GridSortInputEntry]
    private var scoreMap: [ByteviewUser: GridSortInputEntry]

    var first: GridSortInputEntry? { infos.first }

    var isEmpty: Bool {
        infos.isEmpty
    }

    var enumerated: [GridSortInputEntry] { infos }

    // 输入必须是有序的
    init(scoredInfos: [GridSortInputEntry]) {
        assert(scoredInfos == scoredInfos.sorted(by: <))
        self.infos = scoredInfos
        self.scoreMap = Dictionary(scoredInfos.map { ($0.participant.user, $0) }, uniquingKeysWith: { $1 })
    }

    func remove(with pid: ByteviewUser) -> GridSortInputEntry? {
        guard scoreMap[pid] != nil else { return nil }
        infos.removeAll(where: { $0.participant.user == pid })
        return scoreMap.removeValue(forKey: pid)
    }

    func pop() -> GridSortInputEntry? {
        guard !infos.isEmpty else { return nil }
        let first = infos.removeFirst()
        scoreMap.removeValue(forKey: first.participant.user)
        return first
    }

    func filter(_ isIncluded: (GridSortInputEntry) -> Bool) -> [GridSortInputEntry] {
        infos.filter(isIncluded)
    }

    func insert(_ item: GridSortInputEntry?) {
        if let item = item {
            insert(contentsOf: [item])
        }
    }

    func insert(contentsOf items: [GridSortInputEntry]) {
        for item in items {
            scoreMap[item.pid] = item
            insertInOrder(item)
        }
    }

    private func insertInOrder(_ item: GridSortInputEntry) {
        switch binarySearch(item.rank) {
        case .found(at: let i): infos.insert(item, at: i)
        case .notFound(insertAt: let i): infos.insert(item, at: i)
        }
    }

    private enum SearchResult {
        case found(at: Int)
        case notFound(insertAt: Int)
    }

    private func binarySearch(_ rank: Int) -> SearchResult {
        var start = 0
        var end = infos.count - 1
        while start <= end {
            let mid = (start + end) / 2
            if infos[mid].rank == rank {
                return .found(at: mid)
            } else if infos[mid].rank < rank {
                start = mid + 1
            } else {
                end = mid - 1
            }
        }
        return .notFound(insertAt: start)
    }
}
