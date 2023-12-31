//
//  UniversalRecommendHeaderPresentable.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/17.
//

import Foundation

protocol UniversalRecommendHeaderPresentable {
    var title: String { get }
}

protocol UniversalRecommendChipHeaderPresentable: UniversalRecommendHeaderPresentable {
    var shouldHideClickButton: Bool { get }
    var didClickClearButton: () -> Void { get }
}

protocol UniversalRecommendCardHeaderPresentable: UniversalRecommendHeaderPresentable {
    var isFold: Bool { get }
    var shouldShowFoldButton: Bool { get }
    var didClickFoldButton: (() -> Void)? { get }
}

protocol UniversalRecommendListHeaderPresentable: UniversalRecommendHeaderPresentable {}
