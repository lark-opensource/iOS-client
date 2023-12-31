//
//  RWLock.swift
//  EEAtomic
//
//  Created by SolaWing on 2022/6/7.
//

import Foundation

/// a rwlock wrapper
@_fixed_layout
public final class RWLock {
    @usableFromInline var lock = pthread_rwlock_t()

    /// use swift private compiler method, to avoid the additional ptr allocate
    @inlinable var ptr: UnsafeMutablePointer<pthread_rwlock_t> {
        return _getUnsafePointerToStoredProperties(self).assumingMemoryBound(to: pthread_rwlock_t.self)
    }

    public init() {
        let v = pthread_rwlock_init(ptr, nil)
        assert(v == 0, "pthread_rwlock_init failed")
    }
    deinit {
        pthread_rwlock_destroy(ptr)
    }

    @inlinable
    func rdlock() { pthread_rwlock_rdlock(ptr) }
    @inlinable
    func wrlock() { pthread_rwlock_wrlock(ptr) }
    @inlinable
    func unlock() { pthread_rwlock_unlock(ptr) }
    /// return 0 if success, otherwise return error code
    @inlinable
    func tryrdlock() -> CInt { return pthread_rwlock_tryrdlock(ptr) }
    /// return 0 if success, otherwise return error code
    @inlinable
    func trywrlock() -> CInt { return pthread_rwlock_trywrlock(ptr) }
    // MARK: Block version api
    /// TODO: 考虑加锁报错怎么处理
    public func withRDLocking<T>(action: () throws -> T) rethrows -> T {
        let v = pthread_rwlock_rdlock(ptr)
        defer {
            if v == 0 { pthread_rwlock_unlock(ptr) }
        }
        return try action()
    }
    // TODO: 考虑加锁报错怎么处理
    public func withWRLocking<T>(action: () throws -> T) rethrows -> T {
        let v = pthread_rwlock_wrlock(ptr)
        defer {
            if v == 0 { pthread_rwlock_unlock(ptr) }
        }
        return try action()
    }
}

// TODO: rwlock test, include reentrant and other errors

