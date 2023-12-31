//
//  AnimatedTabBar+UserNavgitor.swift
//  AnimatedTabBar
//
//  Created by ByteDance on 2023/12/6.
//

import Foundation
import EENavigator
import LarkContainer
import Swinject
import LarkSetting

extension UserResolver {
    /// a wrapper to pass userID as context
    var animatedNavigator: AnimatedUserNavigator {
        AnimatedUserNavigator(
            navigator: Navigator.shared, userResolver: self)
    }
}

/// 用户隔离封装，保证路由context里注入了用户相关参数
struct AnimatedUserNavigator: Navigatable {
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
