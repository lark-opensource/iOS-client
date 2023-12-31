//
//  WorkspaceCrossRouterTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/9/7.
//

import XCTest
import SKFoundation
@testable import SKCommon
import SpaceInterface

class MockPhoenixRouteConfig: PhoenixRouteConfigType {
    var pathPrefix: String = "workspace"

    var parseResult: (Bool, DocsType, String) = (true, .docX, "doxcn123456789")
    func parse(url: URL) -> (Bool, DocsType, String) {
        parseResult
    }

    var phoenixPath: String = "/workspace/docx/doxcn123456789"
    func getPhoenixPath(type: DocsType, token: String, originURL: URL) -> String {
        phoenixPath
    }
}

class WorkspaceCrossRouterTests: XCTestCase {
    typealias Router = WorkspaceCrossRouter
    typealias Config = MockPhoenixRouteConfig
    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testPhoenixRedirect() {
        let inputURL = URL(string: "https://www.feishu.cn/docx/doxcn123456789")!
        let result = Router.redirectPhoenixURL(spaceURL: inputURL, config: Config())
        let expect = URL(string: "https://www.feishu.cn/workspace/docx/doxcn123456789")!
        XCTAssertEqual(result, expect)
    }

    func testPhoenixRedirectException() {
        let config = Config()

        config.pathPrefix = "phoenix"
        config.parseResult = (false, .unknown(999), "")
        var inputURL = URL(string: "https://www.feishu.cn/demo")!
        var result = Router.redirectPhoenixURL(spaceURL: inputURL, config: config)
        var expect = URL(string: "https://www.feishu.cn/phoenix/demo")!
        XCTAssertEqual(result, expect)

        inputURL = URL(string: "https://www.feishu.cn/phoenix/demo")!
        result = Router.redirectPhoenixURL(spaceURL: inputURL, config: config)
        expect = URL(string: "https://www.feishu.cn/phoenix/demo")!
        XCTAssertEqual(result, expect)

        config.parseResult = (true, .unknown(999), "")
        result = Router.redirectPhoenixURL(spaceURL: inputURL, config: config)
        XCTAssertEqual(result, expect)

        config.parseResult = (true, .docX, "")
        result = Router.redirectPhoenixURL(spaceURL: inputURL, config: config)
        XCTAssertEqual(result, expect)

        config.parseResult = (true, .docX, "doxcn123456789")
        result = Router.redirectPhoenixURL(spaceURL: inputURL, config: config)
        expect = URL(string: "https://www.feishu.cn/workspace/docx/doxcn123456789")!
        XCTAssertEqual(result, expect)
    }
}
