//
//  KVObject.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2023/1/15.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class Product: NSObject, NSCoding {
    var name: String
    var price: Double

    enum Key: String { case name, price }

    init(name: String, price: Double) {
        self.name = name
        self.price = price
    }

    convenience required init?(coder: NSCoder) {
        guard let name = coder.decodeObject(forKey: Key.name.rawValue) as? String else {
            return nil
        }
        let price = coder.decodeDouble(forKey: Key.price.rawValue)
        self.init(name: name, price: price)
    }

    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: Key.name.rawValue)
        coder.encode(price, forKey: Key.price.rawValue)
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Product else { return false }
        return self.name == other.name && abs(self.price - other.price) < 0.0001
    }

    override var description: String {
        return "[Product] name: \(name), price: \(price)"
    }
}

extension Product: KVMigrationValueType {}

struct KVObject<Object: NSCodingObject> {
    let key: String
    let object: Object
    let type: Object.Type

    init(key: String, object: Object) {
        self.key = key
        self.object = object
        self.type = Object.self
    }

    func mapKey(_ map: (String) -> String) -> Self {
        return Self(key: map(key), object: object)
    }

    func mapValue(_ map: (Object) -> Object) -> Self {
        return Self(key: key, object: map(object))
    }
}

extension KVObject {
    func save(in store: KVStore) {
        store.setObject(self.object, forKey: self.key)
    }
    
    func check(in store: KVStore, context: String? = nil, file: StaticString = #filePath, line: UInt = #line) where Object: Equatable {
        let v: Object? = store.object(forKey: key)
        let message = if let context {
            "key: \(key), lhs = \(String(describing: v)), rhs: \(String(describing: object)), context: \(context)"
        } else {
            "key: \(key), lhs = \(String(describing: v)), rhs: \(String(describing: object))"
        }
        XCTAssert(v == object, message, file: file, line: line)
    }

    func check(in store: KVStore, isEqual: (_ v1: Object, _ v2: Object) -> Bool, file: StaticString = #filePath, line: UInt = #line) {
        guard let v: Object = store.object(forKey: key) else {
            XCTAssert(false, file: file, line: line)
            return
        }
        XCTAssert(isEqual(v, object), file: file, line: line)
    }

    func checkNil(in store: KVStore, file: StaticString = #filePath, line: UInt = #line) {
        let v: Object? = store.object(forKey: key)
        XCTAssertNil(v, file: file, line: line)
        XCTAssert(!store.contains(key: key), file: file, line: line)
    }
}

enum KVObjects {
    static let dict = KVObject(
        key: "nsdict",
        object: NSDictionary(
            dictionaryLiteral: ("bool", true), ("int", 42),
            ("float", Float(42.0)), ("double", Double(42.0)),
            ("string", "42")
        )
    )
    static let array = KVObject(
        key: "nsarray",
        object: NSArray(arrayLiteral: true, 42, Float(42.0), Double(42.0), "42")
    )

    static var allKeys: [String] {
        [dict.key, array.key]
    }

    static var allCasesCount: Int { allKeys.count }

    static let defaultKeyMap: (String) -> String = { $0 }

    static func saveAllCases(in store: KVStore, keyMap: ((String) -> String)? = nil) {
        dict.mapKey(keyMap ?? defaultKeyMap).save(in: store)
        array.mapKey(keyMap ?? defaultKeyMap).save(in: store)
    }

    static func checkAllCases(in store: KVStore, keyMap: ((String) -> String)? = nil, context: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        dict.mapKey(keyMap ?? defaultKeyMap).check(in: store, context: context, file: file, line: line)
        array.mapKey(keyMap ?? defaultKeyMap).check(in: store, context: context, file: file, line: line)
    }

    // NOTE: 这里没有 `checkAllCases(in values: [String: Any])` 是因为
    //       allValues 无法读取NSObject类型的数据(因为被archived过)，所以这个接口就没有必要了

    static func checkAllCasesNil(in store: KVStore, keyMap: ((String) -> String)? = nil, file: StaticString = #filePath, line: UInt = #line) {
        dict.mapKey(keyMap ?? defaultKeyMap).checkNil(in: store, file: file, line: line)
        array.mapKey(keyMap ?? defaultKeyMap).checkNil(in: store, file: file, line: line)
    }

    static func mapWithKeyAndType<R>(_ transform: (String, NSCodingObject.Type) -> R) -> [R] {
        [
            transform(dict.key, dict.type),
            transform(array.key, array.type),
        ]
    }
}
