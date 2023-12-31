//
//  RustHttpURLProtocol+Helper.swift
//  LarkRustHTTP
//
//  Created by SolaWing on 2019/3/31.
//

import Foundation
import RustPB

/// 只读的帮助代码段
extension RustHttpURLProtocol {
    func date(with age: String?) -> Date {
        if let ageString = age, let age = TimeInterval(ageString) {
            return Date() - age
        } else {
            return Date()
        }
    }
    func defaultCachePolicy(response: HTTPURLResponse) -> URLCache.StoragePolicy {
        // 参考CustomHTTPProtocol CacheStoragePolicy.m
        // TODO: 206 Range的缓存，现在主要根据URL缓存，但range只有部分缓存.. range不匹配的情况下会缓存错误
        guard [200, 203, 301, 308, 404, 410].contains(response.statusCode) else { return .notAllowed }

        func isNoCache(in control: Any?) -> Bool {
            guard let control = control as? String else { return false }
            return ["no-cache", "no-store"].contains(where: { control.range(of: $0, options: .caseInsensitive) != nil })
        }
        if
            isNoCache(in: response.allHeaderFields["Cache-Control"]) ||
            isNoCache(in: self.request.value(forHTTPHeaderField: "Cache-Control"))
        {
            return .notAllowed
        }
        return .allowed
    }
    func isValid(cachedResponse: CachedURLResponse, validateHeaders: inout [String: String]) -> Bool {
        guard let method = self.request.httpMethod, method == "GET" || method == "HEAD" else {
            return false
        }
        guard let response = cachedResponse.response as? HTTPURLResponse else { return false }
        var isCacheValid: Bool? {
            if
                let cacheControl = response.headerString(field: "Cache-Control"),
                let age = self.age(in: cacheControl),
                let date = Date(GMT: response.headerString(field: "Date"))
            {
                let elapse = -date.timeIntervalSinceNow
                return elapse >= 0 && elapse < age
            } else if let expires = Date(GMT: response.headerString(field: "Expires")) {
                return expires.timeIntervalSinceNow > 0
            }
            return nil
        }
        switch isCacheValid {
        case true: return true
        case nil:
            // 永久重定向，默认始终缓存, 除非指定缓存且过期
            if case let statusCode = response.statusCode, statusCode == 301 || statusCode == 308 {
                return true
            }
        default: break
        }

        // check if need to add validateHeaders
        if let etag = response.headerString(field: "Etag") {
            validateHeaders["if-none-match"] = etag
        }
        if let lastModified = response.headerString(field: "Last-Modified") {
            validateHeaders["if-modified-since"] = lastModified
        }
        // 判断有效性并可能生成相应的验证header
        return false
    }
    func age(in cacheControl: String) -> TimeInterval? {
        if let start = cacheControl.range(of: "max-age=", options: .caseInsensitive)?.upperBound {
            let end = cacheControl[start...].firstIndex(of: ",") ?? cacheControl.endIndex
            return TimeInterval(cacheControl[start..<end])
        }
        return nil
    }
}
