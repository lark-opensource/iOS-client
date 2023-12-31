//
//  AssemblerUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/2.
//

import XCTest
import Foundation
import LarkAssembler // LarkAssemblyInterface
import Swinject // Assembler

/// LarkSendMessageAssembly新增单测
final class AssemblerUnitTest: CanSkipTestCase {
    func testLarkAssemblyInterface() {
        let container = Container()
        let assemblies: [LarkAssemblyInterface] = [MyAssembly()]
        _ = Assembler(assemblies: assemblies, container: container)
        // 验证MyProtocol1 resolve
        guard let myProtocol1for1 = try? container.resolve(type: MyProtocol1.self) else {
            XCTExpectFailure("resolve myProtocol1 error")
            return
        }
        var point1 = Unmanaged<AnyObject>.passUnretained(myProtocol1for1 as AnyObject).toOpaque()
        guard let myProtocol1for2 = try? container.resolve(type: MyProtocol1.self) else {
            XCTExpectFailure("resolve myProtocol1 error")
            return
        }
        var point2 = Unmanaged<AnyObject>.passUnretained(myProtocol1for2 as AnyObject).toOpaque()
        XCTAssertEqual(point1.hashValue, point2.hashValue)

        // 验证MyProtocol2 resolve
        let subContainer = Container(parent: container)
        guard let myProtocol2for1 = try? subContainer.resolve(type: MyProtocol2.self) else {
            XCTExpectFailure("resolve myProtocol2 error")
            return
        }
        point1 = Unmanaged<AnyObject>.passUnretained(myProtocol2for1 as AnyObject).toOpaque()
        guard let myProtocol2for2 = try? subContainer.resolve(type: MyProtocol2.self) else {
            XCTExpectFailure("resolve myProtocol2 error")
            return
        }
        point2 = Unmanaged<AnyObject>.passUnretained(myProtocol2for2 as AnyObject).toOpaque()
        XCTAssertNotEqual(point1.hashValue, point2.hashValue)
    }
}

final class MyAssembly: LarkAssemblyInterface {
    func getSubAssemblies() -> [LarkAssemblyInterface]? {
        return [MyAssemblyInterface1(), MyAssemblyInterface2()]
    }
}
final class MyAssemblyInterface1: LarkAssemblyInterface {
    func registContainer(container: Container) {
        // 每次都生成同一个对象
        container.register(MyProtocol1.self) { _ in MyProtocolImpl1() }.inObjectScope(.container)
    }
}
final class MyAssemblyInterface2: LarkAssemblyInterface {
    func registContainer(container: Container) {
        // 每次都生成不同对象
        container.register(MyProtocol2.self) { _ in MyProtocolImpl2() }.inObjectScope(.graph)
    }
}

protocol MyProtocol1 {}
final class MyProtocolImpl1: MyProtocol1 {}
protocol MyProtocol2 {}
final class MyProtocolImpl2: MyProtocol2 {}
