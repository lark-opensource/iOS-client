//
//  UserProfileManager.swift
//  DataSource
//
//  Created by weidong fu on 29/11/2017.
//

import Foundation
import SwiftyJSON
import SQLite
import SKFoundation
import RxSwift
import RxRelay
import SpaceInterface
import SKInfra
import LarkContainer

/// 接口文档：https://bytedance.feishu.cn/docs/doccn7d2jXcJ2QFCo9oMdjUTUIA?new_source=message
public enum SKUserType: String {
    /// B端用户即企业版用户
    case standard = "0"
    /// 新的个人用户，即 "小B"
    case simple = "2"
    /// C端用户，之前的个人用户，即租户为 "0"
    case c = ""
    /// unknown user
    case undefined
}

public extension CCMExtension where Base == UserResolver {

    var user: User? {
        if CCMUserScope.commonEnabled {
            let obj = try? base.resolve(type: User.self)
            return obj
        } else {
            return User.singleInstance
        }
    }
}

final public class User {
    
    fileprivate static let singleInstance = User(userResolver: nil) //TODO.chensi 用户态迁移完成后删除旧的单例代码
    
    @available(*, deprecated, message: "new code should use `userResolver.docs.user`")
    public static var current: User {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: true)
        if let obj = userResolver.docs.user {
            return obj
        }
        spaceAssertionFailure("basically impossible, contact chensi.123")
        return singleInstance
    }
    
    let userResolver: UserResolver? // 为nil表示单例
    
    public init(userResolver: UserResolver?) {
        self.userResolver = userResolver
    }
    
    deinit {
        if let ur = self.userResolver { // 用户态实例
            CCMKeyValue.userDefault(ur.userID).set(nil, forKey: "DocsCoreDefaultPrefix_UserProperties")
            DocsLogger.info("user logout: \(ur.userID)")
        }
        DocsLogger.info("SKCommon.User deinit: \(ObjectIdentifier(self))")
    }
    
    public var token: String? {
        return info?.session
    }

    /// 用户是否是飞书文档单品用户
    public var isSingleProduct: Bool? {
        get {
            return info?.isSingleProduct
        }
        set {
            info?.isSingleProduct = newValue
        }
    }

    /// 由于 Lark Tab 顺序不同，可能由于时序原因导致 User.current.info 还是 nil，这个时候就需要通过胶水层从 Lark 那边获取第一手信息
    public var basicInfo: BasicUserInfo? {
        if let currentInfo = info {
            return currentInfo
        }

        guard let docsManagerDelegate = HostAppBridge.shared.call(GetDocsManagerDelegateService()) as? DocsManagerDelegate else { return nil }

        return docsManagerDelegate.basicUserInfo
    }

    public private(set) var info: UserInfo?

    /// Will be updated in lark or LarkDocs
    public var userType: SKUserType? {
        get {
            return info?.userType
        }
        set {
            info?.userType = newValue
        }
    }
    
    public func reloadUserInfo(_ info: UserInfo) {
        self.info = info
    }
    
    /// Will update userID as well
    public func reloadUser(basicInfo info: BasicUserInfo) {
        self.info = UserInfo(info.userID, info.tenantID, info.session, info.isGuest) // 这一步会将 userID 刷新
        self.info?.updateUserPropertiesFromUserDefaults(about: info.userID)
        PreloadKey.cacheKeyPrefix = self.info?.cacheKeyPrefix ?? ""
        NetConfig.shared.userID = info.userID
    }

    public func refreshUserProfileIfNeed() {
        self.info?.refreshUserProfile()
    }

    public func logout() {
        info?.logout()
        info = nil
        DocsLogger.info("user logout")
    }

    public func watermarkText() -> String? {
        return info?.watermarkText()
    }

}

public class BasicUserInfo {
    public let userID: String
    public var tenantID: String
    public var session: String? // same as sid
    public var isGuest: Bool = false // 用户是否为游客

