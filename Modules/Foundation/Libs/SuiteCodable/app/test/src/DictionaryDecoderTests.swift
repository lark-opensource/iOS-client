//
//  RepleacemeSpec.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import Foundation
import XCTest
@testable import SuiteCodable

struct User: Codable {
    var firstName: String
    var lastName: String
    var age: Int

    enum CodingKeys: String, CodingKey {
        case name, age
    }

    enum NameCodingKeys: String, CodingKey {
        case firstName, lastName
    }

    init(firstName: String, lastName: String, age: Int) {
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        age = try container.decode(Int.self, forKey: .age)
        let name = try container.nestedContainer(keyedBy: NameCodingKeys.self, forKey: .name)
        firstName = try name.decode(String.self, forKey: .firstName)
        lastName = try name.decode(String.self, forKey: .lastName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(age, forKey: .age)

        var name = container.nestedContainer(keyedBy: NameCodingKeys.self, forKey: .name)
        try name.encode(firstName, forKey: .firstName)
        try name.encode(lastName, forKey: .lastName)
    }
}

struct Model: Codable {
    let bool: Bool
    let string: String
    let double: Double
    let float: Float
    let int: Int
    let int8: Int8
    let int16: Int16
    let int32: Int32
    let int64: Int64
    let uint: UInt
    let uint8: UInt8
    let uint16: UInt16
    let uint32: UInt32
    let uint64: UInt64
    let url: URL
    let empty: String?
}

// swiftlint:disable nesting
// swiftlint:disable type_body_length
class DictionaryDecoderTests: XCTestCase {
    var decoder = DictionaryDecoder()

    override func setUp() {
        super.setUp()
        decoder = DictionaryDecoder()
    }

    func testDecodeSimpleModel() throws {
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        struct User: Codable {
            let name: String
            let age: Int
            let isAdult: Bool?
        }

        // optional值不用设置
        let dict: [String: Any] = [
            "name": "lwl",
            "age": 15
        ]
        let user = try decoder.decode(User.self, from: dict)
        XCTAssertEqual(user.name, dict["name"] as? String)
        XCTAssertEqual(user.age, dict["age"] as? Int)
        XCTAssertEqual(user.isAdult, nil)

        // optional值
        let dict2: [String: Any] = [
            "name": "lwl",
            "age": 15,
            "is_adult": true
        ]
        let user2 = try decoder.decode(User.self, from: dict2)
        XCTAssertEqual(user2.isAdult, true)

        // 类型不匹配报错
        let dict3: [String: Any] = [
            "name": 20,
            "age": 15
        ]
        XCTAssertThrowsError(try decoder.decode(User.self, from: dict3))
    }

    func testDecodeSimpleModelWithEnum() throws {
        enum Sex: String, Codable {
            case male
            case female
        }
        struct User: Codable {
            let name: String
            let age: Int
            let sex: Sex
        }

        let dict: [String: Any] = [
            "name": "lwl",
            "age": 15,
            "sex": Sex.male
        ]
        let user = try decoder.decode(User.self, from: dict)
        XCTAssertEqual(user.name, dict["name"] as? String)
        XCTAssertEqual(user.age, dict["age"] as? Int)
        XCTAssertEqual(user.sex, Sex.male)

        let dict1: [String: Any] = [
            "name": "lwl",
            "age": 15
        ]
        XCTAssertThrowsError(try decoder.decode(User.self, from: dict1), "Key not found")
    }

    func testDecodeLossModeWithEnum() throws {
        enum Sex: String, Codable, HasDefault {
            static func `default`() -> Sex {
                .female
            }

            case male
            case female
        }
        struct User: Codable {
            let name: String
            let age: Int
            let sex: Sex
        }

        let dict: [String: Any] = [
            "name": "lwl",
            "age": 15,
            "sex": Sex.male.rawValue
        ]
        decoder.decodeTypeStrategy = .loose
        let user = try decoder.decode(User.self, from: dict)
        XCTAssertEqual(user.name, dict["name"] as? String)
        XCTAssertEqual(user.age, dict["age"] as? Int)
        XCTAssertEqual(user.sex, Sex.male)

        let dict1: [String: Any] = [
            "name": "lwl",
            "age": 15
        ]
        let user1 = try decoder.decode(User.self, from: dict1)
        XCTAssertEqual(user1.name, dict1["name"] as? String)
        XCTAssertEqual(user1.age, dict1["age"] as? Int)
        XCTAssertEqual(user1.sex, Sex.female)
        decoder.decodeTypeStrategy = .strict
    }

