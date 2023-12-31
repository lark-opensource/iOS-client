//
//  URLSpec.swift
//  LarkExtensionsDevEEUnitTest
//
//  Created by qihongye on 2020/4/13.
//

import Foundation
import XCTest

@testable import LarkExtensions

class URLSpec: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIpv4Regex() {
        XCTAssertFalse(ipv4Regex!.matches("10.10.10.10").isEmpty)
        XCTAssertFalse(ipv4Regex!.matches("0.0.0.0").isEmpty)
        XCTAssertFalse(ipv4Regex!.matches("255.255.255.255").isEmpty)
        XCTAssertTrue(ipv4Regex!.matches("10.255.1").isEmpty)
        XCTAssertTrue(ipv4Regex!.matches("300.1.1.1").isEmpty)
        XCTAssertTrue(ipv4Regex!.matches("300.1.1.1").isEmpty)
        XCTAssertTrue(ipv4Regex!.matches("1.10.100.255.").isEmpty)
    }

    func testToHttpUrl() {
        if let input = URL(string: "http://www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "http://www.baidu.com")
        }
        if let input = URL(string: "https://www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "https://www.baidu.com")
        }
        if let input = URL(string: "//www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "http://www.baidu.com")
        }
        if let input = URL(string: "/www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "http://www.baidu.com")
        }
        if let input = URL(string: "://www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "http://www.baidu.com")
        }
        if let input = URL(string: "www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "http://www.baidu.com")
        }
        if let input = URL(string: "10.10.10.10:8080")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "http://10.10.10.10:8080")
        }
        if let input = URL(string: "longweiwei@bytedance.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "mailto:longweiwei@bytedance.com")
        }
        if let input = URL(string: "http://username@hostname.net")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "http://username@hostname.net")
        }
        if let input = URL(string: "mailto:longweiwei@bytedance.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "mailto:longweiwei@bytedance.com")
        }
        if let input = URL(string: "sslocal://www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "sslocal://www.baidu.com")
        }
        if let input = URL(string: "sslocal:www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "sslocal:www.baidu.com")
        }
        if let input = URL(string: "lark:www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "lark:www.baidu.com")
        }
        if let input = URL(string: "lark://www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "lark://www.baidu.com")
        }
        if let input = URL(string: "123jiasd4://www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "123jiasd4://www.baidu.com")
        }
        if let input = URL(string: "123jiasd4:www.baidu.com")?.lf.toHttpUrl() {
            XCTAssertEqual(input.absoluteString, "123jiasd4:www.baidu.com")
        }
    }
}
