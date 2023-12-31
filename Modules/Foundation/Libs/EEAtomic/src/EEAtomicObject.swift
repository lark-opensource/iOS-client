//
//  EEAtomicObject.swift
//  EEAtomic
//
//  Created by SolaWing on 2020/4/29.
//

import Foundation

@_fixed_layout
@propertyWrapper
final public class AtomicObject<T> {
    @usableFromInline var lock = UnfairLockCell()
    @usableFromInline var _value: T

    @inlinable
    public init(_ value: T) {
        _value = value
    }
    @inlinable
    deinit {
        lock.deallocate()
    }

    @inlinable
    public convenience init(initialValue: T) { self.init(initialValue) }
    @inlinable
    public convenience init(wrappedValue: T) { self.init(wrappedValue) }

    @inlinable public var projectedValue: AtomicObject<T> { return self }
    public var wrappedValue: T {
        @inlinable
        get { value }
        @inlinable
        set { value = newValue }
    }
    public var value: T {
        @inlinable
        get { lock.withLocking { _value } }
        @inlinable
        set { lock.withLocking { _value = newValue } }
    }
    // this enable get and set value in one shot
    public func withLocking<R>(_ body: (inout T) throws -> R) rethrows -> R {
        try lock.withLocking { try body(&_value) }
    }
}
