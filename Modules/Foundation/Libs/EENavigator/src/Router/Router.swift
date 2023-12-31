//
//  Router.swift
//  Pods-EENavigator
//
//  Created by liuwanlin on 2018/9/6.
//

import Foundation
import SuiteCodable
import EETroubleKiller
import LKCommonsLogging

extension Middleware {
    fileprivate static var empty: Self {
        return Middleware(
            match: { _ in false },
            handler: { _, _ in fatalError("unreachable code") }
        )
    }
}

let dictionaryDecoder: DictionaryDecoder = {
    let decoder = DictionaryDecoder()
    decoder.decodeTypeStrategy = .loose
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()

open class Router: NSObject, Routable {
    public static let logger = Logger.log(Router.self, category: "Router")

    public enum Priority: Int, Comparable {
        public static func < (lhs: Router.Priority, rhs: Router.Priority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        case low = 500, `default` = 1000, high = 1500
    }

    private struct RouteItem {
        let priority: Priority
        var routes: [Middleware]
    }

    static let maxRedirectTimes = 10

    public var defaultSchemesBlock: () -> [String] = { [] }

    /// locate or pop observers
    private var locateOrPopObservers: [Middleware] = []

    /// Middlewares before routes
    private var preMiddlewares: [Middleware] = []

    /// The middleware for all routes
    private var routeMiddleware: Middleware = .empty
    /// The middleware for all routes tester
    private var testMiddleware: Middleware = .empty
    /// Routes dic
    private var priorityMiddlewaresDic: [Priority: [Middleware]] = [:]
    private var patternMiddlewareDic: [String: Middleware] = [:]

    /// Middlewares after routes
    /// If any routes matched, no post middleware will be matched
    private var postMiddlewares: [Middleware] = []

    /// observers
    private var observerMiddlewares: [Middleware] = []

    /// Cache all handler
    private var handlerCache: [String: Any] = [:]

    var decoder: DictionaryDecoder { dictionaryDecoder }

    public override init() {
        super.init()
        // Create a middleware for all the routes
        self.routeMiddleware = self.makeRouteMiddleware(with: { (route, req, res) in
            route.handler(req, res)
        })
        // Create a middleware for testers
        self.testMiddleware = self.makeRouteMiddleware()
    }

    open func registerRoute_(
        plainPattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping Handler) -> Router {
        registerRoute(plainPattern: plainPattern, priority: priority, tester: tester, routeHandler)
        return self
    }

    /// register a route with a path pattern
    ///
    /// - Parameters:
    ///   - plainPattern: plain pattern, compare pattern with url directly
    ///   - priority: priority
    ///   - tester: test if the request can pass before handler
    ///   - routeHandler: handler for pattern
    open func registerRoute(
        plainPattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping Handler) {

        let pattern = normalize(pattern: plainPattern)
        let route = Middleware(
            plain: pattern,
            tester: tester,
            handler: routeHandler
        )
        self.append(route, with: priority)
    }

    open func registerRoute_(
        pattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping Handler) -> Router {

        registerRoute(pattern: pattern, priority: priority, tester: tester, routeHandler)
        return self
    }

    /// register a route with a path pattern
    ///
    /// - Parameters:
    ///   - pattern: path pattern, such as `//chat/:id`
    ///   - priority: priority
    ///   - tester: test if the request can pass before handler
    ///   - routeHandler: handler for pattern
    open func registerRoute(
        pattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping Handler) {

        let pattern = normalize(pattern: pattern)
        let route = Middleware(
            pattern: pattern,
            tester: tester,
            handler: routeHandler
        )
        self.append(route, with: priority)
    }

    open func registerRoute_(
        regExpPattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping Handler) -> Router {

        registerRoute(regExpPattern: regExpPattern, priority: priority, tester: tester, routeHandler)
        return self
    }

    /// register a route with a custom regular expression
    ///
    /// - Parameters:
    ///   - regExpPattern: custom regular expression pattern
    ///   - priority: priority
    ///   - tester: test if the request can pass before handler
    ///   - routeHandler: handler for pattern
    open func registerRoute(
        regExpPattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping Handler) {

        let route = Middleware(
            regExpPattern: regExpPattern,
            tester: tester,
            handler: routeHandler
        )
        self.append(route, with: priority)
    }

    open func registerRoute_(
        match: @escaping MatchBlock,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping Handler) -> Router {

        registerRoute(match: match, priority: priority, tester: tester, routeHandler)
        return self
    }

    /// register a route with a custom match block
    ///
    /// - Parameters:
    ///   - match: match block
    ///   - priority: priority
    ///   - tester: test if the request can pass before handler
    ///   - routeHandler: handler
    open func registerRoute(
        match: @escaping MatchBlock,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping Handler) {

        let route = Middleware(
            match: match,
            tester: tester,
            handler: routeHandler
        )
        self.append(route, with: priority)
    }

    open func registerObserver_(
        pattern: String = "",
        _ middlewareHandler: @escaping Handler) -> Router {

        registerObserver(pattern: pattern, middlewareHandler)
        return self
    }

    /// register navigator observer, observer will be call after router match
    /// - Parameters:
    ///   - pattern: path pattern, such as `//chat/:id`
    ///   - middlewareHandler: the middleware handler
    open func registerObserver(
        pattern: String = "",
        _ middlewareHandler: @escaping Handler) {

        let pattern = normalize(pattern: pattern)
        let middleware = Middleware(pattern: pattern, handler: middlewareHandler)
        self.append(observer: middleware)
    }

    open func registerObserver_(
        regExpPattern: String,
        _ middlewareHandler: @escaping Handler) -> Router {

        registerObserver(regExpPattern: regExpPattern, middlewareHandler)
        return self
    }

    /// register navigator observer, observer will be call after router match
    /// - Parameters:
    ///   - regExpPattern: custom regular expression pattern
    ///   - middlewareHandler: the middleware handler
    open func registerObserver(
        regExpPattern: String,
        _ middlewareHandler: @escaping Handler) {

        let middleware = Middleware(regExpPattern: regExpPattern, handler: middlewareHandler)
        self.append(observer: middleware)
    }

    private func append(observer: Middleware) {
        self.observerMiddlewares.append(observer)
    }

    open func registerMiddleware_(
        pattern: String = "",
        postRoute: Bool = false,
        _ middlewareHandler: @escaping Handler) -> Router {
        registerMiddleware(pattern: pattern, postRoute: postRoute, middlewareHandler)
        return self
    }

    /// register a middleware with a path pattern
    ///
    /// - Parameters:
    ///   - pattern: path pattern, such as `//chat/:id`
    ///   - postRoute: middlewares are after routes map or not
    ///   - middlewareHandler: the middleware handler
    open func registerMiddleware(
        pattern: String = "",
        postRoute: Bool = false,
        _ middlewareHandler: @escaping Handler) {

        let pattern = normalize(pattern: pattern)
        let middleware = Middleware(pattern: pattern, handler: middlewareHandler)
        self.append(middleware, postRoute: postRoute)
    }

    open func registerMiddleware_(
        regExpPattern: String,
        postRoute: Bool = false,
        _ middlewareHandler: @escaping Handler) -> Router {

        registerMiddleware(regExpPattern: regExpPattern, postRoute: postRoute, middlewareHandler)
        return self
    }

    /// register a middleware with a custom regular expression
    ///
    /// - Parameters:
    ///   - regExpPattern: a custom regular expression pattern
    ///   - postRoute: the middleware is after routes map or not
    ///   - middlewareHandler: the middleware handler
    open func registerMiddleware(
        regExpPattern: String,
        postRoute: Bool = false,
        _ middlewareHandler: @escaping Handler) {

        let middleware = Middleware(regExpPattern: regExpPattern, handler: middlewareHandler)
        self.append(middleware, postRoute: postRoute)
    }

    open func registerLocateOrPopObserver_(
        pattern: String = "",
        _ locateOrPopObserverHandler: @escaping Handler) -> Router {

        registerLocateOrPopObserver(pattern: pattern, locateOrPopObserverHandler)
        return self
    }

    /// register a locateOrPopObserver with a custom regular expression
    ///
    /// - Parameters:
    ///   - pattern: path pattern, such as `//chat/:id`
    ///   - locateOrPopObserverHandler: the locateOrPopObserver handler
    open func registerLocateOrPopObserver(
        pattern: String = "",
        _ locateOrPopObserverHandler: @escaping Handler) {

        let pattern = normalize(pattern: pattern)
        let locateOrPopObserver = Middleware(pattern: pattern, handler: locateOrPopObserverHandler)
        self.append(locateOrPopObserver: locateOrPopObserver)
    }

    /// deregister route with a path pattern
    ///
    /// - Parameter pattern: a path pattern
    open func deregisterRoute(_ pattern: String) {
        guard patternMiddlewareDic[pattern] != nil else { return }
        let pattern = normalize(pattern: pattern)
        self.priorityMiddlewaresDic.forEach { (key, value) in
            let newValue = value.filter { $0.pattern != pattern }
            priorityMiddlewaresDic[key] = newValue.isEmpty ? nil : newValue
        }
        patternMiddlewareDic[pattern] = nil
    }

    /// deregister middleware with a path pattern
    ///
    /// - Parameter pattern: a path pattern
    open func deregisterMiddleware(_ pattern: String) {
        let pattern = normalize(pattern: pattern)

        self.preMiddlewares = self.preMiddlewares.filter {
            $0.pattern != pattern
        }
        self.postMiddlewares = self.postMiddlewares.filter {
            $0.pattern != pattern
        }
    }

    /// deregister middleware with a path pattern
    ///
    /// - Parameter pattern: a path pattern
    open func deregisterLocateOrPopObserver(_ pattern: String) {
        let pattern = normalize(pattern: pattern)

        self.locateOrPopObservers = self.locateOrPopObservers.filter {
            $0.pattern != pattern
        }
    }

    open func notifyLocateOrPopObservers(for url: URL, context: [String: Any] = [:]) {
        let url = self.normalize(url)
        let response = self.initResponse(for: url, context: context)
        for observer in locateOrPopObservers {
            let result = observer.matcher.match(url: url)
            if result.matched {
                observer.handler(response.request, response)
            }
        }
    }

    /// Send a request and get the response
    ///
    /// - Parameters:
    ///   - url: url of the request
    ///   - context: context
    ///   - test: test only if true
    /// - Returns: response
    open func response(for url: URL, context: [String: Any] = [:], test: Bool = false) -> Response {
        Router.logger.debug("Get resoourse from logger: \(url.absoluteString.hashValue)")

        let url = self.normalize(url)
        // Empty response
        let response = self.initResponse(for: url, context: context)

        // Too many redirects error
        if response.redirectTimes >= Router.maxRedirectTimes {
            response.end(error: RouterError.tooManyRedirects.patchExtraInfo(with: url.absoluteString,
                                                                            from: context.from(),
                                                                            naviParams: context.naviParams))
            self.excute(observers: self.observerMiddlewares, req: response.request, res: response)
            return response
        }

        // Add async redirect handler
        if let asyncRedierct = context[ContextKeys.acyncRedirect] as? RedirectHandler {
            response.asyncRedirectHandler = asyncRedierct
        }

        let middlewares: [Middleware] = test ?
            (preMiddlewares + [testMiddleware]) :
            (preMiddlewares + [routeMiddleware] + postMiddlewares)

        // Excute middlewares
        self.excute(middlewares, req: response.request, res: response)

        // Sync redirect
        if let redirectContext = response.redirectContext {
            return self.response(for: redirectContext.0, context: redirectContext.1)
        }
        self.excute(observers: self.observerMiddlewares, req: response.request, res: response)
        return response
    }

    /// Check whether resource can be found with url
    ///
    /// - Parameter of: the url for the resource
    /// - Returns: can be opened or not
    open func contains(_ url: URL, context: [String: Any] = [:]) -> Bool {
        let response = self.response(for: url, context: context, test: true)
        return (response.parameters[ContextKeys.matched] as? Bool) == true
    }

    /// Clear all the handlers in the cache
    public func clearHandlerCache() {
        self.handlerCache = [:]
    }

    func getCachedHandler(for key: String) -> Any? {
        return self.handlerCache[key]
    }

    func addHandlerToCache(_ handler: Any, for key: String) {
        self.handlerCache[key] = handler
    }

    func initResponse(for url: URL, context: [String: Any] = [:]) -> Response {
        let url = self.normalize(url).schemeAndHostLowercased

        // Create request
        let request = Request(url: url, context: context)

        // Create response
        let response = Response(request: request)

        // Redirect times
        if let redirectTimes = context[ContextKeys.redirectTimes] as? Int {
            response.redirectTimes = redirectTimes
        }

        return response
    }

    private func makeRouteMiddleware(with match: ((Middleware, Request, Response) -> Void)? = nil) -> Middleware {
        return Middleware(pattern: star, handler: { [weak self] (req, res) in
            guard let self = self else { return }
            if let route = self.allRoutes().first(where: { (route) -> Bool in
                let result = route.matcher.match(url: req.url)
                if result.matched {
                    req.context[ContextKeys.matchedParameters] = result.params
                    req.context[ContextKeys.matchedGroups] = result.groups
                    req.context[ContextKeys.matchedPattern] = route.pattern
                    if route.tester(req) {
                        req.context[ContextKeys.matched] = true
                        return true
                    }
                    return false
                }
                return false
            }) {
                match?(route, req, res)
            }
        })
    }

    // All routes, sorted by priority descending order
    func allRoutes() -> [Middleware] {
        priorityMiddlewaresDic.sorted { $0.key > $1.key }.flatMap { $0.value }
    }

    private func append(_ middleware: Middleware, postRoute: Bool) {
        if postRoute {
            self.postMiddlewares.append(middleware)
        } else {
            self.preMiddlewares.append(middleware)
        }
    }

    func append(locateOrPopObserver: Middleware) {
        self.locateOrPopObservers.append(locateOrPopObserver)
    }

    /// Should be called only inside Router. Set it to internal (other than private ) just for perfomance test purpose.
    func append(_ route: Middleware, with priority: Priority) {
        assert(Thread.isMainThread, "should occur on main thread!")
        guard patternMiddlewareDic[route.pattern] == nil else {
            assertionFailure("Route with pattern [\(route.pattern)] has already been registered")
            return
        }
        patternMiddlewareDic[route.pattern] = route
        if priorityMiddlewaresDic[priority] != nil {
            priorityMiddlewaresDic[priority]?.append(route)
        } else {
            priorityMiddlewaresDic[priority] = [route]
        }
    }

    private func excute(_ middlewares: [Middleware], req: Request, res: Response) {
        for middleware in middlewares {
            let result = middleware.matcher.match(url: req.url)
            if result.matched {
                req.context[ContextKeys.matchedGroups] = result.groups
                middleware.handler(req, res)
                if let resource = res.resource {
                    TroubleKiller.pet.triggerRoute(target: resource, domainKey: [
                        "url": req.url.logInfo
                    ])
                }
            }
            if res.status != .handling {
                break
            }
        }
        if res.status == .handling {
            res.end(error: RouterError.notHandled.patchExtraInfo(with: req.url.absoluteString,
                                                                 from: req.from,
                                                                 naviParams: req.context.naviParams))
        }
    }

    private func excute(observers: [Middleware], req: Request, res: Response) {
        for observer in observers {
            let result = observer.matcher.match(url: req.url)
            if result.matched {
                req.context[ContextKeys.matchedGroups] = result.groups
                observer.handler(req, res)
            }
        }
    }

    func normalize(pattern: String) -> String {
        return pattern.asPattern().standardized().rawValue
    }

    func normalize(_ url: URL) -> URL {
        if var components = SafeURLComponents(url: url, resolvingAgainstBaseURL: false) {
            // Remove default scheme
            let isDefaultScheme = defaultSchemesBlock().contains { (scheme) -> Bool in
                return scheme.lowercased() == url.scheme?.lowercased()
            }
            if isDefaultScheme {
                components.scheme = nil
            }
            if (components.queryItems ?? []).isEmpty {
                components.queryItems = nil
            }
            return components.url ?? url
        }
        return url
    }
}

/// 方便包装Router的协议，提供核心使用接口的声明和统一的protocol方法扩展
public protocol Routable {
    /// Send a request and get the response
    ///
    /// - Parameters:
    ///   - url: url of the request
    ///   - context: context
    ///   - test: test only if true
    /// - Returns: response
    func response(for url: URL, context: [String: Any], test: Bool) -> Response
    /// Check whether resource can be found with url
    ///
    /// - Parameter of: the url for the resource
    /// - Returns: can be opened or not
    func contains(_ url: URL, context: [String: Any]) -> Bool
}
