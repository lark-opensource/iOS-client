//
//  SuiteLoginInterface.swift
//  LarkLogin
//
//  Created by qihongye on 2019/1/13.
//

import LarkLocalizations
import LKCommonsLogging
import LarkUIKit

struct SettingFeature: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none = SettingFeature([])
    /// has modify pwd
    public static let modifyPwd = SettingFeature(rawValue: 1)
    /// has two factor verify
    public static let twoFactor = SettingFeature(rawValue: 1 << 1)
    /// has account manager
    public static let accountManage = SettingFeature(rawValue: 1 << 2)
    /// has security verify pwd
    public static let securityVerifyPwd = SettingFeature(rawValue: 1 << 3)
    /// has deviceManager
    public static let deviceManage = SettingFeature(rawValue: 1 << 4)
    /// has bio auth login
    public static let bioAuthLogin = SettingFeature(rawValue: 1 << 5)
    /// has bio auth
    public static let bioAuth = SettingFeature(rawValue: 1 << 6)
}

typealias CurrentUserIndex = Int

typealias SuiteLoginUserInfo = (users: [V3UserInfo], userIndex: CurrentUserIndex)
typealias SuiteFastLoginResult = Result<SuiteLoginUserInfo, Error>
typealias SuiteLoginCallback = (SuiteLoginUserInfo) -> Void

typealias EnterAppUserListCallback = ([V4UserInfo]) -> Void
typealias EnterAppUserContext = (foregroundUser: V4UserInfo, userList: [V4UserInfo]) // user:checked
typealias FastLoginResult = Result<EnterAppUserContext, Error>
typealias FastLoginCallback = (FastLoginResult) -> Void

struct AccountUserInfo: Codable {
    public let userID: String
    public let tenantID: String
    public var name: String
    public var enName: String
    public let isActive: Bool
    public var isFrozen: Bool
    public let avatarKey: String
    public let avatarUrl: String
    public var session: String
    public var sessions: [String: [String: String]]?
    public var logoutToken: String?
    public var tenantCode: String
    public var defaultTenantIconUrl: String
    public var tenant: AccountTenantInfo?
    public var userEnv: String?
    public var userUnit: String?
    public var status: Int?
    public var securityConfig: V3SecurityConfig?
    public var isIdp: Bool?
    public var isGuest: Bool?
    public var upgradeEnabled: Bool?

    public init(
        userID: String,
        tenantID: String,
        name: String,
        enName: String,
        isActive: Bool,
        isFrozen: Bool,
        avatarKey: String,
        avatarUrl: String,
        session: String,
        sessions: [String: [String: String]]?,
        logoutToken: String?,
        tenantCode: String,
        defaultTenantIconUrl: String,
        tenant: AccountTenantInfo?,
        userEnv: String?,
        userUnit: String?,
        status: Int?,
        securityConfig: V3SecurityConfig?,
        isIdp: Bool?,
        isGuest: Bool?,
        upgradeEnabled: Bool?
    ) {
        self.userID = userID
        self.tenantID = tenantID
        self.name = name
        self.enName = enName
        self.isActive = isActive
        self.isFrozen = isFrozen
        self.avatarKey = avatarKey
        self.avatarUrl = avatarUrl
        self.session = session
        self.sessions = sessions
        self.logoutToken = logoutToken
        self.tenantCode = tenantCode
        self.defaultTenantIconUrl = defaultTenantIconUrl
        self.tenant = tenant
        self.userEnv = userEnv
        self.userUnit = userUnit
        self.status = status
        self.securityConfig = securityConfig
        self.isIdp = isIdp
        self.isGuest = isGuest
        self.upgradeEnabled = upgradeEnabled
    }

    public static func getEnableStatus() -> Int {
        return V3UserInfo.Status.enable.rawValue
    }

    public static func getPendingStatus() -> Int {
        return V3UserInfo.Status.pending.rawValue
    }

    public func isPendingUser() -> Bool {
        return status == Self.getPendingStatus()
    }

}

struct AccountTenantInfo: Codable {
    public var userID: String
    public var tenantID: String
    public var name: String
    public var iconUrl: String
    public var tenantCode: String
    public var tag: Int?
    public var fullDomain: String?

    public init(
        userID: String = "",
        tenantID: String,
        tenantCode: String,
        name: String = "",
        iconUrl: String = "",
        tag: Int?,
        fullDomain: String?
    ) {
        self.userID = userID
        self.tenantID = tenantID
        self.tenantCode = tenantCode
        self.name = name
        self.iconUrl = iconUrl
        self.tag = tag
        self.fullDomain = fullDomain
    }
}

// MARK: Log Desensitize

extension AccountUserInfo: LogDesensitize, CustomStringConvertible {

    public var description: String {
        return "\(self.desensitize())"
    }

    private struct Const {
        static let userID: String = "userID"
        static let tenantID: String = "tenantID"
        static let isActive: String = "isActive"
        static let isFronzen: String = "isFronzen"
        static let avatarKey: String = "avatarKey"
        static let tenantCode: String = "tenantCode"
        static let tenant: String = "tenant"
        static let userEnv: String = "userEnv"
        static let userUnit: String = "userUnit"
        static let status: String = "status"
        static let securityConfig: String = "securityConfig"
        static let isIdp: String = "isIdp"
        static let sessionLength: String = "sessionLength"
        static let isGuest: String = "isGuest"
        static let upgradeEnabled: String = "upgradeEnabled"
    }

    func desensitize() -> [String: String] {
        return [
            Const.userID: userID,
            Const.tenantID: tenantID,
            Const.isActive: SuiteLoginUtil.serial(value: isActive),
            Const.isFronzen: SuiteLoginUtil.serial(value: isFrozen),
            Const.avatarKey: avatarKey,
            Const.tenantCode: tenantCode,
            Const.tenant: SuiteLoginUtil.serial(value: tenant),
            Const.userEnv: SuiteLoginUtil.serial(value: userEnv),
            Const.userUnit: SuiteLoginUtil.serial(value: userUnit),
            Const.status: SuiteLoginUtil.serial(value: status),
            Const.securityConfig: SuiteLoginUtil.serial(value: securityConfig),
            Const.isIdp: SuiteLoginUtil.serial(value: isIdp),
            Const.sessionLength: "\(session.count)",
            Const.isGuest: SuiteLoginUtil.serial(value: isGuest),
            Const.upgradeEnabled: SuiteLoginUtil.serial(value: upgradeEnabled)
        ]
    }

}

extension AccountTenantInfo: LogDesensitize, CustomStringConvertible {

    public var description: String {
        return "\(self.desensitize())"
    }

    private struct Const {
        static let userID: String = "userID"
        static let tenantID: String = "tenantID"
        static let iconUrl: String = "iconUrl"
        static let tenantCode: String = "tenantCode"
        static let tag: String = "tag"
        static let empty: String = "empty"
    }

    func desensitize() -> [String: String] {
        let tagValue: String
        if let tag = tag {
            tagValue = "\(tag)"
        } else {
            tagValue = Const.empty
        }
        return [
            Const.userID: userID,
            Const.tenantID: tenantID,
            Const.tenantCode: tenantCode,
            Const.tag: tagValue
        ]
    }
}

