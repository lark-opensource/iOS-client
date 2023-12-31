//
//  SwiftExtention.swift
//  EEFlexiable
//
//  Created by qihongye on 2018/11/26.
//

import UIKit
import Foundation
postfix operator %

extension Int {
    public static postfix func % (value: Int) -> CSSValue {
        return CSSValue(value: Float(value), unit: .percent)
    }
}

extension Float {
    public static postfix func % (value: Float) -> CSSValue {
        return CSSValue(value: value, unit: .percent)
    }

    public static var CSSUndefined: Float {
        return YGUndefined
    }
}

extension CGFloat {
    public static postfix func % (value: CGFloat) -> CSSValue {
        return CSSValue(value: Float(value), unit: .percent)
    }

    public static var CSSUndefined: CGFloat {
        return CGFloat(Float.CSSUndefined)
    }
}

extension CSSValue: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public init(integerLiteral value: Int) {
        self = CSSValue(value: Float(value), unit: .point)
    }

    public init(floatLiteral value: Float) {
        self = CSSValue(value: value, unit: .point)
    }

    public init(float value: Float) {
        self = CSSValue(value: value, unit: .point)
    }

    public init(cgfloat value: CGFloat) {
        self = CSSValue(value: Float(value), unit: .point)
    }
}

extension CSSValue: Equatable {
    public static func == (_ lhs: CSSValue, _ rhs: CSSValue) -> Bool {
        return lhs.unit == rhs.unit && lhs.value == rhs.value
    }
}

extension CSSValue: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "value: \(value), unit: \(unit)"
    }
}

extension CSSUnit: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .auto:
            return "auto"
        case .percent:
            return "percent"
        case .point:
            return "point"
        case .undefined:
            return "undefined"
        @unknown default:
            assertionFailure()
            return "unknown"
        }
    }
}
