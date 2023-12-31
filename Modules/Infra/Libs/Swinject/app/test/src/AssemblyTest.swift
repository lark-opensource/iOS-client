//
//  AssemblyTest.swift
//  SwinjectTestTests
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation
import XCTest
@testable import Swinject

class AssemblyTest: XCTestCase {
    var container: Container!

    override func setUp() {
        super.setUp()
        container = Container()
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    func test_assemble() {
        let assemblerArr: [Assembly] = [FooAssembly(), BarAssembly(), AniAssembly()]

        let assembler = Assembler(assemblerArr, container: container)

        DispatchQueue.global().async {
            assemblerArr.forEach { assemble in
                assemble.asyncAssemble()
            }
        }
        XCTAssert((assembler.resolver as? Container)! === container)

        let result1: String? = container.resolve(String.self)
        XCTAssertNotNil(result1)

        let result2: Int? = container.resolve(Int.self)
        XCTAssertNotNil(result2)
    }
}

class FooAssembly: Assembly {
    func assemble(container: Container) {
        container.register(String.self) { _ in "Foo" }
    }
}

class BarAssembly: Assembly {
    func assemble(container: Container) {
        container.register(Int.self) { _ in 123 }
    }
}

class AniAssembly: Assembly {
    func assemble(container: Container) {
        container.register(Int.self) { _ in 1 }
    }
    func asyncAssemble() {
        print("[asyncAssemble]")
    }
}
