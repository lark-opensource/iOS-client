//
//  Wrapper.swift
//  TangramComponent
//
//  Created by 袁平 on 2021/4/9.
//

import Foundation

private var bucket: Int32 = 0

/// 时间毫秒差值 + 余数 + 随机
@inline(__always)
func uuint() -> Int {
    return Int(OSAtomicIncrement32(&bucket) & Int32.max)
}

// pthread_rwlock_t不能被struct持有，需要封装成引用
public class ReadWriteLock {
    private var rwlock: pthread_rwlock_t = pthread_rwlock_t()

    public init() {
        pthread_rwlock_init(&rwlock, nil)
    }

    public func safeRead<T>(_ read: () -> T) -> T {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock)}
        return read()
    }

    @discardableResult
    public func safeWrite<T>(_ write: () -> T) -> T {
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        return write()
    }
}

// MARK: - EquatableWrapper

/// 对于无法使用Equatable或者==来判断是否相等的对象，可以使用EquatableWrapper，如：闭包等
public struct EquatableWrapper<T> {
    public private(set) var id: Int
    private var rwlock: ReadWriteLock?
    private let threadSafe: Bool
    private var _value: T
    public var value: T {
        mutating get {
            return safeReadIfNeed()
        }
        mutating set {
            update(new: newValue) // default set with id changed
        }
    }

    /// @params: value - T
    /// @params: id - identifier of value which will be used in `==`; a random id will be assigned if nil
    /// @params: threadSafe - `value` read & write will be thread safe if true
    public init(value: T, id: Int? = nil, threadSafe: Bool = true) {
        self._value = value
        self.id = id ?? uuint()
        self.threadSafe = threadSafe
        if threadSafe {
            rwlock = ReadWriteLock()
        }
    }

    /// update value without id changed
    mutating public func updateEqually(new: T) {
        safeWriteIfNeed(new: new, id: nil)
    }

    /// update value with id changed
    mutating public func update(new: T) {
        safeWriteIfNeed(new: new, id: uuint())
    }

    /// update value with specific id
    mutating public func update(new: T, id: Int) {
        safeWriteIfNeed(new: new, id: id)
    }

    /// update id
    mutating public func update(id: Int) {
        safeWriteIfNeed(new: nil, id: id)
    }

    mutating private func safeReadIfNeed() -> T {
        if threadSafe {
            return rwlock!.safeRead { return _value }
        } else {
            return _value
        }
    }

    mutating private func safeWriteIfNeed(new: T?, id: Int?) {
        if threadSafe {
            rwlock!.safeWrite {
                if let new = new {
                    self._value = new
                }
                if let id = id {
                    self.id = id
                }
            }
        } else {
            if let new = new {
                self._value = new
            }
            if let id = id {
                self.id = id
            }
        }
    }
}

// MARK: - WeakEquatableWrapper

// https://dmcyk.xyz/post/safe-weak-references-protocols/
public struct WeakEquatableWrapper<T> {
    public private(set) var id: Int
    private var rwlock: ReadWriteLock?
    private let threadSafe: Bool
    weak private var _value: AnyObject?
    public var value: T? {
        mutating get {
            return safeReadIfNeed()
        }
    }

    /// @params: value - T
    /// @params: id - identifier of value which will be used in `==`; a random id will be assigned if nil
    /// @params: threadSafe - `value` read & write will be thread safe if true
    public init(value: AnyObject?, id: Int? = nil, threadSafe: Bool = true) {
        self._value = value
        self.id = id ?? uuint()
        self.threadSafe = threadSafe
        if threadSafe {
            rwlock = ReadWriteLock()
        }
    }

    /// update value without id changed
    mutating public func updateEqually(new: AnyObject?) {
        safeWriteIfNeed(new: new, id: nil)
    }

    /// update value with id changed
    mutating public func update(new: AnyObject?) {
        safeWriteIfNeed(new: new, id: uuint())
    }

    /// update value with specific id
    mutating public func update(new: AnyObject?, id: Int) {
        safeWriteIfNeed(new: new, id: id)
    }

    /// update id
    mutating public func update(id: Int) {
        safeWriteIfNeed(new: nil, id: id)
    }

    mutating private func safeReadIfNeed() -> T? {
        if threadSafe {
            return rwlock!.safeRead { return _value as? T }
        } else {
            return _value as? T
        }
    }

    mutating private func safeWriteIfNeed(new: AnyObject?, id: Int?) {
        if threadSafe {
            rwlock!.safeWrite {
                if let new = new {
                    self._value = new
                }
                if let id = id {
                    self.id = id
                }
            }
        } else {
            if let new = new {
                self._value = new
            }
            if let id = id {
                self.id = id
            }
        }
    }
}

// MARK: - AsyncSerialEquatable

/// 保证异步更新时序
/// Task中的Completion为逃逸闭包，无法捕获struct
/// ⚠️: copy时，由于是class，需要调用clone方法！！
public class AsyncSerialEquatable<T> {
    public typealias ValueCapturedResult = (_ isCaptured: Bool) -> Void // value是否更新
    public typealias Completion = (_ value: T, _ capturedResult: ValueCapturedResult?) -> Void
    public typealias Task = (_ completion: @escaping Completion) -> Void

    private var taskIdentifier: Int // 判断task最新
    public private(set) var id: Int // 判断相等，每次value改变，id也改变
    private let rwlock: ReadWriteLock
    private var _value: T
    public var value: T {
        get {
            return safeRead()
        }
    }

    public init(value: T) {
        self._value = value
        self.taskIdentifier = uuint()
        self.id = uuint()
        rwlock = ReadWriteLock()
    }

    public func setTask(task: Task) {
        let identifier = self.rwlock.safeWrite { () -> Int in
            // 需要保证taskIdentifier生成与赋值是原子的
            let identifier = uuint()
            self.taskIdentifier = identifier
            return identifier
        }
        task { [weak self] value, capturedResult in
            guard let self = self else { return }
            if identifier == self.taskIdentifier {
                self.rwlock.safeWrite {
                    self._value = value
                    self.id = uuint()
                    capturedResult?(true)
                }
            } else {
                capturedResult?(false)
            }
        }
    }

    public func clone() -> AsyncSerialEquatable<T> {
        return self.rwlock.safeWrite {
            let clone = AsyncSerialEquatable(value: self._value)
            clone.id = self.id
            clone.taskIdentifier = self.taskIdentifier
            return clone
        }
    }

    private func safeRead() -> T {
        return rwlock.safeRead { return _value }
    }
}

public func ==<T>(_ lhs: EquatableWrapper<T>, _ rhs: EquatableWrapper<T>) -> Bool {
    return lhs.id == rhs.id
}

public func ==<T>(_ lhs: WeakEquatableWrapper<T>, _ rhs: WeakEquatableWrapper<T>) -> Bool {
    return lhs.id == rhs.id
}

public func ==<T>(_ lhs: AsyncSerialEquatable<T>, _ rhs: AsyncSerialEquatable<T>) -> Bool {
    return lhs.id == rhs.id
}

public struct WeakRef<T: AnyObject> {
    public weak var ref: T?

    public init(_ ref: T) {
        self.ref = ref
    }
}
