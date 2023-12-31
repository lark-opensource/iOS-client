//
//  Middleware.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/6.
//

import Foundation

public typealias Handler = (Request, Response) -> Void
public typealias Tester = (Request) -> Bool
public typealias OpenTypeHandler = (_ url: URL, _ context: [String: Any]) -> OpenType?

public let defaultTester: Tester = { _ in true }

struct Middleware {
    static var blockMatcherCount = 0

    let pattern: String
    let handler: Handler
    // 路由有使用这个做是否match的过滤，middleware没有开放这个配置项，没有使用
    let tester: Tester
    let matcher: URLMatcher

    init(pattern: String, handler: @escaping Handler, tester: @escaping Tester, matcher: URLMatcher) {
        self.pattern = pattern
        self.handler = handler
        self.tester = tester
        self.matcher = matcher
    }

    /// Path Pattern matcher
    init(
        pattern: String,
        tester: @escaping Tester = defaultTester,
        handler: @escaping Handler,
        options: Options = .default) {
        self.pattern = pattern
        self.handler = handler
        self.tester = tester
        self.matcher = PathPatternURLMatcher(pattern: pattern, options: options)
    }

    /// Plain URL matcher
    init(
        plain: String,
        tester: @escaping Tester = defaultTester,
        handler: @escaping Handler) {
        self.pattern = plain
        self.handler = handler
        self.tester = tester
        self.matcher = PlainURLMatcher(pattern: plain)
    }

    // Custom regular expression matcher
    init(
        regExpPattern: String,
        tester: @escaping Tester = defaultTester,
        handler: @escaping Handler) {
        self.pattern = regExpPattern
        self.handler = handler
        self.tester = tester
        self.matcher = RegExpURLMatcher(regExpPattern: regExpPattern)
    }

    /// Block matcher
    init(
        match: @escaping MatchBlock,
        tester: @escaping Tester = defaultTester,
        handler: @escaping Handler) {

        Middleware.blockMatcherCount += 1

        self.pattern = "_block_\(Middleware.blockMatcherCount)"
        self.handler = handler
        self.tester = tester
        self.matcher = BlockURLMatcher(matchBlock: match)
    }
}
