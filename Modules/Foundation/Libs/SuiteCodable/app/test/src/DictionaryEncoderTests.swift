//
//  DictionaryEncoderTests.swift
//  SuiteCodableDevEEUnitTest
//
//  Created by liuwanlin on 2019/5/4.
//

import Foundation
import XCTest
@testable import SuiteCodable

// swiftlint:disable nesting
class DictionaryEncoderTests: XCTestCase {

     var encoder = DictionaryEncoder()

    override func setUp() {
        super.setUp()
        encoder = DictionaryEncoder()
    }

    func testEncodeSimpleModel() throws {
        struct User: Codable {
            let name: String
            let age: Int
            let isAdult: Bool?
        }
        let user = User(name: "lwl", age: 15, isAdult: true)
        let dict = try encoder.encode(user)
        XCTAssertEqual(user.name, dict["name"] as? String)
        XCTAssertEqual(user.age, dict["age"] as? Int)
        XCTAssertEqual(user.isAdult, true)
        XCTAssert(encoder.storage.containers.isEmpty)
    }

    func testEncodeNestedModel() throws {
        struct User: Codable {
            let name: String
            let age: Int
        }
        struct Article: Codable {
            let title: String
            let authors: [User]
        }

        let article = Article(title: "test", authors: [
            User(name: "lwl", age: 15),
            User(name: "kkk", age: 18)
        ])
        let dict = try encoder.encode(article)
        XCTAssertNotNil(dict["authors"] as? [Any])
        XCTAssertEqual(article.title, dict["title"] as? String)
        XCTAssertEqual(article.authors.first?.name, (dict["authors"] as? [[String: Any]])?.first?["name"] as? String)
        XCTAssert(encoder.storage.containers.isEmpty)
    }

    func testEncodeNestedCodingKeys() throws {
        let user = User(firstName: "liu", lastName: "wanlin", age: 18)
        let dict = try encoder.encode(user)
        XCTAssert(encoder.storage.containers.isEmpty)
        XCTAssertEqual(user.age, dict["age"] as? Int)
    }

    func testEncodeAllFoundationTypes() throws {
        let model1 = Model(
            bool: true,
            string: "string",
            double: Double(1.1),
            float: Float(1.2),
            int: Int(1),
            int8: Int8(2),
            int16: Int16(3),
            int32: Int32(4),
            int64: Int64(5),
            uint: UInt(6),
            uint8: UInt8(7),
            uint16: UInt16(8),
            uint32: UInt32(9),
            uint64: UInt64(10),
            url: URL(string: "http://baidu.com")!,
            empty: nil
        )

        let dict1 = try encoder.encode(model1)
        XCTAssertEqual(model1.bool, dict1["bool"] as? Bool)
        XCTAssertEqual(model1.string, dict1["string"] as? String)
        XCTAssertEqual(model1.double, dict1["double"] as? Double)
        XCTAssertEqual(model1.float, dict1["float"] as? Float)
        XCTAssertEqual(model1.int, dict1["int"] as? Int)
        XCTAssertEqual(model1.int8, dict1["int8"] as? Int8)
        XCTAssertEqual(model1.int16, dict1["int16"] as? Int16)
        XCTAssertEqual(model1.int32, dict1["int32"] as? Int32)
        XCTAssertEqual(model1.int64, dict1["int64"] as? Int64)
        XCTAssertEqual(model1.uint, dict1["uint"] as? UInt)
        XCTAssertEqual(model1.uint8, dict1["uint8"] as? UInt8)
        XCTAssertEqual(model1.uint16, dict1["uint16"] as? UInt16)
        XCTAssertEqual(model1.uint32, dict1["uint32"] as? UInt32)
        XCTAssertEqual(model1.uint64, dict1["uint64"] as? UInt64)
        XCTAssertEqual(model1.url.absoluteString, dict1["url"] as? String)
        XCTAssertEqual(model1.empty, dict1["empty"] as? String)
        XCTAssert(encoder.storage.containers.isEmpty)
    }

    func testEncodeArray() throws {
        struct User: Codable {
            let name: String
            let age: Int
        }

        let users = [
            User(name: "lwl", age: 15),
            User(name: "kkk", age: 18)
        ]
        let array = try encoder.encode(users)
        XCTAssertEqual(users.count, array.count)
        XCTAssertEqual(users.first?.name, array.first?["name"] as? String)

        XCTAssertThrowsError(try encoder.encode([true, true, false]))
        XCTAssertThrowsError(try encoder.encode(["1", "true", "false"]))
        XCTAssertThrowsError(try encoder.encode([Float(1.1), Float(2.1), Float(3.1)]))
        XCTAssertThrowsError(try encoder.encode([Double(1.1), Double(2.1), Double(3.1)]))
        XCTAssertThrowsError(try encoder.encode([Int(1), Int(2), Int(3)]))
        XCTAssertThrowsError(try encoder.encode([Int8(1), Int8(2), Int8(3)]))
        XCTAssertThrowsError(try encoder.encode([Int16(1), Int16(2), Int16(3)]))
        XCTAssertThrowsError(try encoder.encode([Int32(1), Int32(2), Int32(3)]))
        XCTAssertThrowsError(try encoder.encode([Int64(1), Int64(2), Int64(3)]))
        XCTAssertThrowsError(try encoder.encode([UInt(1), UInt(2), UInt(3)]))
        XCTAssertThrowsError(try encoder.encode([UInt8(1), UInt8(2), UInt8(3)]))
        XCTAssertThrowsError(try encoder.encode([UInt16(1), UInt16(2), UInt16(3)]))
        XCTAssertThrowsError(try encoder.encode([UInt32(1), UInt32(2), UInt32(3)]))
        XCTAssertThrowsError(try encoder.encode([UInt64(1), UInt64(2), UInt64(3)]))
        XCTAssert(encoder.storage.containers.isEmpty)
    }
}
