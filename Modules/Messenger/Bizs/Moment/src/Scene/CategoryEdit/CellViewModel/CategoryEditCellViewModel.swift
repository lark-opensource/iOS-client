//
//  CategoryEditCellViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/5/14.
//

import Foundation
import UIKit

final class CategoryEditCellViewModel: NSObject {
    let tab: RawData.PostTab
    let isSelected: Bool
    var onEditing = false
    var section: Int = 0

    var canRemove: Bool {
        return tab.canRemove
    }
    var iconImage: UIImage {
        return section != CategoryEditViewModel.cannotMoveSection ? Resources.categoryDele : Resources.categoryAdd
    }
    var showAnimation: Bool {
        if !onEditing {
            return false
        }
        if section == CategoryEditViewModel.cannotMoveSection {
            return false
        }
        return tab.canRemove
    }

    init(tab: RawData.PostTab, isSelected: Bool) {
        self.tab = tab
        self.isSelected = isSelected
    }
}
