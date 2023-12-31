//
//  URLMatcherTests.swift
//  EENavigatorDemoTests
//
//  Created by liuwanlin on 2018/9/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import EENavigator

class URLMatcherTests: XCTestCase {

    // MARK: String extensions tests
    func testStringParse() {
        // 1. simple pattern
        let simplePattern = "http://toutiao.com"
        var tokens = simplePattern.parse()
        XCTAssert(tokens.count == 1)
        XCTAssert(tokens[0] == Token.simple(token: simplePattern))

        // 2. pattern with param
        let patternWithParam = "http://toutiao.com/test/:id"
        tokens = patternWithParam.parse()
        XCTAssert(tokens.count == 2)
        XCTAssert(tokens[0] == Token.simple(token: "http://toutiao.com/test"))
        XCTAssert(tokens[1] == Token.complex(
            tokenId: .literal(name: "id"), prefix: "/", delimeter: "/",
            optional: false, repeating: false, pattern: "[^\\/]+?"
        ))

        // 3. star
        let starPattern = "http://*"
        tokens = starPattern.parse()
        XCTAssert(tokens.count == 2)
        XCTAssert(tokens[1] == .complex(
            tokenId: .ordinal(index: 0), prefix: "/", delimeter: "/",
            optional: false, repeating: false, pattern: ".*"
        ))
    }

    func testEscape() {
        let escaped = "abc*".escaped()
        XCTAssert(escaped == "abc\\*")
    }

    func testEscapeGroup() {
        let escaped = "(abc)".escapeGroup()
        XCTAssert(escaped == "\\(abc\\)")
    }

    func testTokensToRegExp() {
        let options: Options = []
        // 1. Star
        var pattern = "*"
        var (regex, keys) = tokensToRegExp(tokens: pattern.parse(), options: options)
        XCTAssert(regex?.pattern == "^(.*)(?:/(?=$))?(?=/|$)" && keys.isEmpty)

        // 2. Simple
        pattern = "http://docs.bytecance.com"
        (regex, keys) = tokensToRegExp(tokens: pattern.parse(), options: options)
        XCTAssert(regex?.pattern == "^http\\:\\/\\/docs\\.bytecance\\.com(?:/(?=$))?(?=/|$)" && keys.isEmpty)

        // 3. Pattern with params
        pattern = "http://docs.bytecance.com/doc/:id"
        (regex, keys) = tokensToRegExp(tokens: pattern.parse(), options: options)
        XCTAssert(
            regex?.pattern == "^http\\:\\/\\/docs\\.bytecance\\.com\\/doc\\/([^\\/]+?)(?:/(?=$))?(?=/|$)" &&
            keys.count == 1 && keys[0] == "id"
        )
    }

    // MARK: URLMatcher tests
    func testDefaultURLMatcher() {
        // 1. Star
        var matcher = PathPatternURLMatcher(pattern: "*", options: [])
        var url = "http://baidu.com"
        var result = matcher.match(url: URL(string: url)!)
        XCTAssert(result.matched && result.params.isEmpty && result.url == url)

        // 2. Simple
        matcher = PathPatternURLMatcher(pattern: "lark://client/web", options: [])
        result = matcher.match(url: URL(string: "lark://client/web?url=baidu.com")!)
        XCTAssert(
            result.matched && result.params.isEmpty &&
            result.url == "lark://client/web"
        )

        result = matcher.match(url: URL(string: "lark://client/web/abc")!)
        XCTAssert(result.matched)

        // 3. With params
        matcher = PathPatternURLMatcher(pattern: "lark://client/chat/:id/:pos")
        url = "lark://client/chat/123/abc"
        result = matcher.match(url: URL(string: url)!)
        XCTAssert(
            result.matched && result.url == url && result.params.count == 2 &&
            result.params["id"] == "123" && result.params["pos"] == "abc"
        )

        url = "lark://client/chat/123/abc?name=lwl"
        result = matcher.match(url: URL(string: url)!)
        XCTAssert(result.matched && result.url == "lark://client/chat/123/abc")

        url = "lark://client/chat/123"
        result = matcher.match(url: URL(string: url)!)
        XCTAssert(!result.matched)

        // 4. Optional params
        matcher = PathPatternURLMatcher(pattern: "lark://client/chat/:id/:pos?")
        url = "lark://client/chat/123"
        result = matcher.match(url: URL(string: url)!)
        XCTAssert(
            result.matched && result.url == url &&
            result.params.count == 1
        )

        url = "lark://client/chat/123"
        result = matcher.match(url: URL(string: url)!)
        XCTAssert(result.matched && result.url == url)
    }