    public init(_ userID: String, _ tenantID: String = "", _ session: String? = nil, _ isGuest: Bool = false) {
        self.userID = userID
        self.tenantID = tenantID
        self.session = session
        self.isGuest = isGuest
    }
}

// BasicUserInfo 是通过胶水层向 Lark 索取的信息，UserInfo 继承它，通过网络请求或本机已有的 UserDefaults 信息来补充它

public final class UserInfo: BasicUserInfo {

    enum SpecialTenantID: String {
        case toC = "0"
        case bytedance = "1"
    }
    private var request: DocsRequest<UserInfo>?

    public private(set) var name: String?
    public private(set) var nameCn: String?
    public private(set) var nameEn: String?

    public private(set) var aliasInfo: UserAliasInfo?

    private(set) var email: String?
    /// 用户的手机号
    private(set) var mobile: String?
    public private(set) var isSuperAdmin: Bool = false
    public private(set) var avatarURL: String?
    public private(set) var tenantName: String?
    public private(set) var departmentID: String?
    /// 判断用户是否通过飞书文档注册
    public var isSingleProduct: Bool?
    public var userType: SKUserType?

    public func updatePropertiesFrom(_ json: JSON) {
        json["avatar_url"].string.map { self.avatarURL = $0 }
        json["tenant_id"].string.map { self.tenantID = $0 }
        json["tenant_name"].string.map { self.tenantName = $0 }
        json["en_name"].string.map { self.nameEn = $0 }
        json["name"].string.map { self.name = $0 }
        json["cn_name"].string.map { self.nameCn = $0 }
        json["department_id"].string.map { self.departmentID = $0 }
        json["mobile"].string.map { self.mobile = $0 }
        json["is_super_admin"].bool.map { self.isSuperAdmin = $0 }
        json["is_singleproduct"].bool.map { self.isSingleProduct = $0 }
        json["tenant_tag"].string.map { self.userType = SKUserType(rawValue: $0) ?? .undefined }
        json["domain"].string.map { domain in
            if DocsSDK.isInDocsApp {
                DomainConfig.updateUserDomain(domain)
                DocsLogger.info("set userDomain: \(domain))", component: LogComponents.domain)
            }
        }
        json["display_name"].mapIfExists { aliasJSON in
            self.aliasInfo = UserAliasInfo(json: aliasJSON)
        }
    }

    public func updatePropertiesFromV2(_ json: [String: Any]) {
        let assigner = DataAssigner(target: self, data: json)
        assigner.assignIfPresent(key: "avatar_url", keyPath: \.avatarURL)
        assigner.assignIfPresent(key: "tenant_id", keyPath: \.tenantID)
        assigner.assignIfPresent(key: "tenant_name", keyPath: \.tenantName)
        assigner.assignIfPresent(key: "en_name", keyPath: \.nameEn)
        assigner.assignIfPresent(key: "name", keyPath: \.name)
        assigner.assignIfPresent(key: "cn_name", keyPath: \.nameCn)
        assigner.assignIfPresent(key: "department_id", keyPath: \.departmentID)
        assigner.assignIfPresent(key: "mobile", keyPath: \.mobile)
        assigner.assignIfPresent(key: "is_super_admin", keyPath: \.isSuperAdmin)
        assigner.assignIfPresent(key: "is_singleproduct", keyPath: \.isSingleProduct)
        if let userRawType = json["tenant_tag"] as? String {
            userType = SKUserType(rawValue: userRawType) ?? .undefined
        }

        if let domain = json["domain"] as? String, !domain.isEmpty, DocsSDK.isInDocsApp {
            DomainConfig.updateUserDomain(domain)
            DocsLogger.info("set userDomain: \(domain))", component: LogComponents.domain)
        }

        if let aliasData = json["display_name"] as? [String: Any] {
            self.aliasInfo = UserAliasInfo(data: aliasData)
        }
    }
}

