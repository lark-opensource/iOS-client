//
//  Atomic.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/9/23.
//

import Foundation
import ThreadSafeDataStructure

final class UnsafeAtomicPtr {
    @usableFromInline let storage: UnsafeMutablePointer<catmc_atomic_uintptr_t>!

    @inlinable
    init(_ value: UInt) {
        storage = catmc_atomic_uintptr_t_create(value)
    }

    deinit {
        UnsafeAtomicPtr.free(storage)
    }

    @inlinable
    func compareAndExchange(expected: UInt, desired: UInt) -> Bool {
        return catmc_atomic_uintptr_t_compare_and_exchange(storage, expected, desired)
    }

    @inlinable
    func exchange(with value: UInt) -> UInt {
        return catmc_atomic_uintptr_t_exchange(storage, value)
    }

    @inlinable
    func load() -> UInt {
        return catmc_atomic_uintptr_t_load(storage)
    }

    @inline(__always)
    static func free(_ ptr: UnsafeMutablePointer<catmc_atomic_uintptr_t>!) {
        catmc_atomic_uintptr_t_destroy(ptr)
    }
}

/// 只在主线程读，子线程写场景下可以保证线程安全
/// 针对Component的特殊场景适用
public final class AtomicReference<T: AnyObject> {
    private var atomicBox: UnsafeAtomicPtr

    public var value: T {
        get {
            return Unmanaged<T>.fromOpaque(UnsafeRawPointer(bitPattern: atomicBox.load())!).takeUnretainedValue()
        }
        set {
            var i = 0
            let oldValue = value
            while !compareAndExchange(expected: oldValue, desired: newValue) {
                i += 1
                if i > 20 {
                    assertionFailure("CompareAndExchange more than \(i) times!")
                    break
                }
            }
        }
    }

    public init(_ value: T) {
        atomicBox = UnsafeAtomicPtr(UInt(bitPattern: Unmanaged.passRetained(value).toOpaque()))
    }

    deinit {
        let oldPtrBits = self.atomicBox.exchange(with: 0xdeadbeef)
        let oldPtr = Unmanaged<T>.fromOpaque(UnsafeRawPointer(bitPattern: oldPtrBits)!)
        oldPtr.release()
    }

    @inline(__always)
    func compareAndExchange(expected: T, desired: T) -> Bool {
        return withExtendedLifetime(desired) {
            let expectedPtr = Unmanaged<T>.passUnretained(expected)
            let desiredPtr = Unmanaged<T>.passUnretained(desired)

            if atomicBox.compareAndExchange(expected: UInt(bitPattern: expectedPtr.toOpaque()),
                                            desired: UInt(bitPattern: desiredPtr.toOpaque())) {
                // 这里可以使用expectedPtr.autorelease()。但是autorelease是在当前runloop。子线程runloop
                // 的释放时机并不固定，如果存在主线程中忙等的情况，那么会遇到autorelease释放时主线程获取的情况
                // 为了根本解决这个问题，主线程只读，那么就在主线程释放
                DispatchQueue.main.async {
                    _ = expectedPtr.autorelease()
                }
                _ = desiredPtr.retain()
                return true
            }
            return false
        }
    }
}

@propertyWrapper
public struct Atomic<T> {
    private let value: SafeAtomic<T?>

    public init() {
        self.init(nil)
    }

    public init(_ value: T?) {
        self.value = SafeAtomic(value, with: .readWriteLock)
    }

    public var wrappedValue: T? {
        mutating get {
            value.value
        }
        set {
            self.value.value = newValue
        }
    }
}
