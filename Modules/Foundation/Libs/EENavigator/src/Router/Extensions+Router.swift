//
//  Extensions+Router.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/12/29.
//

import Foundation

public protocol RouterHandler {
    func handle(req: Request, res: Response)
}

public typealias MiddlewareHandler = RouterHandler
public typealias LocateOrPopObserverHandler = RouterHandler

open class TypedRouterHandler<T: Body> {
    public typealias BodyType = T

    public init() {}

    open func handle(_ body: T, req: Request, res: Response) {
        assertionFailure("must override")
    }
}

extension Router {
    func registerRoute<T: Body>(
        type: T.Type, priority: Priority, tester: @escaping Tester, _ handler: @escaping Handler
    ) {
        let config = type.patternConfig
        switch config.type {
        case .path:
            self.registerRoute(pattern: config.pattern, priority: priority, tester: tester, handler)
        case .plain:
            self.registerRoute(plainPattern: config.pattern, priority: priority, tester: tester, handler)
        case .regex:
            self.registerRoute(regExpPattern: config.pattern, priority: priority, tester: tester, handler)
        }
    }

    public func registerRoute_<T: Body>(
        type: T.Type,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping (T, Request, Response) -> Void) -> Router {

        registerRoute(type: type, priority: priority, tester: tester, routeHandler)
        return self
    }

    /// register a route with type
    ///
    /// - Parameters:
    ///   - type: metadata of a type
    ///   - priority: priority
    ///   - tester: test if the request can pass before handler
    ///   - routeHandler: handler for pattern
    public func registerRoute<T: Body>(
        type: T.Type,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping (T, Request, Response) -> Void) {

        let handler = self.wrapCheckParameters(type: type, handler: routeHandler)
        self.registerRoute(type: type, priority: priority, tester: tester, handler)
    }

    public func registerRoute_<T: Body>(
        type: T.Type,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        cacheHandler: Bool = false,
        factory: @escaping () -> TypedRouterHandler<T>) -> Router {

        registerRoute(type: type, priority: priority, tester: tester, cacheHandler: cacheHandler, factory: factory)
        return self
    }

    /// register a route with type and typed router handler
    ///
    /// - Parameters:
    ///   - type: metadata of a type
    ///   - priority: priority
    ///   - tester: test if the request can pass before handler
    ///   - cacheHandler: cache router handler or not
    ///   - factory: fatory or typed router handler
    public func registerRoute<T: Body>(
        type: T.Type,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        cacheHandler: Bool = false,
        factory: @escaping () -> TypedRouterHandler<T>) {

        let factory = wrapFactory(factory, cacheHandler: cacheHandler)
        self.registerRoute(type: type, priority: priority, tester: tester) { body, req, res in
            factory().handle(body, req: req, res: res)
        }
    }

    public func registerRoute_<T: RouterHandler>(
        plainPattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        cacheHandler: Bool = false,
        factory: @escaping () -> T) -> Router {

        registerRoute(plainPattern: plainPattern, priority: priority, tester: tester, cacheHandler: cacheHandler, factory: factory)
        return self
    }

    /// register a route with a path pattern and typed router handler
    ///
    /// - Parameters:
    ///   - plainPattern: plain pattern, compare pattern with url directly
    ///   - priority: priority
    ///   - tester: test if the request can pass before handler
    ///   - cacheHandler: cache router handler or not
    ///   - factory: fatory or typed router handler
    public func registerRoute<T: RouterHandler>(
        plainPattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        cacheHandler: Bool = false,
        factory: @escaping () -> T) {

        let factory = wrapFactory(factory, cacheHandler: cacheHandler)
        self.registerRoute(plainPattern: plainPattern, priority: priority, tester: tester) { (req, res) in
            factory().handle(req: req, res: res)
        }
    }

    /// register a route with a path pattern and typed router handler
    ///
    /// - Parameters:
    ///   - pattern: path pattern, such as `//chat/:id`
    ///   - priority: priority
    ///   - tester: test if the request can pass before handler
    ///   - cacheHandler: cache router handler or not
    ///   - factory: fatory or typed router handler
    public func registerRoute<T: RouterHandler>(
        pattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        cacheHandler: Bool = false,
        factory: @escaping () -> T) {

        let factory = wrapFactory(factory, cacheHandler: cacheHandler)
        self.registerRoute(pattern: pattern, priority: priority, tester: tester) { (req, res) in
            factory().handle(req: req, res: res)
        }
    }

