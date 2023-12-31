//
//  Container+Register.generated.swift
//  Swinject
//
//  Created by CharlieSu on 4/30/20.
//
// swiftlint:disable all
//
// NOTICE: Generated Code, Do Not Edit!
//

import Foundation
import XCTest
import Swinject

// swiftlint:disable identifier_name
class GeneratedTests: XCTestCase {

    var container: Container!
    var resolver: Resolver { return container as Resolver }

    override func setUp() {
        super.setUp()
        container = Container()
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    func test_container_with_arg_1() {

        container.register(String.self) { (_, arg1: String) -> String in
            "result:" + arg1
        }

        container.register(String.self, name: "name") { (_, arg1: String) -> String in
            "resultWithName:" + arg1
        }

        let result = resolver.resolve(String.self, argument: "arg1")!
        XCTAssert(result == "result:arg1")

        let resultWithName = resolver.resolve(String.self, name: "name", argument: "arg1")!
        XCTAssert(resultWithName == "resultWithName:arg1")

        let result2 = try! resolver.resolve(type: String.self, argument: "arg1")
        XCTAssert(result2 == "result:arg1")

        let resultWithName2 = try! resolver.resolve(assert: String.self, name: "name", argument: "arg1")
        XCTAssert(resultWithName2 == "resultWithName:arg1")
    }

    func test_container_with_arg_2() {

        container.register(String.self) { (_, arg1: String, arg2: String) -> String in
            "result:" + arg1 + arg2
        }

        container.register(String.self, name: "name") { (_, arg1: String, arg2: String) -> String in
            "resultWithName:" + arg1 + arg2
        }

        let result = resolver.resolve(String.self, arguments: "arg1", "arg2")!
        XCTAssert(result == "result:arg1arg2")

        let resultWithName = resolver.resolve(String.self, name: "name", arguments: "arg1", "arg2")!
        XCTAssert(resultWithName == "resultWithName:arg1arg2")

        let result2 = try! resolver.resolve(type: String.self, arguments: "arg1", "arg2")
        XCTAssert(result2 == "result:arg1arg2")

        let resultWithName2 = try! resolver.resolve(assert: String.self, name: "name", arguments: "arg1", "arg2")
        XCTAssert(resultWithName2 == "resultWithName:arg1arg2")
    }

    func test_container_with_arg_3() {

        container.register(String.self) { (_, arg1: String, arg2: String, arg3: String) -> String in
            "result:" + arg1 + arg2 + arg3
        }

        container.register(String.self, name: "name") { (_, arg1: String, arg2: String, arg3: String) -> String in
            "resultWithName:" + arg1 + arg2 + arg3
        }

        let result = resolver.resolve(String.self, arguments: "arg1", "arg2", "arg3")!
        XCTAssert(result == "result:arg1arg2arg3")

        let resultWithName = resolver.resolve(String.self, name: "name", arguments: "arg1", "arg2", "arg3")!
        XCTAssert(resultWithName == "resultWithName:arg1arg2arg3")

        let result2 = try! resolver.resolve(type: String.self, arguments: "arg1", "arg2", "arg3")
        XCTAssert(result2 == "result:arg1arg2arg3")

        let resultWithName2 = try! resolver.resolve(assert: String.self, name: "name", arguments: "arg1", "arg2", "arg3")
        XCTAssert(resultWithName2 == "resultWithName:arg1arg2arg3")
    }

    func test_container_with_arg_4() {

        container.register(String.self) { (_, arg1: String, arg2: String, arg3: String, arg4: String) -> String in
            "result:" + arg1 + arg2 + arg3 + arg4
        }

        container.register(String.self, name: "name") { (_, arg1: String, arg2: String, arg3: String, arg4: String) -> String in
            "resultWithName:" + arg1 + arg2 + arg3 + arg4
        }

        let result = resolver.resolve(String.self, arguments: "arg1", "arg2", "arg3", "arg4")!
        XCTAssert(result == "result:arg1arg2arg3arg4")

        let resultWithName = resolver.resolve(String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4")!
        XCTAssert(resultWithName == "resultWithName:arg1arg2arg3arg4")

        let result2 = try! resolver.resolve(type: String.self, arguments: "arg1", "arg2", "arg3", "arg4")
        XCTAssert(result2 == "result:arg1arg2arg3arg4")

        let resultWithName2 = try! resolver.resolve(assert: String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4")
        XCTAssert(resultWithName2 == "resultWithName:arg1arg2arg3arg4")
    }

    func test_container_with_arg_5() {

        container.register(String.self) { (_, arg1: String, arg2: String, arg3: String, arg4: String, arg5: String) -> String in
            "result:" + arg1 + arg2 + arg3 + arg4 + arg5
        }

        container.register(String.self, name: "name") { (_, arg1: String, arg2: String, arg3: String, arg4: String, arg5: String) -> String in
            "resultWithName:" + arg1 + arg2 + arg3 + arg4 + arg5
        }

        let result = resolver.resolve(String.self, arguments: "arg1", "arg2", "arg3", "arg4", "arg5")!
        XCTAssert(result == "result:arg1arg2arg3arg4arg5")

        let resultWithName = resolver.resolve(String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4", "arg5")!
        XCTAssert(resultWithName == "resultWithName:arg1arg2arg3arg4arg5")

        let result2 = try! resolver.resolve(type: String.self, arguments: "arg1", "arg2", "arg3", "arg4", "arg5")
        XCTAssert(result2 == "result:arg1arg2arg3arg4arg5")

        let resultWithName2 = try! resolver.resolve(assert: String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4", "arg5")
        XCTAssert(resultWithName2 == "resultWithName:arg1arg2arg3arg4arg5")
    }

    func test_container_with_arg_6() {

        container.register(String.self) { (_, arg1: String, arg2: String, arg3: String, arg4: String, arg5: String, arg6: String) -> String in
            "result:" + arg1 + arg2 + arg3 + arg4 + arg5 + arg6
        }

        container.register(String.self, name: "name") { (_, arg1: String, arg2: String, arg3: String, arg4: String, arg5: String, arg6: String) -> String in
            "resultWithName:" + arg1 + arg2 + arg3 + arg4 + arg5 + arg6
        }

        let result = resolver.resolve(String.self, arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6")!
        XCTAssert(result == "result:arg1arg2arg3arg4arg5arg6")

        let resultWithName = resolver.resolve(String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6")!
        XCTAssert(resultWithName == "resultWithName:arg1arg2arg3arg4arg5arg6")

        let result2 = try! resolver.resolve(type: String.self, arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6")
        XCTAssert(result2 == "result:arg1arg2arg3arg4arg5arg6")

        let resultWithName2 = try! resolver.resolve(assert: String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6")
        XCTAssert(resultWithName2 == "resultWithName:arg1arg2arg3arg4arg5arg6")
    }

    func test_container_with_arg_7() {

        container.register(String.self) { (_, arg1: String, arg2: String, arg3: String, arg4: String, arg5: String, arg6: String, arg7: String) -> String in
            "result:" + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7
        }

        container.register(String.self, name: "name") { (_, arg1: String, arg2: String, arg3: String, arg4: String, arg5: String, arg6: String, arg7: String) -> String in
            "resultWithName:" + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7
        }

        let result = resolver.resolve(String.self, arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7")!
        XCTAssert(result == "result:arg1arg2arg3arg4arg5arg6arg7")

        let resultWithName = resolver.resolve(String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7")!
        XCTAssert(resultWithName == "resultWithName:arg1arg2arg3arg4arg5arg6arg7")

        let result2 = try! resolver.resolve(type: String.self, arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7")
        XCTAssert(result2 == "result:arg1arg2arg3arg4arg5arg6arg7")

        let resultWithName2 = try! resolver.resolve(assert: String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7")
        XCTAssert(resultWithName2 == "resultWithName:arg1arg2arg3arg4arg5arg6arg7")
    }

    func test_container_with_arg_8() {

        container.register(String.self) { (_, arg1: String, arg2: String, arg3: String, arg4: String, arg5: String, arg6: String, arg7: String, arg8: String) -> String in
            "result:" + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8
        }

        container.register(String.self, name: "name") { (_, arg1: String, arg2: String, arg3: String, arg4: String, arg5: String, arg6: String, arg7: String, arg8: String) -> String in
            "resultWithName:" + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8
        }

        let result = resolver.resolve(String.self, arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8")!
        XCTAssert(result == "result:arg1arg2arg3arg4arg5arg6arg7arg8")

        let resultWithName = resolver.resolve(String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8")!
        XCTAssert(resultWithName == "resultWithName:arg1arg2arg3arg4arg5arg6arg7arg8")

        let result2 = try! resolver.resolve(type: String.self, arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8")
        XCTAssert(result2 == "result:arg1arg2arg3arg4arg5arg6arg7arg8")

        let resultWithName2 = try! resolver.resolve(assert: String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8")
        XCTAssert(resultWithName2 == "resultWithName:arg1arg2arg3arg4arg5arg6arg7arg8")
    }

    func test_container_with_arg_9() {

        container.register(String.self) { (_, arg1: String, arg2: String, arg3: String, arg4: String, arg5: String, arg6: String, arg7: String, arg8: String, arg9: String) -> String in
            "result:" + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8 + arg9
        }

        container.register(String.self, name: "name") { (_, arg1: String, arg2: String, arg3: String, arg4: String, arg5: String, arg6: String, arg7: String, arg8: String, arg9: String) -> String in
            "resultWithName:" + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8 + arg9
        }

        let result = resolver.resolve(String.self, arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8", "arg9")!
        XCTAssert(result == "result:arg1arg2arg3arg4arg5arg6arg7arg8arg9")

        let resultWithName = resolver.resolve(String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8", "arg9")!
        XCTAssert(resultWithName == "resultWithName:arg1arg2arg3arg4arg5arg6arg7arg8arg9")

        let result2 = try! resolver.resolve(type: String.self, arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8", "arg9")
        XCTAssert(result2 == "result:arg1arg2arg3arg4arg5arg6arg7arg8arg9")

        let resultWithName2 = try! resolver.resolve(assert: String.self, name: "name", arguments: "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8", "arg9")
        XCTAssert(resultWithName2 == "resultWithName:arg1arg2arg3arg4arg5arg6arg7arg8arg9")
    }

}
// swiftlint:enable identifier_name
