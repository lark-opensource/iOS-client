//
//  SKUDBaseTextField.swift
//  SKUIKit
//
//  Created by huangzhikai on 2022/9/19.
//

import Foundation
import UniverseDesignInput
//
public final class SKUDBaseTextField: UDTextField {
    override public init(config: UDTextFieldUIConfig = UDTextFieldUIConfig()) {
        super.init(config: config, textFieldType: SKBaseTextField.self)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
