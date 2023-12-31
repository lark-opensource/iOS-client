//
//  Server.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2018/12/21.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import UIKit
import Foundation
import Swifter
@testable import LarkRustClient
@testable import LarkRustHTTP

// swiftlint:disable force_try identifier_name line_length

// 使用域名能被wifi里设置的http代理拦截, 本机ip请求不行
private let _serverURL = URL(string: "http://localhost:8091")!
private let _cocoaServerURL = URL(string: "http://localhost:8092")!
// private let _serverURL = URL(string: "http://mymac.com:8091")!
// private let _serverURL = URL(string: "http://localhost:8080")!

// private let _serverURL = URL(string: "http://localhost/~wang/RustHTTP")!
// private let _serverURL = URL(string: "http://localhost:8081/~wang/RustHTTP")!

extension HttpServer {
    static var testServerURL: URL { return _serverURL }
    static var testServer = { () -> HttpServer in
        let server = HttpServer()
        server.setupDefaultHandler(rootURL: _serverURL)

        let path = Bundle(for: HttpServer.self).path(forResource: "WebResources", ofType: "bundle")!
        server.setupWebViewSupport(path: path)

        server.middleware.append({ req in
            debug("Server receive request: \(req.path)")
            return nil
        })

        // will throw if port not usable
        try! server.start(8_091)
        return server
    }()
    static func makeURL(relativeString: String) -> URL {
        return URL(string: HttpServer.testServerURL.absoluteString + relativeString)!
    }
    func makeURL(relativeString: String) -> URL {
        return URL(string: HttpServer.testServerURL.absoluteString + relativeString)!
    }

