//
//  Deprecated.swift
//  LarkAccountInterface
//
//  Created by au on 2021/5/23.
//

import Foundation
import LarkLocalizations

// swiftlint:disable missing_docs
// swiftlint:disable unused_setter_value

// MARK: - Account

public typealias AccountUserType = Account.UserType
// public typealias AccountUserType = PassportUserType

/// 已废弃，新账号模型下使用 `User` 代表用户身份，目前对原 `Account` 进行兼容，后续将会移除
@available(*, deprecated, message: "Will be removed soon. Use `User` instead.")
public struct Account {

    // public typealias UserType = AccountUserType
    public enum UserType {
        // swiftlint:disable identifier_name
        /// c user
        case c
        // swiftlint:enable identifier_name
        /// b user
        case standard
        /// unknown user
        case undefined
        /// simple b user
        case simple

        public var isStandard: Bool {
            switch self {
            case .standard:
                return true
            case .undefined:
                assertionFailure()
                return false
            default:
                return false
            }
        }
        @inlinable
        public init(_ from: PassportUserType) {
            self = Account.userTypeFromPassportUserType(from)
        }
    }

    private var user: User

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var userID: String {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.userID
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var name: String {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.name
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var enName: String {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.enName
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var avatarKey: String {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.avatarKey
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var avatarUrl: String {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.avatarURL
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var accessToken: String {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.sessionKey ?? ""
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var accessTokens: [String: [String: String]]? {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.sessionKeyWithDomains
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var logoutToken: String? {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.logoutToken
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var tenant: Tenant {
        return user.tenant
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var tenantInfo: TenantInfo {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return TenantInfo(tenant: user.tenant)
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var tenantConfig: TenantConfig {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.tenantConfig
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var userEnv: String? {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.userEnv
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var userUnit: String? {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.userUnit
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var securityConfig: SecurityConfig? {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.securityConfig
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var isIdp: Bool? {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.isIdP
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var isFrozen: Bool {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.isFrozen
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var isActive: Bool {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.isActive
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var isGuest: Bool? {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.isGuest
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var upgradeEnabled: Bool? {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.upgradeEnabled
        }
    }

    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var authnMode: String? {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.authMode
        }
    }
    
    @available(*, deprecated, message: "Will be removed soon. Please use properties in `User` struct ")
    public var leanModeInfo: LeanModeInfo? {
        set {
            assertionFailure("This property cannot be modified. Maybe you should contact @PassportOnCall")
        }
        get {
            return user.leanModeInfo
        }
    }

    public init(user: User) {
        self.user = user
    }

    public var type: UserType { return Account.userTypeFromPassportUserType(user.type) }

    public var userTypeInString: String { return user.userTypeInString }

    public var localizedName: String { return user.localizedName }

    public var isIdpUser: Bool { return user.isIdPUser }

    /// 游客User
    public var isGuestUser: Bool { return user.isGuestUser }

    public var singleProductTypes: [TenantSingleProductType]? { return user.singleProductTypes }

    public var canUpgradeTeam: Bool { return user.canUpgradeTeam }
}

public extension Account {
    /// 团队转化侧边栏按钮文案
    var teamConversionEntryTitle: String {
        AccountServiceAdapter.shared.teamConversionEntryTitle(for: self) // user:checked
    }

    static func userTypeFromPassportUserType(_ userType: PassportUserType)-> Account.UserType {
        switch userType {
        case .standard:
            return .standard
        case .undefined:
            return .undefined
        case .simple:
            return .simple
        case .c:
            return .c
        default:
            return .standard
        }
    }
}

// MARK: - TenantInfo

/// 已废弃，新账号模型下使用 `Tenant` 代表租户，目前对原 `TenantInfo` 进行兼容，后续将会移除
@available(*, deprecated, message: "Will be removed soon. Use `Tenant` instead.")
public struct TenantInfo: Equatable {

    private var tenant: Tenant

    public var tenantId: String { tenant.tenantID }
    public var tenantName: String { tenant.tenantName }
    public var iconURL: String { tenant.iconURL }
    public var tenantCode: String { tenant.tenantDomain ?? "" }
    public var tenantTag: Int? { tenant.tenantTag?.rawValue }
    public var fullDomain: String? { tenant.tenantFullDomain }

    public var singleProductTypes: [TenantSingleProductType]? {
        set {
            tenant.singleProductTypes = newValue
        }
        get {
            return tenant.singleProductTypes
        }
    }

    public static let ByteDancerTenantId: String = "1"

    public var isByteDancer: Bool {
        return self.tenantId == TenantInfo.ByteDancerTenantId
    }

    public init(tenant: Tenant) {
        self.tenant = tenant
    }

    public static func == (lhs: TenantInfo, rhs: TenantInfo) -> Bool {
        return lhs.tenantId == rhs.tenantId
    }
}

public extension TenantInfo {
    static func placeholderTenant() -> TenantInfo {
        let tenant = Tenant(tenantID: "", tenantName: "", i18nTenantNames: nil, iconURL: "", tenantTag: nil, tenantBrand: TenantBrand.feishu, tenantGeo: nil, isFeishuBrand: true, tenantDomain: nil, tenantFullDomain: nil)
        return TenantInfo(tenant: tenant)
    }
}