    public func registerRoute_<T: RouterHandler>(
        regExpPattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        cacheHandler: Bool = false,
        factory: @escaping () -> T) -> Router {

        registerRoute(regExpPattern: regExpPattern, priority: priority, tester: tester, cacheHandler: cacheHandler, factory: factory)
        return self
    }

    /// register a route with a custom regular expression and typed router handler
    ///
    /// - Parameters:
    ///   - regExpPattern: custom regular expression pattern
    ///   - priority: priority
    ///   - tester: test if the request can pass before handler
    ///   - cacheHandler: cache router handler or not
    ///   - factory: fatory or typed router handler
    public func registerRoute<T: RouterHandler>(
        regExpPattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        cacheHandler: Bool = false,
        factory: @escaping () -> T) {

        let factory = wrapFactory(factory, cacheHandler: cacheHandler)
        self.registerRoute(regExpPattern: regExpPattern, priority: priority, tester: tester) { (req, res) in
            factory().handle(req: req, res: res)
        }
    }

    public func registerRoute_<T: RouterHandler>(
        match: @escaping MatchBlock,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        cacheHandler: Bool = false,
        factory: @escaping () -> T) -> Router {

        registerRoute(match: match, priority: priority, tester: tester, cacheHandler: cacheHandler, factory: factory)
        return self
    }

    /// register a route with a custom match block and typed router handler
    ///
    /// - Parameters:
    ///   - match: match block
    ///   - priority: priority
    ///   - tester: test if the request can pass before handler
    ///   - cacheHandler: cache router handler or not
    ///   - factory: fatory or typed router handler
    public func registerRoute<T: RouterHandler>(
        match: @escaping MatchBlock,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        cacheHandler: Bool = false,
        factory: @escaping () -> T) {

        let factory = wrapFactory(factory, cacheHandler: cacheHandler)
        self.registerRoute(match: match, priority: priority, tester: tester) { (req, res) in
            factory().handle(req: req, res: res)
        }
    }

    public func registerMiddleware_(
        pattern: String = "",
        postRoute: Bool = false,
        cacheHandler: Bool = false,
        factory: @escaping () -> MiddlewareHandler) -> Router {

        registerMiddleware(pattern: pattern, postRoute: postRoute, cacheHandler: cacheHandler, factory: factory)
        return self
    }

    /// register a middleware with a path pattern
    ///
    /// - Parameters:
    ///   - pattern: path pattern, such as `//chat/:id`
    ///   - postRoute: middlewares are after routes map or not
    ///   - cacheHandler: cache the handler or not
    ///   - factory: middleware handler factory
    public func registerMiddleware(
        pattern: String = "",
        postRoute: Bool = false,
        cacheHandler: Bool = false,
        factory: @escaping () -> MiddlewareHandler) {

        let key = pattern + "-\(UUID().hashValue)"
        let factory = wrapFactory(factory, cacheHandler: cacheHandler, key: key)
        self.registerMiddleware(pattern: pattern, postRoute: postRoute) { (req, res) in
            factory().handle(req: req, res: res)
        }
    }

    public func registerMiddleware_(
        regExpPattern: String,
        postRoute: Bool = false,
        cacheHandler: Bool = false,
        factory: @escaping () -> MiddlewareHandler) -> Router {

        registerMiddleware(regExpPattern: regExpPattern, postRoute: postRoute, cacheHandler: cacheHandler, factory: factory)
        return self
    }

    /// register a middleware with a custom regular expression
    ///
    /// - Parameters:
    ///   - regExpPattern: a custom regular expression pattern
    ///   - postRoute: middlewares are after routes map or not
    ///   - cacheHandler: cache the handler or not
    ///   - factory: middleware handler factory
    public func registerMiddleware(
        regExpPattern: String,
        postRoute: Bool = false,
        cacheHandler: Bool = false,
        factory: @escaping () -> MiddlewareHandler) {

        let key = regExpPattern + "-\(UUID().hashValue)"
        let factory = wrapFactory(factory, cacheHandler: cacheHandler, key: key)
        self.registerMiddleware(regExpPattern: regExpPattern, postRoute: postRoute) { (req, res) in
            factory().handle(req: req, res: res)
        }
    }

