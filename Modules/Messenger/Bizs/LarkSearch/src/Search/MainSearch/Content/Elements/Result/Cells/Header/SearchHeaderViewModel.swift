//
//  SearchHeaderViewModel.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/21.
//

import UIKit
import Foundation
import SnapKit

final class SearchHeaderViewModel {
    let icon: UIImage?
    let title: String
    let label: String?
    let titleColor: UIColor
    let actionText: String

    var didTapHeader: ((SearchTableHeaderView) -> Void)?
    var contentConstraint: ((ConstraintMaker) -> Void)?
    var shouldEnableActionButton: ((Bool) -> Void)?

    init(icon: UIImage? = nil,
         title: String,
         label: String? = nil,
         actionText: String,
         titleColor: UIColor = UIColor.ud.textTitle) {
        self.icon = icon
        self.title = title
        self.label = label
        self.actionText = actionText
        self.titleColor = titleColor
    }

    func headerTappingAction(_ view: SearchTableHeaderView) {
        didTapHeader?(view)
    }

    func setHeaderActionVisible(_ isVisible: Bool) {
        shouldEnableActionButton?(isVisible)
    }
}