    func testDecodeNestedModel() throws {
        struct User: Codable {
            let name: String
            let age: Int
        }
        struct Article: Codable {
            let title: String
            let authors: [User]
        }

        let dict: [String: Any] = [
            "title": "Tatsuya Tanaka",
            "authors": [
                [
                    "name": "hello",
                    "age": 15
                ]
            ]
        ]
        let article = try decoder.decode(Article.self, from: dict)
        XCTAssertEqual(article.title, dict["title"] as? String)
        XCTAssertEqual(article.authors.first?.name, (dict["authors"] as? [[String: Any]])?.first?["name"] as? String)
    }

    func testDecodeNestedCodingKeys() throws {
        let dict: [String: Any] = [
            "name": [
                "firstName": "Taylor",
                "lastName": "Swift"
            ],
            "age": 26
        ]
        let user = try decoder.decode(User.self, from: dict)
        XCTAssertEqual(user.age, dict["age"] as? Int)
    }

    func testDecodeAllFoundationTypes() throws {
        let dict1: [String: Any] = [
            "bool": true,
            "string": "string",
            "double": Double(1.1),
            "float": Float(1.2),
            "int": Int(1),
            "int8": Int8(2),
            "int16": Int16(3),
            "int32": Int32(4),
            "int64": Int64(5),
            "uint": UInt(6),
            "uint8": UInt8(7),
            "uint16": UInt16(8),
            "uint32": UInt32(9),
            "uint64": UInt64(10),
            "url": URL(string: "http://baidu.com")!
        ]

        let model1 = try decoder.decode(Model.self, from: dict1)
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
        XCTAssertEqual(model1.url, dict1["url"] as? URL)
        XCTAssertEqual(model1.empty, dict1["empty"] as? String)
    }

    func testDecodeArray() throws {
        struct User: Codable {
            let name: String
            let age: Int
        }

        let array: [[String: Any]] = [
            [
                "name": "lwl",
                "age": 15
            ],
            [
                "name": "mike",
                "age": 16
            ]
        ]

        let users = try decoder.decode([User].self, from: array)
        XCTAssertEqual(users.count, 2)

        XCTAssertThrowsError(try decoder.decode([Int].self, from: [Int16(1)]))
        XCTAssertThrowsError(try decoder.decode([Int8].self, from: [Int16(1)]))
        XCTAssertThrowsError(try decoder.decode([Int16].self, from: [Int8(1)]))
        XCTAssertThrowsError(try decoder.decode([Int32].self, from: [Int16(1)]))
        XCTAssertThrowsError(try decoder.decode([Int64].self, from: [Int16(1)]))
        XCTAssertThrowsError(try decoder.decode([UInt].self, from: [Int16(1)]))
        XCTAssertThrowsError(try decoder.decode([UInt8].self, from: [Int16(1)]))
        XCTAssertThrowsError(try decoder.decode([UInt16].self, from: [Int8(1)]))
        XCTAssertThrowsError(try decoder.decode([UInt32].self, from: [Int16(1)]))
        XCTAssertThrowsError(try decoder.decode([UInt64].self, from: [Int16(1)]))
        XCTAssertThrowsError(try decoder.decode([Float].self, from: [Double(1)]))
        XCTAssertThrowsError(try decoder.decode([Double].self, from: [Float(1)]))
        XCTAssertThrowsError(try decoder.decode([Bool].self, from: [Float(1)]))
        XCTAssertThrowsError(try decoder.decode([String].self, from: [Float(1)]))
    }

    func testFailDecoding() throws {
        decoder.storage.push(container: "string")

        let container = try decoder.singleValueContainer()
        XCTAssertNil(try? container.decode(Bool.self))
    }

    func testLooseDecodeAllFoundationTypes() throws {
        decoder.decodeTypeStrategy = .loose

        let dict1: [String: Any] = [
            "bool": "true",
            "string": "string",
            "double": 1.1,
            "float": 1.2,
            "int": 1,
            "int8": 2,
            "int16": 3,
            "int32": 4,
            "int64": 5,
            "uint": 6,
            "uint8": 7,
            "uint16": 8,
            "uint32": 9,
            "uint64": 10,
            "url": "http://baidu.com"
        ]

        let model1 = try decoder.decode(Model.self, from: dict1)
        XCTAssertEqual(model1.bool, Bool.transform(from: dict1["bool"]!))
        XCTAssertEqual(model1.string, dict1["string"] as? String)
        XCTAssertEqual(model1.double, dict1["double"] as? Double)
        XCTAssertEqual(model1.float, Float(dict1["float"] as? Double ?? 0.0))
        XCTAssertEqual(model1.int, dict1["int"] as? Int ?? 0)
        XCTAssertEqual(model1.int8, Int8(dict1["int8"] as? Int ?? 0))
        XCTAssertEqual(model1.int16, Int16(dict1["int16"] as? Int ?? 0))
        XCTAssertEqual(model1.int32, Int32(dict1["int32"] as? Int ?? 0))
        XCTAssertEqual(model1.int64, Int64(dict1["int64"] as? Int ?? 0))
        XCTAssertEqual(model1.uint, UInt(dict1["uint"] as? Int ?? 0))
        XCTAssertEqual(model1.uint8, UInt8(dict1["uint8"] as? Int ?? 0))
        XCTAssertEqual(model1.uint16, UInt16(dict1["uint16"] as? Int ?? 0))
        XCTAssertEqual(model1.uint32, UInt32(dict1["uint32"] as? Int ?? 0))
        XCTAssertEqual(model1.uint64, UInt64(dict1["uint64"] as? Int ?? 0))
        XCTAssertEqual(model1.url.absoluteString, dict1["url"] as? String)
        XCTAssertEqual(model1.empty, dict1["empty"] as? String)
    }

