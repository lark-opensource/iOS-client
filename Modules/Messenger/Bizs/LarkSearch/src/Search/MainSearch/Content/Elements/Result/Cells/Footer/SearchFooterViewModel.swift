//
//  SearchFooterViewModel.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/3/5.
//

import UIKit
import Foundation
import SnapKit

final class SearchFooterViewModel {
    let icon: UIImage?
    let titleColor: UIColor
    let actionText: String

    var didTapFooter: ((SearchTableFooterView) -> Void)?

    init(icon: UIImage? = nil,
         actionText: String,
         titleColor: UIColor = UIColor.ud.textTitle) {
        self.icon = icon
        self.actionText = actionText
        self.titleColor = titleColor
    }

    func footerTappingAction(_ view: SearchTableFooterView) {
        didTapFooter?(view)
    }
}
