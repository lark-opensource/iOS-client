//
//  ECOGenericDictionary.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/4.
//

import Foundation

/// 用于在一个 Dict 中存放不同泛型
struct ECOGenericDictionary<Key> where Key : Hashable {
    public var dict = [Key: Any]()
    public var keys: Dictionary<Key, Any>.Keys { dict.keys }
    public var values: Dictionary<Key, Any>.Values { dict.values }
    public var count: Int { dict.count }

    public subscript(key: Key) -> Any? {
        get { dict[key] }
        set(newValue) { dict[key] = newValue }
    }
    
    public func value<ValueType>(forKey key: Key) -> ValueType? {
        let value = dict[key]
        return value as? ValueType
    }
    
    public mutating func updateValue(_ value: Any, forKey key: Key) -> Any? {
        dict.updateValue(value, forKey: key)
    }
    
    public mutating func removeAll() {
        dict.removeAll()
    }
    
    public mutating func removeValue(forKey key: Key){
        dict.removeValue(forKey: key)
    }
}
