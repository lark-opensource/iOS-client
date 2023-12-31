//
//  KVGetSetTester.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

// swiftlint:disable force_cast force_try

class KVGetSetTester: Tester {

    let store: KVStore

    init(store: KVStore) {
        self.store = store
    }

    func run() {
        // for `Bool`
        do {
            var val: Bool?
            val = store.value(forKey: "bool")
            XCTAssert(val == nil)

            store.set(true, forKey: "bool")
            val = store.value(forKey: "bool")
            XCTAssert(val!)
        }
        // for `Int`
        do {
            var val: Int?
            val = store.value(forKey: "int")
            XCTAssert(val == nil)

            let saved: Int = 9521
            store.set(saved, forKey: "int")
            val = store.value(forKey: "int")
            XCTAssert(val == saved)
        }
        // for `Double`
        do {
            var val: Double?
            val = store.value(forKey: "double")
            XCTAssert(val == nil)

            let saved: Double = 42.0
            store.set(saved, forKey: "double")
            val = store.value(forKey: "double")
            XCTAssert(val == saved)
        }
        // for `Float`
        do {
            var val: Float?
            val = store.value(forKey: "float")
            XCTAssert(val == nil)

            let saved: Float = 42.0
            store.set(saved, forKey: "float")
            val = store.value(forKey: "float")
            XCTAssert(val == saved)
        }
        // for `String`
        do {
            var val: String?
            val = store.value(forKey: "string")
            XCTAssert(val == nil)

            let saved: String = "42"
            store.set(saved, forKey: "string")
            val = store.value(forKey: "string")
            XCTAssert(val == saved)
        }
        // for `Data`
        do {
            var val: Data?
            val = store.value(forKey: "data")
            XCTAssert(val == nil)

            let dict = ["answer": 42] as NSDictionary
            let data = try! JSONSerialization.data(
                withJSONObject: dict,
                options: .fragmentsAllowed
            )
            store.set(data, forKey: "data")
            val = store.value(forKey: "data")
            let parse = try! JSONSerialization.jsonObject(with: val!)
                            as! NSDictionary
            XCTAssert((parse["answer"] as! Int) == 42)
        }
        // for `Date`
        do {
            var val: Date?
            val = store.value(forKey: "date")
            XCTAssert(val == nil)

            let saved = Date()
            store.set(saved, forKey: "date")
            val = store.value(forKey: "date")
            XCTAssert(abs(val!.timeIntervalSince1970 - saved.timeIntervalSince1970) < 0.001)
        }
        // for `Codable`
        do {
            var val: Person?
            val = store.value(forKey: "person")
            XCTAssert(val == nil)

            let jobs = Person(name: "Steve Jobs", age: 56)
            store.set(jobs, forKey: "person")
            val = store.value(forKey: "person")
            XCTAssert(jobs.isSame(as: val!))
        }
    }

}

// swiftlint:enable force_cast force_try
