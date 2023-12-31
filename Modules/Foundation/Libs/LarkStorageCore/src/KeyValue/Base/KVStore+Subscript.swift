//
//  KVStore+Subscript.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

/// Support Subscript
public extension KVStore {
    subscript<T: KVValue>(key: KVKey<T>) -> T {
        get { value(forKey: key) }
        set { set(newValue, forKey: key) }
    }

    subscript<T: Codable>(key: String) -> T? {
        get { value(forKey: key) }
        set {
            if let v = newValue {
                set(v, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }
    }
}
