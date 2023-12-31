//
//  UnfairLock.swift
//  EEAtomic
//
//  Created by SolaWing on 2019/12/24.
//

import Foundation

/// UnfairLock wrapper to solve the thread sanitizer issue

public protocol UnfairLockAPI {
    /// this pointer is for adopt require, not for use directly
    var pointer: UnsafeMutablePointer<os_unfair_lock_s> { get }
}

public extension UnfairLockAPI {
    @inlinable
    func lock() {
        os_unfair_lock_lock(pointer)
    }
    @inlinable
    func tryLock() -> Bool {
        return os_unfair_lock_trylock(pointer)
    }
    @inlinable
    func unlock() {
        os_unfair_lock_unlock(pointer)
    }
    @inlinable
    func withLocking<T>(action: () throws -> T) rethrows -> T {
        lock(); defer { unlock() }
        return try action()
    }
    @inlinable
    func assertOwner() {
        os_unfair_lock_assert_owner(pointer)
    }
}

@frozen
public struct UnfairLockCell: UnfairLockAPI {
    public let pointer: UnsafeMutablePointer<os_unfair_lock_s>
    @inlinable
    public init() {
        pointer = UnsafeMutablePointer.allocate(capacity: 1)
        pointer.initialize(to: os_unfair_lock_s())
    }
    @inlinable
    public func deallocate() {
        pointer.deallocate()
    }
}

@_fixed_layout
public final class UnfairLock: UnfairLockAPI {
    public let pointer: UnsafeMutablePointer<os_unfair_lock_s>
    @inlinable
    public init() {
        pointer = UnsafeMutablePointer.allocate(capacity: 1)
        pointer.initialize(to: os_unfair_lock_s())
    }
    @inlinable
    deinit {
        pointer.deallocate()
    }
}
