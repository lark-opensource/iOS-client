//
//  Priority.swift
//  RunloopTools
//
//  Created by KT on 2019/9/20.
//

import Foundation

/// Task执行优先级
public struct Priority: ExpressibleByFloatLiteral, Equatable, Strideable, Hashable {
    public typealias FloatLiteralType = Float

    public let value: Float

    public init(floatLiteral value: Float) {
        self.value = value
    }

    public init(_ value: Float) {
        self.value = value
    }

    /// 最高优先级
    public static var emergency: Priority {
        return 1250.0
    }
    /// 高优先级
    public static var required: Priority {
        return 1000.0
    }

    public static var high: Priority {
        return 750.0
    }

    public static var medium: Priority {
        return 500.0
    }

    public static var low: Priority {
        return 250.0
    }

    // MARK: Strideable
    public func advanced(by n: FloatLiteralType) -> Priority {
        return Priority(floatLiteral: value + n)
    }

    public func distance(to other: Priority) -> FloatLiteralType {
        return other.value - value
    }
}