    // MARK: HttpServer Basic support
    func setupDefaultHandler(rootURL: URL) {
        self.setupFileSupport(path: "/file")
        self.setupRedirectSupport(rootURL: rootURL)
        self.setupRequestDataCheck()
        self.setupCookieSupport()
        self.setupAuthSupport()
        self.setupCacheSupport()
        // other misc
        self["/greet"] = { _ in
            return HttpResponse.ok(.text("greet"))
        }
        self["/slowresponse"] = { req in
            let duration = TimeInterval(req.headers["duration"] ?? "2") ?? 2
            return HttpResponse.raw(200, "OK", nil) { (writer) throws in
                var c: TimeInterval = 0
                while c < duration {
                    c += 1
                    try writer.write([UInt8(c.truncatingRemainder(dividingBy: 256))])
                    sleep(1)
                }
            }
        }
        self["/largeResponse"] = { req in
            /// 回应数据大小
            let size = req.headers["size"].flatMap { Int($0) } ?? 0
            /// 回应几次数据
            let count = req.headers["count"].flatMap { Int($0) } ?? 1
            /// 单位ms
            let interval = req.headers["interval"].flatMap { UInt32($0) } ?? 0
            let data = Data(repeating: ("S" as Character).asciiValue!, count: size)
            return HttpResponse.raw(200, "OK", ["Content-Length": String(size * count)]) { (writer) throws in
                for _ in 0..<count {
                    try writer.write(data)
                    if interval > 0 {
                        usleep(interval * 1_000)
                    }
                }
            }
        }
    }
    func setupRequestDataCheck() {
        // return get http body
        self["/post"] = { req in
            // current Swifter imp, not read body when no content length header
            let body = String(bytes: req.body, encoding: .utf8)!
            return HttpResponse.ok(.text(body))
        }
        // return client header in server headers
        self["/head"] = { req in
            return HttpResponse.raw(200, "OK", req.headers, { (writer) throws -> Void in
                try writer.write("receive header request".data(using: .utf8)!)
            })
        }
        // return client header in body
        self["/header"] = { req in
            return HttpResponse.ok(.data( try! JSONEncoder().encode(req.headers)))
        }
        // return client method and body
        self["/receive"] = { req in
            return HttpResponse.raw(200, "Ok", ["method": req.method]) {
                if req.body.isEmpty {
                    try $0.write("no body".data(using: .utf8)!)
                } else {
                    try $0.write(req.body)
                }
            }
        }
    }
    func setupRedirectSupport(rootURL: URL) {
        self["/redirect/:path"] = { req in
            let code = req.headers["code"].flatMap { Int($0) } ?? 302
            let locationType = req.headers["type"]
            let path = req.params[":path"] ?? ""
            var location: String
            if locationType == "relative" {
                location = "../\(path)"
            } else if locationType == "root_relative" {
                location = "\(rootURL.path)/\(path)"
            } else {
                location = "\(rootURL.absoluteString)/\(path)"
            }
            return HttpResponse.raw(code, "", ["Location": location]) {
                try $0.write(path.data(using: .utf8)!)
            }
        }
        self["/unlimitRedirect/:count"] = { req in
            let count = Int( req.params[":count"]! )!
            return HttpResponse.raw(307, "", ["Location": "\(count + 1)"], nil)
        }
    }
    func setupCacheSupport() {
        var counter = 0
        let increment = {
            counter += 1
            debug("counter is \(counter)")
        }
        // inc and return count. should cache
        self["/cache/count"] = { _ in
            increment()
            return HttpResponse.raw(200, "OK", [
                "Cache-Control": "max-age=30"
            ], { try $0.write("\(counter)".data(using: .utf8)!) })
        }
        // revalidate will 304, or inc and return count. should revalidate
        self["/cache/get"] = { req in
            if let cache = Int(req.headers["if-none-match"] ?? ""), cache == counter {
                return HttpResponse.raw(304, "Not Modified", nil, nil)
            }
            increment() // return new data when no cache. if the client don't provide cache infomation
            return HttpResponse.raw(200, "OK", [
                "ETag": "\(counter.description)",
                "Cache-Control": "must-revalidate"
            ], { try $0.write(counter.description.data(using: .utf8)!) })
        }
        // inc and: if code is 3xx, redirect to get. else return count and cache
        self["/cache/code/:code"] = { req in
            increment()
            let code = Int( req.params[":code"]! )!
            let header: [String: String]
            if code >= 300 && code < 400 {
                header = ["Location": "../get"]
            } else {
                header = ["Cache-Control": "max-age=30"]
            }
            return HttpResponse.raw(code, "", header, { try $0.write(counter.description.data(using: .utf8)!) })
        }
        // inc and short age cache(1). return count
        self["/cache/age"] = { _ in
            increment()
            return HttpResponse.raw(200, "OK", [
                "Cache-Control": "max-age=1"
            ], { try $0.write(counter.description.data(using: .utf8)!) })
        }
    }
    func setupFileSupport(path: String) {
        var files: [String: Data] = [:]
        let pattern = "\(path)/:path"
        self.PUT[pattern] = { req in
            let path = req.params[":path"]!
            files[path] = Data(req.body)
            return HttpResponse.created
        }
        self.DELETE[pattern] = { req in
            let path = req.params[":path"]!
            if files[path] == nil { return HttpResponse.notFound() }
            files[path] = nil
            return HttpResponse.raw(204, "No Content", nil, nil)
        }
        self.PATCH[pattern] = { req in
            let path = req.params[":path"]!
            var data = files[path] ?? Data()
            data.append(contentsOf: req.body)
            files[path] = data
            return HttpResponse.raw(204, "No Content", nil, nil)
        }
        // other as a get req
        self[pattern] = { req in
            let path = req.params[":path"]!
            guard let data = files[path] else { return HttpResponse.notFound() }
            return HttpResponse.ok(.data(data))
        }
    }
    func setupCookieSupport() {
        self["/setCookies"] = paramToSetCookie()
        self["/cookies"] = printReqCookies()
    }
    func setupAuthSupport() {
        var lastAuth = ""
        self["/auth/login"] = { req in
            debug("server receive authorization: \(req.headers["authorization"] ?? "")")
            if
                let auth = req.headers["authorization"]?.trimmingCharacters(in: .whitespaces).split(
                    separator: " ", maxSplits: 1, omittingEmptySubsequences: true
                    ).map({ $0.trimmingCharacters(in: .whitespaces) }),
                auth.count == 2 && auth[0] == "Basic",
                let data = Data(base64Encoded: auth[1]),
                let credential = String(data: data, encoding: .utf8)?
                    .split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
                    .map(String.init),
                credential.count == 2,
                case let (user, password) = (credential[0], credential[1]) {
                lastAuth = "\(user):\(password)"
                if user == "byte" && password == "dance" {
                    return HttpResponse.ok(.text(lastAuth))
                }
                return HttpResponse.raw(401, "Unauthorize", [
                    "WWW-Authenticate": "Basic realm=RustHTTP, charset=utf8"
                ], { try $0.write(lastAuth.data(using: .utf8)!) })
            }
            return HttpResponse.raw(401, "Unauthorize", [
                "WWW-Authenticate": "Basic realm=\"RustHTTP\""
            ], { try $0.write("no user".data(using: .utf8)!) })
        }
        self["/auth/state"] = { _ in
            return HttpResponse.ok(.text(lastAuth))
        }
        self["/auth/header"] = { req in
            let headers = req.headers
            return HttpResponse.ok(.data( try! JSONEncoder().encode(headers)))
        }
    }
    // MARK: HttpServer WebView support
    func setupWebViewSupport(path: String) {
        self["/web/page/:path"] = shareFilesFromDirectory(path)
        self["/web/redirect/:code/:path"] = { req in
            let code = Int(req.params[":code"] ?? "302") ?? 302
            let path = req.params[":path"] ?? ""
            let location = "../../\(path)"
            return HttpResponse.raw(code, "", ["Location": location]) {
                try $0.write(path.data(using: .utf8)!)
            }
        }
        self["/web/redirect2Unknown"] = { _ in
            return HttpResponse.movedTemporarily("unknown://scheme")
        }
        self["/web/redirect2Settings"] = { _ in
            return HttpResponse.movedTemporarily("app-settings://")
        }
        self["/web/post"] = { req in
            let body = String(bytes: req.body, encoding: .utf8)!
            return HttpResponse.ok(.text(body))
        }
        self["/web/header"] = { req in
            let header = try! JSONEncoder().encode(req.headers)
            return HttpResponse.ok(.data(header))
        }
        self["/web/setCookies"] = paramToSetCookie()
        self["/web/cookies"] = printReqCookies()
        self["/web/redirectWithCookies/:path"] = { req in
            let path = req.params[":path"] ?? ""
            let location = "../\(path)"
            var header = [("Location", location)]
            // 默认cookie设置到/web上
            header.append(contentsOf: req.queryParams.map { ("Set-Cookie", "\($0)=\($1)\($1.contains("Path=") ? "" : ";Path=/web")") })
            return HttpResponse.custom(302, "moved", header) {
                try $0.write(path.data(using: .utf8)!)
            }
        }
    }

