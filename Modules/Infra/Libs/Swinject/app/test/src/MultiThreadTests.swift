//
//  MultiThreadTests.swift
//  SwinjectTestTests
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation
import XCTest
@testable import Swinject

// swiftlint:disable identifier_name
class MultiThreadTests: XCTestCase {

    var container: Container!

    override func setUp() {
        super.setUp()
        container = Container()
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    func test_no_lock_with_transient_scope() {
        container.register(Foo.self) { _ in Foo() }

        let queue = DispatchQueue(label: "123", attributes: .concurrent)

        let expect = expectation(description: "")
        (0..<10).forEach { i in
            queue.async { _ = self.container.resolve(Foo.self) }
            if i == 9 {
                queue.async(flags: .barrier) {
                    expect.fulfill()
                }
            }
        }
        wait(for: [expect], timeout: 1.1)
    }

    func test_lock_with_container_scope() {
        (0..<10_000).forEach { _ in
            let lock = NSLock()

            container = nil
            container = Container()
            container.register(Foo.self) { _ in Foo() }.inObjectScope(.container)
            let queue = DispatchQueue(label: "123", attributes: .concurrent)

            var resultSet: Set<Foo> = Set()

            let expect = expectation(description: "")
            (0..<10).forEach { i in
                queue.async {
                    let foo = self.container.resolve(Foo.self)
                    lock.lock()
                    XCTAssertNotNil(foo)
                    resultSet.insert(foo!)
                    lock.unlock()
                }
                if i == 9 {
                    queue.async(flags: .barrier) {
                        XCTAssertEqual(resultSet.count, 1)
                        expect.fulfill()
                    }
                }
            }
            wait(for: [expect], timeout: 1.1)
        }
    }

    func test_lock_with_graph_scope() {
        (0..<10_000).forEach { _ in
            let lock = NSLock()

            container = nil
            container = Container()

            container.register(ScopeFooA.self) { r in ScopeFooA(b: r.resolve(ScopeFooB.self)!, c: r.resolve(ScopeFooC.self)!) }.inObjectScope(.graph)
            container.register(ScopeFooB.self) { r in ScopeFooB(r.resolve(ScopeFooD.self)!) }.inObjectScope(.graph)
            container.register(ScopeFooC.self) { r in ScopeFooC(r.resolve(ScopeFooD.self)!) }.inObjectScope(.graph)
            container.register(ScopeFooD.self) { _ in ScopeFooD() }.inObjectScope(.graph)

            let queue = DispatchQueue(label: "123", attributes: .concurrent)

            var resultSet: Set<ScopeFooA> = Set()

            let expect = expectation(description: "")
            (0..<10).forEach { i in
                queue.async {
                    let a: ScopeFooA? = self.container.resolve(ScopeFooA.self)
                    lock.lock()
                    XCTAssertNotNil(a)
                    resultSet.insert(a!)
                    XCTAssertEqual(self.container.resolutionDepth, 0)
                    XCTAssertEqual(self.container.cachedGraphObjects.innerDic.count, 0)
                    lock.unlock()
                }
                if i == 9 {
                    queue.async(flags: .barrier) {
                        resultSet.forEach { (foo) in
                            XCTAssert(foo.b.d === foo.c.d)
                        }
                        XCTAssertEqual(resultSet.count, 10)
                        expect.fulfill()
                    }
                }
            }
            wait(for: [expect], timeout: 1.1)
        }
    }
}

class Foo: NSObject {
}
// swiftlint:enable identifier_name
