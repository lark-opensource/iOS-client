//
//  HTTProtocolHandler.swift
//  HTTProtocol
//
//  Created by SolaWing on 2019/7/18.
//

import Foundation

// swiftlint:disable missing_docs

/// handler of BaseHTTProtocol. should loading resource, and give response. (may need to cache or deal cookie)
public protocol HTTProtocolHandler {
    /// start loading resource. may need to deal with cache load and cookie storages
    func startLoading(request: BaseHTTProtocol)
    /// after stopLoading, shouldn't call any HandlerClientEvent
    func stopLoading(request: BaseHTTProtocol)
}

/// info of a request, used by extension helper methods
public protocol URLProtocolContext {
    var request: URLRequest { get }
    var task: URLSessionTask? { get }
}

public extension URLProtocolContext {
    var session: URLSession? {
        return task?.perform(NSSelectorFromString("session"))?.takeUnretainedValue() as? URLSession
    }
    var cookieStorage: HTTPCookieStorage? {
        // httpShouldSetCookies为false时，不应该发送和设置cookies
        guard self.request.httpShouldHandleCookies else { return nil }
        if let configuration = session?.configuration {
            if configuration.httpShouldSetCookies {
                return configuration.httpCookieStorage
            } else {
                return nil
            }
        }
        return HTTPCookieStorage.shared
    }
    var urlCache: URLCache? {
        if let configuration = session?.configuration {
            return configuration.urlCache
        }
        return URLCache.shared
    }
    var cachePolicy: URLRequest.CachePolicy {
        // 优先取request的，其次是configuration上的
        if case let policy = request.cachePolicy, policy != .useProtocolCachePolicy { return policy }
        if let policy = session?.configuration.requestCachePolicy { return policy }
        return .useProtocolCachePolicy
    }
    var bodyStream: InputStream? {
        if let bodyStream = request.httpBodyStream { return bodyStream }
        if let body = request.httpBody { return InputStream(data: body) }
        return nil
    }
    var credentialStorage: URLCredentialStorage? {
        if let configuration = session?.configuration {
            return configuration.urlCredentialStorage
        }
        return URLCredentialStorage.shared
    }
}
// swiftlint:enable missing_docs
