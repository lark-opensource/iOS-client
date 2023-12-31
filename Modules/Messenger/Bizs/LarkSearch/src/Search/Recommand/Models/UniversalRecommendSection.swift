//
//  UniversalRecommendSection.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/17.
//

import UIKit
import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkSearchCore
import LarkUIKit
import LarkContainer
import LarkMessengerInterface

enum UniversalRecommendSection: Equatable {
    enum SectionType: Equatable {
        case history, hotword, recommend, unknown
    }

    case list(ListSection)
    case card(CardSection)
    case chip(ChipSection)

    var title: String? {
        switch self {
        case .list(let v): return v.title
        case .card(let v): return v.title
        case .chip(let v): return v.title
        }
    }

    var contentType: SectionType {
        switch self {
        case .list(let v): return v.contentType
        case .card(let v): return v.contentType
        case .chip(let v): return v.contentType
        }
    }

}

extension UniversalRecommendSection {
    final class ChipSection: Equatable {
        typealias TitleCell = UniversalRecommendChipCell

        let title: String
        let items: [UniversalRecommendChipItem]
        let contentType: SectionType
        var maxFoldRow: Int // 是否需要展示折叠按钮
        var shouldSupportFold: Bool = false

        let userResolver: UserResolver

        var shouldHideClickButton: Bool {
            switch contentType {
            case .history: return false
            case .hotword: return true
            case .recommend, .unknown: return false
            }
        }
        // 当前是否处于折叠状态
        var isFold: Bool = true {
            didSet { invalidLayout() }
        }

        init(userResolver: UserResolver,
             title: String,
             contentType: SectionType,
             items: [UniversalRecommendChipItem],
             isFold: Bool = true) {
            self.title = title
            self.contentType = contentType
            self.items = items
            self.isFold = isFold
            self.maxFoldRow = 2 //搜索历史改版后，默认展示行数改为2行
            self.userResolver = userResolver
        }
        private var _itemsByRow: [[UniversalRecommendChipItem]]?
        private var _layoutRows: Int? // 非折叠态的rows, 可能为nil，代表还没计算好(比如折叠态)
        static func == (lhs: UniversalRecommendSection.ChipSection, rhs: UniversalRecommendSection.ChipSection) -> Bool {
            if lhs.title != rhs.title {
                return false
            } else if lhs.contentType != rhs.contentType {
                return false
            } else if lhs.isFold != rhs.isFold {
                return false
            } else {
                if lhs.items.count != rhs.items.count {
                    return false
                } else {
                    var cnt: Int = 0
                    while cnt < lhs.items.count {
                        if lhs.items[cnt].title != rhs.items[cnt].title {
                            return false
                        } else if lhs.items[cnt].iconStyle != rhs.items[cnt].iconStyle {
                            return false
                        }
                        cnt += 1
                    }
                }
            }
            return true
        }
        func cellViewModel(forRow row: Int) -> UniversalRecommendChipCellViewModel {
            guard let itemsByRow = _itemsByRow, row < itemsByRow.count else {
                return UniversalRecommendChipCellViewModel(items: [], foldType: .none) // invalid row
            }
            var type: TitleCell.FoldType = .none
            if !shouldSupportFold {
                type = .none
            } else if isFold, row + 1 == maxFoldRow { // 折叠状态最后一行展示fold
                type = .fold
            } else if !isFold, row + 1 == itemsByRow.count { // 最后一行展示unfold
                type = .unfold
            }
            return UniversalRecommendChipCellViewModel(items: itemsByRow[row], foldType: type)
        }
        func item(forRow row: Int, index: Int) -> UniversalRecommendChipItem? {
            guard let itemsByRow = _itemsByRow, row < itemsByRow.count else {
                return nil
            }
            return itemsByRow[row][safe: index]
        }
        func invalidLayout() {
            lastWidth = -1
        }
        var lastWidth: CGFloat = -1
        /// after updateLayout, should reload data to use it
        /// - Returns: calculate rows
        func numberOfRows(withWidth width: CGFloat) -> Int {
            assert(Thread.isMainThread, "should occur on main thread!")
            if lastWidth == width { return _itemsByRow?.count ?? 0 }
            defer { lastWidth = width }
            _layoutRows = nil
            guard width > 0, !items.isEmpty else {
                _itemsByRow = []
                return 0
            }
            if let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self), searchOuterService.enableUseNewSearchEntranceOnPad() {
                self.maxFoldRow = searchOuterService.isCompactStatus() ? 2 : 1
            }
            _itemsByRow = nil
            let label = TitleCell.makeLabel()
            // 默认状态放下的数量
            var maxFoldCount = 0
            for row in 0..<self.maxFoldRow {
                let currentItems = items[maxFoldCount...]
                let currentCount = TitleCell.layout(in: width, items: currentItems, fold: .none, sample: label)
                maxFoldCount += currentCount
            }

