//
//  HelperTests.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2018/12/12.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import XCTest
@testable import LarkRustClient
@testable import LarkRustHTTP
@testable import HTTProtocol

// swiftlint:disable line_length
class HelperTests: XCTestCase {

    func testCanonicalizeRequest() {
        func genCanonicalRequest(url: String) -> URLRequest {
            var req = URLRequest(url: URL(string: url)!)
            req.mainDocumentURL = req.url
            req.allHTTPHeaderFields = [
                "Accept": "*/*",
                // 系统默认是br, gzip, deflate, 但RustHTTP只支持gzip, 所以标准化为gzip
                "Accept-Encoding": "gzip",
                "Accept-Language": Locale.preferredLanguages.first ?? "en-us"
            ]
            return req
        }

        let httpCanonicalRequest = genCanonicalRequest(url: "http://localhost/")
        let httpsCanonicalRequest = genCanonicalRequest(url: "https://localhost/")
        let canonicalRequestWithEscape = genCanonicalRequest(url: "https://localhost/%E8%B7%AF%E5%BE%84;v=2?%E6%9F%A5%E8%AF%A2=value#ref")
        let canonicalRequestFullComponents = genCanonicalRequest(url: "https://user:password@localhost/path/to/resource;v=1?query=value#ref")

        var lastReq: URLRequest!
        func canonical(url: String) -> URLRequest {
            var request = URLRequest(url: URL(string: url)!)
            request.mainDocumentURL = request.url
//             let cls: AnyObject! = NSClassFromString("_NSURLHTTPProtocol")
//             lastReq = cls.perform(NSSelectorFromString("canonicalRequestForRequest:"), with: request)
//                 .takeUnretainedValue() as? URLRequest // swiftlint:disable:this all
            lastReq = request.canonicalHTTPRequest()
            return lastReq
        }

        func XCTAssertRequestEqual(_ a: URLRequest, _ b: URLRequest, file: StaticString = #file, line: UInt = #line) { // swiftlint:disable:this all
            // bug? XCTAssertEqual fail, but after po, == is true!
            // XCTAssertEqual(a, b, line: line)
            XCTAssertEqual(a.url, b.url, "URL", line: line)
            XCTAssertEqual(a.mainDocumentURL, b.mainDocumentURL, "mainDocumentURL", line: line)
            XCTAssertEqual(a.allHTTPHeaderFields, b.allHTTPHeaderFields)
        }
        func XCTAssertRequestNotEqual(_ a: URLRequest, _ b : URLRequest, file: StaticString = #file, line: UInt = #line) { // swiftlint:disable:this all
//            XCTAssertNotEqual(a, b, "", line: line)
            XCTAssert(a.url != b.url || a.allHTTPHeaderFields != b.allHTTPHeaderFields, "", line: line)
        }

        // scheme should be lower case
        XCTAssertRequestEqual(canonical(url: "HTTP://localhost/"), httpCanonicalRequest)
        // host should be lower case
        XCTAssertRequestEqual(canonical(url: "HTTP://LocalHOST/"), httpCanonicalRequest)
        // empty path should be /
        XCTAssertRequestEqual(canonical(url: "HTTP://LocalHOST"), httpCanonicalRequest)
        XCTAssertRequestEqual(canonical(url: "HTTP://LocalHOST?k=v"), genCanonicalRequest(url: "http://localhost/?k=v"))
        XCTAssertRequestEqual(canonical(url: "HTTP://LocalHOST#k=v"), genCanonicalRequest(url: "http://localhost/#k=v"))
        // default port should be avoided
        XCTAssertRequestEqual(canonical(url: "HTTP://LocalHOST:"), httpCanonicalRequest)
        XCTAssertRequestEqual(canonical(url: "HTTP://LocalHOST:80"), httpCanonicalRequest)
        XCTAssertRequestEqual(canonical(url: "HTTPS://LocalHOST:443"), httpsCanonicalRequest)
        XCTAssertRequestNotEqual(canonical(url: "HTTP://LocalHOST:443"), httpCanonicalRequest)
        XCTAssertRequestNotEqual(canonical(url: "HTTPS://LocalHOST:80"), httpsCanonicalRequest)
        // empty host should be localhost
        XCTAssertRequestEqual(canonical(url: "HTTP:///"), httpCanonicalRequest)
        XCTAssertRequestEqual(canonical(url: "HTTP://"), httpCanonicalRequest)
        XCTAssertRequestEqual(canonical(url: "HTTP:/"), httpCanonicalRequest)
        XCTAssertRequestEqual(canonical(url: "HTTP:"), httpCanonicalRequest)

        // TODO: 以下情况不是那么常见，Apple实现也没支持。暂时不支持
        /*
        // relative path should convert to absolute
        XCTAssertRequestEqual(canonicalHTTPRequest(url: "hTtPs://user:password@loCAlhost/path/to/../../path/./to/resource;v=1?query=value#ref"),
                       canonicalRequestFullComponents)
        // lowercase escaping should convert to uppercase
        XCTAssertRequestEqual(canonicalHTTPRequest(url: "https://localhost/%e8%B7%af%E5%BE%84;v=2?%e6%9f%A5%E8%AF%A2=value#ref"),
                       canonicalRequestWithEscape)
        // unneeded escaping should be remove
        XCTAssertRequestEqual(canonicalHTTPRequest(url: "https://localhost/%e8%B7%af%E5%BE%84;v=2?%e6%9f%A5%E8%AF%A2=%76alue#ref"),
                       canonicalRequestWithEscape)
        */
    }
    func testExtractAuthenticate() {
        typealias Auth = (scheme: String, [String: String])
        func XCAssertAuthEqual(_ a: [Auth], _ b: [Auth]) { // swiftlint:disable:this all
            XCTAssertEqual(a.count, b.count, "\(a) with \(b)")
            for i in 0..<a.count {
                XCTAssert(a[i] == b[i], "\(i) element \(a) should equal to \(b)")
            }
        }
        XCAssertAuthEqual(HTTProtocol.extract(authenticate: "Basic Realm=\"Rust\""),
                          [(scheme: "basic", ["realm": "Rust"])])
        // wrong header without comma between k-v
        XCAssertAuthEqual(HTTProtocol.extract(authenticate: "Basic Realm=\"Rust\\\"HTTP - UTF-8\" special=\"!@#$%^&*()_+-=[]{}ÛÝ;:''\""),
                          [(scheme: "basic", ["realm": "Rust\\\"HTTP - UTF-8"])])
        XCAssertAuthEqual(HTTProtocol.extract(authenticate: "Basic, AAA, BBB"),
                          [(scheme: "basic", [:]), ("aaa", [:]), ("bbb", [:])])
        XCAssertAuthEqual(HTTProtocol.extract(authenticate: "Basic Realm=\"Rust\\\"HTTP - UTF-8\", special=\"!@#$%^&*()_+-=[]{}ÛÝ;:''\""),
                          [(scheme: "basic", ["realm": "Rust\\\"HTTP - UTF-8", "special": "!@#$%^&*()_+-=[]{}ÛÝ;:''"])])
        // multiple comma are ignored
        XCAssertAuthEqual(HTTProtocol.extract(authenticate: "Basic Realm=AAA,a=b, AAA A=b,, ,BBB"),
                          [(scheme: "basic", ["realm": "AAA", "a": "b"]), ("aaa", ["a": "b"]), ("bbb", [:])])
    }
    func testDateFromGMT() {
        XCTAssertEqual( Date(GMT: "Tue, 18 Dec 2018 13:42:57 GMT"), Date(timeIntervalSince1970: 1_545_140_577))
        // 时间格式应该是大小写无关的, 除了GMT时区
        XCTAssertEqual( Date(GMT: "TUE, 18 DEC 2018 13:42:57 GMT"), Date(timeIntervalSince1970: 1_545_140_577))
        XCTAssertEqual( Date(GMT: "tue, 18 dec 2018 13:42:57 GMT"), Date(timeIntervalSince1970: 1_545_140_577))
    }
    func testDateToGMT() {
        XCTAssertEqual( Date(timeIntervalSince1970: 1_545_140_577).toGMT(), "Tue, 18 Dec 2018 13:42:57 GMT" )
    }
    func testRedirectLocation() {
        // [Location规范](https://tools.ietf.org/html/rfc7231#section-7.1.2)

        let base = URL(string: "http://localhost:8091/cache/code/301")!
        // apple会escape中文, 且按utf8 escape，但没有escape `%=&?`等特殊符号, fragment被丢弃, 和标准不一致。
        let locationQuery = "AAA=BBB&CCC=DDD&中=国\"\"&%E4%B8%AD=%E5%9B%BD"
        let resolveQuery = "AAA=BBB&CCC=DDD&%E4%B8%AD=%E5%9B%BD%22%22&%E4%B8%AD=%E5%9B%BD"
        // 绝对路径
        XCTAssertEqual(base.redirect(to: "http://localhost:8091/cache/code/get?\(locationQuery)#EEE")?.absoluteString,
                       "http://localhost:8091/cache/code/get?\(resolveQuery)#EEE")
        // Root Relative
        XCTAssertEqual(base.redirect(to: "/cache/code/get?\(locationQuery)#EEE")?.absoluteString,
                       "http://localhost:8091/cache/code/get?\(resolveQuery)#EEE")
        // 相对路径
        XCTAssertEqual(base.redirect(to: "get?\(locationQuery)#EEE")?.absoluteString,
                       "http://localhost:8091/cache/code/get?\(resolveQuery)#EEE")
        XCTAssertEqual(base.redirect(to: "./get?\(locationQuery)#EEE")?.absoluteString,
                       "http://localhost:8091/cache/code/get?\(resolveQuery)#EEE")
        XCTAssertEqual(base.redirect(to: "../get?\(locationQuery)#EEE")?.absoluteString,
                       "http://localhost:8091/cache/get?\(resolveQuery)#EEE")
        XCTAssertEqual(base.redirect(to: "../../get?\(locationQuery)#EEE")?.absoluteString,
                       "http://localhost:8091/get?\(resolveQuery)#EEE")

        // 按照规范，如果Location没有fragment, 需要把原来的fragment加上
        XCTAssertEqual(URL(string: "http://localhost/cache/code/301#EEE")?.redirect(to: "get")?.absoluteString,
                       "http://localhost/cache/code/get#EEE")
    }
    func testURLRequestHeaderShouldCaseInsensitive() {
        var request = URLRequest(url: URL(string: "http://localhost/")!)
        request.allHTTPHeaderFields = ["cache-control": "no-store"]
        XCTAssertEqual(request.value(forHTTPHeaderField: "Cache-Control"), "no-store")
        XCTAssertEqual(request.value(forHTTPHeaderField: "cache-control"), "no-store")
        XCTAssertEqual(request.value(forHTTPHeaderField: "CACHE-CONTROL"), "no-store")
    }

    func xtestGetProxy() {
        print(RustHttpManager.systemProxyURL as Any)
    }
}
