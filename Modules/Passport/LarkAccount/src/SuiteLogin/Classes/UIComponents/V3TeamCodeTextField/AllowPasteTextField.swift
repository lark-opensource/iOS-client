//
//  AllowPasteTextField.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/5.
//

import Foundation
/// only paste  action
class AllowPasteTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) && text?.isEmpty ?? true {
           return true
        }
        return false
    }
}
