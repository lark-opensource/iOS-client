//
//  LarkConstraintExtension.swift
//  EEAtomic
//
//  Created by Hayden on 2020/11/20.
//

import UIKit
import Foundation
import yoga
import UniverseDesignFont

// Support YGValue.
extension UDConstraintCompatible {

    /// Default implimentation for fixed(), returning a BinaryInteger value.
    public func fixed() -> YGValue {
        return YGValue(value: fixed(), unit: .point)
    }

    /// Default implimentation for fixed(_:), returning a BinaryInteger value.
    public static func fixed(_ num: Self) -> YGValue {
        return YGValue(value: fixed(num), unit: .point)
    }

    /// Default implimentation for auto(), returning a BinaryInteger value.
    public func auto(_ transformer: Zoom.Transformer = .s6) -> YGValue {
        return YGValue(value: auto(transformer), unit: .point)
    }

    /// Default implimentation for auto(_:), returning a BinaryInteger value.
    public static func auto(_ num: Self, for transformer: Zoom.Transformer = .s6) -> YGValue {
        return YGValue(value: auto(num, for: transformer), unit: .point)
    }
}

extension CGFloat {

    /// Convert CGFloat to YGValue (CSSValue).
    public var css: YGValue {
        return YGValue(value: Float(self), unit: .point)
    }
}
