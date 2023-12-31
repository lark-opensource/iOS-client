//
//  Docs.swift
//  DocsNetwork
//
//  Created by weidong fu on 24/11/2017.
//
//  Included OSS: Alamofire
//  Copyright (c) 2014-2022 Alamofire Software Foundation (http://alamofire.org/)
//  spdx license identifier: MIT

import Foundation
import Alamofire
import SwiftyJSON
import LarkRustHTTP
import LarkContainer

public protocol NetworkAuthDelegate: AnyObject {
    func handleAuthenticationChallenge()
}

protocol SessionEventHandler: AnyObject {
    func request() -> URLRequest?
    func should(_ manager: SessionManager?, retry request: URLRequest?, currentRetryCount: UInt, with error: Error, completion: @escaping RequestRetryCompletion)
}

class EventHandlerWarrper {
    weak var target: SessionEventHandler?
    init(_ target: SessionEventHandler) {
        self.target = target
    }
}

public final class NetworkSession: NSObject {
    public weak var authDelegate: NetworkAuthDelegate?
    var identifier: String?
    fileprivate var eventHandlers: NSHashTable<EventHandlerWarrper>
    public var host: String
    public var requestHeader: [String: String]
    fileprivate let workQueue: DispatchQueue = {
        return DispatchQueue(label: "com.docs.netQueue", qos: DispatchQoS.userInitiated)
    }()

    public let manager: DocsSessionManager
    
    private var docRequestRetrier: DocRequestRetrier?
    
    private let userResolver: UserResolver

    public init(host: String, requestHeader: [String: String], timeoutInterval: TimeInterval = 8, userResolver: UserResolver) {
        spaceAssert(!host.isEmpty)
        self.userResolver = userResolver
        self.host = host
        self.requestHeader = requestHeader

        self.manager = DocsSessionManager(host: host, requestHeader: requestHeader, timeoutInterval: timeoutInterval, userResolver: userResolver)

        self.eventHandlers = NSHashTable(options: .strongMemory)
        super.init()

        self.docRequestRetrier = DocRequestRetrier(netWorkSession: self)

        self.manager.docRequestRetrier = docRequestRetrier
    }

    public func cookies() -> [HTTPCookie]? {
        guard let url = URL(string: self.host), let storage = manager.httpCookieStorage else { return nil }
        return storage.cookies(for: url)
    }

//    class public func makeDocsRequest(with file: String?, headers: [String: String]?) -> URLRequest? {
//        guard let file = file, let openURL = URL(string: file) else {
//            spaceAssertionFailure("Invalid URL")
//            return nil
//        }
//        var request = URLRequest(url: openURL)
//        headers?.forEach({ (key, value) in
//            request.setValue(value, forHTTPHeaderField: key)
//        })
//        return request
//    }

    func addSessionEventHandler(_ handler: SessionEventHandler?) {
        workQueue.async {
            guard let handler = handler else { return }
            self.eventHandlers.add(EventHandlerWarrper(handler))
        }
    }

    func removeSessionEventHandler(_ request: URLRequest?) {
        workQueue.async {
            guard let request = request else { return }
            guard let index = self.eventHandlerIndexFor(request) else { return }
            guard self.eventHandlers.allObjects.count > index else { return }
            self.eventHandlers.remove(self.eventHandlers.allObjects[index])
        }
    }

    fileprivate func eventHandlerIndexFor(_ request: URLRequest?) -> Int? {
        guard let request = request else { return nil }
        
        
        //为false默认打开，后续去掉fg，要保持这里的清除方法
        //背景：https://bytedance.feishu.cn/wiki/YBLcwWbadiBGRokekC5cM2ifnkf
        if !UserScopeNoChangeFG.HZK.disableNetworkRetryOptimize {
            eventHandlers.allObjects.forEach { wrapper in
                if wrapper.target?.request() == nil {
                    eventHandlers.remove(wrapper)
                }
            }
        }
        
        let index = eventHandlers.allObjects.firstIndex { (wrapper) -> Bool in
            guard let targetRequest = wrapper.target?.request() else {
                return false
            }
            return targetRequest == request
        }
        return index
    }
}

extension NetworkSession: DocsRequestContext {
    public var useRust: Bool {
        return self.manager.useRust
    }
    
    public var session: NetworkSession {
        return self
    }

    public var header: [String: String] {
        return self.requestHeader
    }

    public func authorizationRequired(_ session: String?) {
        if session == self.identifier {
            self.identifier = nil
            DispatchQueue.main.async {
                self.authDelegate?.handleAuthenticationChallenge()
            }
        }
    }
}

