//
//  Once.swift
//  EEAtomic
//
//  Created by SolaWing on 2020/3/6.
//

import Foundation

/// a wrapper for dispatch_once, for instance lazy initial
@_fixed_layout
final public class AtomicOnce {
    public let pointer: UnsafeMutablePointer<c_dispatch_once_token>
    @inlinable
    public init() {
        self.pointer = c_dispatch_once_token.create()
    }
    @inlinable
    deinit {
        c_dispatch_once_token.destroy(pointer)
    }
    @inlinable
    public func once(execute: () -> Void) {
        c_dispatch_once_token.exec(self.pointer, execute: execute)
    }
}

@_fixed_layout
@propertyWrapper
final public class SafeLazy<Value> {
    @usableFromInline
    @frozen
    enum Storage {
        case uninitialized(() -> Value)
        case initialized(Value)
    }
    @usableFromInline var storage: Storage
    @usableFromInline var token = AtomicOnce()

// 即使标记为@autoclosure, @propertyWrapper仍然不能lazy eval..
    @available(swift, // https://github.com/apple/swift/pull/30537
        introduced: 5.3,
        message: "https://github.com/apple/swift/pull/30537")
    @inlinable
    public init(wrappedValue: @autoclosure @escaping () -> Value) {
        storage = .uninitialized(wrappedValue)
    }
    @inlinable
    public init(block: @escaping () -> Value) {
        storage = .uninitialized(block)
    }
    @inlinable
    public init(expr: @autoclosure @escaping () -> Value) {
        storage = .uninitialized(expr)
    }

    @inlinable public var value: Value { wrappedValue }
    @inlinable public var wrappedValue: Value {
        token.once {
            switch storage {
            case .uninitialized(let initializer):
                let value = initializer()
                self.storage = .initialized(value)
            case .initialized:
                break // already init, ignored
            }
        }
        guard case let .initialized(value) = storage else {
            fatalError("after once execute, value must already init")
        }
        return value
    }
    @inlinable public var projectedValue: SafeLazy<Value> { return self }
}
