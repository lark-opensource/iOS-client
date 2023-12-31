//
//  CheckboxNormalCellProp.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/27.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignCheckBox

open class CheckboxNormalCellProp: NormalCellProp {
    var isOn: Bool = false
    var isEnabled: Bool = true
    var boxType: UDCheckBoxType = .single
    public init(title: String,
         detail: String? = nil,
         boxType: UDCheckBoxType = .single,
         isOn: Bool,
         isEnabled: Bool = true,
         accessories: [NormalCellAccessory] = [],
         cellIdentifier: String = "CheckboxNormalCell",
         separatorLineStyle: CellSeparatorLineStyle = .normal,
         selectionStyle: CellSelectionStyle = .normal,
         id: String? = nil,
         onClick: ClickHandler? = nil) {
        self.isOn = isOn
        self.isEnabled = isEnabled
        self.boxType = boxType
        super.init(title: title,
                   detail: detail,
                   accessories: accessories,
                   cellIdentifier: cellIdentifier,
                   separatorLineStyle: separatorLineStyle,
                   selectionStyle: isEnabled ? selectionStyle : .none,
                   id: id,
                   onClick: onClick)
    }
}

open class CheckboxNormalCell: NormalCell {
    var isEnabled: Bool = true
    public let checkBox = UDCheckBox()

    public override func getLeadingView() -> UIView? {
        return checkBox
    }

    open override func update(_ info: CellProp) {
        super.update(info)
        guard let info = info as? CheckboxNormalCellProp else { return }
        isEnabled = info.isEnabled
        checkBox.updateUIConfig(boxType: info.boxType, config: checkBox.config)
        checkBox.isEnabled = info.isEnabled
        checkBox.isSelected = info.isOn
        checkBox.tapCallBack = { [weak self] _ in
            guard let self = self else { return }
            info.onClick?(self)
        }
    }
}