    func testCustomURLMatcher() {
        // 1. Simple prefix
        var matcher = RegExpURLMatcher(regExpPattern: "^http(s)?\\://.+")

        var url = "http://toutiao.com"
        var result = matcher.match(url: URL(string: url)!)
        XCTAssert(result.matched && result.url == url)

        url = "https://toutiao.com/abc"
        result = matcher.match(url: URL(string: url)!)
        XCTAssert(result.matched && result.url == url)

        // 2. Prefix with certain host
        matcher = RegExpURLMatcher(regExpPattern: "^http(s)?\\://docs\\.bytedance\\.net/.*")

        url = "https://docs.bytedance.net/abc"
        result = matcher.match(url: URL(string: url)!)
        XCTAssert(result.matched && result.url == url)

        url = "http://test.bytedance.net/abc"
        result = matcher.match(url: URL(string: url)!)
        XCTAssert(!result.matched)
    }
    
    func testBlockMatcher() {
        let urlString = "http://toutiao.com"
        let matcher = BlockURLMatcher { url in
            return url.absoluteString == urlString
        }
        let result = matcher.match(url: URL(string: urlString)!)
        XCTAssert(result.matched)
    }

    // MARK: URL extensions tests
    func testWithoutQueryAndFragment() {
        // 1. Simple
        var url = URL(string: "http://bytedance.com/user?name=123&age=18")!
        XCTAssert(url.withoutQueryAndFragment == "http://bytedance.com/user")

        // 2. Path ends with slash
        url = URL(string: "http://bytedance.com/user/?name=123&age=18")!
        XCTAssert(url.withoutQueryAndFragment == "http://bytedance.com/user/")

        // 3. With fragment
        url = URL(string: "http://bytedance.com/user/?name=123&age=18#fragment")!
        XCTAssert(url.withoutQueryAndFragment == "http://bytedance.com/user/")

        url = URL(string: "http://bytedance.com/user/#fragment?name=123&age=18")!
        XCTAssert(url.withoutQueryAndFragment == "http://bytedance.com/user/")
    }

    func testRegMatcherPerformance() {
        self.measure {
            for _ in 0...10000 {
                let _ = RegExpURLMatcher(regExpPattern: "^https?:\\/\\/(drive-test|drive)\\.bytedance.net(\\/p\\/[^?]+)(\\?.*)*")
                let _ = RegExpURLMatcher(regExpPattern: "^http(s)?\\://itunes\\.apple\\.com")
                let _ = RegExpURLMatcher(regExpPattern: "^http(s)?\\://")
                let _ = RegExpURLMatcher(regExpPattern: "^(mailto:|)[+a-zA-Z0-9_.!#$%&'*\\/=?^`{|}~-]+@([a-zA-Z0-9-]+\\.)+[a-zA-Z0-9]{2,63}$")
            }
        }
    }

    func testRegMatcherImmediatePerformance() {
        self.measure {
            for _ in 0...10000 {
                let _ = RegExpURLMatcher(regExpPattern: "^https?:\\/\\/(drive-test|drive)\\.bytedance.net(\\/p\\/[^?]+)(\\?.*)*", immediate: true)
                let _ = RegExpURLMatcher(regExpPattern: "^http(s)?\\://itunes\\.apple\\.com", immediate: true)
                let _ = RegExpURLMatcher(regExpPattern: "^http(s)?\\://", immediate: true)
                let _ = RegExpURLMatcher(regExpPattern: "^(mailto:|)[+a-zA-Z0-9_.!#$%&'*\\/=?^`{|}~-]+@([a-zA-Z0-9-]+\\.)+[a-zA-Z0-9]{2,63}$", immediate: true)
            }
        }
    }

    func testPathMatcherPerformance() {
        self.measure {
            for _ in 0...10000 {
                let _ = PathPatternURLMatcher(pattern: "//chat/:id")
                let _ = PathPatternURLMatcher(pattern: "//chat/info")
            }
        }
    }

    func testPathMatcherImmediatePerformance() {
        self.measure {
            for _ in 0...10000 {
                let _ = PathPatternURLMatcher(pattern: "//chat/:id", immediate: true)
                let _ = PathPatternURLMatcher(pattern: "//chat/info", immediate: true)
            }
        }
    }

    func testSimplePathMatcherPerformance() {
        self.measure {
            for _ in 0...10000 {
                let _ = PathPatternURLMatcher(pattern: "//chat/info/test")
                let _ = PathPatternURLMatcher(pattern: "//chat/info")
            }
        }
    }

    func testSimplePathMatcherImmediatePerformance() {
        self.measure {
            for _ in 0...10000 {
                let _ = PathPatternURLMatcher(pattern: "//chat/info/test", immediate: true)
                let _ = PathPatternURLMatcher(pattern: "//chat/info", immediate: true)
            }
        }
    }
}
