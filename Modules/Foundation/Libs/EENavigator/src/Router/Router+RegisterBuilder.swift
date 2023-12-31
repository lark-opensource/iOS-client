//
//  Router+RegisterBuilder.swift
//  EENavigator
//
//  Created by SolaWing on 2022/8/26.
//
// 目前Router注册包含4种pattern，2种body，2种对象封装，还可能有User的扩展封装，且都可以自由组合..
// 组合数太多了，因此提供builder，简化相关API的提供和扩展能力.

import Foundation

// swiftlint:disable missing_docs

extension Router {
    /// 注册路由，返回可继续构造的Builder
    public var registerRoute: RouterRegisterBuilder0 { .init(router: self) }
    public var registerMiddleware: RouteMiddlewareBuilder { .init(base: .init(router: self)) }
    public var registerObserver: RouteObserverBuilder { .init(base: .init(router: self)) }
    public var registerLocateOrPopObserver: RouteLocateOrPopObserverBuilder { .init(base: .init(router: self)) }
}

public struct RouterRegisterBuilder0 {
    public var router: Router
    /// - Parameter plainPattern: plain pattern, compare pattern with url directly
    public func plain(_ pattern: String) -> RouterRegisterBuilder {
        .init(base: .init(router: router, pattern: .plain(pattern)))
    }
    /// - Parameter path: path pattern, such as `//chat/:id`
    public func path(_ path: String) -> RouterRegisterBuilder {
        .init(base: .init(router: router, pattern: .path(path)))
    }
    /// - Parameter regex: a custom regular expression pattern
    public func regex(_ pattern: String) -> RouterRegisterBuilder {
        .init(base: .init(router: router, pattern: .regex(pattern)))
    }
    /// - Parameter match: custom match block
    public func match(_ match: @escaping MatchBlock) -> RouterRegisterBuilder {
        .init(base: .init(router: router, pattern: .match(match)))
    }
    /// - Parameter type: BodyType to decide pattern. and handle can also accept the concrete Body type
    public func type<T: Body>(_ type: T.Type) -> RouterRegisterBuilderBody<T> {
        .init(base: .init(router: router, pattern: T.patternConfig.bridge()))
    }
}

public enum RouterMatchPattern {
    case plain(String)
    case path(String)
    case regex(String)
    case match(MatchBlock)
}

public protocol RouterRegisterBuilderType {
    var base: RouterRegisterBuilderBase { get set }
}

public struct RouterRegisterBuilderBase {
    public let router: Router
    public let pattern: RouterMatchPattern
    public var priority: Router.Priority = .default
    public var tester: Tester = defaultTester
}

extension RouterRegisterBuilderType {
    public func tester(_ tester: @escaping Tester) -> Self {
        var `self` = self
        self.base.tester = tester
        return self
    }
    public func priority(_ priority: Router.Priority) -> Self {
        var `self` = self
        self.base.priority = priority
        return self
    }
    // 结束builder

    // FIXME: 这个是缓存会在用户切换时清空，可能需要处理..
    // @discardableResult
    // public func factory<T: RouterHandler>(cache: Bool = false, _ factory: @escaping () -> T) -> Router {
        // let factory = base.router.wrapFactory(factory, cacheHandler: cache)
        // let handler = { factory().handle(req: $0, res: $1) }
        // return handle(handler)
    // }
    @discardableResult
    public func handle(_ handler: @escaping Handler) -> Router {
        switch base.pattern {
        case let .plain(pattern):
            base.router.registerRoute(plainPattern: pattern, priority: base.priority, tester: base.tester, handler)
        case let .path(pattern):
            base.router.registerRoute(pattern: pattern, priority: base.priority, tester: base.tester, handler)
        case let .regex(pattern):
            base.router.registerRoute(regExpPattern: pattern, priority: base.priority, tester: base.tester, handler)
        case let .match(pattern):
            base.router.registerRoute(match: pattern, priority: base.priority, tester: base.tester, handler)
        }
        return base.router
    }
}

public struct RouterRegisterBuilder: RouterRegisterBuilderType {
    public var base: RouterRegisterBuilderBase
}

