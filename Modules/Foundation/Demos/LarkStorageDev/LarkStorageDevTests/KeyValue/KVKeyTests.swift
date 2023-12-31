//
//  KVKeyTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class KVKeyTests: KVTestCase {

    func store() -> KVStore {
        let space = Space.uuidUser(type: typeName)
        let suiteName = UD.suiteName(with: space, mode: .normal)
        return UDKVStore(suiteName: suiteName)!.disposed(self)
    }

    func doTestReal<T: KVValue & Equatable>(store: KVStore, value: T) {
        let rawKey = String(describing: type(of: T.self))
        let key = KVKey(rawKey, default: value)
        XCTAssert(!store.contains(key: key))
        XCTAssert(store.value(forKey: key) == value)
    }

    func doTestSome<T: KVValue & Equatable>(store: KVStore, value: T) {
        let rawKey = "optional_some_\(String(describing: type(of: T.self)))"
        let key = KVKey(rawKey, default: Optional.some(value))
        XCTAssert(!store.contains(key: key))
        XCTAssert(store.value(forKey: key) == value)
    }

    func doTestNone<T: KVValue>(store: KVStore, none: Optional<T> = nil) {
        let rawKey = "optional_none_\(String(describing: type(of: T.self)))"
        let key = KVKey<Optional<T>>(rawKey)
        XCTAssert(!store.contains(key: key))
        XCTAssert(store.value(forKey: key) == nil)
    }

    func doTestValue<T: KVValue & Equatable>(store: KVStore, value: T) {
        doTestReal(store: store, value: value)
        doTestSome(store: store, value: value)
        doTestNone(store: store, none: Optional<T>.none)
    }

    func testDefault() {
        let store = store()

        doTestValue(store: store, value: true)
        doTestValue(store: store, value: Int(42))
        doTestValue(store: store, value: Double(42))
        doTestValue(store: store, value: Float(42))
        doTestValue(store: store, value: "42")
    }

    func testRemove() {
        let store = store()
        let key = KVKey("answer", default: "42")
        XCTAssert(!store.contains(key: key))

        store.set("43", forKey: key)
        XCTAssert(store.contains(key: key))
        XCTAssert(store.value(forKey: key) == "43")

        store.removeValue(forKey: key)
        XCTAssert(!store.contains(key: key))
        XCTAssert(store.value(forKey: key) == "42")
    }

}
