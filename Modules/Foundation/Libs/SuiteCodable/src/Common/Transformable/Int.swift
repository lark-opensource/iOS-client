//
//  Int.swift
//  SuiteCodable
//
//  Created by liuwanlin on 2019/5/4.
//

import Foundation

protocol IntegerProperty: Transformable, FixedWidthInteger {}

extension IntegerProperty {
    // swiftlint:disable cyclomatic_complexity
    static func transform(from object: Any) -> Self? {
        switch object {
        case let num as Self:
            return num
        case let str as String:
            return Self(str, radix: 10)
        case let num as Int:
            return Self(truncatingIfNeeded: num)
        case let num as Int8:
            return Self(truncatingIfNeeded: num)
        case let num as Int16:
            return Self(truncatingIfNeeded: num)
        case let num as Int32:
            return Self(truncatingIfNeeded: num)
        case let num as Int64:
            return Self(truncatingIfNeeded: num)
        case let num as UInt:
            return Self(truncatingIfNeeded: num)
        case let num as UInt8:
            return Self(truncatingIfNeeded: num)
        case let num as UInt16:
            return Self(truncatingIfNeeded: num)
        case let num as UInt32:
            return Self(truncatingIfNeeded: num)
        case let num as UInt64:
            return Self(truncatingIfNeeded: num)
        default:
            return nil
        }
    }
}

extension Int: IntegerProperty, HasDefault {
    public static func `default`() -> Int {
        return 0
    }
}
extension Int8: IntegerProperty, HasDefault {
    public static func `default`() -> Int8 {
        return 0
    }
}
extension Int16: IntegerProperty, HasDefault {
    public static func `default`() -> Int16 {
        return 0
    }
}
extension Int32: IntegerProperty, HasDefault {
    public static func `default`() -> Int32 {
        return 0
    }
}
extension Int64: IntegerProperty, HasDefault {
    public static func `default`() -> Int64 {
        return 0
    }
}
extension UInt: IntegerProperty, HasDefault {
    public static func `default`() -> UInt {
        return 0
    }
}
extension UInt8: IntegerProperty, HasDefault {
    public static func `default`() -> UInt8 {
        return 0
    }
}
extension UInt16: IntegerProperty, HasDefault {
    public static func `default`() -> UInt16 {
        return 0
    }
}
extension UInt32: IntegerProperty, HasDefault {
    public static func `default`() -> UInt32 {
        return 0
    }
}
extension UInt64: IntegerProperty, HasDefault {
    public static func `default`() -> UInt64 {
        return 0
    }
}
