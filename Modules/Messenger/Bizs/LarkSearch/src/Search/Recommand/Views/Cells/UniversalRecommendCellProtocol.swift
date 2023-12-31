//
//  SearchRecommendCellProtocol.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/23.
//

import Foundation

protocol UniversalRecommendCellProtocol: SearchCellProtocol {
    func setup(withViewModel viewModel: UniversalRecommendCellPresentable, isLastRow: Bool?)
}

extension UniversalRecommendCellProtocol {
    func setup(withViewModel viewModel: UniversalRecommendCellPresentable) {
        setup(withViewModel: viewModel, isLastRow: nil)
    }
}
