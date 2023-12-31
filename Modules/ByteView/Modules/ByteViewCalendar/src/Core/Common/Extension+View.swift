//
//  Extension+View.swift
//  ByteViewCalendar
//
//  Created by lutingting on 2023/8/22.
//

import Foundation

extension UIView {
    var isHiddenInStackView: Bool {
        get {
            return isHidden
        }
        set {
            if isHidden != newValue {
                isHidden = newValue
            }
        }
    }
}