class DocRequestRetrier: NSObject, RequestRetrier, DocsInternalRequestRetrier {
    
    weak var netWorkSession: NetworkSession?
    init(netWorkSession: NetworkSession?) {
        self.netWorkSession = netWorkSession
    }
    
    //原来 Alamofire的是否需要重试逻辑回调
    public func should(_ manager: SessionManager, retry request: Alamofire.Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        netWorkSession?.workQueue.async { [weak self] in
            guard let self = self else {
                completion(false, 0)
                return
            }
            
            guard let index = self.netWorkSession?.eventHandlerIndexFor(request.request) else {
                completion(false, 0)
                return
            }
            
            guard self.netWorkSession?.eventHandlers.allObjects.count ?? 0 > index else {
                completion(false, 0)
                return
            }

            let wrapper = self.netWorkSession?.eventHandlers.allObjects[index]
            wrapper?.target?.should(manager, retry: request.request, currentRetryCount: request.retryCount, with: error, completion: completion)
        }
    }
    
    //直连rust 的是否需要重试逻辑回调
    func should(retry request: URLRequest, currentRetryCount: UInt, with error: Error, completion: @escaping Alamofire.RequestRetryCompletion) {
        netWorkSession?.workQueue.async { [weak self] in
            guard let self = self else {
                completion(false, 0)
                return
            }
            guard let index = self.netWorkSession?.eventHandlerIndexFor(request) else {
                completion(false, 0)
                return
            }
            
            guard self.netWorkSession?.eventHandlers.allObjects.count ?? 0 > index else {
                completion(false, 0)
                return
            }

            let wrapper = self.netWorkSession?.eventHandlers.allObjects[index]
            wrapper?.target?.should(nil, retry: request, currentRetryCount: currentRetryCount, with: error, completion: completion)
        }
    }
}

struct DocsRequestAdapter: RequestAdapter {
    
    let userResolver: UserResolver
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    public func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var request = urlRequest
        request.retryCount = 3
        if urlRequest.httpMethod?.lowercased() == "get" {
            request.enableComplexConnect = true
        } else if urlRequest.httpMethod?.lowercased() == "post" && SKFoundationConfig.shared.useComplexConnectionForPost == true {
            request.enableComplexConnect = true
        }

        request.url.map {
            if request.allHTTPHeaderFields?[DocsCustomHeader.xCommandID.rawValue] == nil {
                request.addValue(xCommandFor($0), forHTTPHeaderField: DocsCustomHeader.xCommandID.rawValue)
            }
            
            if UserScopeNoChangeFG.HZK.enableCsrfVerification { //安全需求，所有请求都加上csrfToken
                if request.allHTTPHeaderFields?[DocsCustomHeader.csrfToken.rawValue] == nil,
                   let url = request.url {
                    let allCookies = HTTPCookieStorage.shared.cookies(for: url)
                    if let csrfCookie = allCookies?.first(where: { (cookie) -> Bool in
                        guard let ame = cookie.properties?[HTTPCookiePropertyKey.name] as? String else { return false }
                        return ame == DocsCookiesName.csrfToken.rawValue
                    }) {
                        let value = csrfCookie.value
                        request.setValue(value, forHTTPHeaderField: DocsCustomHeader.csrfToken.rawValue)
                    }
                }
            } else {
                if request.allHTTPHeaderFields?[DocsCustomHeader.fromSource.rawValue] == DocsCustomHeaderValue.fromMobileWeb,
                   request.allHTTPHeaderFields?[DocsCustomHeader.csrfToken.rawValue] == nil,
                   let url = request.url {
                    let allCookies = HTTPCookieStorage.shared.cookies(for: url)
                    if let csrfCookie = allCookies?.first(where: { (cookie) -> Bool in
                        guard let ame = cookie.properties?[HTTPCookiePropertyKey.name] as? String else { return false }
                        return ame == DocsCookiesName.csrfToken.rawValue
                    }) {
                        let value = csrfCookie.value
                        request.setValue(value, forHTTPHeaderField: DocsCustomHeader.csrfToken.rawValue)
                    }
                }
            }
            request.addValue("docs", forHTTPHeaderField: "called_from")
        }

        request = DocsCustomHeader.addCookieHeaderIfNeed(request, userResolver: userResolver)

        return request
    }

    private func xCommandFor(_ url: URL) -> String {
        return url.pathComponents.dropFirst().map { $0.count < 22 ? $0 : "" }.joined(separator: ".")
    }
}
