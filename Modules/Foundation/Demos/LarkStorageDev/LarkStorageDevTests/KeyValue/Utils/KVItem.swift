//
//  KVItem.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2023/1/15.
//

import Foundation
import XCTest
@testable import LarkStorage
@testable import LarkStorageCore

struct Person: Codable {
    var name: String
    var age: Int
}

extension Person: KVNonOptionalValue {
    typealias StoreType = Self

    func isSame(as other: Person) -> Bool {
        return self.name == other.name
            && self.age == other.age
    }

    static let rubo = Person(name: "Rubo", age: 38)
    static let yiming = Person(name: "Yiming", age: 37)
}

struct KVItem<Value: Codable> {
    let key: String
    let value: Value
    let type: Value.Type

    init(key: String, value: Value) {
        self.key = key
        self.value = value
        self.type = Value.self
    }

    func mapKey(_ map: KeyMap) -> Self {
        return Self.init(key: map(key), value: value)
    }

    func mapValue(_ map: (Value) -> Value) -> Self {
        return Self.init(key: key, value: map(value))
    }
}

extension KVItem {
    func save(in store: KVStore) {
        store.set(self.value, forKey: self.key)
    }

    func check(in store: KVStore, context: String? = nil, file: StaticString = #filePath, line: UInt = #line) where Value: Equatable {
        let v: Value? = store.value(forKey: key)
        let message = if let context {
            "key: \(key), value = \(String(describing: v)), context: \(context)"
        } else {
            "key: \(key), value = \(String(describing: v))"
        }
        XCTAssert(v == value, message, file: file, line: line)
    }

    func check(in dict: Dictionary<String, Any>, file: StaticString = #filePath, line: UInt = #line) where Value: Equatable {
        if let v = dict[key] as? Value {
            XCTAssert(
                v == value,
                "key: \(key), value = \(String(describing: v)), expected: \(value)",
                file: file, line: line
            )
        } else {
            XCTAssert(
                false,
                "key: \(key), value = \(String(describing: dict[key])), expected: \(value)",
                file: file, line: line
            )
        }
    }

    func checkNil(in store: KVStore, file: StaticString = #filePath, line: UInt = #line) {
        let v: Value? = store.value(forKey: key)
        XCTAssertNil(v, file: file, line: line)
        XCTAssert(!store.contains(key: key), file: file, line: line)
    }

}

typealias KeyMap = (String) -> String

enum KVItems {
    static let bool     = KVItem(key: "bool",   value: true)
    static let int      = KVItem(key: "int",    value: 42)
    static let float    = KVItem(key: "float",  value: Float(42.0))
    static let double   = KVItem(key: "double", value: Double(42.0))
    static let string   = KVItem(key: "string", value: "42")
    static let data     = KVItem(key: "data",   value: Data("42".utf8))
    static let int64    = KVItem(key: "int64",  value: Int64(42))

    static var allKeys: [String] {
        [bool.key, int.key, float.key, double.key, string.key, data.key, int64.key]
    }

    static var allCasesCount: Int { allKeys.count }

    static let defaultKeyMap: KeyMap = { $0 }

    static func saveAllCases(in store: KVStore, keyMap: KeyMap? = nil) {
        bool.mapKey(keyMap ?? defaultKeyMap).save(in: store)
        int.mapKey(keyMap ?? defaultKeyMap).save(in: store)
        float.mapKey(keyMap ?? defaultKeyMap).save(in: store)
        double.mapKey(keyMap ?? defaultKeyMap).save(in: store)
        string.mapKey(keyMap ?? defaultKeyMap).save(in: store)
        data.mapKey(keyMap ?? defaultKeyMap).save(in: store)
        int64.mapKey(keyMap ?? defaultKeyMap).save(in: store)
    }

    static func checkAllCases(in store: KVStore, keyMap: KeyMap? = nil, context: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        bool.mapKey(keyMap ?? defaultKeyMap).check(in: store, context: context, file: file, line: line)
        int.mapKey(keyMap ?? defaultKeyMap).check(in: store, context: context, file: file, line: line)
        float.mapKey(keyMap ?? defaultKeyMap).check(in: store, context: context, file: file, line: line)
        double.mapKey(keyMap ?? defaultKeyMap).check(in: store, context: context, file: file, line: line)
        string.mapKey(keyMap ?? defaultKeyMap).check(in: store, context: context, file: file, line: line)
        data.mapKey(keyMap ?? defaultKeyMap).check(in: store, context: context, file: file, line: line)
        int64.mapKey(keyMap ?? defaultKeyMap).check(in: store, context: context, file: file, line: line)
    }

    static func checkAllCases(in dict: [String: Any], keyMap: KeyMap? = nil, file: StaticString = #filePath, line: UInt = #line) {
        bool.mapKey(keyMap ?? defaultKeyMap).check(in: dict, file: file, line: line)
        int.mapKey(keyMap ?? defaultKeyMap).check(in: dict, file: file, line: line)
        float.mapKey(keyMap ?? defaultKeyMap).check(in: dict, file: file, line: line)
        double.mapKey(keyMap ?? defaultKeyMap).check(in: dict, file: file, line: line)
        string.mapKey(keyMap ?? defaultKeyMap).check(in: dict, file: file, line: line)
        data.mapKey(keyMap ?? defaultKeyMap).check(in: dict, file: file, line: line)
        int64.mapKey(keyMap ?? defaultKeyMap).check(in: dict, file: file, line: line)
    }

    static func checkAllCasesNil(in store: KVStore, keyMap: KeyMap? = nil, file: StaticString = #filePath, line: UInt = #line) {
        bool.mapKey(keyMap ?? defaultKeyMap).checkNil(in: store, file: file, line: line)
        int.mapKey(keyMap ?? defaultKeyMap).checkNil(in: store, file: file, line: line)
        float.mapKey(keyMap ?? defaultKeyMap).checkNil(in: store, file: file, line: line)
        double.mapKey(keyMap ?? defaultKeyMap).checkNil(in: store, file: file, line: line)
        string.mapKey(keyMap ?? defaultKeyMap).checkNil(in: store, file: file, line: line)
        data.mapKey(keyMap ?? defaultKeyMap).checkNil(in: store, file: file, line: line)
        int64.mapKey(keyMap ?? defaultKeyMap).checkNil(in: store, file: file, line: line)
    }

    static func mapWithKeyAndType<R>(_ transform: (String, Codable.Type) -> R) -> [R] {
        [
            transform(bool.key, bool.type),
            transform(int.key, int.type),
            transform(float.key, float.type),
            transform(double.key, double.type),
            transform(string.key, string.type),
            transform(data.key, data.type),
            transform(int64.key, int64.type),
        ]
    }

}
