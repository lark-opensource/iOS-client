//
//  OrderedMap.swift
//  Todo
//
//  Created by wangwanxin on 2021/7/14.
//

import Foundation

/// OrderedMap is a Dictionary except that it maintains the insertion order by keys
public struct OrderedMap<KeyType: Hashable, ValueType> {

    private var _dictionary: [KeyType: ValueType]
    private var _keys: [KeyType]

    public init() {
        _dictionary = [:]
        _keys = []
    }

    public init(_ dictionary: [KeyType: ValueType]) {
        _dictionary = dictionary
        _keys = dictionary.keys.map({ $0 })
    }

    public subscript(key: KeyType) -> ValueType? {
        get {
            return _dictionary[key]
        }
        set {
            guard let value = newValue else {
                removeValueForKey(key: key)
                return
            }
            updateValue(value: value, forKey: key)

        }
    }

    mutating func updateValue(value: ValueType, forKey key: KeyType) -> ValueType? {
        let oldValue = _dictionary.updateValue(value, forKey: key)
        if oldValue == nil {
            _keys.append(key)
        }
        return oldValue
    }

    mutating func removeValueForKey(key: KeyType) {
        _keys = _keys.filter({ $0 != key })
        _dictionary.removeValue(forKey: key)
    }

    public var count: Int {
        get {
           return _dictionary.count
        }
    }

    public var keys: [KeyType] {
        get {
            return _keys
        }
    }

    public var values: [ValueType] {
        get {
            return _keys.map({ _dictionary[$0]! })
        }
    }

    static func ==<Key: Equatable, Value: Equatable>(lhs: OrderedMap<Key, Value>, rhs: OrderedMap<Key, Value>) -> Bool {
         return lhs._keys == rhs._keys && lhs._dictionary == rhs._dictionary
     }

     static func !=<Key: Equatable, Value: Equatable>(lhs: OrderedMap<Key, Value>, rhs: OrderedMap<Key, Value>) -> Bool {
         return lhs._keys != rhs._keys || lhs._dictionary != rhs._dictionary
     }
}

extension OrderedMap: Sequence {

    public func makeIterator() -> OrderedMapIterator<KeyType, ValueType> {
        return OrderedMapIterator<KeyType, ValueType>(sequence: _dictionary, keys: keys, current: 0)
    }

}

public struct OrderedMapIterator<KeyType: Hashable, ValueType>: IteratorProtocol {

    let sequence: [KeyType: ValueType]
    let keys: [KeyType]
    var current = 0

    mutating public func next() -> (KeyType, ValueType)? {
        defer {
            current += 1
        }
        guard sequence.count > current else {
            return nil
        }

        let key = keys[current]
        guard let value = sequence[key] else {
            return nil
        }
        return (key, value)
    }
}
