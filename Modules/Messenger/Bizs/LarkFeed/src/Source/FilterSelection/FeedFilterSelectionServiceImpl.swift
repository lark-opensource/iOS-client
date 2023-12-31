//
//  FeedFilterSelectionServiceImpl.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/16.
//

import Foundation
import RxRelay
import RxSwift

final class FeedFilterSelectionServiceImpl: FeedFilterSelectionService {
    private let selectionRelay = BehaviorRelay<FeedFilterSelection>(value: FeedFilterSelection.defaultSelection())

    var currentSelection: FeedFilterSelection {
        return selectionRelay.value
    }

    var dataObservable: Observable<FeedFilterSelection> {
        return selectionRelay.asObservable()
    }

    func updateFilterSelection(_ selection: FeedFilterSelection) {
        selectionRelay.accept(selection)
    }

    private func defaultSelection() -> FeedFilterSelection {
        let selection = FeedFilterSelection(type: .inbox, secLevelId: nil)
        return selection
    }
}
