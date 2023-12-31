//
//  User.swift
//  LarkAccountInterface
//
//  Created by au on 2021/5/23.
//

import Foundation
import LarkLocalizations

// swiftlint:disable missing_docs

public enum PassportUserType {
    // swiftlint:disable identifier_name
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
}

/// 侧边栏等场景下用户状态，背后是各种`表现状态(UserExpressiveStatus)`的聚合
public enum UserStatus: Int {

    /// `活跃`，用户 Session 有效，侧边栏头像正常显示
    case normal = 0

    /// `新`，新用户申请，团队管理员通过审核，有 New 角标
    case new = 1

    /// `失效`，用户 Session 失效，侧边栏头像浅色显示
    case invalid = 2

    /// `不可登录`，可能是：被平台封禁、管理员冻结或凭证未验证等，有警告角标
    case restricted = 3
}

/// 用于客户自定义的用户信息
public struct UserCustomAttr: Codable {
    public let attrID: String
    public let type: String
    public let value: UserCustomAttrValue

    enum CodingKeys: String, CodingKey {
        case attrID = "id"
        case type = "type"
        case value = "value"
    }

    public func convertToDictionary() -> Dictionary<String, Any>? {
        var dict: Dictionary<String, Any>? = nil
        do {
            let data = try JSONEncoder().encode(self)
            dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any>
        } catch {
            
        }
        return dict
    }
}

public struct UserCustomAttrValue: Codable {
    public let text: String?
    public let url: String?
    public let pcURL: String?
    public let optionID: String?
    public let optionValue: String?
    public let name: String?
    public let pictureURL: String?
    public let genericUser: UserCustomAttrGenericUser?

    enum CodingKeys: String, CodingKey {
        case text = "text"
        case url = "url"
        case pcURL = "pc_url"
        case optionID = "option_id"
        case optionValue = "option_value"
        case name = "name"
        case pictureURL = "picture_url"
        case genericUser = "generic_user"
    }
}

public struct UserCustomAttrGenericUser: Codable {
    public let type: Int
    public let userID: String

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case userID = "id"
    }
}

public struct User {

    // MARK: 以下新账号模型使用字段

    public let userID: String
    public let userStatus: UserStatus
    public let name: String
    public let displayName: String?
    public let avatarURL: String
    public let avatarKey: String
    public let logoutToken: String?
    public let tenant: Tenant
    public let createTime: TimeInterval
    public let isExcludeLogin: Bool

    /// 客户自定义用户信息
    public let userCustomAttr: [UserCustomAttr]?

    /// 多语言的name和displayname结构
    public let i18nNames: I18nName?
    public let i18nDisplayNames: I18nName?

    /// 用户 Unit
    public let userUnit: String?

    /// 用户国家或地区归属
    public let geo: String

    /// 用户 geo 是否为中国大陆地区
    public let isChinaMainlandGeo: Bool

    /// 相当于原 Account 结构中的 accessToken
    public let sessionKey: String?

    /// 相当于原 Account 结构中的 accessTokens, 用于 Cookie 组装
    /// 业务方请使用 AccountServiceCore.sessionKeyWithDomains 读取
    public let sessionKeyWithDomains: [String: [String: String]]?
    
    public let leanModeInfo: LeanModeInfo?

    /// 是否是租户创建者
    public let isTenantCreator: Bool

    public let deviceLoginID: String?

    // MARK: 以下兼容老版本 Account 字段，未来版本中将会被移除，请尽量避免使用

    @available(*, deprecated, message: "Will be removed soon.")
    public let enName: String

    @available(*, deprecated, message: "Will be removed soon.")
    public let tenantConfig: TenantConfig

    @available(*, deprecated, message: "Will be removed soon.")
    public let userEnv: String?

    @available(*, deprecated, message: "Will be removed soon.")
    public let securityConfig: SecurityConfig?

    @available(*, deprecated, message: "Will be removed soon.")
    public let isIdP: Bool?

    @available(*, deprecated, message: "Will be removed soon.")
    public let isFrozen: Bool

    @available(*, deprecated, message: "Will be removed soon.")
    public let isActive: Bool

    @available(*, deprecated, message: "Will be removed soon.")
    public let isGuest: Bool?

    @available(*, deprecated, message: "Will be removed soon.")
    public let upgradeEnabled: Bool?

    @available(*, deprecated, message: "Will be removed soon.")
    public let authMode: String?

