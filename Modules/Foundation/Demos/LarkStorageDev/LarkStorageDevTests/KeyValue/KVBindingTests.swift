//
//  KVBindingTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/10/28.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

final class KVBindingTests: KVTestCase {

    private let _store = KVStores.udkv(
        space: .user(id: "KVBindingTests" + UUID().uuidString.prefix(5)),
        domain: Domain("KVBindingTests").uuidChild()
    ).disposed(KVBindingTests.self)

    // shortshut path to `KVBindingTests#store`
    static let store = \KVBindingTests._store

    @KVBinding(to: store, key: Keys.bool)
    var bool: Bool
    @KVBinding(to: store, key: Keys.int)
    var int: Int
    @KVBinding(to: store, key: Keys.double)
    var double: Double
    @KVBinding(to: store, key: Keys.string)
    var string: String
    @KVBinding(to: store, key: Keys.person)
    var person: Person

    func testBinding() {
        _store.clearAll()

        // get 测试：默认值
        do {
            XCTAssert(bool == Keys.bool.defaultValue)
            XCTAssert(int == Keys.int.defaultValue)
            XCTAssert(abs(double - Keys.double.defaultValue) < 0.01)
            XCTAssert(string == Keys.string.defaultValue)
            XCTAssert(person.isSame(as: Keys.person.defaultValue))
        }

        // set 测试：修改属性值，预期从 store 里的值也跟着变
        do {
            bool = !bool
            XCTAssert(_store.value(forKey: Keys.bool) == !Keys.bool.defaultValue)

            int += int
            XCTAssert(_store.value(forKey: Keys.int) == Keys.int.defaultValue * 2)

            double *= 2.0
            XCTAssert(abs(_store.value(forKey: Keys.double) - Keys.double.defaultValue * 2) < 0.01)

            string += "suffix"
            XCTAssert(_store.value(forKey: Keys.string) == Keys.string.defaultValue + "suffix")
        }
    }

}
