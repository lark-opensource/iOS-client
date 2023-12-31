//
//  Extension.swift
//  TangramComponent
//
//  Created by 袁平 on 2021/4/15.
//

import TangramLayoutKit

/// TLValue，TLUnit不符合swift命名规范 & 为避免改动影响，重新包一层
public enum TCUnit {
    case undefined
    case auto
    case pixcel
    case percentage

    public var value: TLUnit {
        switch self {
        case .undefined: return TLUnitUndefined
        case .auto: return TLUnitAuto
        case .pixcel: return TLUnitPixcel
        case .percentage: return TLUnitPercentage
        @unknown default: return TLUnitUndefined
        }
    }
}

// value默认值为0，通过unit区分是否定义
public struct TCValue {
    public var value: CGFloat
    public var unit: TCUnit

    public init(value: CGFloat, unit: TCUnit) {
        self.value = value
        self.unit = unit
    }

    public var tlValue: TLValue {
//        if self == .zero { return TLValueZero }
//        if self == .undefined { return TLValueUndefined }
//        if self == .auto { return TLValueAuto }
        return TLValue(value: Float(value), unit: unit.value)
    }

    public static var zero: TCValue {
        return TCValue(value: 0, unit: .pixcel)
    }

    public static var undefined: TCValue {
        return TCValue(value: 0, unit: .undefined)
    }

    public static var auto: TCValue {
        return TCValue(value: 0, unit: .auto)
    }
}

extension TCValue: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    public init(integerLiteral value: Int) {
        self = TCValue(value: CGFloat(value), unit: .pixcel)
    }

    public init(floatLiteral value: Float) {
        self = TCValue(value: CGFloat(value), unit: .pixcel)
    }

    public init(float value: Float) {
        self = TCValue(value: CGFloat(value), unit: .pixcel)
    }

    public init(cgfloat value: CGFloat) {
        self = TCValue(value: value, unit: .pixcel)
    }
}

extension TCValue: Equatable {
    /// ⚠️`nan == nan`值为false，需要用isNan判断；undefined时value为nan
    public static func == (_ lhs: TCValue, _ rhs: TCValue) -> Bool {
        if lhs.value.isNaN, rhs.value.isNaN { return lhs.unit == rhs.unit }
        return lhs.unit == rhs.unit && lhs.value == rhs.value
    }
}

postfix operator %

extension Int {
    public static postfix func % (value: Int) -> TCValue {
        return TCValue(value: CGFloat(value), unit: .percentage)
    }
}

extension Float {
    public static postfix func % (value: Float) -> TCValue {
        return TCValue(value: CGFloat(value), unit: .percentage)
    }

    public func fixTo() -> CGFloat {
        if isNaN { return 0.0 }
        return CGFloat(self)
    }
}

extension CGFloat {
    public static var undefined: CGFloat {
        // from Yoga: YGUndefined
        return 10e20
    }

    public static postfix func % (value: CGFloat) -> TCValue {
        return TCValue(value: CGFloat(value), unit: .percentage)
    }

    public func fix() -> CGFloat {
        if isNaN { return 0.0 }
        return self
    }
}
