//
//  FeedFilterSelectionHandler.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/16.
//

import Foundation
import RxSwift
import RxRelay
import RustPB

struct FeedFilterSelection: Equatable {
    let filterType: Feed_V1_FeedFilter.TypeEnum
    let secLevelId: String?

    init(type: Feed_V1_FeedFilter.TypeEnum,
         secLevelId: String?) {
        self.filterType = type
        self.secLevelId = secLevelId
    }

    static func defaultSelection() -> FeedFilterSelection {
        let selection = FeedFilterSelection(type: .inbox, secLevelId: nil)
        return selection
    }

    static func == (lhs: FeedFilterSelection, rhs: FeedFilterSelection) -> Bool {
        return lhs.filterType == rhs.filterType && lhs.secLevelId == rhs.secLevelId
    }
}

/// 对外部提供的分组选中能力
protocol FeedFilterSelectionAbility {
    var currentSelection: FeedFilterSelection { get }
    var selectionObservable: Observable<FeedFilterSelection> { get }
    func updateFilterSelection(_ selection: FeedFilterSelection)
}

/// 分组选中能力的操作集合
final class FeedFilterSelectionHandler: FeedFilterSelectionAbility {
    private let selectionService: FeedFilterSelectionService // 接收外部选中执行操作

    init(selectionService: FeedFilterSelectionService) {
        self.selectionService = selectionService
    }

    // MARK: - FeedFilterSelectionAbility
    var currentSelection: FeedFilterSelection {
        selectionService.currentSelection
    }

    var selectionObservable: Observable<FeedFilterSelection> {
        return selectionService.dataObservable
    }

    func updateFilterSelection(_ selection: FeedFilterSelection) {
        selectionService.updateFilterSelection(selection)
    }
}
