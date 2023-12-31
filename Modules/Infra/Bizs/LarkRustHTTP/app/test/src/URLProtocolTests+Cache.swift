//
//  URLProtocolTests+Cache.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2018/12/21.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import XCTest
@testable import LarkRustClient
@testable import LarkRustHTTP
import HTTProtocol

extension URLProtocolTests {
    // swiftlint:disable:next function_body_length
    func testCache() {
        Self.sharedSession.baseConfiguration.urlCache?.removeAllCachedResponses()
        let customStorageSession = makeSession(config: {
            $0.urlCache = URLCache(memoryCapacity: 20 << 20, diskCapacity: 0, diskPath: nil)
        })
        customStorageSession.accessibilityHint = "customStorage"

        var stage = ""
        func request(method: String, in session: BaseSession, shouldSaveCache: Bool) {
            // native only support shared config
            if self is NativeHTTPURLProtocolTests, session !== URLSession.shared {
                return
            }

            var req: URLRequest!
            let task = httpRequest(path: "/cache/count", method: method, in: session) { (_, response, _) in
                XCTAssertEqual(response?.statusCode, 200)
                XCTAssert((session.baseConfiguration.urlCache?.cachedResponse(for: req) != nil) == shouldSaveCache,
                          "\(method) should \(shouldSaveCache ? "":"not") save cache")
                if req.httpMethod == "GET" {
                    var otherReq = req!
                    otherReq.httpMethod = "HEAD"
                    XCTAssertNotNil(session.baseConfiguration.urlCache?.cachedResponse(for: otherReq),
                                    "head request should use normal request's cache")
                }
            }
            req = task.urlrequest
            // NOTE: 有时候这里会有缓存，怎么没清干净呢?
            XCTAssertNil(session.baseConfiguration.urlCache?.cachedResponse(for: req),
                         "\(session.accessibilityHint ?? "shared session")")
            task.resume()
        }
        func formatDataNumber(_ data: Data?) -> Int? {
            if let data = data, let string = String(data: data, encoding: .utf8), let v = Int(string) {
                return v
            }
            return nil
        }
        func request(configure: (inout RequestTask) -> Void = { _ in }, in session: BaseSession, shouldUseCache: Bool, failMessage: String = "") { // swiftlint:disable:this all
            let registerProtocolClass = type(of: self).registerProtocolClass
            if Self.useRustNetwork, shouldUseCache == false {
                // FIXME: Rust现在始终缓存，不支持忽略缓存选项
                return
            }
            // only support shared config
            if registerProtocolClass == NativeHTTProtocol.self, session !== URLSession.shared {
                return
            }
            var cachedData: Data?
            var task = httpRequest(path: "/cache/count", in: session) { (data, _, _) in
                XCTAssert( (cachedData == data) == shouldUseCache,
                           "\(stage): \((failMessage, session, shouldUseCache)): \((formatDataNumber(cachedData), formatDataNumber(data)))" ) // swiftlint:disable:this all
            }
            configure(&task)
            cachedData = session.baseConfiguration.urlCache?.cachedResponse(for: task.urlrequest)?.data
            XCTAssertNotNil(cachedData)
            task.resume()
            if !shouldUseCache { waitTasks() } // 请求服务器时会产生副作用。串行保证共享状态正确
        }
        func request(policy: URLRequest.CachePolicy, in session: BaseSession, shouldUseCache: Bool) {
            // policy优先取request上的，request没设置就取configuration上的
            request(configure: { $0.urlrequest.cachePolicy = policy },
                    in: session, shouldUseCache: shouldUseCache,
                    failMessage: "policy: \(policy.rawValue)")
        }
        func request(method: String, policy: URLRequest.CachePolicy = .useProtocolCachePolicy, shouldUseCache: Bool) {
            // policy优先取request上的，request没设置就取configuration上的
            request(configure: {
                $0.urlrequest.httpMethod = method
                $0.urlrequest.cachePolicy = policy
            }, in: Self.sharedSession, shouldUseCache: shouldUseCache,
               failMessage: "\(method) method")
        }
        func expiredCacheShouldnotBeUsed() {
            httpRequest(path: "/cache/age") { cachedData, _, _ in
                sleep(1)
                self.httpRequest(path: "/cache/age") { newData, _, _ in
                    XCTAssertNotEqual(cachedData, newData)
                    }.resume()
                }.resume()
            waitTasks()
        }
        func cacheDataDontLoadPolicyShouldnotLoadWhenNoCache() {
            var task = httpRequest(path: "/cache/unknown") { _, _, error in
                XCTAssertEqual((error as? URLError)?.code, URLError.resourceUnavailable)
            }
            // NOTE: 没有走URLProtocol？直接缓存里拿数据?
            task.urlrequest.cachePolicy = .returnCacheDataDontLoad
            task.resume()
        }
        func response(code: Int, shouldUseCache: Bool) {
            let path =  "/cache/code/\(code)"
            httpRequest(path: path) { cachedData, _, _ in
                self.httpRequest(path: path) { newData, response, _ in
                    if code > 300 && code < 400 {
                        XCTAssertEqual(response?.statusCode, 200)
                    } else {
                        XCTAssertEqual(response?.statusCode, code)
                    }
                    XCTAssert( (cachedData == newData) == shouldUseCache,
                               "\((code, shouldUseCache))" )
                    }.resume()
                }.resume()
            waitTasks()
        }
        func notModifiedResponseShouldUseCache() {
            var request: URLRequest!
            // 304 response should return cached response
            let task = httpRequest(path: "/cache/get") { cachedData, _, _ in
                var cachedResponse: HTTPURLResponse?
                if self.isProtocolRegisterd {
                    cachedResponse = URLCache.shared.cachedResponse(for: request)?.response as? HTTPURLResponse
                    sleep(1) // sleep for waiting date changes
                }
                // 仅在defaultPolicy时会传`if-none-match`
                self.httpRequest(path: "/cache/get") { newData, response, _ in
                    XCTAssertEqual(cachedData, newData)
                    XCTAssertEqual(response?.statusCode, 200)
                    if Self.useRustNetwork {
                        // refresh cache should change the Date header
                        let newCachedResponse = URLCache.shared.cachedResponse(for: request)?.response as? HTTPURLResponse // swiftlint:disable:this all
                        XCTAssertNotEqual(cachedResponse?.headerString(field: "Date"),
                                          newCachedResponse?.headerString(field: "Date"),
                                          "Cache Date should change after revalidate")
                    }
                    }.resume()
            }
            request = task.urlrequest
            task.resume()
            waitTasks()
        }
        let makeSessionForPolicy = { (policy: URLRequest.CachePolicy) -> BaseSession in
            let session = self.makeSession(config: {
                $0.requestCachePolicy = policy
            })
            session.accessibilityHint = "session policy: \(policy.rawValue)"
            return session
        }

        // cache是异步清理的？稍微等待一下, 避免缓存不干净的情况
        runUntil(condition: Self.sharedSession.baseConfiguration.urlCache?.currentMemoryUsage == 0)
        // test begin
        stage = "begin"
        request(method: "HEAD", in: Self.sharedSession, shouldSaveCache: false)
        request(method: "HEAD", in: customStorageSession, shouldSaveCache: false)
        waitTasks()
        request(method: "GET", in: Self.sharedSession, shouldSaveCache: true)
        request(method: "GET", in: customStorageSession, shouldSaveCache: true)
        waitTasks()

        stage = "policy"
        // CachePolicy优先取request上的，request没设置就取configuration上的
        cacheDataDontLoadPolicyShouldnotLoadWhenNoCache()
        // 协议默认会考虑maxAge, 也就是会用缓存
        for v in [URLRequest.CachePolicy.returnCacheDataElseLoad, .returnCacheDataDontLoad, .useProtocolCachePolicy] {
            request(policy: v, in: Self.sharedSession, shouldUseCache: true)
            request(policy: v, in: customStorageSession, shouldUseCache: true)
        }
        waitTasks()
        for v in [URLRequest.CachePolicy.reloadIgnoringLocalCacheData, .reloadIgnoringLocalAndRemoteCacheData] {
            request(policy: v, in: Self.sharedSession, shouldUseCache: false)
            request(policy: v, in: customStorageSession, shouldUseCache: false)
        }
        waitTasks()
        for v in [.returnCacheDataElseLoad, .returnCacheDataDontLoad].map({ makeSessionForPolicy($0) }) {
            request(in: v, shouldUseCache: true)
        }
        waitTasks()
        // reloadIgnoringLocalAndRemoteCacheData is unimplemented
        for v in [.reloadIgnoringLocalCacheData].map({ makeSessionForPolicy($0) }) { // swiftlint:disable:this all
            request(in: v, shouldUseCache: false)
        }
        waitTasks()

        stage = "METHOD"
        // only GET and HEAD should use cache
        for v in ["GET", "HEAD"] { request(method: v, shouldUseCache: true) }
        waitTasks()
        for v in ["POST", "PUT", "DELETE", "PATCH"] { request(method: v, shouldUseCache: false) }
        waitTasks()
        for v in ["POST", "PUT", "DELETE", "PATCH"] {
            request(method: v, policy: .returnCacheDataElseLoad, shouldUseCache: true)
        }
        waitTasks()

        stage = "extra"
        // same common code should be cached
        for v in [200, 301, 308, 404] { response(code: v, shouldUseCache: true) }
        notModifiedResponseShouldUseCache() // 304 response
        expiredCacheShouldnotBeUsed()

        // TODO: 206 and range cache
        // TODO: Http Header, like Cache-Control, Vary, Can control cache behaviour
    }
}
