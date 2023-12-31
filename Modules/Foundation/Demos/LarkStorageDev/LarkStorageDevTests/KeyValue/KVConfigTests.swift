//
//  KVConfigTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/11/2.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

enum Keys {
    static let bool = KVKey("bool", default: false)
    static let int = KVKey("int", default: 42)
    static let double = KVKey("double", default: 42.2)
    static let string = KVKey("string", default: "str")
    static let person = KVKey("person", default: Person.rubo)
}

final class KVConfigTests: KVTestCase {

    static let store = KVStores.udkv(
        space: .uuidUser(type: typeName),
        domain: Domain("KVConfigTests").uuidChild()
    ).disposed(KVConfigTests.self)

    @KVConfig(key: Keys.bool, store: store)
    var bool: Bool
    @KVConfig(key: Keys.int, store: store)
    var int: Int
    @KVConfig(key: Keys.double, store: store)
    var double: Double
    @KVConfig(key: Keys.string, store: store)
    var string: String
    @KVConfig(key: Keys.person, store: store)
    var person: Person

    // 测试 `@KVConfig`
    func testConfig() {
        let store = Self.store

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
            XCTAssert(store.value(forKey: Keys.bool) == !Keys.bool.defaultValue)

            int += int
            XCTAssert(store.value(forKey: Keys.int) == Keys.int.defaultValue * 2)

            double *= 2.0
            XCTAssert(abs(store.value(forKey: Keys.double) - Keys.double.defaultValue * 2) < 0.01)

            string += "suffix"
            XCTAssert(store.value(forKey: Keys.string) == Keys.string.defaultValue + "suffix")

            person.name += " Liang"
            person.age += 1
            var expected = Keys.person.defaultValue
            expected.name += " Liang"
            expected.age += 1
            XCTAssert(store.value(forKey: Keys.person).isSame(as: expected))
        }
    }

    func testOptional() {
        let store = KVStores.udkv(
            space: .uuidUser(type: typeName),
            domain: Domain("KVConfigTests").child("testOptional").uuidChild()
        ).disposed(self)

        // test `Bool?`
        do {
            var nonConf = KVConfig<Bool>(key: "bool", default: false, store: store)
            var optConf = KVConfig<Bool?>(key: "bool", store: store)
            XCTAssert(nonConf.value == false)
            XCTAssert(optConf.value == nil)

            nonConf.value = true
            XCTAssert(nonConf.value == true)
            XCTAssert(optConf.value == true)

            optConf.value = nil
            XCTAssert(nonConf.value == false)
            XCTAssert(optConf.value == nil)
        }

        // test `Int?`
        do {
            var nonConf = KVConfig<Int>(key: "int", default: 42, store: store)
            var optConf = KVConfig<Int?>(key: "int", store: store)
            XCTAssert(nonConf.value == 42)
            XCTAssert(optConf.value == nil)

            nonConf.value = 73
            XCTAssert(nonConf.value == 73)
            XCTAssert(optConf.value == 73)

            optConf.value = nil
            XCTAssert(nonConf.value == 42)
            XCTAssert(optConf.value == nil)
        }

        // test `Double?`
        do {
            var nonConf = KVConfig<Double>(key: "double", default: 42.0, store: store)
            var optConf = KVConfig<Double?>(key: "double", store: store)
            XCTAssert(nonConf.value == 42.0)
            XCTAssert(optConf.value == nil)

            nonConf.value = 73.0
            XCTAssert(nonConf.value == 73.0)
            XCTAssert(optConf.value == 73.0)

            optConf.value = nil
            XCTAssert(nonConf.value == 42.0)
            XCTAssert(optConf.value == nil)
        }

        // test `Float?`
        do {
            var nonConf = KVConfig<Float>(key: "float", default: 42.0, store: store)
            var optConf = KVConfig<Float?>(key: "float", store: store)
            XCTAssert(nonConf.value == 42.0)
            XCTAssert(optConf.value == nil)

            nonConf.value = 73.0
            XCTAssert(nonConf.value == 73.0)
            XCTAssert(optConf.value == 73.0)

            optConf.value = nil
            XCTAssert(nonConf.value == 42.0)
            XCTAssert(optConf.value == nil)
        }

        // test `String?`
        do {
            var nonConf = KVConfig<String>(key: "string", default: "default", store: store)
            var optConf = KVConfig<String?>(key: "string", store: store)
            XCTAssert(nonConf.value == "default")
            XCTAssert(optConf.value == nil)

            nonConf.value = "foo"
            XCTAssert(nonConf.value == "foo")
            XCTAssert(optConf.value == "foo")

            optConf.value = nil
            XCTAssert(nonConf.value == "default")
            XCTAssert(optConf.value == nil)
        }

        // test `Person?`
        do {
            var nonConf = KVConfig<Person>(key: "person", default: Person.rubo, store: store)
            var optConf = KVConfig<Person?>(key: "person", store: store)
            XCTAssert(nonConf.value.isSame(as: Person.rubo))
            XCTAssert(optConf.value == nil)

            nonConf.value = .yiming
            XCTAssert(nonConf.value.isSame(as: .yiming))
            XCTAssert(optConf.value!.isSame(as: .yiming))

            optConf.value = nil
            XCTAssert(nonConf.value.isSame(as: .rubo))
            XCTAssert(optConf.value == nil)
        }
    }

}
