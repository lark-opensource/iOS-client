//
//  URLProtocolTests+Cookie.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2018/12/21.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import XCTest
import HTTProtocol

extension URLProtocolTests {
    func requestSetCookie(
        with session: BaseSession,
        configure: (inout RequestTask) -> Void = { _ in },
        completeHandler: @escaping (HTTPCookieStorage, Data?, HTTPURLResponse?, Error?) -> Void
    ) {
        let cookieStorage = session.baseConfiguration.httpCookieStorage!
        cookieStorage.removeCookies(since: Date.distantPast) // remove all cookies before test
        XCTAssertEqual(cookieStorage.cookies ?? [], [])
        let cookies: String = [
                "AA=aa",
                "BB=bb;Domain=\(serverURL.host!)",
                "CC=cc;Max-Age=600;",
                "DD=dd;Domain=other.com",
                "EE=\( "\"ee\";Path=/cookie".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! )" // swiftlint:disable:this all
                ].joined(separator: "&")
        var req = httpRequest(path: "/setCookies?\(cookies)", in: session) { (data, response, error) -> Void in
            completeHandler(cookieStorage, data, response, error)
            }
        configure(&req)
        req.resume()
    }

    func testCookieCanBeSaved() {
        func action(with session: BaseSession, identifier: String) {
            requestSetCookie(with: session) { (cookieStorage, _, response, _) -> Void in
                XCTAssertEqual(response?.statusCode, 200, identifier)
                // cookieStorage.cookies可能返回重复的cookie名?
                let cookies = Dictionary(cookieStorage.cookies!.map { ($0.name, $0) }, uniquingKeysWith: { $1 })
                func assert(cookie key: String, equal value: String, domain: String? = nil, path: String? = nil, sessionOnly: Bool? = nil) { // swiftlint:disable:this all
                    let cookie = cookies[key]
                    XCTAssertNotNil(cookie, identifier)
                    XCTAssertEqual(cookie?.value, value, identifier)
                    if let path = path { XCTAssertEqual(cookie?.path, path, identifier) }
                    if let sessionOnly = sessionOnly { XCTAssertEqual(cookie?.isSessionOnly, sessionOnly, identifier) }
                }
                // https://tools.ietf.org/html/rfc6265#section-5.1.4
                // default domain to current host and path to current path, sessionOnly to true
                assert(cookie: "AA", equal: "aa", domain: "localhost",
                       path: response?.url?.deletingLastPathComponent().path, sessionOnly: true)
                // only my impl support server return multiple kv in one Set-Cookie.
                // if test multiple Set-Cookie, should use other server or my fork patch server
                assert(cookie: "BB", equal: "bb", domain: self.serverURL.host!, sessionOnly: true)
                assert(cookie: "CC", equal: "cc", sessionOnly: false)
                XCTAssertNil(cookies["DD"], identifier) // other domain shouldn't enter cookieStorage
                // iOS HTTP will not unwrap DQUOTE around value. so we also not support it
                assert(cookie: "EE", equal: "\"ee\"", path: "/cookie", sessionOnly: true)
            }
        }
        func defaultStorageCanbeSaved() {
            action(with: Self.sharedSession, identifier: "shared")
        }
        func customStorageCanbeSaved() {
            let session = makeSession( config: {
                // direct new HTTPCookieStorage cannot be save. even in system api
                // testConfiguration.httpCookieStorage = HTTPCookieStorage()
                $0.httpCookieStorage =
                    HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "test")
                                      })
            action(with: session, identifier: "test")
        }
        func ephemeralStorageCanbeSaved() {
            // though ephemeral configuration not save to disk, it should save to memory
            // TODO: RustHTTPSession supported
            let ephemeralConfiguration = makeURLSessionConfiguration(identifier: "ephemeral")
            // FIXME: 这里改了cookieStorage，那可能和默认的ephemeral没关系了？
            // ephemeralConfiguration.httpCookieStorage =
            //     HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "ephemeral")
            action(with: URLSession(configuration: ephemeralConfiguration), identifier: "ephemeral")
        }

        defaultStorageCanbeSaved()
        // only support shared config
        if type(of: self).registerProtocolClass != NativeHTTProtocol.self {
            customStorageCanbeSaved()
            ephemeralStorageCanbeSaved()
        }
        // TODO: 收到Header后，异常断开，是否还保存Cookie?

        waitTasks()
    }

    func testCookieSavePolicyCanbeControl() {
        func cookieAcceptPolicyCanDisableSave() {
            let session = makeSession(config: { configuration in
                configuration.httpCookieStorage =
                    HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "nosave")
                // no effect? still save in system api
                // configuration.httpCookieAcceptPolicy = .never
                configuration.httpCookieStorage?.cookieAcceptPolicy = .never
                                          })
            requestSetCookie(with: session) { (cookieStorage, _, response, _) -> Void in // swiftlint:disable:this all
                XCTAssertEqual(response?.statusCode, 200)
                XCTAssertEqual(cookieStorage.cookies ?? [], [])
            }
        }
        func httpShouldSetCookiesCanDisableSave() {
            let session = makeSession(config: { configuration in
                configuration.httpCookieStorage =
                    HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: "nosave")
                configuration.httpShouldSetCookies = false // disable setCookies also disable server side Set-Cookies
                                          })
            requestSetCookie(with: session) { (cookieStorage, _, response, _) -> Void in // swiftlint:disable:this all
                XCTAssertEqual(response?.statusCode, 200)
                XCTAssertEqual(cookieStorage.cookies ?? [], [])
            }
        }
        func requestCanAlsoDisableCookieSave() {
            requestSetCookie(with: Self.sharedSession, configure: {
                $0.urlrequest.setValue("xxx", forHTTPHeaderField: "Test")
                $0.urlrequest.httpShouldHandleCookies = false // disable handle cookie also disable set-cookies
            }, completeHandler: { (cookieStorage, _, response, _) -> Void in
                XCTAssertEqual(response?.statusCode, 200)
                XCTAssertEqual(cookieStorage.cookies ?? [], [])
            })
        }

        // only support shared config
        if type(of: self).registerProtocolClass != NativeHTTProtocol.self {
            cookieAcceptPolicyCanDisableSave()
            httpShouldSetCookiesCanDisableSave()
        }
        // NOTE: TTNet始终会带上cookie，没有禁用的能力
        if self is NativeHTTPURLProtocolTests {
            requestCanAlsoDisableCookieSave()
        }

        waitTasks()
    }
    func makeCookie(identifier: String, url: URL? = nil, properties: [HTTPCookiePropertyKey: Any] = [:])
        -> HTTPCookie {
            let url = url ?? serverURL
            var prop: [HTTPCookiePropertyKey: Any] = [
                .name: identifier,
                .value: identifier,
                .path: "/"
                ].merging(properties, uniquingKeysWith: { $1 })
            prop[.originURL] = url
            return HTTPCookie(properties: prop)!
    }
    func setupCookies(in cookieStorage: HTTPCookieStorage) {
        cookieStorage.removeCookies(since: Date.distantPast)

        let cookies = [
            makeCookie(identifier: "A"),
            makeCookie(identifier: "B", properties: [.path: "/setCookies"]),
            makeCookie(identifier: "C", properties: [.path: "/", .value: "CC"]),
            makeCookie(identifier: "C", properties: [.path: serverURL.appendingPathComponent("/cookies").path]),
            makeCookie(identifier: "D", properties: [.expires: Date(timeIntervalSinceNow: 30)]),
            // expires cookie won't enter cookieStorage, so use a short expires
            makeCookie(identifier: "E", properties: [.expires: Date(timeIntervalSinceNow: 1)]),
            makeCookie(identifier: "F", properties: [.maximumAge: "30"]),
            makeCookie(identifier: "G", properties: [.secure: "1"])
        ]
        cookieStorage.setCookies(cookies, for: serverURL, mainDocumentURL: nil)
        let otherURL = URL(string: "http://www.example.com")
        cookieStorage.setCookies([
            makeCookie(identifier: "a", url: otherURL)
            ], for: otherURL, mainDocumentURL: nil)

        // expires cookie not accept by setCookies
        XCTAssertEqual(cookieStorage.cookies!.count, cookies.count + 1)
        sleep(1) // wait cookie expires
    }

    func testRequestWithCookie() {
        let session = Self.sharedSession

        func customCookieOverrideSystemCookies() {
            // Custom Cookie header override system default cookies
            httpRequest(path: "/cookies", headers: ["Cookie": "A=1"]) { (data, response, _) in
                XCTAssertEqual(response?.statusCode, 200)
                guard let data = data else { return XCTFail("no data") }
                guard case let cookies? = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    else {
                        return XCTFail("error data \(data)")
                }
                // user set cookie will override storage cookies
                XCTAssertEqual(cookies["A"] as? [String], ["1"])
                XCTAssertEqual(cookies.count, 1)
                }.resume()
        }

        func systemPassCorrectCookies() {
            httpRequest(path: "/cookies", in: session) { (data, response, _) in
                XCTAssertEqual(response?.statusCode, 200)
                guard let data = data else { return XCTFail("no data") }
                guard case let cookies? = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    else {
                        return XCTFail("error data \(data)")
                }
                // prefix path, and dont expire(by date or age) is valid cookie
                for i in ["A", "C", "D", "F"] {
                    XCTAssertNotNil(cookies[i])
                }
                // other paths, or expired or other domain, or secure but request http, will not pass to server
                for i in ["B", "E", "a", "G"] {
                    XCTAssertNil(cookies[i])
                }
                // according to https://tools.ietf.org/html/rfc6265#section-5.4
                // same name, system will sent all but longer path first.
                XCTAssertEqual(cookies["C"] as? [String], ["C", "CC"])
                }.resume()
        }

        setupCookies(in: session.baseConfiguration.httpCookieStorage!)
        customCookieOverrideSystemCookies()
        systemPassCorrectCookies()

        waitTasks()
    }

    func testRequestWithoutCookie() {
        // NOTE: TTNet始终会带上cookie, 目前没有禁用他的方法.., 边界使用场景..
//        guard self is NativeHTTPURLProtocolTests else { return }
        func requestWithFalseHttpShouldSetCookies_DisablePassCookies() {
            Self.sharedSession.baseConfiguration.httpCookieStorage?.setCookies([
                makeCookie(identifier: "A")
                ], for: serverURL, mainDocumentURL: nil)
            var task = httpRequest(path: "/cookies") { (_, response, _) in
                XCTAssertEqual(response?.statusCode, 400)
            }
            task.urlrequest.httpShouldHandleCookies = false // URLRequest's option can control cookie feature
            task.resume()
        }
        func sessionConfigurationWithFalseHttpShouldSetCookies_DisablePassCookies() {
            let session = makeSession(config: { (configure) in
                configure.httpShouldSetCookies = false // URLSessionConfiguration's option can control cookie feature
            })
            httpRequest(path: "/cookies", in: session) { (_, response, _) in
                XCTAssertEqual(response?.statusCode, 400)
                }.resume()
        }
        requestWithFalseHttpShouldSetCookies_DisablePassCookies()
        // NOTE: native现在只支持shared的配置
        if type(of: self).registerProtocolClass != NativeHTTProtocol.self {
            sessionConfigurationWithFalseHttpShouldSetCookies_DisablePassCookies()
        }

        waitTasks()
    }
}
