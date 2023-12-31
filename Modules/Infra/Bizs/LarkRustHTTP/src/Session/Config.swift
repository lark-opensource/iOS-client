//
//  Config.swift
//  LarkRustHTTP
//
//  Created by SolaWing on 2023/4/11.
//

import Foundation
// swiftlint:disable missing_docs line_length

@objc
public class RustHTTPSessionConfig: NSObject, NSCopying {
    // use struct to ensure copy behaviour
    struct Raw {
        static var `default`: Raw { Raw() }
        static var ephemeral: Raw {
            Raw(httpCookieStorage: nil, urlCache: nil, urlCredentialStorage: nil)
        }
        // 后续按需陆续加全局配置属性
        var httpAdditionalHeaders: [String: String]?
        var httpCookieStorage: HTTPCookieStorage? = .shared
        var httpShouldSetCookies: Bool = true
        var urlCache: URLCache? = .shared
        var requestCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
        var urlCredentialStorage: URLCredentialStorage? = .shared
    }
    var rawValue = Raw()
    init(rawValue: Raw) {
        self.rawValue = rawValue
    }
    public func copy(with zone: NSZone? = nil) -> Any {
        return RustHTTPSessionConfig(rawValue: rawValue)
    }
}
@objc
extension RustHTTPSessionConfig {
    public static var `default`: RustHTTPSessionConfig { .init(rawValue: Raw.default) }
    /// an ephemeral session without disk cache.
    /// NOTE:TODO: memory cache need to implement, and currently no cookie, credential, response cache
    public static var ephemeral: RustHTTPSessionConfig { .init(rawValue: Raw.ephemeral) }
    public var httpAdditionalHeaders: [String: String]? {
        get { return rawValue.httpAdditionalHeaders }
        set { rawValue.httpAdditionalHeaders = newValue }
    }
    /// Same as URLSessionConfiguration.httpCookieStorage
    /// This property determines the cookie storage object used by all tasks based on this configuration.
    /// To disable cookie storage, set this property to nil.
    public var httpCookieStorage: HTTPCookieStorage? {
        get { return rawValue.httpCookieStorage }
        set { rawValue.httpCookieStorage = newValue }
    }
    public var httpShouldSetCookies: Bool {
        get { return rawValue.httpShouldSetCookies }
        set { rawValue.httpShouldSetCookies = newValue }
    }
    public var urlCache: URLCache? {
        get { return rawValue.urlCache }
        set { rawValue.urlCache = newValue }
    }
    public var requestCachePolicy: URLRequest.CachePolicy {
        get { return rawValue.requestCachePolicy }
        set { rawValue.requestCachePolicy = newValue }
    }
    public var urlCredentialStorage: URLCredentialStorage? {
        get { return rawValue.urlCredentialStorage }
        set { rawValue.urlCredentialStorage = newValue }
    }
}

// swiftlint:enable missing_docs line_length
