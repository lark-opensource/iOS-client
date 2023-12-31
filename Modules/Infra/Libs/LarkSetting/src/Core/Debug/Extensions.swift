//
//  Extensions.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/11/2.
//

import UIKit
import Foundation
#if ALPHA

extension UITextView {
    func customize() {
        autocapitalizationType = .none
        spellCheckingType = .no
        smartDashesType = .no
        smartQuotesType = .no
        smartInsertDeleteType = .no
        autocorrectionType = .no
    }
}

extension UITextField {
    func customize(with content: String? = nil) {
        text = content
        autocapitalizationType = .none
        spellCheckingType = .no
        smartDashesType = .no
        smartQuotesType = .no
        smartInsertDeleteType = .no
        autocorrectionType = .no
    }
}

#endif
