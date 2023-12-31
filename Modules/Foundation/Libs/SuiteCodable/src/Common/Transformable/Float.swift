//
//  Float.swift
//  SuiteCodable
//
//  Created by liuwanlin on 2019/5/4.
//

import Foundation

protocol FloatProperty: Transformable, LosslessStringConvertible {
    init(_ float: FloatProperty)
}

extension FloatProperty {
    static func transform(from object: Any) -> Self? {
        switch object {
        case let num as FloatProperty:
            return Self(num)
        case let str as String:
            return Self(str)
        default:
            return nil
        }
    }
}

extension Float: FloatProperty, HasDefault {
    init(_ float: FloatProperty) {
        switch float {
        case let num as Float:
            self = num
        case let num as Double:
            self = Float(num)
        default:
            self = 0.0
        }
    }

    public static func `default`() -> Float {
        return 0.0
    }
}

extension Double: FloatProperty, HasDefault {
    init(_ float: FloatProperty) {
        switch float {
        case let num as Double:
            self = num
        case let num as Float:
            self = Double(num)
        default:
            self = 0.0
        }
    }

    public static func `default`() -> Double {
        return 0.0
    }
}
