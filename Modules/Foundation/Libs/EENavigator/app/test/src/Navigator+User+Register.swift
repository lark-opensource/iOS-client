//
//  Navigator+User+Register.swift
//  EENavigatorDevEEUnitTest
//
//  Created by SolaWing on 2022/10/20.
//  Copy from LarkNavigator, without additional dependency
//

import Foundation
import LarkContainer
import EENavigator

// swiftlint:disable missing_docs
public typealias UserHandler = (UserResolver, EENavigator.Request, EENavigator.Response) throws -> Void
// NOTE: tester的过滤使用很少，而且不一定需要UserResolver.. UserResolver也可以从req上获取, 就不专门封装了
// public typealias UserRouteTester = (UserResolver, EENavigator.Request) throws -> Bool

public typealias UserRouterHandler = _UserRouterHandler & UserRouterHandlerType
public typealias UserTypedRouterHandler = _UserRouterHandler & UserTypedRouterHandlerType
public typealias UserMiddlewareHandlerType = UserRouterHandlerType // middleware相关的扩展应该使用这个类型名
public typealias UserMiddlewareHandler = UserRouterHandler // middleware相关的扩展应该使用这个类型名
open class _UserRouterHandler: UserResolverWrapper { // swiftlint:disable:this all
    public var userResolver: UserResolver
    public init(resolver: UserResolver) {
        userResolver = resolver
    }
}
public protocol UserRouterHandlerType {
    static func compatibleMode() -> Bool
    func handle(req: EENavigator.Request, res: EENavigator.Response) throws
}
extension UserRouterHandlerType {
    public static func compatibleMode() -> Bool { false }
}

public protocol UserTypedRouterHandlerType {
    associatedtype B: Body // swiftlint:disable:this all
    static func compatibleMode() -> Bool
    func handle(_ body: B, req: EENavigator.Request, res: EENavigator.Response) throws
}
extension UserTypedRouterHandlerType {
    public static func compatibleMode() -> Bool { false }
}

extension RouterRegisterBuilderType {
    @discardableResult
    public func handle(
        compatibleMode: @escaping () -> Bool = { false },
        _ handler: @escaping UserHandler
    ) -> Router {
        return handle(wrapUserHandler(routeHandler: handler, compatibleMode: compatibleMode))
    }
    /// - Parameter cache: 使用类型作为缓存key，用户生命周期，按用户隔离
    @discardableResult
    public func factory<H: UserRouterHandlerType>(
        cache: Bool = false, _ factory: @escaping (UserResolver) throws -> H
    ) -> Router {
        let factory = wrapFactory(cache: cache, factory: factory)
        return handle(compatibleMode: H.compatibleMode) { resolver, req, res in
            try factory(resolver).handle(req: req, res: res)
        }
    }
}

extension RouterRegisterBuilderBody {
    public func handle(
        compatibleMode: @escaping () -> Bool = { false },
        _ handler: @escaping (UserResolver, T, EENavigator.Request, EENavigator.Response) throws -> Void
    ) -> Router where T: Body {
        return handle(compatibleMode: compatibleMode) { (resolver, req, res) in
            // 先获取resolver再获取body
            try handler(resolver, req.getBody(), req, res)
        }
    }

    /// - Parameter cache: 使用类型作为缓存key，用户生命周期，按用户隔离
    @discardableResult
    public func factory<H>(
        cache: Bool = false, _ factory: @escaping (UserResolver) throws -> H
    ) -> Router where H: UserTypedRouterHandler, H.B == T, T: Body {
        // 考虑到需要限制Body和type一致，所以不继承UserRouterHandlerType。继承会fallback到上面的普通factory调用上..
        let factory = wrapFactory(cache: cache, factory: factory)
        return handle(compatibleMode: H.compatibleMode) { resolver, req, res in
            try factory(resolver).handle(req.getBody(), req: req, res: res)
        }
    }
}

extension RouteMiddlewareBuilderType {
    /// - Important: 注意middleware throws的error只会忽略，不会输出到res.error导致路由终止
    @discardableResult
    public func handle(
        compatibleMode: @escaping () -> Bool = { false },
        _ handler: @escaping UserHandler
    ) -> Router {
        return handle { req, res in
            do {
                let resolver = try req.getUserResolver(compatibleMode: compatibleMode())
                try handler(resolver, req, res)
            } catch {
                userLogger.warn("middleware error \(req.url.withoutQueryAndFragment)", error: error)
            }
        }
    }
    /// - Important: 注意middleware throws的error只会忽略，不会输出到res.error导致路由终止
    /// - Parameter cache: 使用类型作为缓存key，用户生命周期，按用户隔离
    @discardableResult
    public func factory<H: UserMiddlewareHandlerType>(
        cache: Bool = false, _ factory: @escaping (UserResolver) throws -> H
    ) -> Router {
        let factory = wrapFactory(cache: cache, factory: factory)
        return handle(compatibleMode: H.compatibleMode) { resolver, req, res in
            try factory(resolver).handle(req: req, res: res)
        }
    }
}

