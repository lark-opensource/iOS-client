//
//  LKBackspaceDetectingTextField.swift
//  LKTokenInputView
//
//  Created by majx on 05/26/19 from CLTokenInputView-Swift by Robert La Ferla.
//  
//

import Foundation
import UIKit
import LarkEMM

protocol LKBackspaceDetectingTextFieldDelegate: UITextFieldDelegate {
    func textFieldDidDeleteBackwards(textField: UITextField)
    func textFieldDidPaste()
    func textFieldDidSelectAll()
}

class LKBackspaceDetectingTextField: UITextField {
    var myDelegate: LKBackspaceDetectingTextFieldDelegate? {
        get { return self.delegate as? LKBackspaceDetectingTextFieldDelegate }
        set { self.delegate = newValue }
    }

    override func deleteBackward() {
        if self.text?.isEmpty ?? false {
            self.textFieldDidDeleteBackwards(textField: self)
        }
        super.deleteBackward()
    }

    func textFieldDidDeleteBackwards(textField: UITextField) {
        myDelegate?.textFieldDidDeleteBackwards(textField: textField)
    }

    override func paste(_ sender: Any?) {
        super.paste(sender)
        if SCPasteboard.general(SCPasteboard.defaultConfig()).hasStrings {
            myDelegate?.textFieldDidPaste()
        }
    }
    override func selectAll(_ sender: Any?) {
        super.selectAll(sender)
        myDelegate?.textFieldDidSelectAll()
    }
}
