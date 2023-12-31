//
//  EERouterTests.swift
//  EENavigatorDemoTests
//
//  Created by liuwanlin on 2018/9/10.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import EENavigator

class RouterResource: Resource {
    var content: Any {
        return self
    }

    var count: Int = 0

    var identifier: String?
}

struct TestBody: CodablePlainBody {
    static let pattern = "/test"

    var name: String = ""
    var age: Int = 1
}

class TestRouterHandler: TypedRouterHandler<TestBody> {
    var count: Int = 0

    override func handle(_ body: TestBody, req: Request, res: Response) {
        count += 1
        let resource = RouterResource()
        resource.count = count
        res.end(resource: resource)
    }
}

let larkScheme = "lark"

class EERouterHandlerTests: XCTestCase {
    let router = Router()

    override func setUp() {
        super.setUp()
        router.defaultSchemesBlock = { [larkScheme] }
    }

    // Router.normalize 接口，会把含有 lark 这种 scheme 前缀给抹掉
    func doTestRemoveScheme(scheme: String?, slash: String, hostPath: String) {
        var expected = slash + hostPath
        let url: URL
        if let scheme = scheme, !scheme.isEmpty {
            url = URL(string: scheme + ":" + slash + hostPath)!
            if scheme.lowercased() != larkScheme {
                expected = scheme + ":" + expected
            }
        } else {
            url = URL(string: slash + hostPath)!
        }
        let ouput = self.router.normalize(url).absoluteString
        XCTAssert(expected == ouput, "expeced: \(expected), output: \(ouput)")
    }

    func testNormalize() {
        let hostPath = "applink.feishu.cn/client/invite/memberSmart"
        for i in 1..<5 {
            let slash = String(repeating: "/", count: i)
            doTestRemoveScheme(scheme: nil, slash: slash, hostPath: hostPath)
            doTestRemoveScheme(scheme: "", slash: slash, hostPath: hostPath)
            doTestRemoveScheme(scheme: "lark", slash: slash, hostPath: hostPath)
            doTestRemoveScheme(scheme: "LARK", slash: slash, hostPath: hostPath)
        }
    }

    func testNotCacheHandler() {
        router.registerRoute(type: TestBody.self) {
            return TestRouterHandler()
        }
        var res = router.response(for: TestBody())
        XCTAssert((res.resource as? RouterResource)?.count == 1)

        res = router.response(for: TestBody())
        XCTAssert((res.resource as? RouterResource)?.count == 1)
    }

    func testCacheHandler() {
        router.registerRoute(type: TestBody.self, cacheHandler: true) {
            return TestRouterHandler()
        }
        var res = router.response(for: TestBody())
        XCTAssert((res.resource as? RouterResource)?.count == 1)

        res = router.response(for: TestBody())
        XCTAssert((res.resource as? RouterResource)?.count == 2)
    }
}

class EERouterTests: XCTestCase {

    let router = Router()

    override func setUp() {
        super.setUp()

        router.registerMiddleware { (_, res) in
            res.append(error: RouterError(code: 20000, message: "pre error"))
        }

        router.registerMiddleware { (req, _) in
            req.context["loggerMiddleware"] = true
        }

        router.registerMiddleware(regExpPattern: "^http\\://docs\\.bytedance\\.com/(.*)") { (req, res) in
            let matchedGroups = (req.context[ContextKeys.matchedGroups] as? [String?])
            let path = matchedGroups?[1] ?? ""
            let url = URL(string: "http://docs.bytedance.net/\(path)")!
            res.redirect(url)
        }

        router.registerRoute(regExpPattern: "^http(?:s)?\\://docs\\.bytedance\\.net/(.*)") { (_, res) in
            res.end(resource: RouterResource())
        }

        router.registerRoute(type: TestBody.self) { (_, _, res) in
            res.end(resource: RouterResource())
        }

        router.registerRoute(pattern: "Lark://chat/:chatId") { (_, res) in
            res.end(resource: RouterResource())
        }

        router.registerMiddleware(postRoute: true) { (req, res) in
            req.context["postMiddleware"] = true
            res.end(error: RouterError(code: 20001, message: "post error"))
        }

        // Test too many redirects
        router.registerRoute(plainPattern: "//redirect1") { (_, res) in
            res.redirect(URL(string: "//redirect2")!)
        }

        router.registerRoute(plainPattern: "//redirect2") { (_, res) in
            res.redirect(URL(string: "//redirect1")!)
        }
    }

    override func tearDown() {
        super.tearDown()

        router.deregisterMiddleware("")
        router.deregisterMiddleware("^http\\://docs\\.bytedance\\.com/(.*)")
        router.deregisterRoute(TestBody.patternConfig.pattern)
        router.deregisterRoute("Lark://chat/:chatId")
        router.deregisterRoute("^http(?:s)?\\://docs\\.bytedance\\.net/(.*)")
        router.deregisterRoute("//redirect1")
        router.deregisterRoute("//redirect2")
    }

