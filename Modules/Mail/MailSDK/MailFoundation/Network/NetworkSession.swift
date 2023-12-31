//
//  Docs.swift
//  MailNetwork
//
//  Created by weidong fu on 24/11/2017.
//

import Foundation
import Alamofire
import SwiftyJSON
import LarkRustHTTP

public protocol NetworkAuthDelegate: AnyObject {
    func handleAuthenticationChallenge()
}

protocol SessionEventHandler: AnyObject {
    func request() -> URLRequest?
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion)
}

class MailEventHandlerWarrper {
    weak var target: SessionEventHandler?
    init(_ target: SessionEventHandler) {
        self.target = target
    }
}

final class NetworkSession {
    weak var authDelegate: NetworkAuthDelegate?
    var identifier: String?
    fileprivate var eventHandlers: NSHashTable<MailEventHandlerWarrper>
    var host: String
    var requestHeader: [String: String]
    fileprivate let workQueue: DispatchQueue = {
        return DispatchQueue(label: "com.mail.netQueue", qos: DispatchQoS.userInitiated)
    }()
    private static var isEnableRust: Bool = {
        return MailSDKManager.isEnableRustHttp
    }()
    let manager: SessionManager
    private(set) var useRust: Bool = false

    init(host: String, requestHeader: [String: String], timeoutInterval: TimeInterval = 8, forceNoRust: Bool = false ) {
        self.host = host
        self.requestHeader = requestHeader
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.httpAdditionalHeaders?.merge(other: requestHeader)
        if useRust {
            configuration.timeoutIntervalForRequest = 60
        } else {
            configuration.timeoutIntervalForRequest = timeoutInterval
        }

        self.manager = SessionManager(configuration: configuration, delegate: MailSessionDelegate())
        manager.adapter = MailRequestAdapter()

        self.eventHandlers = NSHashTable(options: .strongMemory)
        self.manager.retrier = self
    }

    func cookies() -> [HTTPCookie]? {
        guard let url = try? URL.forceCreateURL(string: self.host), let storage = manager.session.configuration.httpCookieStorage else { return nil }
        return storage.cookies(for: url)
    }

    class func makeMailRequest(with file: String?, headers: [String: String]?) -> URLRequest? {
        guard let file = file, let openURL = URL(string: file) else {
            return nil
        }
        var request = URLRequest(url: openURL)
        headers?.forEach({ (key, value) in
            request.setValue(value, forHTTPHeaderField: key)
        })
        return request
    }

    func addSessionEventHandler(_ handler: SessionEventHandler?) {
        workQueue.async {
            guard let handler = handler else { return }
            self.eventHandlers.add(MailEventHandlerWarrper(handler))
        }
    }

    func removeSessionEventHandler(_ handler: SessionEventHandler?) {
        workQueue.async {
            guard let handler = handler else { return }
            guard let index = self.eventHandlerIndexFor(handler.request()) else { return }
            self.eventHandlers.remove(self.eventHandlers.allObjects[index])
        }
    }

    fileprivate func eventHandlerIndexFor(_ request: URLRequest?) -> Int? {
        guard let request = request else { return nil }
        let index = eventHandlers.allObjects.firstIndex { (wrapper) -> Bool in
            guard let targetRequest = wrapper.target?.request() else { return false }
            return targetRequest == request
        }
        return index
    }
}

extension NetworkSession: MailRequestContext {
    var session: NetworkSession {
        return self
    }

    var header: [String: String] {
        return self.requestHeader
    }

    func authorizationRequired(_ session: String?) {
        if session == self.identifier {
            self.identifier = nil
            DispatchQueue.main.async {
                self.authDelegate?.handleAuthenticationChallenge()
            }
        }
    }
}

extension NetworkSession: RequestRetrier {
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        workQueue.async {
            guard let index = self.eventHandlerIndexFor(request.request) else {
                completion(false, 0)
                return
            }

            let wrapper = self.eventHandlers.allObjects[index]
            wrapper.target?.should(manager, retry: request, with: error, completion: completion)
        }
    }
}

private struct MailRequestAdapter: RequestAdapter {
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var request = urlRequest
        request.retryCount = 3
        if urlRequest.httpMethod?.lowercased() == "get" {
            request.enableComplexConnect = true
        }
        return request
    }
}