            if maxFoldCount >= items.count { // 不需要折叠按钮就可以放下
                shouldSupportFold = false
                var count = TitleCell.layout(in: width, items: items, fold: .none, sample: label)
                var itemsByRow = [Array(items[..<count])]
                defer {
                    _layoutRows = itemsByRow.count
                    _itemsByRow = itemsByRow
                }
                var i = count
                if count < items.count {
                    for row in 1..<self.maxFoldRow {
                        let currentItems = items[count...]
                        count = TitleCell.layout(in: width, items: currentItems, fold: .none, sample: label)
                        var j = i + count
                        if j > items.count { j = items.count } // 保护一下潜在的越界crash
                        itemsByRow.append(Array(items[i..<j]))
                        if j == items.count { break }
                        i = j
                    }
                }
            } else if isFold { // 折叠状态
                shouldSupportFold = true
                if self.maxFoldRow < 2 {
                    var count = TitleCell.layout(in: width, items: items, fold: .fold, sample: label)
                    _itemsByRow = [Array(items[..<count])]
                } else {
                    var count = TitleCell.layout(in: width, items: items, fold: .none, sample: label)
                    // 第一行展开态已经计算，且小于results.count, 从第二行开始接着计算
                    var itemsByRow = [Array(items[..<count])]
                    defer {
                        _layoutRows = itemsByRow.count
                        _itemsByRow = itemsByRow
                    }

                    var i = count
                    for row in 1..<self.maxFoldRow {
                        let currentItems = items[count...]
                        let foldType: TitleCell.FoldType = row + 1 == self.maxFoldRow ? .fold : .none
                        count = TitleCell.layout(in: width, items: currentItems, fold: foldType, sample: label)
                        var j = i + count
                        if j == items.count && foldType == .none {
                            // 消耗完了，保证这行能否放下fold btn, 否则换行, 保证fold btn始终显示
                            count = TitleCell.layout(in: width, items: currentItems, fold: .fold, sample: label)
                            j = i + count
                        }
                        if j > items.count { j = items.count } // 保护一下潜在的越界crash
                        itemsByRow.append(Array(items[i..<j]))

                        if j == items.count { break }
                        i = j
                    }
                }
            } else {
                shouldSupportFold = true
                // 第一行展开态已经计算，且小于results.count, 从第二行开始接着计算
                var count = TitleCell.layout(in: width, items: items, fold: .none, sample: label)
                var itemsByRow = [Array(items[..<count])]
                defer {
                    _layoutRows = itemsByRow.count
                    _itemsByRow = itemsByRow
                }

                var i = count
                while i <= items.count {
                    let currentItems = items[i...]
                    var count = TitleCell.layout(in: width, items: currentItems, fold: .none, sample: label)
                    var j = i + count
                    if j == items.count {
                        // 消耗完了，保证这行能否放下unfold btn, 否则换行, 保证unfold btn始终显示
                        count = TitleCell.layout(in: width, items: currentItems, fold: .unfold, sample: label)
                        j = i + count
                    }
                    if j > items.count { j = items.count } // 保护一下潜在的越界crash
                    itemsByRow.append(Array(items[i..<j]))

                    if j == items.count { break }
                    i = j
                }
            }
            assert(_itemsByRow != nil)
            return _itemsByRow?.count ?? 0
        }
    }

    final class CardSection: Equatable {
        let userResolver: UserResolver
        var contentWidth: CGFloat
        let title: String
        var itemPerRow: Int
        private(set) var totalRow: Int
        let items: [UniversalRecommendResult]
        let iconStyle: UniversalRecommend.IconStyle
        let defaultIsFold: Bool
        var shouldShowFoldButton: Bool = true
        let sectionTag: String
        let cellOnPadWidth: CGFloat = 70
        let cellOnPadMargin: CGFloat = 20
        let serverItemPerRow: Int
        let serverTotalRow: Int

        private(set) var isFold: Bool
        init(userResolver: UserResolver,
             contentWidth: CGFloat,
             title: String,
             itemPerRow: Int,
             totalRow: Int,
             items: [UniversalRecommendResult],
             iconStyle: UniversalRecommend.IconStyle,
             defaultIsFold: Bool,
             sectionTag: String
             ) {
            self.userResolver = userResolver
            self.contentWidth = contentWidth
            self.title = title
            self.itemPerRow = itemPerRow
            self.totalRow = totalRow
            self.items = items
            self.iconStyle = iconStyle
            self.defaultIsFold = defaultIsFold
            self.isFold = defaultIsFold
            self.sectionTag = sectionTag
            self.serverItemPerRow = itemPerRow
            self.serverTotalRow = totalRow

            setup()
        }

        private func calPerRow(serverRes: Int) -> Int {
            if let service = try? userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
                if !service.isCompactStatus() {
                    let perRows: CGFloat = self.contentWidth / (cellOnPadWidth + cellOnPadMargin)
                    if perRows > 8 {
                        return 8
                    } else if perRows <= 0 {
                        return serverRes
                    } else {
                        return Int(perRows)
                    }
                } else {
                    return serverRes
                }
            }
            return serverRes
        }

        var contentType: SectionType { return .recommend }

        var didClickFoldButton: (() -> Void)?

        func numberOfRows(withWidth width: CGFloat) -> Int {
            if let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self), searchOuterService.enableUseNewSearchEntranceOnPad() {
                self.contentWidth = width
                setup()
            }
            if isFold {
                return 1
            } else {
                return totalRow
            }
        }

        var showingItems: [UniversalRecommendResult] {
            if isFold {
                return itemsByRow[safe: 0] ?? []
            } else {
                return itemsByRow.flatMap { $0 }
            }
        }

        private(set) var itemsByRow: [[UniversalRecommendResult]] = []
        static func == (lhs: UniversalRecommendSection.CardSection, rhs: UniversalRecommendSection.CardSection) -> Bool {
            if lhs.title != rhs.title {
                return false
            } else if lhs.itemPerRow != rhs.itemPerRow {
                return false
            } else if lhs.items != rhs.items {
                return false
            } else if lhs.iconStyle != rhs.iconStyle {
                return false
            } else if lhs.defaultIsFold != rhs.defaultIsFold {
                return false
            } else if lhs.shouldShowFoldButton != rhs.shouldShowFoldButton {
                return false
            } else if lhs.sectionTag != rhs.sectionTag {
                return false
            } else {
                return true
            }
        }

        private func setup() {
            var currentItemsByRow: [UniversalRecommendResult] = []
            var currentRow = 1
            if let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self), searchOuterService.enableUseNewSearchEntranceOnPad() {
                self.itemPerRow = calPerRow(serverRes: self.serverItemPerRow)
                itemsByRow = []
                totalRow = serverTotalRow
            }

            for item in items {
                if currentItemsByRow.count == itemPerRow {
                    itemsByRow.append(currentItemsByRow)
                    currentItemsByRow = []
                    currentRow += 1
                }
                currentItemsByRow.append(item)
            }

            if !currentItemsByRow.isEmpty {
                itemsByRow.append(currentItemsByRow)
            }

            // 如果后端的数据 totalRow 给高了，使用计算后的争取数据 @秦鹏
            if currentRow < totalRow {
                totalRow = currentRow
            }

            // 如果后端的数据 totalRow 给低了，对数据进行截取 @秦鹏
            if currentRow > totalRow {
                itemsByRow = Array(itemsByRow[0 ..< totalRow])
            }

            shouldShowFoldButton = totalRow > 1
        }

        func fold() {
            isFold = !isFold
        }

        func cellViewModel(forRow row: Int) -> UniversalRecommendCardCellViewModel {
            guard let rowItems = itemsByRow[safe: row] else {
                assertionFailure("Card Section row out of index")
                return UniversalRecommendCardCellViewModel(items: [], totalItems: 0, iconStyle: .rectangle)
            }
            return UniversalRecommendCardCellViewModel(items: rowItems, totalItems: itemPerRow, iconStyle: iconStyle)
        }

        func headerViewModel() -> UniversalRecommendCardHeaderPresentable {
            let vm = UniversalRecommendCardHeaderViewModel(title: title, isFold: isFold, shouldShowFoldButton: shouldShowFoldButton, didClickFoldButton: didClickFoldButton)
            return vm
        }
        func item(forRow row: Int, index: Int) -> UniversalRecommendResult? {
            guard row < itemsByRow.count else {
                return nil
            }
            return itemsByRow[row][safe: index]
        }
    }

    final class ListSection: Equatable {
        let title: String
        let items: [UniversalRecommendResult]
        let iconStyle: UniversalRecommend.IconStyle
        let sectionTag: String

        init(title: String,
             items: [UniversalRecommendResult],
             iconStyle: UniversalRecommend.IconStyle,
             sectionTag: String ) {
            self.title = title
            self.items = items
            self.iconStyle = iconStyle
            self.sectionTag = sectionTag
        }

        var numberOfRows: Int { return items.count }
        var contentType: SectionType { return .recommend }

        static func == (lhs: UniversalRecommendSection.ListSection, rhs: UniversalRecommendSection.ListSection) -> Bool {
            if lhs.title != rhs.title {
                return false
            }
            if lhs.items != rhs.items {
                return false
            }
            if lhs.iconStyle != rhs.iconStyle {
                return false
            }
            if lhs.sectionTag != rhs.sectionTag {
                return false
            }
            return true
        }
    }
}
