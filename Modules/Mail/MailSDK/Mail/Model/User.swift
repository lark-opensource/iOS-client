//
//  UserProfileManager.swift
//  DataSource
//
//  Created by weidong fu on 29/11/2017.
//

import Foundation
import SwiftyJSON
import RustPB
import LKCommonsLogging
import RxSwift
import ThreadSafeDataStructure

public typealias RefreshProfile = (_ error: Error?) -> Void
public final class User {
    static let logger = Logger.log(User.self, category: "Module.User")

    var mailConfig: UserMailConfig?

    private(set) var userID: String
    private(set) var tenantID: String
    private(set) var token: String?
    private(set) var domain: String
    private(set) var emailDomains: [String]?
    private(set) var info: UserInfo?
    private(set) var isOverSea: Bool?
    private(set) var avatarKey: String

    private var tenantName: String?
    private var disposeBag: DisposeBag = DisposeBag()
//    private var setting: SafeAtomic<Email_Client_V1_Setting?> = nil + .readWriteLock

    /// 0: userID, 1: tenantID, 2: token
//    public typealias userInfo = ((userID: String, tenantID: String, tenantName: String, token: String, isOverSea: Bool, avatarKey: String))

    public typealias UserPartialInfo = (userID: String,
                                        tenantID: String,
                                        tenantName: String,
                                        token: String?,
                                        isOverSea: Bool,
                                        avatarKey: String)


    init(userInfo: UserPartialInfo, domain: String) {
        User.logger.info("update user \(userInfo.userID)")
        self.userID = userInfo.userID
        self.tenantID = userInfo.tenantID
        self.tenantName = userInfo.tenantName
        self.isOverSea = userInfo.isOverSea
        self.token = userInfo.token
        self.domain = domain
        self.avatarKey = userInfo.avatarKey
        MailNetConfig.userID = userInfo.userID
        DispatchQueue.global(qos: .userInitiated).async {
            let tempInfo = UserInfo()
            tempInfo.userID = self.userID
            tempInfo.tenantID = self.tenantID
            tempInfo.tenantName = self.tenantName
            DispatchQueue.main.async {
                self.info = tempInfo
            }
        }
    }

//    func updateUserSetting(updateSetting: Email_Client_V1_Setting) {
//        setting.value = updateSetting
//    }

    func getUserSetting() -> Email_Client_V1_Setting? {
        return Store.settingData.getCachedCurrentSetting()
    }

    func fetchEmailDomain() {
        if self.emailDomains != nil {
            return
        }
        MailDataServiceFactory.commonDataService?.fetchEmailDomain()
            .subscribe(onNext: { [weak self] (res) in
                guard let `self` = self else { return }
                self.emailDomains = res.domains
            }, onError: { (error) in
                User.logger.error("fetchEmailDomain failed", error: error)
            }).disposed(by: disposeBag)
    }

    func getUndoConfig() -> (enable: Bool, time: Int64) {
        if let setting = getUserSetting() {
            return (enable: setting.undoSendEnable, time: setting.undoTime)
        }
        return (false, 0)
    }
}

extension User {
    var myMailAddress: String? {
        // 优先使用mailConfig里面的
        if let mailConfig = mailConfig,
            let address = mailConfig.mailAddress,
            !address.address.isEmpty {
            return address.address
        }
        // 使用info里的兜底
        return info?.mailAddress
    }
}

@objcMembers
final class UserInfo: NSObject {
    var name: String?
    var nameEn: String?
    var avatarURL: String?
    var userID: String?
    var tenantID: String?
    var tenantName: String?
    var departmentName: String?
    var email: String?
    /// 这个是从主端统一接口获取的email地址，如果你是想拿自己email，请使用：myMailAddress
    var mailAddress: String?
}
