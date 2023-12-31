//
//  LarkContainerDemoTests.swift
//  LarkContainerDemoTests
//
//  Created by SuPeng on 8/24/19.
//  Copyright © 2019 SuPeng. All rights reserved.
//

// swiftlint:disable all
import Foundation
import XCTest
import Swinject
import LarkContainer

class InjectedTest: XCTestCase {
    let container = Container.shared

    override func setUp() {
        container.register(Bar.self) { _ in Bar() }
        container.register(Bar.self) { (_, arg: String) in Bar(arg) }
        container.register(Bar.self) { (_, arg1: String, arg2: String) in Bar(arg1 + arg2) }
    }

    func testInject() {
        let foo = Foo()
        // basic
        assert(foo.bar.name == "")
        // 确保每次取出是同一个对象
        assert(foo.bar === foo.bar)
        // keyPath
        assert(foo.name == "")
        // funcReference
        assert(foo.doSomething(1) == "")
    }

    func testName() {
        container.register(Bar.self, name: "Name1") { _ in Bar("Name1")}
        container.register(Bar.self, name: "Name2") { _ in Bar("Name2")}

        let nameFoo = NameFoo()
        assert(nameFoo.bar1.name == "Name1")
        assert(nameFoo.bar2.name == "Name2")
    }

    func testArgument() {
        let argumentFoo = ArgumentFoo()
        assert(argumentFoo.bar1.name == "arg1")
        assert(argumentFoo.bar2.name == "arg1arg2")
    }


    func testLazy() {
        let currentAllocNumber = Bar.allocNumber

        let lazyFoo = LazyFoo()
        //确保没有新的Bar创建
        assert(Bar.allocNumber == currentAllocNumber)

        //确保创建了一个新的Bar
        let bar1 = lazyFoo.bar1
        assert(Bar.allocNumber == currentAllocNumber + 1)

        //确保再次调用没有新的Bar创建
        assert(bar1 === lazyFoo.bar1)
        assert(Bar.allocNumber == currentAllocNumber + 1)

        assert(bar1.name == "")
        assert(lazyFoo.bar2.name == "arg1")
    }
    func testSafeLazy() {
        let currentAllocNumber = Bar.allocNumber

        let lazyFoo = SafeLazyFoo()
        //确保没有新的Bar创建
        assert(Bar.allocNumber == currentAllocNumber)

        //确保创建了一个新的Bar
        let bar1 = lazyFoo.bar1
        assert(Bar.allocNumber == currentAllocNumber + 1)

        //确保再次调用没有新的Bar创建
        assert(bar1 === lazyFoo.bar1)
        assert(Bar.allocNumber == currentAllocNumber + 1)

        assert(bar1.name == "")
        assert(lazyFoo.bar2.name == "arg1")
    }

    func testProvider() {
        let currentAllocNumber = Bar.allocNumber

        let providerFoo = ProviderFoo()
        //确保没有新的Bar创建
        assert(Bar.allocNumber == currentAllocNumber)

        //确保创建了一个新的Bar
        let bar1 = providerFoo.bar1
        assert(Bar.allocNumber == currentAllocNumber + 1)

        //确保再次调用创建新的Bar
        assert(bar1 !== providerFoo.bar1)
        assert(Bar.allocNumber == currentAllocNumber + 2)

        assert(bar1.name == "")
        assert(providerFoo.bar2.name == "arg1")
    }

    func testOptional() {
        let fooOptional = FooOptional()
        XCTAssertNotNil(fooOptional.bar1)
        XCTAssertNil(fooOptional.bar2)
        XCTAssertNotNil(fooOptional.bar3)
        XCTAssertNil(fooOptional.bar4)
    }
}

// swiftlint:enable all
