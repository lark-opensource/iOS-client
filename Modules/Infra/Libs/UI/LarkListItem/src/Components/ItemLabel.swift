//
//  ItemLabel.swift
//  AnimatedTabBar
//
//  Created by 姚启灏 on 2020/8/17.
//

import Foundation
import UIKit

public final class ItemLabel: UILabel {
    public var textChangedCallback: ((String?, NSAttributedString?) -> Void)?
    /// attributedText不置为空会有bug，text会携带attributedText的ui属性
    override public var text: String? {
        get {
            super.text
        }
        set {
            super.attributedText = nil
            super.text = newValue
            textChangedCallback?(newValue, nil)
        }
    }

    override public var attributedText: NSAttributedString? {
        get {
            super.attributedText
        }
        set {
            super.attributedText = newValue
            textChangedCallback?(text, newValue)
        }
    }
}
