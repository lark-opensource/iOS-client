//
//  MailManager.swift
//  MailSDK
//
//  Created by 谭志远 on 2019/6/10.
//

import RxSwift
import LarkUIKit
import RustPB
import LKCommonsLogging
import Homeric

// TODO: 这里暴露的修改状态接口过多，不利于后续维护。找时间收敛相似的接口
public struct MailUserInfoResp {
    var name: String?
    var avatarKey: String?
    var address: MailAddress?
    var department: String?

    public init(name: String?, avatarKey: String?, address: MailAddress?, department: String?) {
        self.name = name
        self.avatarKey = avatarKey
        self.address = address
        self.department = department
    }
}

public protocol MailSDKAPI {
    func getUserInfo() -> MailUserInfoResp
    func getUserEmailAddress() -> MailAddress
    func getUserAvatarKey() -> String
    func getUserName() -> String
    func getAppConfigUrl(by key: String) -> URL?
    func getUserAvatarKey(userId: String) -> Observable<String>
    func getUserTenantId(userId: String) -> Observable<String>
    func getAvatarUrl(entityID: String, avatarkey: String) -> Observable<String>
    func getGloballyEnterChatPosition() -> Int64
}

final class MailModelManager {
    static let shared = MailModelManager()
    private static let logger = Logger.log(MailModelManager.self, category: "Module.MailManager")
    private var useridAndAvatar = NSCache<NSString, NSString>()
    private var useridAvatarKey = NSCache<NSString, NSString>()

    public var mailAPI: MailSDKAPI!
}

// MARK: - ReadMail
extension MailModelManager {
    func setAvatar(userid: String, path: String) {
        self.useridAndAvatar.setObject((path as NSString), forKey: (userid as NSString))
    }

    func getAvatar(userid: String) -> String {
        return (self.useridAndAvatar.object(forKey: (userid as NSString)) as String?) ?? ""
    }

    func removeAvatar(userid: String) {
        self.useridAndAvatar.removeObject(forKey: userid as NSString)
    }

    func setAvatarKey(userid: String, avatarKey: String) {
        self.useridAvatarKey.setObject((avatarKey as NSString), forKey: (userid as NSString))
    }

    func getAvatarKey(userid: String) -> String {
        return (self.useridAvatarKey.object(forKey: (userid as NSString)) as String?) ?? ""
    }
}

// MARK: - UserProfile
extension MailModelManager {
    func getUserInfo() -> MailUserInfoResp {
        return self.mailAPI.getUserInfo()
    }

    func getUserEmailAddress() -> MailAddress {
        return self.mailAPI.getUserEmailAddress()
    }

    func getUserAvatarKey() -> String {
        return self.mailAPI.getUserAvatarKey()
    }

    func getUserTenantId(userId: String) -> Observable<String> {
        return self.mailAPI.getUserTenantId(userId: userId)
    }

    func getUserAvatarKey(userId: String) -> Observable<String> {
        return self.mailAPI.getUserAvatarKey(userId: userId).do { (avatarKey) in
            MailModelManager.shared.setAvatarKey(userid: userId, avatarKey: avatarKey)
        }
    }

    func getAvatarUrl(entityID: String, avatarkey: String) -> Observable<String> {
        return self.mailAPI.getAvatarUrl(entityID: entityID, avatarkey: avatarkey)
    }

    func getUserName() -> String {
        return self.mailAPI.getUserName()
    }
}

// MARK: - UserAppConfig
extension MailModelManager {
    func getAppConfigUrl(by key: String) -> URL? {
        return self.mailAPI.getAppConfigUrl(by: key)
    }
    
    func getGloballyEnterChatPosition() -> Int64 {
        return self.mailAPI.getGloballyEnterChatPosition()
    }
}
