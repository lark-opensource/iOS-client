//
//  Navigator+User.swift
//  LarkNavigator
//
//  Created by SolaWing on 2022/7/7.
//

import Foundation
import EENavigator
import LarkContainer
import Swinject
import LarkSetting

extension UserResolver {
    /// a wrapper to pass userID as context
    public var navigator: UserNavigator {
        UserNavigator(
            navigator: Navigator.shared, userResolver: self)
    }
}
extension UserResolverWrapper {
    /// a wrapper to pass userID as context
    public var navigator: UserNavigator { self.userResolver.navigator }
}

extension Resolver {
    // TODO: 清理旧兼容接口
    @_disfavoredOverload
    public func getUserResolver(req: EENavigator.Request, compatibleMode: Bool = false) throws -> UserResolver {
        return try req.getUserResolver(compatibleMode: compatibleMode, resolver: self)
    }
    /// 路由有外部调用，可能不太好保证都传了userID
    /// 先统一用这个方法，兼容记录没传userID的请求
    /// @see EENavigator.Request.getUserResolver
    public func getUserResolver(req: EENavigator.Request, type: UserScopeType = .foreground, compatibleMode: Bool = false) throws -> UserResolver {
        return try req.getUserResolver(type: type, compatibleMode: compatibleMode, resolver: self)
    }
}
extension EENavigator.Request {
    @_disfavoredOverload
    public func getUserResolver(compatibleMode: Bool = false, resolver: Resolver = Container.shared) throws -> UserResolver { // Global
        try getUserResolver(type: .foreground, compatibleMode: compatibleMode, resolver: resolver)
    }
    /// 路由有外部调用，可能不太好保证都传了userID
    /// 先统一用这个方法，兼容记录没传userID的请求
    public func getUserResolver(type: UserScopeType = .foreground, compatibleMode: Bool = false, resolver: Resolver = Container.shared) throws -> UserResolver { // Global
        // resolver默认使用全局的. 实现方使用的container应该和调用方无关..
        // 但是storage代表有生命周期的用户，userID是无生命周期的。
        // 所以优先用调用方的storage
        let threadCompatibleMode: Bool
        if let callerResolver = context["__callerResolver"] as? UserResolver {
            if !type.contains(callerResolver.storageType) {
                // 期望的用户类型不匹配直接抛错，不用当前用户兜底...
                // 不过下面未知user的情况有兜底，需要另外扫描代码避免调用
                throw UserScopeError.unsafeCall
            }

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
            type: type,
            compatibleMode: compatibleMode,
            threadCompatibleMode: threadCompatibleMode,
            identifier: { "Router Req \(self.logInfo)" })
    }
}

/// 用户隔离封装，保证路由context里注入了用户相关参数
public struct UserNavigator: Navigatable {
    public func open(_ req: NavigatorOpenRequest) {
        var req = req
        // Navigator内部调用response就拦截不到了，只能拦截入口注入
        injectUser(context: &req.context)
        return navigator.open(req)
    }
    public func open(_ params: NavigatorOpenControllerRequest) {
        return navigator.open(params)
    }
    // 未来支持多用户的话还应该判断是否前台用户, 现在简化只判断了disposed
    public func globalValid() -> Bool { userResolver.valid }
    public func switchTab(_ url: URL, from: NavigatorFrom, animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard userResolver.valid else {
            completion?(false)
            return
        }
        navigator.switchTab(url, from: from, animated: animated, completion: completion)
    }
    public func response(for url: URL, context: [String: Any], test: Bool) -> Response {
        var context = context
        injectUser(context: &context)
        return navigator.response(for: url, context: context, test: test)
    }
    public func contains(_ url: URL, context: [String: Any]) -> Bool {
        var context = context
        injectUser(context: &context)
        return navigator.contains(url, context: context)
    }

    let navigator: Navigatable
    public let userResolver: UserResolver
    public var userID: String { userResolver.userID }
    public var compatibleMode: Bool { userResolver.compatibleMode }

    @inlinable
    func injectUser(context: inout [String: Any]) {
        // 注意底层redirect也要保留，现在是写死的约定string, 修改要注意一致性
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
