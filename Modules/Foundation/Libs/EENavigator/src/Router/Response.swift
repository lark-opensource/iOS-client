//
//  Response.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/6.
//

import Foundation

public protocol Resource {
    var identifier: String? { get set }
}

public struct EmptyResource: Resource {
    public var identifier: String?

    public init() {}
}

public typealias RedirectHandler = (URL, [String: Any]) -> Void

/// the open behavior use model that confirm to Request-Respone. This class define the response behavior for the route.
public final class Response {
    /// Status of response
    ///
    /// - handling: handling the reques
    /// - pending: the request is pending, and will be handled in the future
    /// - ended: the request is handled, and get the resource for the response
    public enum Status {
        case handling, pending, ended
    }

    /// Resource
    public private(set) var resource: Resource?
    /// Error from routes or middlewares
    public private(set) var error: RouterError?
    /// Associated request
    public let request: Request
    /// Status
    public private(set) var status: Status = .handling

    /// Redirect times
    var redirectTimes: Int = 0
    /// Save the context of sync redirect
    var redirectContext: (URL, [String: Any])?
    /// Async redirect handler
    var asyncRedirectHandler: RedirectHandler?

    public var parameters: [String: Any] {
        return request.parameters
    }

    public init(request: Request) {
        self.request = request
    }

    /// Redirect using model
    ///
    /// - Parameters:
    ///   - body: redirect requst body
    ///   - naviParams: navigation parameters
    ///   - context: 
    public func redirect<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        context: [String: Any] = [:]
    ) {
        var context = context.merging(body: body)
        context.merge(request.context) { (current, _) in current }
        if let naviParams = naviParams {
            context[ContextKeys.naviParams] = naviParams
        }
        _redirect(body._url, context: context)
    }

    /// Redirect to another url, and the request ends
    ///
    /// - Parameters:
    ///   - url: redirect url
    ///   - context: redirect context
    public func redirect(_ url: URL, context: [String: Any] = [:]) {
        var context = context
        for key in ContextKeys.inheritKeys { // 特殊环境字段始终继承，除非覆盖
            if let value = request.context[key], context.index(forKey: key) == nil {
                context[key] = value
            }
        }
        _redirect(url, context: context)
    }
    private func _redirect(_ url: URL, context: [String: Any] = [:]) {
        var context = context
        context[ContextKeys.redirectTimes] = self.redirectTimes + 1

        if let asyncResult = self.resource as? AsyncResult {
            asyncResult.release()
            self.asyncRedirectHandler?(url, context)
        } else {
            self.redirectContext = (url, context)
            self.status = .ended
        }
    }

    /// Append error, and the request continues
    ///
    /// - Parameter error: error from routes or middlewares
    public func append(error: Error) {
        if self.error == nil {
            self.error = RouterError.empty
        }
        self.error?.append(error)
    }

    /// End the request with error
    ///
    /// - Parameter error: error from routes or middlewares
    public func end(error: Error?, file: String = #fileID, function: String = #function, line: Int = #line) {
        if let error = error {
            self.append(error: error)
        }
        self.status = .ended
        Router.logger.error("end error: \(String(describing: error))", file: file, function: function, line: line)

        if let asyncResult = self.resource as? AsyncResult {
            asyncResult.set(error: error)
        }
        if let routerError = error as? RouterError {
            Monitor.upload(error: routerError)
        }
    }

    /// End with resouce
    ///
    /// - Parameters:
    ///   - resource: resource of the request
    public func end(resource: Resource?, file: String = #fileID, function: String = #function, line: Int = #line) {
        self.status = .ended

        Router.logger.error("end resource", file: file, function: function, line: line)

        var resource = resource
        resource?.identifier = self.request.url.identifier
        if let asyncResult = self.resource as? AsyncResult {
            asyncResult.set(resource: resource)
        } else {
            self.resource = resource
        }
    }

    /// Wait to be handled in the future
    public func wait() {
        self.status = .pending
        // FIXME: asyncResult可能捕获res, 循环引用。不调用end就不会释放..
        self.resource = AsyncResult()
    }
}
