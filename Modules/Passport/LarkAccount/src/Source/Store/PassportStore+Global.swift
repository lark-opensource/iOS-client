//
//  PassportStore+Global.swift
//  LarkAccount
//
//  Created by au on 2023/3/14.
//

import Foundation
import LarkStorage

extension PassportStore {
    
    internal static func eraseUserValue<T: Codable>(key: PassportStorageKey<T>) -> T? {
        if passportStorageCipherMigration {
            return LarkStorageAdapter(space: .global, simplified: false).value(forKey: key)
        } else {
            return LarkStorageAdapter(space: .global, simplified: true, cipherSuite: .passport).value(forKey: key)
        }
    }
    
    internal static func eraseUserSet<T: Codable>(key: PassportStorageKey<T>, value: T?) {
        if passportStorageCipherMigration {
            if let value = value {
                LarkStorageAdapter(space: .global, simplified: false).set(value, forKey: key)
            } else {
                LarkStorageAdapter(space: .global, simplified: false).removeValue(forKey: key)
            }
        } else {
            if let value = value {
                LarkStorageAdapter(space: .global, simplified: true, cipherSuite: .passport).set(value, forKey: key)
            } else {
                LarkStorageAdapter(space: .global, simplified: true, cipherSuite: .passport).removeValue(forKey: key)
            }
        }
    }

    static func value<T>(forKey key: PassportStorageKey<T>) -> T? where T: Codable {
        if passportStorageCipherMigration {
            return Self.kvStore(space: .global).value(forKey: key)
        } else {
            return Isolator.layersGlobal(namespace: .passportStoreIsolator).get(key: key)
        }
    }

    static func set<T>(_ value: T?, forKey key: PassportStorageKey<T>) where T: Codable {
        if passportStorageCipherMigration {
            if let value = value {
                Self.kvStore(space: .global).set(value, forKey: key)
            } else {
                Self.kvStore(space: .global).removeValue(forKey: key)
            }
        } else {
            if let value = value {
                _ = Isolator.layersGlobal(namespace: .passportStoreIsolator).update(key: key, value: value)
            } else {
                _ = Isolator.layersGlobal(namespace: .passportStoreIsolator).remove(key: key)
            }
        }
    }
}
