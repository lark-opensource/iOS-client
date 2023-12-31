//
//  ThreadSafe.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/11/28.
//  

import Foundation

/// 使用 DispatchSemaphore 保证线程安全的读写操作
@propertyWrapper
public final class ThreadSafe<Value> {
    private let semaphore = DispatchSemaphore(value: 1)
    private var value: Value

    public init(wrappedValue: Value) {
        value = wrappedValue
    }

    public var wrappedValue: Value {
        get {
            semaphore.wait()
            defer {
                semaphore.signal()
            }
            return value
        }

        set {
            semaphore.wait()
            defer {
                semaphore.signal()
            }
            value = newValue
        }
    }
}
