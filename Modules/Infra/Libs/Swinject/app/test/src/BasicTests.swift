//
//  BasicTests.swift
//  SwinjectTestTests
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation
import XCTest
@testable import Swinject

// swiftlint:disable identifier_name
// swiftlint:disable empty_count
class BasicTests: XCTestCase {

    var container: Container!

    override func setUp() {
        super.setUp()
        container = Container()
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    func test_container_synchronize() {
        let result = container.synchronize()
        let resultContainer = result as? Container
        XCTAssertNotNil(resultContainer)
        XCTAssert(container === resultContainer!)
    }

    func test_container_basic() {
        container.register(String.self) { _ in "123" }
        let result = container.resolve(String.self)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, "123")

        let anotherResult: String? = container.resolve(String.self)
        XCTAssertEqual(anotherResult, result)

        XCTAssertNil(container.resolve(NSMutableDictionary.self))
    }

    func test_container_name() {
        container.register(String.self, name: "name") { _ in "123" }
        var result = container.resolve(String.self)
        XCTAssertNil(result)
        result = container.resolve(String.self, name: "name")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, "123")
    }

    func test_container_arg() {
        container.register(String.self) { (_, arg: String) in arg + "123" }
        var result = container.resolve(String.self)
        XCTAssertNil(result)
        result = container.resolve(String.self, argument: "argument")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, "argument123")
    }

    func test_container_two_depths_resolve() {
        container.register(FooA.self) { _ in FooA() }
        container.register(FooB.self) { (r) in
            let a = r.resolve(FooA.self)
            XCTAssertNotNil(a)
            return FooB(a: a!)
        }
        let b = container.resolve(FooB.self)
        XCTAssertNotNil(b)
    }

    // MARK: Internal Test
    func test_resolve_reach_max_depth() {
        container.resolutionDepth = Int.max
        XCTAssertThrowsError(try container.incrementResolutionDepth()) { (error) in
            if case SwinjectError.maxResolutionDepth = error {

            } else {
                XCTExpectFailure("not raise maxResolutionDepth error")
            }
        }
        container.resolutionDepth = 0
    }

    func test_cached_graph_objects_cleaned_when_depth_is_zero() {
        container.cachedGraphObjects.removeAllObjects()
        container.cachedGraphObjects[ObjectIdentifier(container)] = "aaa"
        container.resolutionDepth = 1
        XCTAssertNoThrow(try container.decrementResolutionDepth())
        XCTAssert(container.cachedGraphObjects.innerDic.count == 0)
        XCTAssert(container.resolutionDepth == 0)
    }

    func test_depth_cannot_be_negative() {
        container.resolutionDepth = 0
        XCTAssertThrowsError(try container.decrementResolutionDepth()) { (error) in
            if case SwinjectError.depthCannotBeNegative = error {
            } else {
                XCTExpectFailure("not raise depthCannotBeNegative error")
            }
        }
    }
}

struct FooA { }

struct FooB {
    let a: FooA
}
// swiftlint:enable identifier_name
// swiftlint:enable empty_count
