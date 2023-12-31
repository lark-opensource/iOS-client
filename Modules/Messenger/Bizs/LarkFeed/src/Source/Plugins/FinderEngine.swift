//
//  FinderEngine.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/7/14.
//

import Foundation
import RustPB

enum FindState {
    case found(IndexPath)
    case notFound
}
struct FindUnreadConfig {
    static let minLeastUnreadItem = 3
    static let invalidValue = -1
    static let firstFeed = -1
}

final class FinderEngine {

    static func findNextUnread(_ allItems: [[FeedFinderItem]], fromPosition: IndexPath, finder: FeedFinderInterface, isAtBottom: Bool = false) -> FindState {
        if isAtBottom {
            return .notFound
        }
        var row: Int?
        var section: Int?
        if fromPosition.section >= allItems.count {
            return .notFound
        }
        var start = fromPosition.row + 1
        for i in fromPosition.section ..< allItems.count {
            if start >= allItems[fromPosition.section].count {
                return .notFound
            }
            for j in start ..< allItems[fromPosition.section].count {
                if finder.finder(item: allItems[i][j]) {
                    section = i
                    row = j
                    break
                }
            }
            start = 0
        }
        guard let row = row, let section = section else { return .notFound }
        let nextUnread = IndexPath(row: row, section: section)
        return .found(nextUnread)
    }

    static func isNeedPullNextUnread(_ allItems: [[FeedFinderItem]], fromPosition: IndexPath, finder: FeedFinderInterface) -> Bool {
        var num = 0
        if fromPosition.row + 1 >= allItems[fromPosition.section].count {
            return false
        }
        for i in (fromPosition.row + 1 ..< allItems[fromPosition.section].count).reversed() {
            if finder.finder(item: allItems[fromPosition.section][i]) {
                num += 1
                if num >= FindUnreadConfig.minLeastUnreadItem {
                    return false
                }
            }
        }
        return true
    }
}
