//
//  KVKey+KVValue.swift
//  LarkStorage
//
//  Created by 7Up on 2022/11/8.
//

import Foundation

// MARK: Optional & Non-Optional

/// 表示 non-optional
public protocol KVNonOptional { }
/// 表示 optional
public protocol KVOptional {
    static var nilValue: Self { get }
    var isNil: Bool { get }
}

// MARK: KVClosure

public struct KVClosure<T> {
    var callee: () -> T

    public static func `dynamic`(_ block: @escaping () -> T) -> Self {
        return Self(callee: block)
    }

    public static func `static`(_ store: T) -> Self {
        return Self(callee: { store })
    }
}

// MARK: KVValue

public protocol KVValue: Codable {
    associatedtype StoreType: Codable

    var storeWrapped: StoreType? { get }
    static func fromStore(_ val: StoreType) -> Self
}

extension KVValue where Self: KVNonOptional, Self.StoreType == Self {
    public var storeWrapped: StoreType? {
        Optional.some(self)
    }
    public static func fromStore(_ val: StoreType) -> Self {
        return val
    }
}

public typealias KVNonOptionalValue = KVValue & KVNonOptional

// MARK: KVKey

public struct KVKey<Value: KVValue> {
    public let raw: String
    public var defaultValue: Value { self.defalut.callee() }

    let `defalut`: KVClosure<Value>

    public init(_ raw: String, default defaultValue: KVClosure<Value>) {
        self.raw = raw
        self.defalut = defaultValue
    }

    public init(_ raw: String, default defaultValue: Value) {
        self.init(raw, default: .static(defaultValue))
    }

    public init(_ raw: String) where Value: KVOptional {
        self.init(raw, default: Value.nilValue)
    }
}

public struct KVKeys {}

// FIXME: 如下可模板生成

extension Bool: KVNonOptionalValue {
    public typealias StoreType = Self
}
extension Int: KVNonOptionalValue {
    public typealias StoreType = Self
}
extension Int32: KVNonOptionalValue {
    public typealias StoreType = Self
}
extension Int64: KVNonOptionalValue {
    public typealias StoreType = Self
}
extension Double: KVNonOptionalValue {
    public typealias StoreType = Self
}
extension Float: KVNonOptionalValue {
    public typealias StoreType = Self
}
extension String: KVNonOptionalValue {
    public typealias StoreType = Self
}
extension Data: KVNonOptionalValue {
    public typealias StoreType = Self
}
extension Date: KVNonOptionalValue {
    public typealias StoreType = Self
}
extension CGFloat: KVNonOptionalValue {
    public typealias StoreType = Self
}
extension Dictionary: KVNonOptionalValue where Self: Codable {
    public typealias StoreType = Self
}
extension Array: KVNonOptionalValue where Self: Codable {
    public typealias StoreType = Self
}
extension Optional: KVOptional {
    public static var nilValue: Wrapped? { .none }
    public var isNil: Bool { self == nil }
}
extension Optional: KVValue where Wrapped: Codable {
    public typealias StoreType = Wrapped
    public var storeWrapped: StoreType? {
        switch self {
        case .some(let v): return v
        case .none: return nil
        }
    }

    public static func fromStore(_ val: StoreType) -> Self {
        return .some(val)
    }
}
