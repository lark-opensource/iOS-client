//
//  PassportLifeCycleDelegate.swift
//  LarkAccountInterface
//
//  Created by au on 2021/5/24.
//

import Foundation

// swiftlint:disable missing_docs

public protocol PassportLifeCycleDelegate: AnyObject {
    /// 登录前
    func beforeLogin(_ context: ActionContext)
    /// 登录成功后
    func afterLogin(_ context: ActionContext)

    /// 登出前
    func beforeLogout()
    /// 登出操作过程中清理用户数据前
    func beforeLogoutClearUsers(_ users: [User])
    /// 登出成功后
    func afterLogout(_ context: LogoutContext)

    /// 切换用户前
    func beforeSwitchUser()
    /// 切换用户error
//    func afterSwitchUserError(error: Error?) -> Observable<Void>
    /// 切换用户成功
    func afterSwitchUser(_ context: ActionContext)
}

// MARK: - LoginAndSwitchProtocol
public enum ActionReason {
    /// 已登陆时打开App快速进入当前用户
    case fastLogin
    /// 无已登陆用户时走登陆流程
    case slowLogin
    /// 应用内侧边栏切换至活跃用户
    case fastSwitch
    /// 应用内侧边栏切换至非活跃用户，走登陆流程
    case slowSwitch
    /// 应用内侧边栏 + 登陆
    case addUserLogin
    /// 登出操作完成后当前用户变成活跃用户
    case logoutFastSwitch
    /// 登出操作后当前用户是非活跃用户/对端用户，需走登陆流程
    case logoutSlowSwitch

}

public protocol ActionContext: AnyObject {
    /// error: before为空，after: error= nil时succeed, 有值时为failed
    var error: Error { get set }
    /// 是否启动直接登录
    var reason: ActionReason { get set }
    /// 是否来自引导页
    var onLaunchGuide: Bool { get set }
    /// 当前UserID, before和after不同
    var currentUserID: String? { get set }
    /// 新增User，before时为空
    var newUsers: [User] { get set }
    /// 所有User
    var allUsers: [User] { get set }
}

// MARK: - Login
class LoginContext: ActionContext {
    /// error: before为空，after: error = nil时succeed, 有值时为failed
    var error: Error
    /// Login操作来源
    var reason: ActionReason
    /// 是否来自引导页
    var onLaunchGuide: Bool
    /// 当前UserID
    var currentUserID: String?
    /// 新增User
    var newUsers: [User]
    /// 所有User
    var allUsers: [User]

    init(error: Error,
         reason: ActionReason = .slowLogin,
         onLaunchGuide: Bool = false,
         currentUserID: String? = nil,
         newUsers: [User],
         allUsers: [User]) {
        self.error = error
        self.reason = reason
        self.onLaunchGuide = onLaunchGuide
        self.currentUserID = currentUserID
        self.newUsers = newUsers
        self.allUsers = allUsers
    }
}

// MARK: - SwitchUser
class SwitchContext: ActionContext {
    /// error: before为空，after: error= nil时succeed, 有值时为failed
    var error: Error
    /// Switch操作来源(login会触发switch操作)
    var reason: ActionReason
    /// 是否来自引导页
    var onLaunchGuide: Bool
    /// 当前UserID，before与after的不同
    var currentUserID: String?
    /// 新增User，before时为空
    var newUsers: [User]
    /// 所有User
    var allUsers: [User]

    init(error: Error,
         reason: ActionReason = .slowLogin,
         onLaunchGuide: Bool = false,
         currentUserID: String? = nil,
         newUsers: [User],
         allUsers: [User]) {
        self.error = error
        self.reason = reason
        self.onLaunchGuide = onLaunchGuide
        self.currentUserID = currentUserID
        self.newUsers = newUsers
        self.allUsers = allUsers
    }
}

// MARK: - Logout
public enum LogoutReason {
    /// user manual logout
    case manual
    /// logout
    case sessionExpired
    /// unregister user push event
    case unregisterUser
    /// debug menu switch env
    case debugSwitchEnv

}

public final class LogoutContext {
    /// error: before为空，after = nil时succeed, 有值时为failed
    var error: Error?

    public var clearData: Bool

    public var message: String?

    public var reason: LogoutReason

    public var serverLogoutReason: Int64?

    public var needAlert: Bool

    /// 回滚登出，不会更新RootVC
    /// 目前用于 VC 登录前入会，加入会议失败回滚
    public var isRollbackLogout: Bool

    public var extra: [String: Any]

    public init(
        error: Error? = nil,
        clearData: Bool = false,
        message: String? = nil,
        serverLogoutReason: Int64? = nil,
        needAlert: Bool = false,
        reason: LogoutReason = .manual,
        isRollbackLogout: Bool = false,
        extra: [String: Any] = [:]
    ) {
        self.error = error
        self.clearData = clearData
        self.message = message
        self.serverLogoutReason = serverLogoutReason
        self.needAlert = needAlert
        self.reason = reason
        self.isRollbackLogout = isRollbackLogout
        self.extra = extra
    }
}
