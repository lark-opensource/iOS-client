//
//  RegisterBuilderTest.swift
//  EENavigatorDevEEUnitTest
//
//  Created by SolaWing on 2022/9/4.
//

import Foundation
import XCTest
@testable import EENavigator

// swiftlint:disable all
class RegisterBuilderTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRouteRegister() throws {
        // This is an example of a performance test case.
        self.measure {
            let route = Navigator.resetSharedNavigator().registerRoute
            route.plain("builderabc").priority(.high).handle { (_, res) in
                res.end(resource: StringResource.init(string: "abc"))
            }
            route.type(TestPathBody.self).tester({ _ in true }).handle { Test().handle(req: $0, res: $1) }
            route.match({ $0.absoluteString.hasPrefix("zzz") }).handle({ $1.end(resource: StringResource(string: "zzz")) })
            route.type(TestBody.self).handle { (body, req, res) in
                res.end(resource: StringResource(string: body.no.description))
            }
            route.type(TestBody2.self).handle{ TestBodyHandler().handle($0, req: $1, res: $2) }
        }
        XCTAssertEqual(Navigator.shared.response(for: URL(string: "builderabc")!).resource as? StringResource,
                       StringResource(identifier: "builderabc", string: "abc"))
        XCTAssertEqual(Navigator.shared.response(for: URL(string: "//aaa/123")!).resource as? StringResource,
                       StringResource(identifier: "//aaa/123", string: "123"))
        XCTAssertEqual(Navigator.shared.response(for: URL(string: "zzz123")!).resource as? StringResource,
                       StringResource(identifier: "zzz123", string: "zzz"))
        
        XCTAssertEqual(Navigator.shared.response(for: TestBody(no: 123)).resource as? StringResource,
                       StringResource(identifier: "//bbb123", string: "123"))
        XCTAssertEqual(Navigator.shared.response(for: TestBody2(no: 123)).resource as? StringResource,
                       StringResource(identifier: "//ccc123", string: "123"))
    }
    class Test: RouterHandler {
        func handle(req: Request, res: Response) {
            do {
                let body: TestPathBody = try req.getBody()
                res.end(resource: StringResource(string: body.no.description))
            } catch {
                res.end(error: error)
            }
        }
    }
    struct StringResource: Resource, Equatable {
        var identifier: String? {
            didSet {

            }
        }
        var string: String
    }
    struct TestPathBody: Body, Codable {
        static var patternConfig: PatternConfig { .init(pattern: "//aaa/:no", type: .path) }

        var no: Int // URL转body要精确匹配?
        var _url: URL { .init(string: "//aaa\(no)")! }
    }
    struct TestBody: Body {
        static var patternConfig: PatternConfig { .init(pattern: "//bbb\\d+", type: .regex) }

        var no: Int
        var _url: URL { .init(string: "//bbb\(no)")! }
    }
    struct TestBody2: Body {
        static var patternConfig: PatternConfig { .init(pattern: "//ccc\\d+", type: .regex) }

        var no: Int
        var _url: URL { .init(string: "//ccc\(no)")! } // swiftlint:disable:this all
    }
    class TestBodyHandler: TypedRouterHandler<TestBody2> {
        override func handle(_ body: RegisterBuilderTest.TestBody2, req: Request, res: Response) {
            res.end(resource: StringResource(string: body.no.description))
        }
    }
}
