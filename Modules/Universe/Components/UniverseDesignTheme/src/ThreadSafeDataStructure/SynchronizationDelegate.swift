//
//  SynchronizationDelegate.swift
//  ThreadSafeDataStructure
//
//  Created by PGB on 2019/11/5.
//

import Foundation

/// The type of synchronization primtive provied for ThreadSafeDataStructure
///
/// Checkout the [guidebook](https://bytedance.feishu.cn/space/doc/doccnNb7YCSPctnUGmWNEUs3Ywh) to get started with more information
public enum SynchronizationType {
    /// Common read/write lock, faster than .concurrentQueue.
    case readWriteLock
    /// Slower than .readWriteLock, but some write operations can be executed asynchronously.
    case concurrentQueue
    /// Perform better when write operations are called more frequently than read operations.
    case semaphore
    /// As fast as spin-lock, but the lock ordering is not promised.
    case unfairLock
    /// A lock that may be acquired multiple times by the same thread without causing a deadlock.
    case recursiveLock

    init(delegate synchronizationDelegate: SynchronizationDelegate) {
        self = .unfairLock
        if synchronizationDelegate is ReadWriteLock {
            self = .readWriteLock
        }
        if synchronizationDelegate is ConcurrentQueue {
            self = .concurrentQueue
        }
        if synchronizationDelegate is Semaphore {
            self = .semaphore
        }
        if synchronizationDelegate is RecursiveLock {
            self = .recursiveLock
        }
    }

    func generateSynchronizationDelegate() -> SynchronizationDelegate {
        switch self {
        case .concurrentQueue: return ConcurrentQueue()
        case .readWriteLock: return ReadWriteLock()
        case .semaphore: return Semaphore()
        case .unfairLock: return UnfairLock()
        case .recursiveLock: return RecursiveLock()
        }
    }
}

protocol SynchronizationDelegate: AnyObject {
    func writeOperation(block: () -> Void)
    func writeOperation<T>(block: () -> T) -> T
    func writeOperation(block: () throws -> Void) rethrows
    func writeOperation<T>(block: () throws -> T) rethrows -> T
    func readOperation<T>(block: () -> T) -> T
    func readOperation<T>(block: () throws -> T) rethrows -> T

    func lock(for lock: LockType)
    func unlock()
}

enum LockType {
    case shared
    case exclusive
}

class ReadWriteLock: SynchronizationDelegate {
    var rwLock = pthread_rwlock_t()

    init() {
        pthread_rwlock_init(&rwLock, nil)
    }

    func writeOperation<T>(block: () -> T) -> T {
        pthread_rwlock_wrlock(&rwLock)
        let result = block()
        pthread_rwlock_unlock(&rwLock)
        return result
    }

    func writeOperation(block: () throws -> Void) rethrows {
        pthread_rwlock_wrlock(&rwLock)
        try block()
        pthread_rwlock_unlock(&rwLock)
    }

    func readOperation<T>(block: () throws -> T) rethrows -> T {
        pthread_rwlock_rdlock(&rwLock)
        let result = try block()
        pthread_rwlock_unlock(&rwLock)

        return result
    }

    func readOperation<T>(block: () -> T) -> T {
        pthread_rwlock_rdlock(&rwLock)
        let result = block()
        pthread_rwlock_unlock(&rwLock)

        return result
    }

    func writeOperation(block: () -> Void) {
        pthread_rwlock_wrlock(&rwLock)
        block()
        pthread_rwlock_unlock(&rwLock)
    }

    func writeOperation<T>(block: () throws -> T) rethrows -> T {
        pthread_rwlock_wrlock(&rwLock)
        let result = try block()
        pthread_rwlock_unlock(&rwLock)
        return result
    }

    func lock(for lock: LockType) {
        switch lock {
        case .shared:
            pthread_rwlock_rdlock(&rwLock)
        case .exclusive:
            pthread_rwlock_wrlock(&rwLock)
        }
    }

    func unlock() {
        pthread_rwlock_unlock(&rwLock)
    }

    deinit {
        pthread_rwlock_destroy(&rwLock)
    }
}

class Semaphore: SynchronizationDelegate {
    var semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)

    func writeOperation<T>(block: () -> T) -> T {
        semaphore.wait()
        let result = block()
        semaphore.signal()
        return result
    }

    func writeOperation(block: () throws -> Void) rethrows {
        semaphore.wait()
        try block()
        semaphore.signal()
    }

    func writeOperation<T>(block: () throws -> T) rethrows -> T {
        semaphore.wait()
        let result = try block()
        semaphore.signal()
        return result
    }

    func readOperation<T>(block: () throws -> T) rethrows -> T {
        semaphore.wait()
        let result = try block()
        semaphore.signal()
        return result
    }

    func readOperation<T>(block: () -> T) -> T {
        semaphore.wait()
        let result = block()
        semaphore.signal()
        return result
    }

    func writeOperation(block: () -> Void) {
        semaphore.wait()
        block()
        semaphore.signal()
    }

    func lock(for lock: LockType) {
        semaphore.wait()
    }

    func unlock() {
        semaphore.signal()
    }
}

