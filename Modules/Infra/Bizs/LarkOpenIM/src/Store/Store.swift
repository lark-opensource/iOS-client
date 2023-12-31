//
//  Store.swift
//  LarkOpenChat
//
//  Created by 李勇 on 2020/12/6.
//

import Foundation

/// KV存储
public final class Store {
    private var store: [String: Any] = [:]
    private var mutex = pthread_mutex_t()

    /// init
    public init() {
        pthread_mutex_init(&mutex, nil)
    }

    public func getValue<Value>(for key: String) -> Value? {
        pthread_mutex_lock(&mutex)
        defer {
            pthread_mutex_unlock(&mutex)
        }
        return store[key] as? Value
    }

    public func setValue(_ value: Any?, for key: String) {
        pthread_mutex_lock(&mutex)
        defer {
            pthread_mutex_unlock(&mutex)
        }
        if let value = value {
            store[key] = value
        } else {
            store.removeValue(forKey: key)
        }
    }
}
