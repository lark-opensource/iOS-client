//
//  LogoutConf.swift
//  LarkAccountInterface
//
//  Created by Yiming Qu on 2020/4/1.
//

import Foundation

// swiftlint:disable missing_docs
public enum LogoutTrigger {
    /// user manual logout
    case manual
    /// logout
    case sessionExpired
    /// unregister user push event
    case unregisterUser
    /// debug menu switch env
    case debugSwitchEnv
    /// lark setting；设置里面的退出
    case setting
    /// 企业环境下禁止登录非企业身份租户
    case tenantRestrict
    /// JSB 调用
    case jsBridge
    /// 指掌易调用
    case emm
    /// 高风险 session 倒计时结束踢出
    case sessionRiskCountdown
}

public enum LogoutDestination {
    /// logout to login page
    case login
    /// logout to launch guide page
    case launchGuide
    /// switch user after logout
    case switchUser
}

public enum LogoutType {
    /// logout foreground user
    case foreground
    /// logout all user
    case all
    /// non-foreground user
    case background
}

public final class LogoutConf {

    public var forceLogout: Bool            // 传 true 时不会被 interruptor 阻断

    public var clearData: Bool              // 废弃

    public var message: String?             // 如果 message 非空字符串并且 needAlert 为 true，将在登出前展示该文案让用户二次确认

    public var trigger: LogoutTrigger       // 表明登出操作的来源

    public var type: LogoutType             // 登出类型，包括 all（全部）foreground（前台），background（后台用户）

    public var needEraseData: Bool          // 是否需要数据擦除；暂只支持登出全部回到登录页场景

    public var serverLogoutReason: Int64?   // 废弃

    public var needAlert: Bool              // 如果 message 非空字符串并且 needAlert 为 true，将在登出前展示该文案让用户二次确认

    public var destination: LogoutDestination   // 登出后跳转的目的页面，包括 login（登录页），launchGuide（引导页），switchUser（切用户）

    /// 回滚登出，不会更新RootVC
    /// 目前用于 VC 登录前入会，加入会议失败回滚
    public var isRollbackLogout: Bool

    public var extra: [String: Any]         // 废弃

    public init(
        forceLogout: Bool = false,
        clearData: Bool = false,
        message: String? = nil,
        serverLogoutReason: Int64? = nil,
        needAlert: Bool = false,
        trigger: LogoutTrigger = .manual,
        destination: LogoutDestination = .login,
        isRollbackLogout: Bool = false,
        extra: [String: Any] = [:],
        type: LogoutType = .all,
        needEraseData: Bool = false
        ) {
        self.forceLogout = forceLogout
        self.clearData = clearData
        self.message = message
        self.serverLogoutReason = serverLogoutReason
        self.needAlert = needAlert
        self.trigger = trigger
        self.destination = destination
        self.isRollbackLogout = isRollbackLogout
        self.extra = extra
        self.type = type
        self.needEraseData = needEraseData
    }

    /// default config
    public static var `default`: LogoutConf {
        .init()
    }

    /// logout foreground config
    public static var foreground: LogoutConf {
        LogoutConf(
            destination: .switchUser,
            type: .foreground
        )
    }

    /// logout background config
    public static var background: LogoutConf {
        LogoutConf(
            forceLogout: true,
            destination: .switchUser,
            type: .background
        )
    }

    /// config for unregister user
    public static var unregisterUser: LogoutConf {
        LogoutConf(
            forceLogout: true,
            trigger: .unregisterUser
        )
    }

    /// config for debug switch env
    public static var debugSwitchEnv: LogoutConf {
        LogoutConf(
            trigger: .debugSwitchEnv
        )
    }

    /// 强制登出到Login页
    public static var toLogin: LogoutConf {
        LogoutConf(
            forceLogout: true,
            destination: .login
        )
    }

    /// 强制登出到LaunchGuide页
    public static var toLaunchGuide: LogoutConf {
        LogoutConf(
            forceLogout: true,
            destination: .launchGuide
        )
    }
}

extension LogoutConf: CustomStringConvertible {
    public var description: String {
        """
        forceLogout: \(forceLogout),
        clearData: \(clearData),
        message: \(String(describing: message)),
        trigger: \(trigger),
        serverLogoutReason: \(String(describing: serverLogoutReason)),
        needAlert: \(needAlert)
        extra: \(String(describing: extra))
        type: \(type)
        """
    }
}

// swiftlint:enable missing_docs
