//
//  UITextField+Extension.swift
//  TextFiledTest
//
//  Created by SuPeng on 8/7/19.
//  Copyright © 2019 SuPeng. All rights reserved.
//

import Foundation
import UIKit

extension UITextField {
    var selectedRange: NSRange {
        get {
            guard let range = self.selectedTextRange else { return NSRange(location: 0, length: 0) }
            let location = offset(from: beginningOfDocument, to: range.start)
            let length = offset(from: range.start, to: range.end)
            return NSRange(location: location, length: length)
        }
        set {
            let startPosition = position(from: beginningOfDocument, offset: newValue.location) ?? UITextPosition()
            let endPosition = position(from: beginningOfDocument, offset: newValue.location + newValue.length) ?? UITextPosition()
            let selectionRange = textRange(from: startPosition, to: endPosition)
            self.selectedTextRange = selectionRange
        }
    }
}
