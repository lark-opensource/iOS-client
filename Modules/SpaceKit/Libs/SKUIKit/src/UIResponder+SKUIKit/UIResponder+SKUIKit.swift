//
//  UIResponder+SKUIKit.swift
//  SKUIKit
//
//  Created by Weston Wu on 2021/2/3.
//

import Foundation
import SKFoundation

extension UIResponder: SKExtensionCompatible {
    @objc
    fileprivate func findSKFirstResponder(_ sender: Any) {
        UIResponder.sk.skFirstResponder = self
    }
}

public extension SKExtension where Base == UIResponder {
    fileprivate static weak var skFirstResponder: UIResponder?

    static var currentFirstResponder: UIResponder? {
        skFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findSKFirstResponder(_:)), to: nil, from: nil, for: nil)
        return skFirstResponder
    }
}