public struct RouterRegisterBuilderBody<T>: RouterRegisterBuilderType {
    /// NOTE: T: Body, 会导致该泛型类实例化时调用confrom_to_procol, 可能会消耗性能。
    /// 所以不在类型上做泛型约束，而全部加到方法里
    public var base: RouterRegisterBuilderBase
    @discardableResult
    public func handle(_ handler: @escaping (T, Request, Response) -> Void) -> Router where T: Body {
        let handler: Handler = { req, res in
            guard let body: T = T.getBody(req: req) else {
                res.end(error: req.invalidBodyError())
                return
            }
            handler(body, req, res)
        }
        return handle(handler)
    }
    // @discardableResult
    // public func factory(cache: Bool = false, _ factory: @escaping () -> TypedRouterHandler<T>) -> Router where T: Body {
    //     let factory = base.router.wrapFactory(factory, cacheHandler: cache)
    //     let handler = { factory().handle($0, req: $1, res: $2) }
    //     return handle(handler)
    // }
}

fileprivate extension PatternConfig {
    func bridge() -> RouterMatchPattern {
        switch type {
        case .path:
            return .path(pattern)
        case .plain:
            return .plain(pattern)
        case .regex:
            return .regex(pattern)
        }
    }
}

/// 监听拦截路由的通用类型
public struct RouteMiddlewareBuilderBase {
    var router: Router
    var pattern: RouterMatchPattern = .path("")
}

public protocol RouteMiddlewareBuilderType {
    var base: RouteMiddlewareBuilderBase { get set }
    @discardableResult
    func handle(_ handler: @escaping Handler) -> Router
}
extension RouteMiddlewareBuilderType {
    public var router: Router { base.router }
    public func path(_ pattern: String) -> Self {
        var `self` = self
        self.base.pattern = .path(pattern)
        return self
    }
    public func regex(_ regex: String) -> Self {
        var `self` = self
        self.base.pattern = .regex(regex)
        return self
    }
    @discardableResult
    public func factory<T: MiddlewareHandler>(cache: Bool = false, _ factory: @escaping () -> T) -> Router {
        let factory = base.router.wrapFactory(factory, cacheHandler: cache, key: factoryKey())
        handle { factory().handle(req: $0, res: $1) }
        return base.router
    }
    func factoryKey() -> String {
        switch base.pattern {
        case let .path(pattern), let .plain(pattern), let .regex(pattern):
            return pattern + "-\(UUID().hashValue)"
        case .match:
            return "block" + "-\(UUID().hashValue)"
        }
    }
}
public struct RouteMiddlewareBuilder: RouteMiddlewareBuilderType {
    public var base: RouteMiddlewareBuilderBase
    var postRoute: Bool = false
    public func postRoute(_ postRoute: Bool) -> Self {
        var `self` = self
        self.postRoute = postRoute
        return self
    }
    public func handle(_ handler: @escaping Handler) -> Router {
        switch base.pattern {
        case .path(let pattern):
            base.router.registerMiddleware(pattern: pattern, postRoute: postRoute, handler)
        case .regex(let pattern):
            base.router.registerMiddleware(regExpPattern: pattern, postRoute: postRoute, handler)
        default:
            #if DEBUG || ALPHA
            fatalError("unsupported pattern type")
            #endif
        }
        return base.router
    }
}
public struct RouteObserverBuilder: RouteMiddlewareBuilderType {
    public var base: RouteMiddlewareBuilderBase
    public func handle(_ handler: @escaping Handler) -> Router {
        switch base.pattern {
        case .path(let pattern):
            base.router.registerObserver(pattern: pattern, handler)
        case .regex(let pattern):
            base.router.registerObserver(regExpPattern: pattern, handler)
        default:
            #if DEBUG || ALPHA
            fatalError("unsupported pattern type")
            #endif
        }
        return base.router
    }
}
public struct RouteLocateOrPopObserverBuilder: RouteMiddlewareBuilderType {
    public var base: RouteMiddlewareBuilderBase
    public func handle(_ handler: @escaping Handler) -> Router {
        switch base.pattern {
        case .path(let pattern):
            base.router.registerLocateOrPopObserver(pattern: pattern, handler)
        case .regex(let pattern):
            let middleware = Middleware(regExpPattern: pattern, handler: handler)
            base.router.append(locateOrPopObserver: middleware)
        default:
            #if DEBUG || ALPHA
            fatalError("unsupported pattern type")
            #endif
        }
        return base.router
    }
}