    // MARK: Helper Function
    func paramToSetCookie() -> (HttpRequest) -> HttpResponse {
        return { req in
            // NOTE: Swifter don't support multiple Set-Cookie.
            // though we support the `,` joined syntax, apple doesn't support
            // so we fork Swifter to extension and support multiple Set-Cookie
            HttpResponse.custom(200, "ok", req.queryParams.map { ("Set-Cookie", "\($0)=\($1)") }, nil)
        }
    }
    func printReqCookies() -> (HttpRequest) -> HttpResponse {
        return { req in
            if let cookie = req.headers["cookie"], let cookies = try? HttpServer.format(cookie: cookie) {
                return HttpResponse.ok(HttpResponseBody.json(cookies as AnyObject))
            } else {
                return HttpResponse.badRequest(nil)
            }
        }
    }
    static func format(cookie: String) throws -> [String: [String]] {
        return try cookie.split(separator: ";").reduce(into: [String: [String]]()) {
            let kv = $1.trimmingCharacters(in: CharacterSet.whitespaces).split(separator: "=", maxSplits: 1)
            if kv.count == 2 {
                $0[String(kv[0]), default: []].append(String(kv[1]))
            } else {
                throw HTTPError.badParam("incorrect cookie format")
            }
        }
    }
    enum HTTPError: Error {
        case badParam(String)
    }
}
