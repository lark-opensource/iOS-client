//
//  LarkCompatibleTest.swift
//  LarkCompatibleDevEEUnitTest
//
//  Created by CharlieSu on 3/19/20.
//

import Foundation
import XCTest
import LarkCompatible

class LarkCompatibleTest: XCTestCase {

    var foo: Foo!

    override func setUp() {
        foo = Foo()
        Foo.staticFuncCalled = false
    }

    override func tearDown() {
        foo = nil
    }

    func test_lu_extension() {
        XCTAssert(foo.lu.base === foo)
        Foo.lu.test()
        XCTAssertTrue(Foo.staticFuncCalled)
    }

    func test_lk_extension() {
        XCTAssert(foo.lf.base === foo)
        Foo.lf.test()
        XCTAssertTrue(Foo.staticFuncCalled)
    }
}


class Foo {
    static var staticFuncCalled: Bool = false
}

extension Foo: LarkUIKitExtensionCompatible {}

extension LarkUIKitExtension where BaseType == Foo {
    static func test() {
        BaseType.staticFuncCalled = true
    }
}

extension Foo: LarkFoundationExtensionCompatible {}

extension LarkFoundationExtension where BaseType == Foo {
    static func test() {
        BaseType.staticFuncCalled = true
    }
}
