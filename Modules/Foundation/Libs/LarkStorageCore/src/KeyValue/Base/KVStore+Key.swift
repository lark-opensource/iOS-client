//
//  KVStore+Key.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

/// Operations based on `KVKey`
public extension KVStore {

    // MARK: Get/Set

    func value<T: KVValue>(forKey key: KVKey<T>) -> T {
        return KVConfig(key: key, store: self).value
    }

    func set<T: KVValue>(_ value: T, forKey key: KVKey<T>) {
        var conf = KVConfig(key: key, store: self)
        conf.value = value
    }

    // MARK: Contains/RemoveValue

    func contains<T: KVValue>(key: KVKey<T>) -> Bool {
        return contains(key: key.raw)
    }

    func removeValue<T: KVValue>(forKey key: KVKey<T>) {
        removeValue(forKey: key.raw)
    }

}