    func testCanOpen() {
        var contains = router.contains(URL(string: "lark://chat/123")!)
        XCTAssert(contains)

        contains = router.contains(URL(string: "lark://chat")!)
        XCTAssert(!contains)

        contains = router.contains(URL(string: "http://baidu.com")!)
        XCTAssert(!contains)
    }

    func testSimpleRouter() {
        var url = "lark://chat/123"
        var response = router.response(for: URL(string: url)!)
        var request = response.request

        XCTAssert(
            request.parameters["chatId"] as? String == "123" &&
            (request.context["loggerMiddleware"] as? Bool) == true &&
            request.context["postMiddleware"] == nil &&
            response.resource?.identifier == url
        )

        url = "lark://chat/123?name=lark"
        response = router.response(for: URL(string: url)!)
        request = response.request
        XCTAssert(
            request.parameters["name"] as? String == "lark"
        )
    }

    func testNotMatchedRouter() {
        let url = "http://toutiao.com"
        let response = router.response(for: URL(string: url)!)
        let request = response.request

        XCTAssert(
            response.resource == nil &&
            (request.context["postMiddleware"] as? Bool) == true
        )
    }

    func testCustomRegExpRouter() {
        let url = "http://docs.bytedance.net/folder"
        let response = router.response(for: URL(string: url)!)
        let request = response.request

        let matchedGroup = (request.context[ContextKeys.matchedGroups] as? [String?]) ?? []
        XCTAssert(
            response.resource?.identifier == url &&
            matchedGroup.count == 2 &&
            matchedGroup[0] == url &&
            matchedGroup[1] == "folder"
        )
    }
    
    func testBlockMiddleWare() {
        let url = "http://docs.bytedance.net/folder"
        let response = router.response(for: URL(string: url)!)
        let request = response.request
        
    }

    func testRedirect() {
        let url = "http://docs.bytedance.com/folder/123"
        let newURL = "http://docs.bytedance.net/folder/123"
        let response = router.response(for: URL(string: url)!)

        XCTAssert(
            response.resource?.identifier == newURL
        )
    }

    func testError() {
        let response = router.response(for: URL(string: "none")!)
        XCTAssert(
            response.error?.stack.count == 2
        )
    }

    func testResource() {
        var response = router.response(for: URL(string: "Lark://chat/123?abc=hhh")!)
        XCTAssert(response.resource != nil && response.resource?.identifier == "lark://chat/123")

        response = router.response(for: URL(string: "none")!)
        XCTAssert(response.resource == nil)
    }

    func testRouteWithBody() {
        var body = TestBody()
        body.name = "lwl"
        body.age = 15

        let response = router.response(for: body._url, context: [String: Any](body: body))

        XCTAssert(response.resource != nil)
    }

    func testRouteParameters() {
        let response = router.response(for: URL(string: "\(TestBody.patternConfig.pattern)?name=lwl&age=15")!)
        XCTAssert(response.resource != nil)
    }

    func testRouteWithDict() {
        let context: [String: Any] = [
            "name": "lwl",
            "age": 15
        ]
        let response = router.response(for: URL(string: "/test")!, context: context)

        let body = response.request.body
        XCTAssert(response.resource != nil && body is TestBody)
    }

    func testTooManyRedirects() {
        let res = router.response(for: URL(string: "//redirect1")!)
        XCTAssert(
            res.resource == nil &&
            (res.error?.stack.last as? RouterError)?.code == RouterError.tooManyRedirects.code
        )
    }

    func testMiddleWarePriority() {
        Navigator.resetSharedNavigator()

        Navigator.shared.registerRoute(type: TestBody.self, priority: .low) { (_, _, res) in
            res.end(resource: RouterResource())
        }

        Navigator.shared.registerRoute(pattern: "Lark://chat/:chatId", priority: .high) { (_, res) in
            res.end(resource: RouterResource())
        }

        Navigator.shared.registerRoute(regExpPattern: "^http(?:s)?\\://docs\\.bytedance\\.net/(.*)", priority: .default) { (_, res) in
            res.end(resource: RouterResource())
        }

        let allRoutes = Navigator.shared.allRoutes()
        XCTAssertEqual(allRoutes.count, 3)
        XCTAssertEqual(allRoutes[0].pattern, "lark://chat/:chatId")
        XCTAssertEqual(allRoutes[1].pattern, "^http(?:s)?\\://docs\\.bytedance\\.net/(.*)")
        XCTAssertEqual(allRoutes[2].pattern, TestBody.pattern)
    }
}
