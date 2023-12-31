//
//  UIStackView+Fixed.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/18.
//

import Foundation
import SKFoundation

private var backgroundViewKey: UInt8 = 0

extension UIStackView {
    private var backgroundView: UIView? {
        get {
            return objc_getAssociatedObject(self, &backgroundViewKey) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &backgroundViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func fixBackgroundColor(backgroundColor: UIColor? = nil, cornerRadius: CGFloat = 0) {
        if #available(iOS 14.0, *) {
            self.backgroundColor = backgroundColor
            self.layer.cornerRadius = cornerRadius
        } else {
            if backgroundColor != nil && backgroundColor != .clear {
                let backgroundView: UIView
                if let view = self.backgroundView {
                    backgroundView = view
                } else {
                    backgroundView = UIView(frame: self.bounds)
                    self.insertSubview(backgroundView, at: 0)
                    backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                }
                self.backgroundView = backgroundView
            }
            self.backgroundView?.backgroundColor = backgroundColor
            self.backgroundView?.layer.cornerRadius = cornerRadius
        }
    }
}
