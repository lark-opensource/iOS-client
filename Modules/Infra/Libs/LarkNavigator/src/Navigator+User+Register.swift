//
//  Navigator+User+Register.swift
//  LarkNavigator
//
//  Created by SolaWing on 2022/8/20.
//
// 这个文件添加Route User相关的接口封装
// Route目前有原始的分pattern handler接口，
// 扩展的protocol接口(可被缓存)，包装的Body(Codable？)
// Body还会决定pattern类型, Body可以和protocol组合成typed基础类
// 路由链式接口(LarkInterface接口规范要求..)等等
//
// 使用上主要是链式接口, 以及类型封装用得多一些

import Foundation
import LarkContainer
import EENavigator
import LKCommonsLogging

// swiftlint:disable missing_docs
public typealias UserHandler = (UserResolver, EENavigator.Request, EENavigator.Response) throws -> Void
public typealias UserRouteTester = (UserResolver, EENavigator.Request) throws -> Bool
// NOTE: 使用方可能有用户登录后才能决定是否真的能处理对应Request的需求，但目前使用较少..
// 考虑是否提供基于navigator的API, 对应的实现也是先调用一次tester，再调用handler..
// 现在也不能同时测试多个相同的pattern(除了matchBlock), regex和match的也不能取消注册..

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
    static func handledUserScopeType() -> UserScopeType
    func handle(req: EENavigator.Request, res: EENavigator.Response) throws
}
extension UserRouterHandlerType {
    public static func compatibleMode() -> Bool { false }
    public static func handledUserScopeType() -> UserScopeType { .foreground }
}

public protocol UserTypedRouterHandlerType {
    associatedtype B: Body // swiftlint:disable:this all
    static func compatibleMode() -> Bool
    static func handledUserScopeType() -> UserScopeType
    func handle(_ body: B, req: EENavigator.Request, res: EENavigator.Response) throws
}
extension UserTypedRouterHandlerType {
    public static func compatibleMode() -> Bool { false }
    public static func handledUserScopeType() -> UserScopeType { .foreground }
}

extension RouterRegisterBuilderType {
    @_disfavoredOverload
    @discardableResult
    public func handle(
        compatibleMode: @escaping () -> Bool = { false },
        _ handler: @escaping UserHandler
    ) -> Router {
        return handle(type: .foreground, compatibleMode: compatibleMode, handler)
    }
    @discardableResult
    public func handle(
        type: UserScopeType = .foreground,
        compatibleMode: @escaping () -> Bool = { false },
        _ handler: @escaping UserHandler
    ) -> Router {
        return handle(wrapUserHandler(routeHandler: handler, type: type, compatibleMode: compatibleMode))
    }
    /// - Parameter cache: 使用类型作为缓存key，用户生命周期，按用户隔离
    @discardableResult
    public func factory<H: UserRouterHandlerType>(
        cache: Bool = false,
        _ factory: @escaping (UserResolver) throws -> H
    ) -> Router {
        let factory = wrapFactory(cache: cache, factory: factory)
        return handle(type: H.handledUserScopeType(), compatibleMode: H.compatibleMode) { resolver, req, res in
            try factory(resolver).handle(req: req, res: res)
        }
    }

    @_disfavoredOverload
    public func tester(
        compatibleMode: @escaping () -> Bool = { false },
        _ tester: @escaping UserRouteTester
    ) -> Self {
        return self.tester(type: .foreground, compatibleMode: compatibleMode, tester)
    }
    public func tester(
        type: UserScopeType = .foreground,
        compatibleMode: @escaping () -> Bool = { false },
        _ tester: @escaping UserRouteTester
    ) -> Self {
        self.tester { req in
            do {
                let userResolver = try req.getUserResolver(type: type, compatibleMode: compatibleMode())
                return try tester(userResolver, req)
            } catch {
                userLogger.warn("route tester error \(req.url.withoutQueryAndFragment)", error: error)
                // FIXME: 这里是否需要区分UserScopeError?
                return false
            }
        }
    }
}

extension RouterRegisterBuilderBody {
    @_disfavoredOverload
    public func handle(
        compatibleMode: @escaping () -> Bool = { false },
        _ handler: @escaping (UserResolver, T, EENavigator.Request, EENavigator.Response) throws -> Void
    ) -> Router where T: Body {
        return self.handle(type: .foreground, compatibleMode: compatibleMode, handler)
    }
    public func handle(
        type: UserScopeType = .foreground,
        compatibleMode: @escaping () -> Bool = { false },
        _ handler: @escaping (UserResolver, T, EENavigator.Request, EENavigator.Response) throws -> Void
    ) -> Router where T: Body {
        return handle(type: type, compatibleMode: compatibleMode) { (resolver, req, res) in
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
        return handle(type: H.handledUserScopeType(), compatibleMode: H.compatibleMode) { resolver, req, res in
            try factory(resolver).handle(req.getBody(), req: req, res: res)
        }
    }
}

extension RouteMiddlewareBuilderType {
    @_disfavoredOverload
    @discardableResult
    public func handle(
        compatibleMode: @escaping () -> Bool = { false },
        _ handler: @escaping UserHandler
    ) -> Router {
        return self.handle(type: .foreground, compatibleMode: compatibleMode, handler)
    }
    /// - Important: 注意middleware throws的error只会忽略，不会输出到res.error导致路由终止
    @discardableResult
    public func handle(
        type: UserScopeType = .foreground,
        compatibleMode: @escaping () -> Bool = { false },
        _ handler: @escaping UserHandler
    ) -> Router {
        return handle { req, res in
            do {
                let resolver = try req.getUserResolver(type: type, compatibleMode: compatibleMode())
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
        return handle(type: H.handledUserScopeType(), compatibleMode: H.compatibleMode) { resolver, req, res in
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
    routeHandler: @escaping UserHandler,
    type: UserScopeType,
    compatibleMode: @escaping () -> Bool
) -> Handler {
    return { req, res in
        do {
            let userResolver = try req.getUserResolver(type: type, compatibleMode: compatibleMode())
            try routeHandler(userResolver, req, res)
        } catch {
            userLogger.warn("route error \(req.url.withoutQueryAndFragment)", error: error)
            // FIXME: 这里是否需要区分UserScopeError?
            res.end(error: error)
        }
    }
}

let userLogger = Logger.log(UserRouterHandler.self, category: "UserNavigator")
