//
//  ScopeTests.swift
//  SwinjectTestTests
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation
import XCTest
import Swinject

// swiftlint:disable identifier_name
class ScopeTests: XCTestCase {

    var container: Container!

    override func setUp() {
        super.setUp()
        container = Container()
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    func test_resolve_transient_objects() {
        container.register(NSObject.self) { _ in NSObject() }.inObjectScope(.transient)
        let firstObject: NSObject? = container.resolve(NSObject.self)
        XCTAssertNotNil(firstObject)

        let secondObject: NSObject? = container.resolve(NSObject.self)
        XCTAssertNotNil(secondObject)
        XCTAssertNotEqual(firstObject, secondObject)
    }

    func test_resolve_container_objects() {
        container.register(NSObject.self) { _ in NSObject() }.inObjectScope(.container)

        let firstObject: NSObject? = container.resolve(NSObject.self)
        XCTAssertNotNil(firstObject)

        let secondObject: NSObject? = container.resolve(NSObject.self)
        XCTAssertNotNil(secondObject)
        XCTAssertEqual(firstObject, secondObject)
    }

    func test_resolve_container_scope_reset() {
        container.register(NSObject.self) { _ in NSObject() }.inObjectScope(.container)

        let firstObject: NSObject? = container.resolve(NSObject.self)
        XCTAssertNotNil(firstObject)

        container.resetObjectScope(.container)

        let secondObject: NSObject? = container.resolve(NSObject.self)
        XCTAssertNotNil(secondObject)

        XCTAssertNotEqual(firstObject, secondObject)
    }

    func test_resolve_graph_objects() {
        container.register(ScopeFooA.self) { r in ScopeFooA(b: r.resolve(ScopeFooB.self)!, c: r.resolve(ScopeFooC.self)!) }.inObjectScope(.graph)
        container.register(ScopeFooB.self) { r in ScopeFooB(r.resolve(ScopeFooD.self)!) }.inObjectScope(.graph)
        container.register(ScopeFooC.self) { r in ScopeFooC(r.resolve(ScopeFooD.self)!) }.inObjectScope(.graph)
        container.register(ScopeFooD.self) { _ in ScopeFooD() }.inObjectScope(.graph)

        let a: ScopeFooA = container.resolve(ScopeFooA.self)!
        XCTAssert(a.b.d === a.c.d)
    }

    func test_resolve_custom_scope_objects() {
        container.register(NSObject.self) { _ in NSObject() }.inObjectScope(.user)

        let firstObject: NSObject? = container.resolve(NSObject.self)
        XCTAssertNotNil(firstObject)

        let secondObject: NSObject? = container.resolve(NSObject.self)
        XCTAssertNotNil(secondObject)

        XCTAssertEqual(firstObject, secondObject)

        container.resetObjectScope(.user)

        let thirdObject: NSObject? = container.resolve(NSObject.self)
        XCTAssertNotNil(thirdObject)

        XCTAssertNotEqual(firstObject, thirdObject)
    }
}

extension ObjectScope {
    static let user = PermanentObjectScope()
}

class ScopeFooA: Hashable {
    let b: ScopeFooB
    let c: ScopeFooC
    init(b: ScopeFooB, c: ScopeFooC) {
        self.b = b
        self.c = c
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(b)
        hasher.combine(c)
        hasher.combine(b.d)
        hasher.combine(c.d)
    }

    static func == (lhs: ScopeFooA, rhs: ScopeFooA) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

class ScopeFooB: NSObject {
    let d: ScopeFooD
    init(_ d: ScopeFooD) {
        self.d = d
    }
}

class ScopeFooC: NSObject {
    let d: ScopeFooD
    init(_ d: ScopeFooD) {
        self.d = d
    }
}

class ScopeFooD: NSObject {
}
// swiftlint:enable identifier_name
