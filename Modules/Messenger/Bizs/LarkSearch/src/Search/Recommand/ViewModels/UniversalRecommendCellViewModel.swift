//
//  UniversalRecommendCellViewModel.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/24.
//

import UIKit
import Foundation

final class UniversalRecommendCardCellViewModel: UniversalRecommendCardCellPresentable {
    let items: [UniversalRecommendResult]
    let totalItems: Int
    let iconStyle: UniversalRecommend.IconStyle
    var didSelectItem: ((Int) -> Void)?

    init(items: [UniversalRecommendResult], totalItems: Int, iconStyle: UniversalRecommend.IconStyle) {
        self.items = items
        self.totalItems = totalItems
        self.iconStyle = iconStyle
    }
}

final class UniversalRecommendChipCellViewModel: UniversalRecommendChipCellPresentable {
    let items: [UniversalRecommendChipItem]
    let foldType: UniversalRecommendChipCell.FoldType
    var didSelectItem: ((Int) -> Void)?
    var didSelectFold: ((Bool) -> Void)?
    var sectionWidth: (() -> CGFloat?)?

    init(items: [UniversalRecommendChipItem], foldType: UniversalRecommendChipCell.FoldType) {
        self.items = items
        self.foldType = foldType
    }
}
