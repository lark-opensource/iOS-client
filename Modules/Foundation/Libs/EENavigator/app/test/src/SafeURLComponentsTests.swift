//
//  SafeURLComponentsTests.swift
//  EENavigatorDevEEUnitTest
//
//  Created by 7Up on 2022/6/9.
//

import Foundation
import XCTest
@testable import EENavigator

class SafeURLComponentsTests: XCTestCase {

    func makeUrl(scheme: String?, slash: String, hostPath: String) -> URL {
        var str = slash + hostPath
        if let scheme = scheme, !scheme.isEmpty {
            str = scheme + ":" + str
        }
        return URL(string: str)!
    }

    func makeComponents(from url: URL) -> SafeURLComponents {
        return SafeURLComponents(url: url, resolvingAgainstBaseURL: false)!
    }

    func testSafeURLComponents() {
        let hostPath = "client/feed/home"
        // 无 scheme
        let withoutScheme = { (slash: String) in
            let input = self.makeUrl(scheme: nil, slash: slash, hostPath: hostPath)
            let output = SafeURLComponents(url: input, resolvingAgainstBaseURL: false)!.url!
            XCTAssert(
                input.absoluteString == output.absoluteString,
                "input: \(input.absoluteString), output: \(output.absoluteString)"
            )
        }
        // 有 scheme
        let withScheme = { (scheme: String, slash: String) in
            let input = self.makeUrl(scheme: scheme, slash: slash, hostPath: hostPath)
            let output = SafeURLComponents(url: input, resolvingAgainstBaseURL: false)!.url!
            XCTAssert(
                input.absoluteString == output.absoluteString,
                "input: \(input.absoluteString), output: \(output.absoluteString)"
            )
        }
        // 有 scheme -> 无 scheme
        let delScheme = { (scheme: String, slash: String) in
            let input = self.makeUrl(scheme: scheme, slash: slash, hostPath: hostPath)
            var components = SafeURLComponents(url: input, resolvingAgainstBaseURL: false)!
            components.scheme = nil
            let output = components.url!
            XCTAssert(
                slash + hostPath == output.absoluteString,
                "input: \(input.absoluteString), output: \(output.absoluteString)"
            )
        }
        // 无 scheme -> 有 scheme
        let addScheme = { (scheme: String, slash: String) in
            let input = self.makeUrl(scheme: nil, slash: slash, hostPath: hostPath)
            var components = SafeURLComponents(url: input, resolvingAgainstBaseURL: false)!
            components.scheme = scheme
            let output = components.url!
            XCTAssert(
                scheme + ":" + slash + hostPath == output.absoluteString,
                "input: \(input.absoluteString), output: \(output.absoluteString)"
            )
        }
        for i in 0..<5 {
            let slash = String(repeating: "/", count: i)
            withoutScheme(slash)
            withScheme("lark", slash)
            delScheme("lark", slash)
            addScheme("lark", slash)
        }
    }

}
