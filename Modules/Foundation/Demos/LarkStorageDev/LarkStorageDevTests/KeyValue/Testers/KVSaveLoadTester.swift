//
//  KVSaveLoadTester.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

// swiftlint:disable force_cast force_try

class KVSaveLoadTester: Tester {
    let store: KVStoreBase

    init(store: KVStoreBase) {
        self.store = store
    }

    func run() {
        // for `Bool`
        do {
            var val: Bool?
            val = store.loadValue(forKey: "bool")
            XCTAssert(val == nil)

            store.saveValue(true, forKey: "bool")
            val = store.loadValue(forKey: "bool")
            XCTAssert(val!)
        }
        // for `Int`
        do {
            var val: Int?
            val = store.loadValue(forKey: "int")
            XCTAssert(val == nil)

            let saved: Int = 9521
            store.saveValue(saved, forKey: "int")
            val = store.loadValue(forKey: "int")
            XCTAssert(val == saved)
        }
        // for `Double`
        do {
            var val: Double?
            val = store.loadValue(forKey: "double")
            XCTAssert(val == nil)

            let saved: Double = 42.0
            store.saveValue(saved, forKey: "double")
            val = store.loadValue(forKey: "double")
            XCTAssert(val == saved)
        }
        // for `Float`
        do {
            var val: Float?
            val = store.loadValue(forKey: "float")
            XCTAssert(val == nil)

            let saved: Float = 42.0
            store.saveValue(saved, forKey: "float")
            val = store.loadValue(forKey: "float")
            XCTAssert(val == saved)
        }
        // for `String`
        do {
            var val: String?
            val = store.loadValue(forKey: "string")
            XCTAssert(val == nil)

            let saved: String = "42"
            store.saveValue(saved, forKey: "string")
            val = store.loadValue(forKey: "string")
            XCTAssert(val == saved)
        }
        // for `Data`
        do {
            var val: Data?
            val = store.loadValue(forKey: "data")
            XCTAssert(val == nil)

            let dict = ["answer": 42] as NSDictionary
            let data = try! JSONSerialization.data(
                withJSONObject: dict,
                options: .fragmentsAllowed
            )
            store.saveValue(data, forKey: "data")
            val = store.loadValue(forKey: "data")
            let parse = try! JSONSerialization.jsonObject(with: val!)
                            as! NSDictionary
            XCTAssert((parse["answer"] as! Int) == 42)
        }
        // for `Date`
        do {
            var val: Date?
            val = store.loadValue(forKey: "date")
            XCTAssert(val == nil)

            let saved = Date()
            store.saveValue(saved, forKey: "date")
            val = store.loadValue(forKey: "date")
            XCTAssert(abs(val!.timeIntervalSince1970 - saved.timeIntervalSince1970) < 0.001)
        }
        // for `NSCoding + NSObjectProtocol`
        do {
            var val: Product?
            val = store.loadValue(forKey: "product")
            XCTAssert(val == nil)

            let ipad = Product(name: "iPad", price: 666.6)
            store.saveValue(ipad, forKey: "product")
            val = store.loadValue(forKey: "product")
            XCTAssert(ipad == val!)
        }
    }
}

// swiftlint:enable force_cast force_try
