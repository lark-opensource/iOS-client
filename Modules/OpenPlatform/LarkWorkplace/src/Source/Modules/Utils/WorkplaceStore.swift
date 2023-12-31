//
//  WorkplaceStore.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/9.
//

import Foundation
import ThreadSafeDataStructure

final class WorkplaceStore {
    private var store: SafeDictionary<String, Any> = [:] + .readWriteLock

    func getValue<Value>(for key: String) -> Value? {
        return store[key] as? Value
    }

    func setValue(_ value: Any?, for key: String) {
        if let value = value {
            store[key] = value
        } else {
            store.removeValue(forKey: key)
        }
    }
}