extension UserInfo {
    public func makeCopy() -> UserInfo {
        let newUser = UserInfo(userID, tenantID, session, isGuest)
        newUser.name = name
        newUser.nameCn = nameCn
        newUser.nameEn = nameEn
        newUser.email = email
        newUser.mobile = mobile
        newUser.isSuperAdmin = isSuperAdmin
        newUser.avatarURL = avatarURL
        newUser.tenantName = tenantName
        newUser.departmentID = departmentID
        newUser.userType = userType
        newUser.isSingleProduct = isSingleProduct
        newUser.aliasInfo = aliasInfo
        return newUser
    }
}

// MARK: - 衍生信息
extension UserInfo {
    public var enctypedId: String {
        return DocsTracker.encrypt(id: userID)
    }

    ///老的C端用户，租户为 "0"
    public var isToC: Bool {
        return tenantID == SpecialTenantID.toC.rawValue
    }

    ///新的C端用户属性，包含有最新飞书个人版用户和老的C端用户
    public var isToNewC: Bool {
        return (userType == SKUserType.simple) || (userType == SKUserType.c)
    }
    public var isBytedance: Bool {
        return tenantID == SpecialTenantID.bytedance.rawValue
    }
    public var cacheKeyPrefix: String? {
        guard !tenantID.isEmpty else { return nil }
        return tenantID + "_" + userID + "_"
    }

    public var dbUserKey: String? {
        guard !tenantID.isEmpty else { return nil }
        return userID + "_" + tenantID
    }

    // TODO: alias 确认下水印用本名还是别名
    public func watermarkText() -> String? {
        guard let mobile = mobile else {
            //            spaceAssertionFailure("info mobile nil")
            return nil
        }

        var markText = ""
        if I18nUtil.currentLanguage == I18nUtil.LanguageType.zh_CN {
            guard let name = name else {
                spaceAssertionFailure("info name nil")
                return nil
            }
            markText = name
        } else {
            guard let nameEn = nameEn else {
                spaceAssertionFailure("info nameEn nil")
                return nil
            }
            markText = nameEn
        }
        markText += "   \(mobile)"
        return markText
    }

    public func nameForDisplay() -> String {
        if let aliasName = aliasInfo?.currentLanguageDisplayName {
            return aliasName
        }
        var userName = ""
        if DocsSDK.currentLanguage == .en_US, let enName = nameEn, let cnName = nameCn {
            userName = enName.count > 0 ? enName : cnName
        } else if let name = name {
            userName = name
        } else if let cnName = nameCn {
            userName = cnName
        } else {
            spaceAssertionFailure()
        }
        return userName
    }

}

// MARK: - 更新信息的逻辑
extension UserInfo {
    /// 0: userID, 1: tenantID, 2: token
    public func updateUserPropertiesFromUserDefaults(about userID: String) {
        if let data = CCMKeyValue.userDefault(userID).data(forKey: "DocsCoreDefaultPrefix_UserProperties") {
            if let infoDic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                self.updatePropertiesFrom(JSON(infoDic))
            }
        }
    }

    func logout() {
        CCMKeyValue.userDefault(userID).set(nil, forKey: "DocsCoreDefaultPrefix_UserProperties")
        tenantID = ""
        session = nil
        isGuest = true
    }

    public func refreshUserProfile() {
        request?.cancel()
        request = DocsRequest<UserInfo>(path: OpenAPI.APIPath.userProfile, params: nil)
            .set(method: .GET)
            .set(transform: {[weak self] (response) -> (UserInfo?, error: Error?) in
                guard let self = self, let dataDic = response?["data"].dictionaryObject else {
                    return (nil, DocsNetworkError.parse)
                }
                DispatchQueue.main.async {
                    self.updatePropertiesFrom(JSON(dataDic))
                    if let uid = dataDic["suid"] as? String, JSONSerialization.isValidJSONObject(dataDic), let data = try? JSONSerialization.data(withJSONObject: dataDic, options: []) {
                        CCMKeyValue.userDefault(uid).set(data, forKey: "DocsCoreDefaultPrefix_UserProperties")
                    }
                }
                return (self, nil)
            })
            .start(result: { (_, _) in })
    }
}