class ConcurrentQueue: SynchronizationDelegate {
    static var count: Int = 0
    static var unfairLock = os_unfair_lock_s()

    var queue: DispatchQueue
    var iteratorLock = pthread_rwlock_t()

    init() {
        os_unfair_lock_lock(&ConcurrentQueue.unfairLock)
        let identifier = "ThreadSafeCollection" + String(ConcurrentQueue.count)
        ConcurrentQueue.count += 1
        queue = DispatchQueue(label: identifier, attributes: .concurrent)
        pthread_rwlock_init(&iteratorLock, nil)
        os_unfair_lock_unlock(&ConcurrentQueue.unfairLock)
    }

    func readOperation<T>(block: () -> T) -> T {
        return queue.sync {
            let result = block()
            return result
        }
    }

    func writeOperation<T>(block: () -> T) -> T {
        return queue.sync(flags: .barrier) {
            return block()
        }
    }

    func writeOperation(block: () throws -> Void) rethrows {
        try queue.sync(flags: .barrier) {
            try block()
        }
    }

    func writeOperation<T>(block: () throws -> T) rethrows -> T {
        return try queue.sync(flags: .barrier) {
            return try block()
        }
    }

    func readOperation<T>(block: () throws -> T) rethrows -> T {
        return try queue.sync {
            return try block()
        }
    }

    func writeOperation(block: () -> Void) {
        queue.sync(flags: .barrier) {
            block()
        }
    }

    func lock(for lock: LockType) {
        switch lock {
        case .shared:
            _ = queue.sync {
                pthread_rwlock_rdlock(&iteratorLock)
            }
        case .exclusive:
            _ = queue.sync(flags: .barrier) {
                pthread_rwlock_wrlock(&iteratorLock)
            }
        }
    }

    func unlock() {
        pthread_rwlock_unlock(&iteratorLock)
    }
}

class UnfairLock: SynchronizationDelegate {
    var unfairLock = os_unfair_lock_s()

    func writeOperation<T>(block: () -> T) -> T {
        os_unfair_lock_lock(&unfairLock)
        let result = block()
        os_unfair_lock_unlock(&unfairLock)
        return result
    }

    func writeOperation<T>(block: () throws -> T) rethrows -> T {
        os_unfair_lock_lock(&unfairLock)
        let result = try block()
        os_unfair_lock_unlock(&unfairLock)
        return result
    }

    func writeOperation(block: () throws -> Void) rethrows {
        os_unfair_lock_lock(&unfairLock)
        try block()
        os_unfair_lock_unlock(&unfairLock)
    }

    func readOperation<T>(block: () throws -> T) rethrows -> T {
        os_unfair_lock_lock(&unfairLock)
        let result = try block()
        os_unfair_lock_unlock(&unfairLock)
        return result
    }

    func readOperation<T>(block: () -> T) -> T {
        os_unfair_lock_lock(&unfairLock)
        let result = block()
        os_unfair_lock_unlock(&unfairLock)
        return result
    }

    func writeOperation(block: () -> Void) {
        os_unfair_lock_lock(&unfairLock)
        block()
        os_unfair_lock_unlock(&unfairLock)
    }

    func lock(for lock: LockType) {
        os_unfair_lock_lock(&unfairLock)
    }

    func unlock() {
        os_unfair_lock_unlock(&unfairLock)
    }
}

class RecursiveLock: SynchronizationDelegate {
    var recursiveLock: NSRecursiveLock = NSRecursiveLock()

    func writeOperation<T>(block: () -> T) -> T {
        recursiveLock.lock()
        let result = block()
        recursiveLock.unlock()
        return result
    }

    func writeOperation<T>(block: () throws -> T) rethrows -> T {
        recursiveLock.lock()
        let result = try block()
        recursiveLock.unlock()
        return result
    }

    func writeOperation(block: () throws -> Void) rethrows {
        recursiveLock.lock()
        try block()
        recursiveLock.unlock()
    }

    func readOperation<T>(block: () throws -> T) rethrows -> T {
        recursiveLock.lock()
        let result = try block()
        recursiveLock.unlock()
        return result
    }

    func readOperation<T>(block: () -> T) -> T {
        recursiveLock.lock()
        let result = block()
        recursiveLock.unlock()
        return result
    }

    func writeOperation(block: () -> Void) {
        recursiveLock.lock()
        block()
        recursiveLock.unlock()
    }

    func lock(for lock: LockType) {
        recursiveLock.lock()
    }

    func unlock() {
        recursiveLock.unlock()
    }
}
