//
//  FuncContextSpec.swift
//  LarkFoundationDevEEUnitTest
//
//  Created by qihongye on 2019/11/21.
//

import UIKit
import Foundation
import XCTest

@testable import LarkFoundation

class FuncContextSpec: XCTestCase {
    let types: [Any.Type] = [Int.self, Int32.self, Int8.self, Int64.self, Int16.self, String.self, NSObject.self, NSString.self, DispatchQueue.self, NSAttributedString.self,
                             NSMutableSet.self, NSDate.self, Data.self, NSNumber.self]
    let values: [Any] = [1, 2, 3, 4, 5, "1", NSObject(), NSString("1"), DispatchQueue.main, NSAttributedString(string: "1"), NSMutableSet(), NSDate(), Data(), NSNumber()]

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFuncContextKey() {
        let key = FuncContextKey("int", Int.self)
        let keyIntInt = FuncContextKey("int", Int.self)
        XCTAssertEqual(key, keyIntInt)
        let keyIntInt64 = FuncContextKey("int", Int64.self)
        XCTAssertNotEqual(key, keyIntInt64)
        let keyIntInt32 = FuncContextKey("int", Int32.self)
        XCTAssertNotEqual(key, keyIntInt32)
        let keyInt64Int = FuncContextKey("int64", Int.self)
        XCTAssertNotEqual(key, keyInt64Int)

        var map: [FuncContextKey: Bool] = [:]
        map[key] = false
        XCTAssertTrue(map.keys.contains(FuncContextKey("int", Int.self)))
    }

    func testFuncContext() {
        let key = "Key"
        let context = FuncContext()
        context.set(key: key, value: Int(1))
        context.set(key: key, value: Int32(2))
        context.set(key: key, value: Int8(3))
        context.set(key: key, value: Int64(4))
        context.set(key: key, value: Int16(5))
        context.set(key: key, value: String("1231"))
        context.set(key: key, value: NSString(string: "1231"))
        if true {
            let v: Int? = context.get(key: key)
            XCTAssertTrue(v == 1)
        }
        if true {
            let v: Int32? = context.get(key: key)
            XCTAssertTrue(v == Int32(2))
        }
        if true {
            let v: Int8? = context.get(key: key)
            XCTAssertTrue(v == Int8(3))
        }

        if true {
            let v: Int64? = context.get(key: key)
            XCTAssertTrue(v == Int64(4))
        }

        if true {
            let v: Int16? = context.get(key: key)
            XCTAssertTrue(v == Int16(5))
        }

        if true {
            let v: String? = context.get(key: key)
            XCTAssertTrue(v == String("1231"))
        }

        if true {
            let v: NSString? = context.get(key: key)
            XCTAssertTrue(v == NSString(string: "1231"))
        }
    }

    func testPerformanceObjectIdentify() {
        // This is an example of a performance test case.
        var map: [ObjectIdentifier: Bool] = [:]
        self.measure {
            for type in types {
                map[ObjectIdentifier(type)] = false
            }
        }
    }

    func testPerformanceUnsafeBitCast() {
        // This is an example of a performance test case.
        var map: [Int: Bool] = [:]
        self.measure {
            for type in types {
                map[Int(bitPattern: unsafeBitCast(type, to: UnsafeRawPointer.self))] = false
            }
        }
    }


    func testPerformanceObjectIdentifyHaser() {
        // This is an example of a performance test case.
        var hasher = Hasher()
        self.measure {
            for type in types {
                ObjectIdentifier(type).hash(into: &hasher)
            }
        }
    }

    func testPerformanceUnsafeBitCastHasher() {
        // This is an example of a performance test case.
        var hasher = Hasher()
        self.measure {
            for type in types {
                hasher.combine(Int(bitPattern: unsafeBitCast(type, to: UnsafeRawPointer.self)))
            }
        }
    }
}