    public init(userID: String, userStatus: UserStatus, name: String, displayName: String?, i18nNames: I18nName?, i18nDisplayNames: I18nName?, userCustomAttr: [UserCustomAttr]?, avatarURL: String, avatarKey: String, logoutToken: String? = nil, tenant: Tenant, createTime: TimeInterval, enName: String, sessionKey: String?, sessionKeyWithDomains: [String: [String: String]]? = nil, userEnv: String? = nil, userUnit: String? = nil, geo: String, isChinaMainlandGeo: Bool = true, securityConfig: SecurityConfig? = nil, isIdP: Bool? = nil, isFrozen: Bool, isActive: Bool, isGuest: Bool? = nil, upgradeEnabled: Bool? = nil, authMode: String? = nil, isExcludeLogin: Bool = false, leanModeInfo: LeanModeInfo?, isTenantCreator: Bool?, deviceLoginID: String?) {
        self.userID = userID
        self.userStatus = userStatus
        self.name = name
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.avatarKey = avatarKey
        self.logoutToken = logoutToken
        self.tenant = tenant
        self.createTime = createTime
        self.enName = enName
        self.sessionKey = sessionKey
        self.sessionKeyWithDomains = sessionKeyWithDomains
        if tenant.isByteDancer {
            self.tenantConfig = TenantConfig.default
        } else {
            self.tenantConfig = TenantConfig.other
        }
        self.userEnv = userEnv
        self.userUnit = userUnit
        self.geo = geo
        self.isChinaMainlandGeo = isChinaMainlandGeo
        self.securityConfig = securityConfig
        self.isIdP = isIdP
        self.isFrozen = isFrozen
        self.isActive = isActive
        self.isGuest = isGuest
        self.upgradeEnabled = upgradeEnabled
        self.authMode = authMode
        self.isExcludeLogin = isExcludeLogin
        self.i18nNames = i18nNames
        self.i18nDisplayNames = i18nDisplayNames
        self.leanModeInfo = leanModeInfo
        self.userCustomAttr = userCustomAttr
        self.isTenantCreator = isTenantCreator ?? false
        self.deviceLoginID = deviceLoginID
    }

    public var type: PassportUserType {
        if tenant.tenantID == "0" {
            return .c
        }
        let defaultUserType: PassportUserType = .standard
        let userType: PassportUserType
        if let tenantTag = tenant.tenantTag {
            switch tenantTag {
            case .standard:
                userType = .standard
            case .undefined:
                userType = .undefined
            case .simple:
                userType = .simple
            case .unknown:
                userType = .undefined
            }
        } else {
            userType = defaultUserType
        }
        return userType
    }

    public var userTypeInString: String {
        let defaultUserType = "2"
        let map: [PassportUserType: String] = [
            .standard: "0",
            .undefined: "1",
            .simple: "2"
        ]

        let result = map[self.type] ?? defaultUserType
        return result
    }

    public var localizedName: String {
        self.i18nNames?.currentLocalName ?? self.name
    }
    public var localizedDisplayName: String {
        if let displayName = self.displayName {
            return self.i18nDisplayNames?.currentLocalName ?? displayName
        } else {
            return self.i18nNames?.currentLocalName ?? name
        }
    }

    public var isIdPUser: Bool { isIdP ?? false }

    /// 游客User
    public var isGuestUser: Bool { isGuest ?? false }

    public var singleProductTypes: [TenantSingleProductType]? {
        return self.tenant.singleProductTypes
    }

    public var canUpgradeTeam: Bool {
        // 2 : simple
        upgradeEnabled ?? (tenant.tenantTag == .simple)
    }

    public var userCustomAttrMap: [[String: Any]] {
        guard let attr = userCustomAttr else { return [] }
        return attr.compactMap {
            $0.convertToDictionary()
        }
    }

    /// 用于收敛控制是否开启用户ID一致性校验, 校验不通过时通常会进入容错处理
    /// NOTE：这个调用有FG控制，FG关闭时会忽略检查始终返回true, 用于回滚一些异常case
    public static func expect(user: String?, equal to: String?) -> Bool {
        if !validateUserID() { return true }
        return user == to
    }
    /// FG用于控制是否开启用户ID一致性的校验, 可注入修改返回值
    public static var validateUserID = { true }
}

public struct I18nName: Codable {
    let zhCN: String?
    let enUS: String?
    let jaJP: String?
    enum CodingKeys: String, CodingKey {
        case zhCN = "zh_cn"
        case enUS = "en_us"
        case jaJP = "ja_jp"
    }

    /*
     展示多语言的逻辑
     如果有中、日、英，则直接展示对应语言
     “非中文”语言默认用英文兜底
     如果没有英文则用默认name兜底（这段逻辑需要使用方写）
    */
    public var currentLocalName: String? {
        //多语言的逻辑
        var i18nName: String? = nil
        switch LanguageManager.currentLanguage {
        case .zh_CN, .zh_TW, .zh_HK:
            if let zhName = self.zhCN, zhName != "" {
                i18nName = zhName
            }
        case .en_US:
            if let enName = self.enUS, enName != "" {
                i18nName = enName
            }
        case .ja_JP:
            //日文需要考虑如果没有日文名，要兜底到英文
            if let jaName = self.jaJP, jaName != "" {
                i18nName = jaName
            } else {
                fallthrough
            }
        default:
            if let enName = self.enUS, enName != "" {
                i18nName = enName
            }
        }
        // 此时有可能返回一个nil，在外部调用时需要用默认name兜底
        return i18nName
    }
}

// swiftlint:enable missing_docs
