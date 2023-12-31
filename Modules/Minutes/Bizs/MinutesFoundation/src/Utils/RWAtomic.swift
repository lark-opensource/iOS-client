//
//  RWAtomic.swift
//  MinutesFoundation
//
//  Created by 陈乐辉 on 2022/10/31.
//

import Foundation
import EEAtomic

public final class RwLock {
    private var lock = EEAtomic.RWLock()

    public init() {}

    public func withRead<T>(_ block: () throws -> T) rethrows -> T {
        try lock.withRDLocking(action: block)
    }

    public func withWrite<T>(_ block: () throws -> T) rethrows -> T {
        try lock.withWRLocking(action: block)
    }
}

@propertyWrapper
public final class RwAtomic<T> {
    private let lock = RwLock()
    private var value: T

    public init(wrappedValue: T) {
        self.value = wrappedValue
    }

    public var wrappedValue: T {
        get {
            return lock.withRead { value }
        }
        set {
            lock.withWrite { value = newValue }
        }
    }
}

public extension RwAtomic where T: Equatable {
    /// 仅在和原值不相等的时候设置
    /// - returns: 和原值不相等时返回true，否则返回false
    func setIfChanged(_ newValue: T) -> Bool {
        lock.withWrite {
            if value != newValue {
                value = newValue
                return true
            }
            return false
        }
    }
}
