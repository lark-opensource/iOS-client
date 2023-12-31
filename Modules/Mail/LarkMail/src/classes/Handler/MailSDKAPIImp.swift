//
//  MailSDKAPIImp.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/6/28.
//

import Foundation
import MailSDK
import RxSwift
import LarkModel
import LKCommonsLogging
import LarkAccountInterface
import LarkSDKInterface
import LarkFeatureGating
import Swinject
import LarkNavigation
import LarkContainer

// MailSDKAPI 的实现。
final class MailSDKApiWrapper: MailSDKAPI {
    
    
    var hasConstruct: Bool = false

    private let disposeBag = DisposeBag()

    private static let logger = Logger.log(MailSDKApiWrapper.self, category: "Module.MailSDKApiWrapper")

    private var chatterAPI: ChatterAPI?

    private var resourceAPI: ResourceAPI?

    private var userAppConfig: UserAppConfig?
    
    private var userUniversalSettingService: UserUniversalSettingService?
    
    private var passportService: PassportUserService?

    private var currentChatterBlock: (() -> Chatter?) = { nil }
    private var currentChatter: Chatter? { currentChatterBlock() }

    private var userProfile: UserProfile?

    /// 二维码、分享链接进来此界面有token
    private var contactToken: String = ""
    /// 是否是异步请求获取用户信息
    private var isRemote: Bool = false

    func setChatterAPI(_ chatterAPI: ChatterAPI?) {
        self.chatterAPI = chatterAPI
    }

    func setResourceAPI(_ resourceAPI: ResourceAPI?) {
        self.resourceAPI = resourceAPI
    }

    func setUserAppConfig(_ userAppConfig: UserAppConfig?) {
        self.userAppConfig = userAppConfig
    }
    
    func setUserUniversalSettingService(_ userUniversalSettingService: UserUniversalSettingService?) {
        self.userUniversalSettingService = userUniversalSettingService
    }

    func setPassportService(_ passportService: PassportUserService?) {
        self.passportService = passportService
    }

    func setCurrentAccount(_ currentAccount: @escaping () -> Chatter?) {
        self.currentChatterBlock = currentAccount
    }

    func clean() {
        userProfile = nil
        NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SDK_CLEAN_DATA, object: nil)
    }

    func getUserInfo() -> MailSDK.MailUserInfoResp {
        guard let currentChatter = currentChatter else {
            return MailSDK.MailUserInfoResp(name: nil, avatarKey: nil, address: nil, department: nil)
        }
        let email = currentChatter.email ?? ""
        let name = currentChatter.displayName
        let avatarKey = currentChatter.avatarKey
        let department = currentChatter.department
        let larkId = currentChatter.id
        let tenantId = currentChatter.tenantId
        let address = MailSDK.MailAddress(name: name,
                                          address: email,
                                          larkID: larkId,
                                          tenantId: tenantId,
                                          displayName: "",
                                          type: nil)
        return MailSDK.MailUserInfoResp(name: name, avatarKey: avatarKey, address: address, department: department)
    }

    func getUserEmailAddress() -> MailSDK.MailAddress {
        guard let currentChatter = currentChatter else {
            return MailSDK.MailAddress(name: "", address: "", larkID: "", tenantId: "", displayName: "", type: nil)
        }
        let email = currentChatter.email ?? ""
        let name = currentChatter.displayName
        let larkId = currentChatter.id
        let tenantId = currentChatter.tenantId
        let address = MailSDK.MailAddress(name: name,
                                          address: email,
                                          larkID: larkId,
                                          tenantId: tenantId,
                                          displayName: "",
                                          type: nil)
        return address
    }

    func getUserName() -> String {
        return currentChatter?.displayName ?? ""
    }

    func getUserAvatarKey() -> String {
        return currentChatter?.avatarKey ?? ""
    }

    func getUserAvatarKey(userId: String) -> Observable<String> {
        guard let chatterAPI = chatterAPI else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return chatterAPI
            .getChatter(id: userId)
            .observeOn(MainScheduler.instance)
            .map { (res) -> String in
                guard let chatter = res else {
                    MailSDKApiWrapper.logger.debug("getUserAvatarKey get nil chatter")
                    return ""
                }
            return chatter.avatarKey
            }
    }

    func getUserTenantId(userId: String) -> Observable<String> {
        guard let chatterAPI = chatterAPI else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return chatterAPI
            .getChatter(id: userId)
            .observeOn(MainScheduler.instance)
            .map { (res) -> String in
                guard let chatter = res else {
                    MailSDKApiWrapper.logger.debug("getUserAvatarKey get nil chatter")
                    return ""
                }
                return chatter.tenantId
            }
    }

    func getAvatarUrl(entityID: String, avatarkey: String) -> Observable<String> {
        guard let resourceAPI = resourceAPI else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        // 使用新接口新逻辑。
        let pathSize: Int32 = 48
        return resourceAPI.fetchResourcePath(entityID: entityID,
                                                  key: avatarkey,
                                                  size: pathSize,
                                                  dpr: Float(UIScreen.main.scale),
                                                  format: "jpeg").observeOn(MainScheduler.instance)

    }

    func getAppConfigUrl(by key: String) -> URL? {
        guard let userAppConfig = userAppConfig,
              let str = userAppConfig.resourceAddrWithLanguage(key: key)
        else { return nil }

        return URL(string: str)
    }
    
    func getGloballyEnterChatPosition() -> Int64 {
        guard let userUniversalSettingService = userUniversalSettingService else { return 1 }
        return userUniversalSettingService.getIntUniversalUserSetting(key: "GLOBALLY_ENTER_CHAT_POSITION") ?? 1
    }
    
}
