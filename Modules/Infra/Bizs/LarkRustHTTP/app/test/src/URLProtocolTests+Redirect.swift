//
//  URLProtocolTests+Redirect.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2018/12/21.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import XCTest
import Swifter
import LarkRustHTTP

extension URLProtocolTests {
    func testRedirectCodeAndMethod() {
        // https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
        // 通常情况, 除了303, 都应该保留body和method.
        // 但目前301，302的实现有分歧，有些变成了GET，有些没变, 属于不确定行为。
        for _ in 0..<1 {
            // 不测试并发了，会超时，影响稳定性。感觉rust处理不过来.. -- 同时测试大量并发时行为也应该正常
            codes([301, 302, 307, 308], shouldKeep: "GET")
            codes([301, 302, 307, 308], shouldKeep: "HEAD")
            codes([307, 308], shouldKeep: "POST", body: "hello".data(using: .utf8)!)
            codes([307, 308], shouldKeep: "PUT", body: "hello".data(using: .utf8)!)
            codes([307, 308], shouldKeep: "PATCH", body: "hello".data(using: .utf8)!)
            codes([307, 308], shouldKeep: "DELETE", body: "hello".data(using: .utf8)!)
            if Self.useRustNetwork {
                code([302, 303], shouldChangeMethodsToGet: ["GET", "POST", "PUT", "PATCH", "DELETE"])
                codes([303], shouldKeep: "HEAD")
            } else {
                code([302], shouldChangeMethodsToGet: ["POST"])
                code([303], shouldChangeMethodsToGet: ["GET", "POST", "PUT", "PATCH", "DELETE"])
            }
//            code([303], shouldChangeMethodsToGet: ["GET", "POST"])
        }

        waitTasks()
    }
    private func codes(_ codes: [Int], shouldKeep method: String, body: Data? = nil) {
        let returnPathType = ["absolute", "relative", "root_relative"]
        codes.forEach { (code) -> Void in
            let ident = nextID()
            httpRequest(
                path: "/redirect/receive?m=\(method)&c=\(code)&id=\(ident)", method: method,
                headers: [
                    "Cache-Control": "no-store",
                    "code": code.description,
                    "type": returnPathType.randomElement()!,
                    "i": "id \(ident)"],
                body: body,
                // FIXME: 经测试，bodyStream在重定向时会无响应直到timeout. 包括系统实现的. 暂时不管他
                // TODO: 测试needNewBodyStream delegate对这种情况的支持。
                // bodyStream: InputStream(data: body ?? Data()),
                completeHandler: { (data, response, error) -> Void in
                    XCTAssertNil(error)
                    XCTAssertTrue(response?.url?.absoluteString.hasSuffix("/redirect/receive") == false)
                    XCTAssertEqual(response?.statusCode, 200, "\((code, method, ident))")
                    XCTAssertEqual(response?.allHeaderFields["method"] as? String, method, "\((code, method, ident))")
                    switch method {
                    case "GET": XCTAssertEqual(data, "no body".data(using: .utf8))
                    case "HEAD": XCTAssert( data == nil || data!.isEmpty )
                    case "POST", "PUT", "PATCH", "DELETE": XCTAssertEqual(data, body ?? "no body".data(using: .utf8))
                    default: break
                    }
            }).resume()
        }
    }
    // https://tools.ietf.org/html/rfc7231#section-6.4.4
    // 根据规范，303意味着请求被处理，但在其它URI间接拿结果。agent可执行相应的GET或HEAD请求间接拿结果。
    // 所以HEAD请求到303仍然应该保留HEAD请求。
    // 目前iOS系统的默认实现都转换成了GET，不一致。
    //
    // https://stackoverflow.com/questions/8138137/http-post-request-receives-a-302-should-the-redirect-request-be-a-get?rq=1
    // 另外302原本是设计给307的，但基本所有的浏览器都当成303处理了... 所以从实际兼容性考虑，302也当成303处理
    // 测试发现对于302，系统实现是把POST变为GET，但是PUT, PATCH等却没有变... 应该影响不大
    private func code(_ codes: [Int], shouldChangeMethodsToGet methods: [String]) {
        for code in codes {
            for method in methods {
                let ident = nextID()
                httpRequest(
                    path: "/redirect/receive?m=\(method)&c=\(code)&id=\(ident)",
                    method: method,
                    headers: [
                        "Cache-Control": "no-store",
                        "code": "\(code)",
                        "i": "id \(ident)"],
                    body: Data([33])
                ) { (data, response, error) -> Void in
                    XCTAssertNil(error)
                    XCTAssertTrue(response?.url?.absoluteString.hasSuffix("/redirect/receive") == false)
                    XCTAssertEqual(response?.statusCode, 200, "\((code, method, ident))")
                    XCTAssertEqual(response?.allHeaderFields["method"] as? String, "GET", "\((code, method))")
                    XCTAssertEqual(data, "no body".data(using: .utf8), "\((code, method))")
                    }.resume()
            }
        }
    }

    func testCanControlNoRedirect() {
        let isNative = self is NativeHTTPURLProtocolTests
        func disableRedirect(methods: [String], codes: [Int])
        -> ((), willGetOriginalResponse: () -> Void) {
            let session = makeSession(
                config: { $0.requestCachePolicy = .reloadIgnoringLocalCacheData },
                delegate: { $0.redirectionHandler = { $0.completionHandler(nil) } })
            return ((), {
                for method in methods {
                    for code in codes {
                        self.httpRequest(path: "/redirect/greet?code=\(code)&method=\(method)", method: method,
                                         headers: ["code": code.description], body: Data([96]),
                                         in: session, completeHandler: { (data, response, error) in
                                            // disable redirect will return the 3xx response directly
                                            XCTAssertNil(error, response?.description ?? "nil")
                                            XCTAssertEqual(response?.statusCode, code, "\((method, code, response))")
                                            if method == "HEAD" {
                                                XCTAssert(data == nil || data!.isEmpty)
                                            } else {
                                                // NOTE:兼容性: rust对于3xx 没有再读取body..
                                                // 系统会正常读取body，这个影响应该不大..
                                                if isNative {
                                                    XCTAssertEqual(data, "greet".data(using: .utf8),
                                                                   "\((method, code))")
                                                }
                                            }
                        }).resume()
                    }
                }
            })
        }

        disableRedirect(methods: ["GET", "HEAD", "POST", "PUT", "DELETE", "PATCH"],
                        codes: [301, 302, 303, 307, 308])
            .willGetOriginalResponse()
        waitTasks()
    }

    func testRedirectOfNSConnection() {
        DispatchQueue.global().async { [self] in // avoid runtime sync issue report
            tasks.add(1); defer { tasks.sub(1) }
            do {
                var response: URLResponse?
                // 怎么suppress这个warnning?
                let data = try NSURLConnection.sendSynchronousRequest(
                    URLRequest(url: HttpServer.makeURL(relativeString: "/unlimitRedirect/0")),
                    returning: &response)
                XCTFail("should fail: \((data, response))")
            } catch {
                XCTAssertEqual((error as? URLError)?.code, URLError.httpTooManyRedirects, "\(error)")
            }
        }
        waitTasks()
    }

    func testRedirectCountShouldLimited() {
        httpRequest(path: "/unlimitRedirect/0") { (_, response, error) -> Void in
            XCTAssertEqual((error as? URLError)?.code, URLError.httpTooManyRedirects, "\((response, error))")
            }.resume()
        waitTasks()
    }
}
