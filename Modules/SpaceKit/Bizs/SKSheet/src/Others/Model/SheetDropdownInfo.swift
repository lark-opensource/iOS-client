//
// Created by duanxiaochen.7 on 2021/2/19.
// Affiliated with SKSheet.
//
// Description:

import SKUIKit
import Foundation
import UniverseDesignColor
import UIKit

class SheetDropdownInfo {
    var index = 0
    var isSelected = false
    var optionValue = ""
    var optionColorHex: String?
    var optionColor: UIColor?
    var textColor: UIColor

    init(index: Int, value: String, bgColorHex: String? = nil, textColorHex: String, selected: Bool) {
        self.index = index
        optionValue = value
        isSelected = selected
        if let colorHex = bgColorHex {
            optionColorHex = colorHex
            optionColor = UIColor.docs.rgb(colorHex)
        } else {
            optionColorHex = nil
            optionColor = nil
        }
        if textColorHex.isEmpty {
            textColor = UDColor.textTitle
        } else {
            textColor = UIColor.docs.rgb(textColorHex)
        }
    }
}
