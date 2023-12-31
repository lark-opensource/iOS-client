//
//  WKHTTPTests+Cookie.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2019/1/9.
//  Copyright © 2019年 Bytedance. All rights reserved.
//

#if ENABLE_WKWebView
import Foundation
import XCTest
import RxSwift
@testable import LarkRustClient
@testable import LarkRustHTTP
import WebKit
import Swifter

@available(iOS 12.0, *)
extension WKHTTPTests {
    func testCookie() { // swiftlint:disable:this function_body_length
        // 请求: 分导航和AJAX
        //  重复请求能带上之前的cookie. (这个应该没问题，拦截后保存了Cookie)
        //  JS设置的Cookie能被带上
        // 查询同步:
        //  Set-Cookie可被JS查到
        //  Set-Cookie可被WKCookieStorage查到
        //  JS设置的Cookie可同步至原生并保存

      // 多个webView实例会产生干扰，导致cookie同步错误，需要想办法保证同步到正确的webView
      let views = (0..<4).map { _ in makeWebView() }
      for v in views {
        self.webView = v
        let cookies: String = [
                // if Domain is ip, need to match ip request exactly
                "AA=aa",
                "BB=bb;Domain=localhost", // all three Domain resolve to .localhost
                "BBB=bb;Domain=.localhost",
                "BBBB=bb;Domain=.localhost.",
                "CC=cc;Max-Age=600;",
                "DD=dd;Domain=other.com",
                "DD=dd;Domain=host", // partial suffix not match
                // "DD=dd;Domain=com.cn", // public suffix match nothing
                "EE=\("\"ee\";Path=/web".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)",
                "EE=\("\"ee\";Path=/".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
            ].joined(separator: "&")
        // 获取到的Cookie应该和设置的一致
        func assertValid(cookies: [HTTPCookie], identifier: String) {
            let cookies = Dictionary(
                cookies.map { ($0.name, ($0, 1)) },
                uniquingKeysWith: { (_, v2) in (v2.0, v2.1 + 1) })
            func assert(cookie key: String, equal value: String, domain: String? = nil, path: String? = nil, sessionOnly: Bool? = nil, count: Int = 1) { // swiftlint:disable:this line_length
                guard case let (cookie, sameCount)? = cookies[key] else {
                    // NOTE: 不拦截时，单独测试没问题，但整个Class一起跑就报错...
                    // teardown时清除旧webView后，正常了...
                    XCTFail("\(identifier): \(key)")
                    return
                }
                let message = "\(identifier): \(cookie)"
                XCTAssertEqual(sameCount, count, message)
                XCTAssertEqual(cookie.value, value, message)
                if let domain = domain { XCTAssertEqual(cookie.domain, domain, message) }
                if let path = path { XCTAssertEqual(cookie.path, path, message) }
                if let sessionOnly = sessionOnly { XCTAssertEqual(cookie.isSessionOnly, sessionOnly, message) }
            }
            // https://tools.ietf.org/html/rfc6265#section-5.1.4
            // default domain to current host and path to current path, sessionOnly to true
            assert(cookie: "AA", equal: "aa", domain: "localhost",
                   path: HttpServer.testServerURL.appendingPathComponent("web").path,
                   sessionOnly: true)
            // only my impl support server return multiple kv in one Set-Cookie.
            // if test multiple Set-Cookie, should use other server
            assert(cookie: "BB", equal: "bb", domain: ".localhost", sessionOnly: true)
            assert(cookie: "BBB", equal: "bb", domain: ".localhost", sessionOnly: true)
            assert(cookie: "BBBB", equal: "bb", domain: ".localhost", sessionOnly: true)
            assert(cookie: "CC", equal: "cc", sessionOnly: false)
            assert(cookie: "EE", equal: "\"ee\"", count: 2)
            XCTAssertNil(cookies["DD"], identifier) // other domain shouldn't enter cookieStorage
        }
        /// @param identifier: use as a log tip
        let didSetCookies = { (identifier: String) in Completable.zip([
            Completable.create { complete in
                if self.isProtocolRegisterd {
                    // 拦截后是共用的系统的Cookie，所有会保存进去. 这个是实现相关，WKWebView没这方面要求
                    assertValid(cookies: HTTPCookieStorage.shared.cookies!, identifier: "\(identifier):system")
                }
                // WKCookieStore可以取到对应的Cookie
                let store = self.webView.configuration.websiteDataStore
                store.httpCookieStore.getAllCookies { (cookies) in
                    assertValid(cookies: cookies, identifier: "\(identifier):WK")
                    complete(.completed)
                }
                return Disposables.create()
            },
            // js也能取到本域名的Cookie
            self.evaluateJavaScript("document.cookie").do(onSuccess: { (cookie: String) in
                // NOTE: 全部一起跑的时候这个Case可能过不了? 但单独跑能过...
                // 是同步时机问题? delay了也一样随机出现
                // testCase teardown时，移除旧webView后没再失败了..., 多个webView互相会产生干扰?
                // FIXME: 用safari调试发现，没移除旧webView，会有多个webView实例。
                // cookie加到了旧view的js上，但没加到请求的view上...
                // 另外CC是持久保存的，这里不能马上取到，但延迟能取到。

                // iOS 14上又不稳定了，多了cookie监听同步就会失败了，多的代码不应该有影响啊。即时delay一定时间也没用..
                // 看了日志，好像是因为cookie change调用太频繁，可能重复设置太多导致的
                XCTAssertEqual(try? HttpServer.format(cookie: cookie),
                               ["AA": ["aa"],
                                "BB": ["bb"],
                                "BBB": ["bb"],
                                "BBBB": ["bb"],
                                "CC": ["cc"],
                                "EE": ["\"ee\"", "\"ee\""]],
                                "\(identifier):jscookie")
            })
//            .delaySubscription(.microseconds(100), scheduler: MainScheduler.instance)
            .asCompletable()
        ]) }

        let setCookieBeforeLoad = Completable.create { (observer) -> Disposable in
            let root = HttpServer.makeURL(relativeString: "/web/index")
            var components = URLComponents(url: root, resolvingAgainstBaseURL: false)!
            components.percentEncodedQuery = cookies
            let queryParams = components.queryItems?.map { ($0.name, $0.value ?? "") } ?? []
            let setCookiesHeader = queryParams
                .map { "\($0)=\($1)" }
                .joined(separator: ", ")
            HTTPCookieStorage.shared.setCookies(
                HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": setCookiesHeader], for: root),
                for: root, mainDocumentURL: root)

            assertValid(cookies: HTTPCookieStorage.shared.cookies!, identifier: "Native:before:system")
            observer(.completed)
            return Disposables.create()
        }

        let setCookieByAjax: Completable = self.evaluateAsyncJavaScript(
                "getURL('../setCookies?\(cookies)', function() { callback(this.responseText) })")
            .flatMapCompletable { (_: Any?) in didSetCookies("AJAX") }
        let setCookieByLocation: Completable = self.navigation {
                self.webView.evaluateJavaScript("window.location = '../setCookies?\(cookies)' ")
            }.andThen(didSetCookies("Location"))
            .andThen(navigationBack())
        let setCookieByRedirect: Completable = self.navigation {
                self.webView.evaluateJavaScript("window.location = '../redirectWithCookies/cookies?\(cookies)'")
            }.andThen(didSetCookies("Navigation"))
            .andThen(navigationBack())

        let reqWithJSCookie: Completable = self.evaluateAsyncJavaScript(
                // swiftlint:disable:next line_length
                "document.cookie = 'xx=11'; document.cookie = 'yy=22;path=/'; getURL('../cookies', function() { callback(this.responseText) })"
            ).do(onSuccess: { (result: String) in
                // swiftlint:disable:next force_try
                let result = try! JSONDecoder().decode([String: [String]].self, from: result.data(using: .utf8)!)
                XCTAssertEqual(result,
                               ["yy": ["22"], // xx set to index page, will not apply to ../cookies
                               "AA": ["aa"],
                               "BB": ["bb"],
                               "BBB": ["bb"],
                               "BBBB": ["bb"],
                               "CC": ["cc"],
                               "EE": ["\"ee\"", "\"ee\""]])
            }).asCompletable()

        func run() { // mark for begin run
            wait(completable: Completable.concat([
                clearWebCache()
                    .andThen(setCookieBeforeLoad)
                    .andThen(loadRootPage())
                    .andThen(didSetCookies("Native"))
                    .andThen(reqWithJSCookie),
                clearWebCache()
                    .andThen(setCookieByAjax)
                    .andThen(reqWithJSCookie),
                clearWebCache()
                    .andThen(setCookieByLocation)
                    .andThen(reqWithJSCookie),
                clearWebCache()
                    .andThen(setCookieByRedirect)
                    .andThen(reqWithJSCookie)
            ]))
        }
        run()
      }
      // runUntil(condition: false)
    }
}
#endif
