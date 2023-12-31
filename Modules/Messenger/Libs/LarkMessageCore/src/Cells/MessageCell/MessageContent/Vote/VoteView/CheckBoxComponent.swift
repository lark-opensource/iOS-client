//
//  CheckBoxComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/21.
//

import Foundation
import AsyncComponent
import LarkMessageBase
import LarkUIKit
import UniverseDesignCheckBox
import UIKit

/// default is multiple style
final public class LKCheckboxComponentProps: ASComponentProps {
    public var isSelected: Bool = false
    public var isEnabled: Bool = false
    public var boxType: UDCheckBoxType = .multiple
    public var unselectDisableBgColor = UIColor.ud.neutralColor1
}

public final class LKCheckboxComponent<C: ComponentContext>: ASComponent<LKCheckboxComponentProps, EmptyState, UDCheckBox, C> {
    public override func create(_ rect: CGRect) -> UDCheckBox {
        let checkBox = UDCheckBox(boxType: .multiple)
        // 数据驱动 PureComponent
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }

    public override func update(view: UDCheckBox) {
        view.isSelected = props.isSelected
        view.isEnabled = props.isEnabled
        var config = view.config
        config.unselectedBackgroundDisableColor = props.unselectDisableBgColor
        view.updateUIConfig(boxType: props.boxType, config: config)
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return LKCheckbox.calculateSize()
    }
}