// MARK: Helper
private func wrapFactory<T>(cache: Bool, factory: @escaping (UserResolver) throws -> T) -> (UserResolver) throws -> T {
    if cache {
        return { resolver in
            let id = ObjectIdentifier(T.self)
            if let handler: T = try resolver.storage.get(key: id) {
                return handler
            }
            let handler = try factory(resolver)
            try resolver.storage.set(key: id, value: handler)
            return handler
        }
    }
    return factory
}

private func wrapUserHandler(
    routeHandler: @escaping UserHandler, compatibleMode: @escaping () -> Bool
) -> Handler {
    return { req, res in
        do {
            let userResolver = try req.getUserResolver(compatibleMode: compatibleMode())
            try routeHandler(userResolver, req, res)
        } catch {
            userLogger.warn("route error \(req.url.withoutQueryAndFragment)", error: error)
            // FIXME: 这里是否需要区分UserScopeError?
            res.end(error: error)
        }
    }
}

class Logger {
    static func log(_ type: Any.Type, category: String) -> Logger {
        return Logger()
    }
    func warn(_ message: String, error: Error? = nil) {
        print("[WARN]\(message); \(error.flatMap { String(describing: $0) } ?? "")")
    }
}

let userLogger = Logger.log(UserRouterHandler.self, category: "UserNavigator")


extension UserResolver {
    /// a wrapper to pass userID as context
    public var navigator: Navigatable {
        CompatibleUserNavigator(
            navigator: Navigator.shared, userResolver: self)
    }
}
extension UserResolverWrapper {
    /// a wrapper to pass userID as context
    public var navigator: Navigatable { self.userResolver.navigator }
}

extension Resolver {
    /// 路由有外部调用，可能不太好保证都传了userID
    /// 先统一用这个方法，兼容记录没传userID的请求
    /// @see EENavigator.Request.getUserResolver
    public func getUserResolver(req: EENavigator.Request, compatibleMode: Bool = false) throws -> UserResolver {
        return try req.getUserResolver(compatibleMode: compatibleMode, resolver: self)
    }
}
extension EENavigator.Request {
    /// 路由有外部调用，可能不太好保证都传了userID
    /// 先统一用这个方法，兼容记录没传userID的请求
    public func getUserResolver(compatibleMode: Bool = false, resolver: Resolver = Container.shared) throws -> UserResolver {
        // resolver默认使用全局的. 实现方使用的container应该和调用方无关..
        // 但是storage代表有生命周期的用户，userID是无生命周期的。
        // 所以优先用调用方的storage
        let threadCompatibleMode: Bool
        if let callerResolver = context["__callerResolver"] as? UserResolver {
            if !callerResolver.compatibleMode {
                return resolver.getUserResolver(storage: callerResolver.storage, compatibleMode: compatibleMode)
            }
            // 调用方要求兼容时，使用当前的storage, 而不是其自带的, 可能已经过期的storage
            // 当前storage仍然有可能抛错，但概率相对较小
            threadCompatibleMode = true
        } else {
            threadCompatibleMode = self.userID == nil || (self.context["__userCompatibleMode"] as? Bool == true)
        }

        // 期望的是调用方显示的给user，哪怕的确是用当前user.
        // 传nil的情况只是临时兼容
        // 除了app内部所有可能的地方，外部URL调用也需要注意
        return try resolver.getUserResolver(
            userID: self.userID,
            compatibleMode: compatibleMode,
            threadCompatibleMode: threadCompatibleMode,
            identifier: { "Router Req \(self.url)" })
    }
}

/// 用户隔离封装，保证路由context里注入了用户相关参数
struct CompatibleUserNavigator: Navigatable {
    func globalValid() -> Bool {
        !userResolver.storage.disposed
    }
    
    public func open(_ req: NavigatorOpenRequest) {
        var req = req
        injectUser(context: &req.context)
        return navigator.open(req)
    }
    public func open(_ params: NavigatorOpenControllerRequest) {
        return navigator.open(params)
    }
    public func switchTab(_ url: URL, from: NavigatorFrom, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        if userResolver.storage.disposed {
            completion?(false)
            return
        }
        navigator.switchTab(url, from: from, animated: animated, completion: completion)
    }
    public func response(for url: URL, context: [String : Any], test: Bool) -> Response {
        var context = context
        injectUser(context: &context)
        return navigator.response(for: url, context: context, test: test)
    }
    public func contains(_ url: URL, context: [String : Any]) -> Bool {
        var context = context
        injectUser(context: &context)
        return navigator.contains(url, context: context)
    }

    public let navigator: Navigatable
    public let userResolver: UserResolver
    public var userID: String { userResolver.userID }
    public var compatibleMode: Bool { userResolver.compatibleMode }

    @inlinable
    func injectUser(context: inout [String: Any]) {
        context[ContextKeys.userID] = userID
        context["__callerResolver"] = userResolver
    }
}

extension ContextKeys {
    public static let userID = "_kUserID"
}

extension EENavigator.Request {
    /// 用户ID环境参数，现在先放到context中。不排除未来有其他规范
    public var userID: String? { context[ContextKeys.userID] as? String }
}
