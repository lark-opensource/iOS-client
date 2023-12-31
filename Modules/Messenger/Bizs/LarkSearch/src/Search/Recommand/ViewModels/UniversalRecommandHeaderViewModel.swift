//
//  UniversalRecommandHeaderViewModel.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/18.
//

import Foundation

final class UniversalRecommendChipHeaderViewModel: UniversalRecommendChipHeaderPresentable {
    let title: String
    var shouldHideClickButton: Bool = false
    let didClickClearButton: () -> Void

    init(title: String, didClickClearButton: @escaping () -> Void) {
        self.title = title
        self.didClickClearButton = didClickClearButton
    }
}

final class UniversalRecommendCardHeaderViewModel: UniversalRecommendCardHeaderPresentable {
    let title: String
    let isFold: Bool
    let shouldShowFoldButton: Bool
    let didClickFoldButton: (() -> Void)?

    init(title: String, isFold: Bool, shouldShowFoldButton: Bool, didClickFoldButton: (() -> Void)?) {
        self.title = title
        self.isFold = isFold
        self.shouldShowFoldButton = shouldShowFoldButton
        self.didClickFoldButton = didClickFoldButton
    }
}

struct UniversalRecommendListHeaderViewModel: UniversalRecommendListHeaderPresentable {
    let title: String
}