    public func registerObserver_(
        pattern: String = "",
        cacheHandler: Bool = false,
        factory: @escaping () -> MiddlewareHandler) -> Router {

        registerLocateOrPopObserver(pattern: pattern, cacheHandler: cacheHandler, factory: factory)
        return self
    }

    /// register navigator observer, observer will be call after router match
    /// - Parameters:
    ///   - pattern: path pattern, such as `//chat/:id`
    ///   - cacheHandler: cache the handler or not
    ///   - factory: middleware handler factory
    public func registerObserver(
        pattern: String = "",
        cacheHandler: Bool = false,
        factory: @escaping () -> MiddlewareHandler) {
        let key = pattern + "-\(UUID().hashValue)"
        let factory = wrapFactory(factory, cacheHandler: cacheHandler, key: key)
        self.registerObserver(pattern: pattern) { (req, res) in
            factory().handle(req: req, res: res)
        }
    }

    public func registerObserver_(
        regExpPattern: String,
        cacheHandler: Bool = false,
        factory: @escaping () -> MiddlewareHandler) -> Router {

        registerObserver(regExpPattern: regExpPattern, cacheHandler: cacheHandler, factory: factory)
        return self
    }

    /// register navigator observer, observer will be call after router match
    /// - Parameters:
    ///   - regExpPattern: custom regular expression pattern
    ///   - cacheHandler: cache the handler or not
    ///   - factory: middleware handler factory
    public func registerObserver(
        regExpPattern: String,
        cacheHandler: Bool = false,
        factory: @escaping () -> MiddlewareHandler) {

        let key = regExpPattern + "-\(UUID().hashValue)"
        let factory = wrapFactory(factory, cacheHandler: cacheHandler, key: key)
        self.registerObserver(regExpPattern: regExpPattern) { (req, res) in
            factory().handle(req: req, res: res)
        }
    }

    public func registerLocateOrPopObserver_(
        pattern: String = "",
        cacheHandler: Bool = false,
        factory: @escaping () -> LocateOrPopObserverHandler) -> Router {

        registerLocateOrPopObserver(pattern: pattern, cacheHandler: cacheHandler, factory: factory)
        return self
    }

    /// register a locateOrPopObserver with a path pattern
    ///
    /// - Parameters:
    ///   - pattern: path pattern, such as `//chat/:id`
    ///   - cacheHandler: cache the handler or not
    ///   - factory: middleware handler factory
    public func registerLocateOrPopObserver(
        pattern: String = "",
        cacheHandler: Bool = false,
        factory: @escaping () -> LocateOrPopObserverHandler) {

        let key = "LocateOrPopObserver-" + pattern + "-\(UUID().hashValue)"
        let factory = wrapFactory(factory, cacheHandler: cacheHandler, key: key)
        self.registerLocateOrPopObserver(pattern: pattern) { (req, res) in
            factory().handle(req: req, res: res)
        }
    }

    func wrapFactory<T>(_ factory: @escaping () -> T, cacheHandler: Bool, key: String? = nil) -> () -> T {
        if cacheHandler {
            let key = key ?? String(UInt(bitPattern: ObjectIdentifier(T.self)))
             return { [unowned self] in
                if let handler = self.getCachedHandler(for: key) as? T {
                    return handler
                }
                let handler = factory()
                self.addHandlerToCache(handler, for: key)
                return handler
            }
        }
        return factory
    }

    func wrapCheckParameters<T: Body>(
        type: T.Type,
        handler: @escaping (T, Request, Response) -> Void) -> Handler {
        return { req, res in
            guard let body: T = T.getBody(req: req) else {
                res.end(error: req.invalidBodyError())
                return
            }
            handler(body, req, res)
        }
    }
}

extension Routable {
    /// Send a request body and get the response
    ///
    /// - Parameters:
    ///   - body: reqest body
    ///   - test: test only if true
    /// - Returns: response
    public func response<T: Body>(for body: T, test: Bool = false) -> Response {
        let context = [String: Any](body: body)
        return self.response(for: body._url, context: context, test: test)
    }
    public func response(for url: URL, context: [String: Any] = [:]) -> Response {
        return self.response(for: url, context: context, test: false)
    }
}
