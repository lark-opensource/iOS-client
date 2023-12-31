//
//  KVStore.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/16.
//

import Foundation

public protocol KVStoreService: PageService {
    func getValue<Value>(for key: String) -> Value?
    func setValue(_ value: Any?, for key: String)
}

final class KVStore: KVStoreService {
    private var store: [String: Any] = [:]
    private let lock = NSLock()

    init() {}

    func getValue<Value>(for key: String) -> Value? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return store[key] as? Value
    }

    func setValue(_ value: Any?, for key: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        store[key] = value
    }
}