    func testLooseDecodeArray() throws {
        decoder.decodeTypeStrategy = .loose

        let intsArr = [Int8(1), 2, 3]
        let ints = try decoder.decode([Int].self, from: intsArr)
        XCTAssertEqual(ints.first, Int(intsArr.first ?? 0))

        let int8s = try decoder.decode([Int8].self, from: [Int16(1), Int8(2), Int8(3)])
        XCTAssertEqual(int8s.count, 3)
        let int16s = try decoder.decode([Int16].self, from: [Int16(1), 2, Int16(3)])
        XCTAssertEqual(int16s.count, 3)
        let int32s = try decoder.decode([Int32].self, from: [Int32(1), Int8(2), Int32(3)])
        XCTAssertEqual(int32s.count, 3)
        let int64s = try decoder.decode([Int64].self, from: [Int64(1), Int32(2), Int64(3)])
        XCTAssertEqual(int64s.count, 3)
        let uints = try decoder.decode([UInt].self, from: [UInt(1), 2, UInt(3)])
        XCTAssertEqual(uints.count, 3)
        let uint8s = try decoder.decode([UInt8].self, from: [UInt8(1), UInt(2), UInt8(3)])
        XCTAssertEqual(uint8s.count, 3)
        let uint16s = try decoder.decode([UInt16].self, from: [UInt16(1), UInt32(2), UInt16(3)])
        XCTAssertEqual(uint16s.count, 3)
        let uint32s = try decoder.decode([UInt32].self, from: [UInt32(1), UInt16(2), UInt32(3)])
        XCTAssertEqual(uint32s.count, 3)
        let uint64s = try decoder.decode([UInt64].self, from: [UInt64(1), UInt16(2), UInt64(3)])
        XCTAssertEqual(uint64s.count, 3)

        let bools = try decoder.decode([Bool].self, from: [true, "true", false])
        XCTAssertEqual(bools.count, 3)
        let floats = try decoder.decode([Float].self, from: [Float(1.1), 2.1, Float(3.1)])
        XCTAssertEqual(floats.count, 3)
        let doubles = try decoder.decode([Double].self, from: [Float(1.1), Double(2.1), Double(3.1)])
        XCTAssertEqual(doubles.count, 3)
        let strings = try decoder.decode([String].self, from: [1, "2", "hh"])
        XCTAssertEqual(strings.count, 3)
    }

    func testLooseDecodeDefaults() throws {
        decoder.decodeTypeStrategy = .loose

        let dict1: [String: Any] = [
            "url": "http://baidu.com"
        ]

        let model1 = try decoder.decode(Model.self, from: dict1)
        XCTAssertEqual(model1.bool, false)
        XCTAssertEqual(model1.string, "")
        XCTAssertEqual(model1.double, 0.0)
        XCTAssertEqual(model1.float, Float(0.0))
        XCTAssertEqual(model1.int, 0)
        XCTAssertEqual(model1.int8, Int8(0))
        XCTAssertEqual(model1.int16, Int16(0))
        XCTAssertEqual(model1.int32, Int32(0))
        XCTAssertEqual(model1.int64, Int64(0))
        XCTAssertEqual(model1.uint, UInt(0))
        XCTAssertEqual(model1.uint8, UInt8(0))
        XCTAssertEqual(model1.uint16, UInt16(0))
        XCTAssertEqual(model1.uint32, UInt32(0))
        XCTAssertEqual(model1.uint64, UInt64(0))
        XCTAssertEqual(model1.url.absoluteString, dict1["url"] as? String)
        XCTAssertEqual(model1.empty, nil)

        let dict2: [String: Any] = [:]
        // 缺少URL，URL没有默认值
        XCTAssertThrowsError(try decoder.decode(Model.self, from: dict2))

        let dict3: [String: Any] = [
            "url": ""
        ]
        XCTAssertThrowsError(try decoder.decode(Model.self, from: dict3))
    }
}
