//
//  URLExtensionTests.swift
//  EENavigatorDemoTests
//
//  Created by liuwanlin on 2018/9/10.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import EENavigator

class URLExtensionTests: XCTestCase {

    func testSchemeAndHostLowercased() {
        var url = URL(string: "HTTP://TOUTIAO.com/ABC?Name=lwl")!
        var lowercased = url.schemeAndHostLowercased.absoluteString
        XCTAssert(lowercased == "http://toutiao.com/ABC?Name=lwl")

        url = URL(string: "/ABC?Name=lwl")!
        lowercased = url.schemeAndHostLowercased.absoluteString
        XCTAssert(lowercased == "/ABC?Name=lwl")

        url = URL(string: "Https://127.0.0.1:8080")!
        lowercased = url.schemeAndHostLowercased.absoluteString
        XCTAssert(lowercased == "https://127.0.0.1:8080")
    }

    func testQueryParameters() {
        var url = URL(string: "http://toutiao.com?name=abc&age=25")!
        var queryParameters = url.queryParameters
        XCTAssert(queryParameters["name"] == "abc" && queryParameters["age"] == "25")

        url = URL(string: "http://toutiao.com?name=a%20b%20c&age=25")!
        queryParameters = url.queryParameters
        XCTAssert(queryParameters["name"] == "a b c" && queryParameters["age"] == "25")
    }

    func testIdentifier() {
        // 1. Sort parameters
        var url = URL(string: "http://toutiao.com/test?name=abc&age=25")!
        var identifier = url.identifier
        XCTAssert(identifier == "http://toutiao.com/test")

        // 2. Didn't sort parameters
        url = URL(string: "http://toutiao.com/test?aaa=abc&age=25")!
        identifier = url.identifier
        XCTAssert(identifier == "http://toutiao.com/test")

        // 3. Path only without host and scheme
        url = URL(string: "/client/test?aaa=abc&age=25")!
        identifier = url.identifier
        XCTAssert(identifier == "/client/test")

        // 4. Host
        url = URL(string: "//host/client/test?aaa=abc&age=25")!
        identifier = url.identifier
        XCTAssert(identifier == "//host/client/test")
    }

    func testAppend() {
        var url = URL(string: "http://toutiao.com/test")!
        url = url.append(name: "test", value: "hhh")
        XCTAssert(
            url.queryParameters.count == 1 &&
            url.queryParameters["test"] == "hhh"
        )

        url = url.append(name: "test", value: "abc", forceNew: false)
        XCTAssert(
            url.queryParameters.count == 1 &&
            url.queryParameters["test"] == "hhh"
        )

        url = url.remove(name: "test")
        XCTAssert(
            url.queryParameters.count == 0 &&
            url.queryParameters["test"] == nil
        )

        url = url.append(parameters: ["age": "15", "name": "lwl"])
        XCTAssert(
            url.queryParameters.count == 2 &&
            url.queryParameters["age"] == "15" &&
            url.queryParameters["name"] == "lwl"
        )
    }

    func testFragment() {
        var url = URL(string: "http://toutiao.com/test?name=abc&age=25")!
        url = url.append(fragment: "abc")
        XCTAssert(url.fragment == "abc")

        url = url.append(fragment: "bcd", forceNew: false)
        XCTAssert(url.fragment == "abc")

        url = url.append(name: "test", value: "liu")
        XCTAssert(
            url.fragment == "abc" &&
            url.queryParameters.count == 3 &&
            url.absoluteString == "http://toutiao.com/test?name=abc&age=25&test=liu#abc"
        )
    }
    
    func testRemoveQuery() {
        var url = URL(string: "http://toutiao.com/test?name=abc&age=25")!
        url = url.remove(name: "name")
        XCTAssert(url.absoluteString == "http://toutiao.com/test?age=25")
    }
    
    func testRemoveQueries() {
        var url = URL(string: "http://toutiao.com/test?name=abc&age=25")!
        url = url.remove(names: ["name", "age"])
        XCTAssert(url.absoluteString == "http://toutiao.com/test?")
    }
    
    func testRemoveFragment() {
        var url = URL(string: "http://toutiao.com/test?name=abc&age=25#123")!
        url = url.removeFragment()
        XCTAssert(url.absoluteString == "http://toutiao.com/test?name=abc&age=25")
    }

}
