//
//  UIButton+Padding.swift
//
//
//  Created by yangyao on 2020/11/20.
//

import UIKit

var byteViewButtonPaddingAssociationKey = "ByteViewButtonPaddingAssociationKey"

public extension UIButton {
    var buttonPadding: CGFloat? {
        get {
            return objc_getAssociatedObject(self, &byteViewButtonPaddingAssociationKey) as? CGFloat
        }
        set(newValue) {
            objc_setAssociatedObject(self, &byteViewButtonPaddingAssociationKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    convenience public init(type: UIButton.ButtonType, padding: CGFloat) {
        self.init(type: type)

        self.buttonPadding = padding
    }

    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let buttonPadding = buttonPadding {
            let newArea = CGRect(x: bounds.origin.x - buttonPadding,
                                 y: bounds.origin.y - buttonPadding,
                                 width: bounds.size.width + buttonPadding * 2,
                                 height: bounds.size.height + buttonPadding * 2)
            return newArea.contains(point)
        } else {
            return super.point(inside: point, with: event)
        }
    }
}
