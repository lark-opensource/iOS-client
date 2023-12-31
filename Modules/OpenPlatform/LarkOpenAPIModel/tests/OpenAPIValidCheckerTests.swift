//
//  OpenAPIValidCheckerTests.swift
//  LarkOpenAPIModel-Unit-Tests
//
//  Created by Meng on 2022/1/6.
//

import XCTest
import ECOInfra
@testable import LarkOpenAPIModel

class OpenAPIValidCheckerTests: XCTestCase {

    func testStringType() {
        /// empty
        XCTAssertFalse(OpenAPIValidChecker.notEmpty(""))
        XCTAssertTrue(OpenAPIValidChecker.notEmpty("stringValue"))

        /// length
        XCTAssertTrue(OpenAPIValidChecker.length(...5)("12"))
        XCTAssertTrue(OpenAPIValidChecker.length(...5)("12345"))
        XCTAssertFalse(OpenAPIValidChecker.length(...5)("123456"))
    }

    func testNumberType() {
        /// Int
        XCTAssertTrue(OpenAPIValidChecker.range(3..<5)(3))
        XCTAssertTrue(OpenAPIValidChecker.range(3..<5)(4))
        XCTAssertFalse(OpenAPIValidChecker.range(3..<5)(5))

        /// Double
        XCTAssertFalse(OpenAPIValidChecker.range(5.0...)(3.0))
        XCTAssertTrue(OpenAPIValidChecker.range(5.0...)(5.0))
        XCTAssertTrue(OpenAPIValidChecker.range(5.0...)(10.0))

        /// Float
        XCTAssertTrue(OpenAPIValidChecker.range(..<5.0)(Float(3.0)))
        XCTAssertFalse(OpenAPIValidChecker.range(..<5.0)(Float(5.0)))

        /// CGFloat
        XCTAssertFalse(OpenAPIValidChecker.range(3.0...5.0)(CGFloat(2.0)))
        XCTAssertTrue(OpenAPIValidChecker.range(3.0...5.0)(CGFloat(3.0)))
        XCTAssertTrue(OpenAPIValidChecker.range(3.0...5.0)(CGFloat(4.0)))
        XCTAssertTrue(OpenAPIValidChecker.range(3.0...5.0)(CGFloat(5.0)))
        XCTAssertFalse(OpenAPIValidChecker.range(3.0...5.0)(CGFloat(6.0)))
    }

    func testStringEnumType() {
        /// single
        XCTAssertTrue(OpenAPIValidChecker.enum(["one", "two", "three"])("one"))
        XCTAssertFalse(OpenAPIValidChecker.enum(["one", "two", "three"])("four"))

        /// list
        XCTAssertTrue(OpenAPIValidChecker.enum(["one", "two", "three"])(["one"]))
        XCTAssertTrue(OpenAPIValidChecker.enum(["one", "two", "three"])(["one", "two"]))
        XCTAssertTrue(OpenAPIValidChecker.enum(["one", "two", "three"])(["one", "two", "three"]))
        XCTAssertTrue(OpenAPIValidChecker.enum(["one", "two", "three"])(["one", "one"]))
        XCTAssertFalse(OpenAPIValidChecker.enum(["one", "two", "three"])(["four"]))
        XCTAssertFalse(OpenAPIValidChecker.enum(["one", "two", "three"])(["one", "four"]))

        /// empty
        XCTAssertTrue(OpenAPIValidChecker.enum(["one", "two", "three"], allowEmpty: true)([]))
        XCTAssertFalse(OpenAPIValidChecker.enum(["one", "two", "three"], allowEmpty: false)([]))
    }

    func testNumberEnumType() {
        /// single
        XCTAssertTrue(OpenAPIValidChecker.enum([1, 2, 3])(1))
        XCTAssertFalse(OpenAPIValidChecker.enum([1, 2, 3])(4))

        /// list
        XCTAssertTrue(OpenAPIValidChecker.enum([1, 2, 3])([1]))
        XCTAssertTrue(OpenAPIValidChecker.enum([1, 2, 3])([1, 2]))
        XCTAssertTrue(OpenAPIValidChecker.enum([1, 2, 3])([1, 2, 3]))
        XCTAssertTrue(OpenAPIValidChecker.enum([1, 2, 3])([1, 1]))
        XCTAssertFalse(OpenAPIValidChecker.enum([1, 2, 3])([4]))
        XCTAssertFalse(OpenAPIValidChecker.enum([1, 2, 3])([1, 4]))

        /// empty
        XCTAssertTrue(OpenAPIValidChecker.enum([1, 2, 3], allowEmpty: true)([]))
        XCTAssertFalse(OpenAPIValidChecker.enum([1, 2, 3], allowEmpty: false)([]))
    }

    func testRegexPattern() {
        XCTAssertTrue(OpenAPIValidChecker.regex("one")("oneTwoThree"))
        XCTAssertFalse(OpenAPIValidChecker.regex("one")("OneTwoThree"))
        XCTAssertTrue(OpenAPIValidChecker.regex("one")("oneone"))
        XCTAssertFalse(OpenAPIValidChecker.regex("four")("OneTwoThree"))
    }
}
