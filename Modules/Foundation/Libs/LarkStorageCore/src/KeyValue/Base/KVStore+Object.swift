//
//  KVStore+Object.swift
//  LarkStorage
//
//  Created by 7Up on 2023/1/14.
//

import Foundation

func _forward_get_object<O: NSCodingObject>(to sender: KVStore, forKey key: String) -> O? {
    if let proxy = sender as? KVStoreProxy {
        return proxy.object(forKey: key)
    } else if let base = sender as? KVStoreBase {
        if let obj: O = base.loadValue(forKey: key) {
            return obj
        } else {
            return nil
        }
    } else {
        KVStores.assertionFailure("unexpected")
        return nil
    }
}

func _forward_set_object<O: NSCodingObject>(to sender: KVStore, forKey key: String, object: O) {
    if let proxy = sender as? KVStoreProxy {
        return proxy.setObject(object, forKey: key)
    } else if let base = sender as? KVStoreBase {
        base.saveValue(object, forKey: key)
    } else {
        KVStores.assertionFailure("unexpected")
    }
}

extension KVStoreProxy {
    public func object<O: NSCodingObject>(forKey key: String) -> O? {
        _forward_get_object(to: wrapped, forKey: key)
    }

    public func setObject<O: NSCodingObject>(_ obj: O, forKey key: String) {
        _forward_set_object(to: wrapped, forKey: key, object: obj)
    }
}

extension KVStore {
    /// 面向 `NSCodingObject` 的 get 操作
    /// 若没有特殊需求，建议使用面向 `Codable` 的 value<Codable>(forKey:) 接口，更 swifty
    public func object<O: NSCodingObject>(forKey key: String) -> O? {
        _forward_get_object(to: self, forKey: key)
    }

    /// 面向 `NSCodingObject` 的 set 操作
    /// 若没有特殊需求，建议使用面向 `Codable` 的 `set<Codable>(_:,forKey:)` 接口，更 swifty
    /// func set<T: Codable>(_ value: T, forKey key: String)
    public func setObject<O: NSCodingObject>(_ obj: O, forKey key: String) {
        _forward_set_object(to: self, forKey: key, object: obj)
    }
}
