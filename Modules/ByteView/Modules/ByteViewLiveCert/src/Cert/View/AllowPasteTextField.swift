//
//  AllowPasteTextField.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit

/// only paste  action
final class AllowPasteTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) && text?.isEmpty ?? true {
           return true
        }
        return false
    }
}
