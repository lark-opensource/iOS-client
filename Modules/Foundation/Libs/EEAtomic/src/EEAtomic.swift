//
//  EEAtomic.swift
//  EEAtomic
//
//  Created by SolaWing on 2019/12/24.
//

import Foundation

// MARK: - Atomic Generic API
// swiftlint:disable attributes
/// C API generic wrap
public protocol CAtomicValue {
    associatedtype Value
    @inlinable static func create(_ value: Value) -> UnsafeMutablePointer<Self>
    @inlinable static func destroy(_ wrapper: UnsafeMutablePointer<Self>)
    @inlinable static func load(_ wrapper: UnsafeMutablePointer<Self>, order: memory_order) -> Value
    @inlinable static func store(_ wrapper: UnsafeMutablePointer<Self>, value: Value, order: memory_order)
    @inlinable static func exchange(_ wrapper: UnsafeMutablePointer<Self>, value: Value, order: memory_order) -> Value
    @inlinable static func compare(_ wrapper: UnsafeMutablePointer<Self>, expected: Value, replace desired: Value, weak: Bool, order: memory_order) -> Bool
    @inlinable static func add(_ wrapper: UnsafeMutablePointer<Self>, value: Value, order: memory_order) -> Value
    @inlinable static func sub(_ wrapper: UnsafeMutablePointer<Self>, value: Value, order: memory_order) -> Value
    @inlinable static func or(_ wrapper: UnsafeMutablePointer<Self>, value: Value, order: memory_order) -> Value
    @inlinable static func xor(_ wrapper: UnsafeMutablePointer<Self>, value: Value, order: memory_order) -> Value
    @inlinable static func and(_ wrapper: UnsafeMutablePointer<Self>, value: Value, order: memory_order) -> Value
}

/// Swift Atomic API
public protocol AtomicAPI {
    associatedtype CType: CAtomicValue
    typealias Value = CType.Value
    var pointer: UnsafeMutablePointer<CType> { get }
    // init
    // deallocate | deinit
}

public extension AtomicAPI {
    @inlinable
    var value: CType.Value {
        get { return CType.load(pointer, order: memory_order_seq_cst) }
        nonmutating set { CType.store(pointer, value: newValue, order: memory_order_seq_cst) }
    }
    /// Returns: old value
    @inlinable
    func exchange(_ value: CType.Value, order: MemoryOrder = .seqCst) -> CType.Value {
        return CType.exchange(pointer, value: value, order: order.asCType)
    }
    /// compare with expected, if true then do replace. return true if do replace
    /// Parameters:
    ///   weak: if true, compare may be false even actually equal, usually used in a while loop. this may gain some performance
    /// Returns: old value
    @inlinable
    func compare(expected: CType.Value, replace: CType.Value, weak: Bool = false, order: MemoryOrder = .seqCst) -> Bool {
        return CType.compare(pointer, expected: expected, replace: replace, weak: weak, order: order.asCType)
    }
    /// Returns: old value
    @discardableResult
    @inlinable
    func add(_ value: CType.Value, order: MemoryOrder = .seqCst) -> CType.Value {
        return CType.add(pointer, value: value, order: order.asCType)
    }
    /// Returns: old value
    @discardableResult
    @inlinable
    func sub(_ value: CType.Value, order: MemoryOrder = .seqCst) -> CType.Value {
        return CType.sub(pointer, value: value, order: order.asCType)
    }

    /// Returns: old value
    @discardableResult
    @inlinable
    func and(_ value: CType.Value, order: MemoryOrder = .seqCst) -> CType.Value {
        return CType.and(pointer, value: value, order: order.asCType)
    }
    /// Returns: old value
    @discardableResult
    @inlinable
    func or(_ value: CType.Value, order: MemoryOrder = .seqCst) -> CType.Value {
        return CType.or(pointer, value: value, order: order.asCType)
    }
    /// Returns: old value
    @discardableResult
    @inlinable
    func xor(_ value: CType.Value, order: MemoryOrder = .seqCst) -> CType.Value {
        return CType.xor(pointer, value: value, order: order.asCType)
    }
}

public extension AtomicAPI where CType.Value: FixedWidthInteger {
    /// Returns: old value
    @discardableResult
    @inlinable
    func increment(order: MemoryOrder = .seqCst) -> CType.Value {
        return CType.add(pointer, value: 1, order: order.asCType)
    }
    /// Returns: old value
    @discardableResult
    @inlinable
    func decrement(order: MemoryOrder = .seqCst) -> CType.Value {
        return CType.sub(pointer, value: 1, order: order.asCType)
    }
}

// MARK: - Implementation
extension c_atomic_bool: CAtomicValue {
    public typealias Value = Bool
}
extension c_atomic_uintptr_t: CAtomicValue {
    public typealias Value = UInt
}
extension c_atomic_int64_t: CAtomicValue {
    public typealias Value = Int64
}
extension c_atomic_uint64_t: CAtomicValue {
    public typealias Value = UInt64
}

/// manual manage the atomic storage's life, use deallocate to release it
/// though it's a struct, assign still share the storage..
/// NOTE: you should use the alias type instead of this one directly

@frozen
public struct AtomicCell<CType: CAtomicValue>: AtomicAPI {
    public let pointer: UnsafeMutablePointer<CType>
    @inlinable
    public init(_ value: Value) {
        self.pointer = CType.create(value)
    }
    @inlinable
    public func deallocate() {
        CType.destroy(pointer)
    }
}
public extension AtomicCell where Value: BinaryInteger {
    @inlinable
    init() { self.pointer = CType.create(Value()) }
}
public extension AtomicCell where Value == Bool {
    @inlinable
    init() { self.pointer = CType.create(Value()) }
}

public typealias AtomicBoolCell = AtomicCell<c_atomic_bool>
public typealias AtomicUIntCell = AtomicCell<c_atomic_uintptr_t>
public typealias AtomicUInt64Cell = AtomicCell<c_atomic_uint64_t>
public typealias AtomicInt64Cell = AtomicCell<c_atomic_int64_t>

/// a class version, auto destroy atomic value
/// NOTE: you should use the alias type instead of this one directly
@_fixed_layout
public final class AtomicRef<CType: CAtomicValue>: AtomicAPI {
    public let pointer: UnsafeMutablePointer<CType>
    @inlinable
    public init(_ value: Value) {
        self.pointer = CType.create(value)
    }
    @inlinable
    deinit {
        CType.destroy(pointer)
    }
}
public extension AtomicRef where Value: BinaryInteger {
    @inlinable
    convenience init() { self.init(Value()) }
}
public extension AtomicRef where Value == Bool {
    @inlinable
    convenience init() { self.init(Value()) }
}
public typealias AtomicBool = AtomicRef<c_atomic_bool>
public typealias AtomicUInt = AtomicRef<c_atomic_uintptr_t>
public typealias AtomicUInt64 = AtomicRef<c_atomic_uint64_t>
public typealias AtomicInt64 = AtomicRef<c_atomic_int64_t>

// MARK: Other
extension MemoryOrder {
    @inlinable
    var asCType: memory_order {
        return memory_order(rawValue: self.rawValue)
    }
}
// swiftlint:enable attributes
