//
//  Atomic.swift
//  LarkResource
//
//  Created by 李晨 on 2020/3/6.
//

import Foundation
import EEAtomic

public final class Atomic<T> {

    public var value: T {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _value
        }
        set {
            lock.lock()
            defer {
                lock.unlock()
            }
            _value = newValue
        }
    }
    private var _value: T
    private var lock: UnfairLock = UnfairLock()

    public init(_ value: T) {
        self._value = value
    }
}
