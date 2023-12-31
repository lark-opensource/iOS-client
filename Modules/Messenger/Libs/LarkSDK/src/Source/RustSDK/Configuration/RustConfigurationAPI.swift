//
//  RustConfigurationAPI.swift
//  Lark
//
//  Created by Sylar on 2017/11/15.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
import LarkAccountInterface
import LKCommonsLogging
import ServerPB
import LarkStorage
import LarkContainer

final class RustConfigurationAPI: LarkAPI, ConfigurationAPI {

    private static let logger = Logger.log(RustConfigurationAPI.self, category: "TranslateLanguage")

    private let deviceId: String

    init(client: SDKRustService, onScheduler: ImmediateSchedulerType?, deviceId: String) {
        self.deviceId = deviceId
        super.init(client: client, onScheduler: onScheduler)
    }

    /// 获取字节云平台指定key对应的value
    func fetchSettingsRequest(fields: [String]) -> Observable<[String: String]> {
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = fields
        return self.client.sendAsyncRequest(request, transform: { (response: GetSettingsResponse) -> [String: String] in
            return response.fieldGroups
        }).subscribeOn(scheduler)
    }

    /// 获取翻译设置 只在UserGeneralSettings中使用
    func fetchTranslateLanguageSetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<TranslateLanguageSetting> {
        var request = RustPB.Im_V1_GetTranslateLanguagesRequest()
        request.syncDataStrategy = strategy
        return self.client.sendAsyncRequest(request) { [weak self] (response: GetTranslateLanguagesResponse) -> TranslateLanguageSetting in
            var translateLanguageSetting: TranslateLanguageSetting = TranslateLanguageSetting()
            guard let self = self else { return translateLanguageSetting }
            translateLanguageSetting.targetLanguage = response.targetLanguage
            translateLanguageSetting.languageKeys = response.languageKeys
            translateLanguageSetting.imageLanguageKeys = response.imageLanguageKeys
            translateLanguageSetting.webLanguageKeys = response.webLanguageKeys
            translateLanguageSetting.supportedLanguages = response.supportedLanguages
            translateLanguageSetting.globalConf = response.globalConf
            translateLanguageSetting.languagesConf = response.languagesConf
            translateLanguageSetting.translateScope = Int(response.switchScopes)
            translateLanguageSetting.translateScopeConfiguration = Dictionary(uniqueKeysWithValues: response.scopes.map { (Int($0), $1) })
            translateLanguageSetting.disAutoTranslateLanguagesConf = response.disAutoTranslateLanguagesConf
            translateLanguageSetting.autoTranslateGlobalSwitch = response.autoTranslateGlobalSwitch
            translateLanguageSetting.srcLanugages = response.srcLanugages
            translateLanguageSetting.srcLanguagesConfig = response.srcLanguagesConfig
            translateLanguageSetting.trgLanguagesConfig = response.trgLanguagesConfig
            translateLanguageSetting.webTranslationConfig = response.webTranslationConfig

            KVPublic.AI.messageCharThreshold.setValue(Int(response.userMainLanguageConfig.messageCharacterThreshold))
            KVPublic.AI.mainLanguage.setValue(response.userMainLanguageConfig.mainLanguage)
            // log
            self.handleTranslateSettingLogging(settings: translateLanguageSetting)
            return translateLanguageSetting
        }.subscribeOn(scheduler)
    }

    /// 设置自动翻译开关
    func setAutoTranslateGlobalSwitch(isOpen: Bool) -> Observable<Void> {
        var request = RustPB.Im_V1_SetAutoTranslateGlobalSwitchRequest()
        request.isOpen = isOpen
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 设置翻译目标语言 只在UserGeneralSettings中使用
    func updateTranslateLanguageSetting(language: String) -> Observable<Void> {
        var request = RustPB.Im_V1_SetTranslateLanguageRequest()
        request.language = language
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 设置翻译语言key->翻译效果 只在UserGeneralSettings中使用
    func updateLanguagesConfiguration(globalConf: RustPB.Im_V1_LanguagesConfiguration?, languagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]?) -> Observable<Void> {
        var request = RustPB.Im_V1_PutLanguagesConfigurationRequest()
        /// 如传globalConf，那所有languagesConf会相应修改，且服务器不会判断languagesConf
        if let conf = globalConf {
            request.globalConf = conf
        }
        if let languagesConf = languagesConf {
            request.languagesConf = languagesConf
        }
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 设置翻译显示翻译效果开关(一级)
    func updateGlobalLanguageDisplayConfig(globalConf: RustPB.Im_V1_LanguagesConfiguration) -> Observable<Void> {
        return updateLanguagesConfiguration(globalConf: globalConf, languagesConf: nil)
    }

    /// 设置翻译源语言(三级) 的翻译效果
    func updateLanguagesConfigurationV2(srcLanguagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]) -> Observable<Void> {
        var request = RustPB.Im_V1_PutLanguagesConfigurationV2Request()
        request.srcLanguagesConf = srcLanguagesConf
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 修改源语种自动翻译设置(三级)scopes范围
    func updateSrcLanguageScopes(srcLanguagesScope: Int, language: String) -> Observable<Void> {
        let srcLanguagesScope: [String: Int32] = [language: Int32(srcLanguagesScope)]
        var request = RustPB.Im_V1_PatchLanguagesAutoTranslationScopeRequest()
        request.srcLanguagesScope = srcLanguagesScope
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 设置TranslateScope，解释见TranslateLanguageSetting
    func updateAutoTranslateScope(scope: Int) -> Observable<Void> {
        var request = Im_V1_SetAutoTranslateScopeRequest()
        request.modifyScopes = Int32(scope)
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler).map({ _ in })
    }

    /// 设置不自动翻译的语言 只在UserGeneralSettings中使用
    func updateDisableAutoTranslateLanguages(languages: [String]) -> Observable<[String]> {
        var request = RustPB.Im_V1_PutDisableAutoTranslateLanguagesRequest()
        request.languageKeys = languages
        return self.client.sendAsyncRequest(request, transform: { (response: PutDisableAutoTranslateLanguagesResponse) -> [String] in
            return response.languageKeys
        }).subscribeOn(scheduler)
    }

    /// 获取某条消息的其他语言翻译内容 （原文, [译文]）
    func fetchMessageTranslateInfos(messageId: String) -> Observable<(MessageTranslateInfo, [MessageTranslateInfo])> {
        var request = RustPB.Im_V1_GetMessageTranslateInfosRequest()
        request.messageID = messageId
        return self.client.sendAsyncRequest(request, transform: { (response: GetMessageTranslateInfosResponse) -> (MessageTranslateInfo, [MessageTranslateInfo]) in
            /// 原文
            let originTranslateInfo = MessageTranslateInfo.transform(pb: response.originMessage)
            /// 译文
            let translateInfos = response.messageTranslateInfos.map({ (translateInfo) -> MessageTranslateInfo in
                return MessageTranslateInfo.transform(pb: translateInfo)
            })
            return (originTranslateInfo, translateInfos)
        }).subscribeOn(scheduler)
    }

    func updateDeviceSetting(language: String) -> Observable<DeviceSetting> {
        var request = RustPB.Device_V1_SetDeviceSettingRequest()
        request.deviceID = deviceId
        request.localeIdentifier = language
        return self.client.sendAsyncRequest(request, transform: { (response: SetDeviceSettingResponse) -> DeviceSetting in
            return DeviceSetting(language: response.localeIdentifier)
        }).subscribeOn(scheduler)
    }

    func getSystemMessageTemplate(language: String) -> Observable<Void> {
        var request = RustPB.Im_V1_GetSystemMessageTemplateRequest()
        request.localeIdentifier = language
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getWorkStatusSetting() -> Observable<Bool> {
        let request = RustPB.Settings_V1_GetUserSettingRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Settings_V1_GetUserSettingResponse) -> Bool in
            return response.autoUpdateWorkStatus
        }).subscribeOn(scheduler)
    }

    func getExternalDisplayTimezone() -> Observable<RustPB.Settings_V1_ExternalDisplayTimezoneSetting> {
        let request = RustPB.Settings_V1_GetUserSettingRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Settings_V1_GetUserSettingResponse) -> RustPB.Settings_V1_ExternalDisplayTimezoneSetting in
            return response.externalDisplayTimezone
        }).subscribeOn(scheduler)
    }

    func setWorkStatusSetting(isUpdate: Bool) -> Observable<Void> {
        var request = RustPB.Settings_V1_SetUserSettingRequest()
        request.autoUpdateWorkStatus = isUpdate
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 获取消息通知设置
    func getNotificationSetting() -> (Observable<(RustPB.Settings_V1_NotificationSetting, Bool)>) {
        let request = RustPB.Settings_V1_GetUserSettingRequest()
        var config = Basic_V1_RequestPacket.BizConfig()
        // 优先返回客户端数据，再返回服务端数据
        config.dataSource = .default
        return self.client.eventStream(request: request, config: config).map { (response: Settings_V1_GetUserSettingResponse) -> (RustPB.Settings_V1_NotificationSetting, Bool)in
            return (response.notificationSetting, response.messageNotificationsOffDuringCalls)
        }.subscribeOn(scheduler)
    }

    /// 设置消息通知 会中电话中免打扰
    func setNotificationSetting(setting: RustPB.Settings_V1_NotificationSetting?, messageNotificationsOffDuringCallsSetting: Bool?) -> Observable<Void> {
        var request = RustPB.Settings_V1_SetUserSettingRequest()
        if let tempsetting = setting {
            request.notificationSetting = tempsetting
        }
        if let tempduringcallsSetting = messageNotificationsOffDuringCallsSetting {
            request.messageNotificationsOffDuringCalls = tempduringcallsSetting
        }
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 获取消息通知设置v2
    func getNotificationSettingV2() -> Observable<RustPB.Settings_V1_NotificationSettingV2> {
        let request = Settings_V1_GetUserSettingRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: Settings_V1_GetUserSettingResponse) -> RustPB.Settings_V1_NotificationSettingV2 in
            return response.notificationSettingV2
        }).subscribeOn(scheduler)
    }

    /// 获取(大部分)用户设置
    func getMostUserSetting() -> Observable<RustPB.Settings_V1_GetUserSettingResponse> {
        let request = Settings_V1_GetUserSettingRequest()
        return self.client.sendAsyncRequest(request)
    }

    /// 设置消息通知v2
    func setNotificationSettingV2(setting: RustPB.Settings_V1_NotificationSettingV2) -> Observable<Void> {
        var request = Settings_V1_SetUserSettingRequest()
        request.notificationSettingV2 = setting
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 获取邮件通知设置
    func getMailNotificationSetting() -> Observable<RustPB.Email_Client_V1_MailNotificationSettings> {
        let request = Email_Client_V1_MailGetNotificationSettingsRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Email_Client_V1_MailNotificationSettingPushResponse) -> RustPB.Email_Client_V1_MailNotificationSettings in
            return response.notificationSettings
        }).subscribeOn(scheduler)
    }

    /// 设置邮件通知
    func setMailNotificationSetting(setting: RustPB.Email_Client_V1_MailNotificationSettings) -> Observable<Void> {
        var request = Email_Client_V1_MailSetNotificationSettingsRequest()
        request.notificationSettings = setting
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getAppConfig() -> Observable<RustPB.Basic_V1_AppConfig> {
        let request = RustPB.Basic_V1_GetAppConfigRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Basic_V1_GetAppConfigResponse) -> RustPB.Basic_V1_AppConfig in
            return response.appConfig
        }).subscribeOn(scheduler)
    }

    func getAppConfigFromLocal() -> RustPB.Basic_V1_AppConfig? {
        let request = RustPB.Basic_V1_GetAppConfigRequest()
        return try? self.client.sendSyncRequest(request, transform: { (response: RustPB.Basic_V1_GetAppConfigResponse) -> RustPB.Basic_V1_AppConfig in
            return response.appConfig
        })
    }

    func getAndReviseBadgeStyle() -> (Observable<RustPB.Settings_V1_BadgeStyle>, Observable<RustPB.Settings_V1_BadgeStyle>) {
        let req1 = GetUserSettingRequest()
        let ob1 = client.sendSyncRequest(req1) { (res: GetUserSettingResponse) -> RustPB.Settings_V1_BadgeStyle in
            return res.badgeStyle
        }.subscribeOn(scheduler)

        let req2 = GetUserSettingRequest()
        let ob2 = client.sendAsyncRequest(req2) { (res: GetUserSettingResponse) -> RustPB.Settings_V1_BadgeStyle in
            return res.badgeStyle
        }.subscribeOn(scheduler)

        return (ob1, ob2)
    }

    func setBadgeStyle(_ badgeStyle: RustPB.Settings_V1_BadgeStyle) -> Observable<Void> {
        var request = SetUserSettingRequest()
        request.badgeStyle = badgeStyle
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 设置是否显示主导航免打扰 badge
    func setShowTabMuteBadge(_ showMuteBadge: Bool) -> Observable<Void> {
        var request = Settings_V1_SetUserSettingRequest()
        request.navigationShowMuteBadge = showMuteBadge
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { _ in
                Self.logger.info("setShowTabMuteBadge: \(showMuteBadge)")
            }, onError: { (error) in
                Self.logger.error("setShowTabMuteBadge error: \(error), \(showMuteBadge)")
            })
    }

    /// 获取是否显示主导航免打扰 badge
    func fetchShowTabMuteBadge() -> Observable<Bool> {
        let request = RustPB.Settings_V1_GetUserSettingRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Settings_V1_GetUserSettingResponse) -> Bool in
            Self.logger.info("fetchShowTabMuteBadge: \(response.navigationShowMuteBadge)")
            return response.navigationShowMuteBadge
        }).subscribeOn(scheduler)
        .do(onError: { (error) in
            Self.logger.error("fetchShowTabMuteBadge error: \(error)")
        })
    }

    /// 本地获取一次好友隐私设置，找到/添加我
    func getAddFriendPrivateConfig() -> Observable<RustPB.Settings_V1_GetAddFriendPrivateConfigResponse> {
        var request = GetAddFriendPrivateConfigRequest()
        request.syncDataStrategy = .local
        request.version = .firstVersion
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 远程获取好友隐私设置，找到/添加我
    func fetchAddFriendPrivateConfig() -> Observable<RustPB.Settings_V1_GetAddFriendPrivateConfigResponse> {
        var request = GetAddFriendPrivateConfigRequest()
        request.syncDataStrategy = .forceServer
        request.version = .firstVersion
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 设置如何找到我
    func setWayToFindMeSetting(id: String, enable: Bool, verifyToken: String) -> Observable<Void> {
        var request = SetWayToFindMeSettingRequest()
        request.id = id
        request.enable = enable
        request.verifyToken = verifyToken
        request.version = .firstVersion
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 设置如何添加我
    func setWayToAddMeSetting(addMeType: RustPB.Settings_V1_WayToAddMeSettingItem.TypeEnum, enable: Bool) -> Observable<Void> {
        var request = SetWayToAddMeSettingRequest()
        request.addMeSetting.type = addMeType
        request.addMeSetting.enable = enable
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func fetchTimeFormat() -> Observable<RustPB.Settings_V1_TimeFormatSetting.TimeFormat> {
        let request = RustPB.Settings_V1_GetUserSettingRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Settings_V1_GetUserSettingResponse) -> RustPB.Settings_V1_TimeFormatSetting.TimeFormat in
            return response.timeFormat.timeFormat
        }).subscribeOn(scheduler)
    }

    func setTimeFormat(_ timeFormat: RustPB.Settings_V1_TimeFormatSetting.TimeFormat) -> Observable<Void> {
        var request = RustPB.Settings_V1_SetUserSettingRequest()
        request.timeFormat = TimeFormatSetting()
        request.timeFormat.timeFormat = timeFormat
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 获取勿扰模式截止ntp时间
    func fetchDoNotDisturbEndTime() -> Observable<Int64> {
        let request = RustPB.Settings_V1_GetUserSettingRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Settings_V1_GetUserSettingResponse) -> Int64 in
            return response.doNotDisturbEndTime
        })
    }

    /// 设置勿扰模式截止ntp时间，单位ms
    func setDoNotDisturbEndTime(time: Int64) -> Observable<Void> {
        var request = RustPB.Settings_V1_SetUserSettingRequest()
        request.doNotDisturbEndTime = time
        return self.client.sendAsyncRequest(request)
    }
    /// 设置语音自动转文字
    func setAudioToTextSetting(enable: Bool) -> Observable<Void> {
        var request = RustPB.Settings_V1_SetUserSettingRequest()
        request.autoAudioToText = enable
        return self.client.sendAsyncRequest(request)
    }

    /// 获取语音自动转文字设置
    func getAudioToTextSetting(isFromServer: Bool) -> Observable<Bool> {
        var request = RustPB.Settings_V1_GetUserSettingRequest()
        request.isFromServer = isFromServer
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Settings_V1_GetUserSettingResponse) -> Bool in
            return response.autoAudioToText
        })
    }

    func setSmsPhoneUrgent(accept: Bool) -> Observable<Void> {
        var request = SetUserSettingRequest()
        var setting = RustPB.Settings_V1_SmsPhoneUrgentSetting()
        setting.accept = accept
        request.smsPhoneUrgentSetting = setting
        return client.sendAsyncRequest(request)
    }

    func fetchSmsPhoneSetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<RustPB.Settings_V1_SmsPhoneUrgentSetting> {
        var request = RustPB.Settings_V1_GetUserSettingRequest()
        request.syncDataStrategy = strategy
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Settings_V1_GetUserSettingResponse) -> RustPB.Settings_V1_SmsPhoneUrgentSetting in
            return response.smsPhoneUrgentSetting
        })
    }

    func getFeedSetting() -> Observable<RustPB.Settings_V1_FeedSetting> {
        let request = RustPB.Settings_V1_GetUserSettingRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Settings_V1_GetUserSettingResponse) -> RustPB.Settings_V1_FeedSetting in
            return response.feedSetting
        })
    }
    func setFeedSetting(setting: RustPB.Settings_V1_FeedSetting) -> Observable<Void> {
        var request = RustPB.Settings_V1_SetUserSettingRequest()
        request.feedSetting = setting
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
    /// 查询屏蔽用户列表
    func getBlockUserListRequest(cursor: String) -> Observable<Contact_V2_GetBlockUserListResponse> {
        var request = RustPB.Contact_V2_GetBlockUserListRequest()
        request.cursor = cursor
        return self.client.sendAsyncRequest(request)
    }
    ///屏蔽用户数
    func getBlockUserNum() -> Observable<Contact_V2_GetBlockUserNumResponse> {
        let request = RustPB.Contact_V2_GetBlockUserNumRequest()
        return self.client.sendAsyncRequest(request)
    }

    /// 删除block用户
    func deleteBlockUserByID(_ id: String) -> Observable<Void> {
        var request = RustPB.Contact_V2_SetupBlockUserRequest()
        request.blockUserID = id
        request.blockStatus = false
        return self.client.sendAsyncRequest(request)
    }

    /// 设置当前用户对于全局非联系人发消息的权限设置
    func setupUserMsgAuth(type: RustPB.Contact_V2_MsgType) -> Observable<Void> {
        var request = RustPB.Contact_V2_SetupUserMsgAuthRequest()
        request.msgType = type
        return self.client.sendAsyncRequest(request)
    }

    /// 设置当前用户对于全局非联系人发消息的权限设置
    func setupExternalDisplayTimezoneSetting(setting: RustPB.Settings_V1_ExternalDisplayTimezoneSetting) -> Observable<Void> {
        var request = RustPB.Settings_V1_SetUserSettingRequest()
        request.externalDisplayTimezone = setting
        return self.client.sendAsyncRequest(request)
    }

    /// 查询当前用户对于全局非联系人发消息的权限设置
    func getUserMsgAuth() -> Observable<Contact_V2_GetUserMsgAuthResponse> {
        let request = RustPB.Contact_V2_GetUserMsgAuthRequest()
        return self.client.sendAsyncRequest(request)
    }

    /// 拉取企业实体词配置
    func getEnterpriseEntityWordConfig() -> Observable<ServerPB.ServerPB_As_setting_GetUserASSettingResponse> {
        var request = ServerPB.ServerPB_As_setting_GetUserASSettingRequest()
        request.featureType = .nautilus
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .getAsSetting)
            .subscribeOn(scheduler)
    }

    /// 设置企业实体词配置
    func setEnterpriseEntityWordConfig(messageEnabled: Bool?, docEnabled: Bool?, minutesEnabled: Bool?) -> Observable<ServerPB.ServerPB_As_setting_SetUserASSettingResponse> {
        var setting = ServerPB_As_setting_UserASSetting()
        if let messageEnabled = messageEnabled {
            setting.nautilusSetting.messengerSetting.isEnabled = messageEnabled
        }
        if let docEnabled = docEnabled {
            setting.nautilusSetting.docsSetting.isEnabled = docEnabled
        }
        if let minutesEnabled = minutesEnabled {
            setting.nautilusSetting.minutesSetting.isEnabled = minutesEnabled
        }
        var request = ServerPB.ServerPB_As_setting_SetUserASSettingRequest()
        request.setting = setting
        request.featureType = .nautilus
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .setAsSetting)
            .subscribeOn(scheduler)
    }

    /// 拉取智能纠错配置
    func getSmartCorrectConfig() -> Observable<ServerPB_Correction_GetCorrectionSettingResponse> {
        let request = ServerPB.ServerPB_Correction_GetCorrectionSettingRequest()
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .getGecSetting)
            .subscribeOn(scheduler)
    }

    /// 设置智能纠错配置
    func setSmartCorrectConfig(_ isEnabeld: Bool) -> Observable<ServerPB_Correction_SetCorrectionSettingResponse> {
        var request = ServerPB.ServerPB_Correction_SetCorrectionSettingRequest()
        var setting = ServerPB_Correction_CorrectionSetting()
        setting.messengerSetting.isEnabled = isEnabeld
        request.correctionSetting = setting
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .setGecSetting)
            .subscribeOn(scheduler)
    }

    /// 拉取智能补全配置
    func getSmartComposeConfig() -> Observable<ServerPB_Composer_GetComposerSettingResponse> {
        let request = ServerPB.ServerPB_Composer_GetComposerSettingRequest()
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .getComposerSetting)
            .subscribeOn(scheduler)
    }

    /// 设置智能补全配置
    func setSmartComposeConfig(_ isEnabeld: Bool) -> Observable<ServerPB_Composer_SetComposerSettingResponse> {
        var request = ServerPB.ServerPB_Composer_SetComposerSettingRequest()
        var setting = ServerPB_Composer_ComposerSetting()
        setting.isMessengerEnabled = isEnabeld
        request.composerSetting = setting
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .setComposerSetting)
            .subscribeOn(scheduler)
    }

    /// 更新系统时区
    func updateSysytemTimezone(_ timezone: String) -> Observable<Void> {
        var request = RustPB.Settings_V1_UpdateTimezoneRequest()
        request.timezone = timezone
        return self.client.sendAsyncRequest(request)
    }
}

extension RustConfigurationAPI {
    func getNewVersion(
        version: String,
        os: String,
        userID: String,
        tenantID: String,
        source: String,
        kaChannel: String?
    ) -> Observable<RustPB.Basic_V1_GetNewVersionResponse> {

        var request = RustPB.Basic_V1_GetNewVersionRequest()
        request.version = version
        request.os = os
        request.userID = userID
        request.tenantID = tenantID
        request.deviceID = deviceId
        request.source = source
        request.osVersion = UIDevice.current.systemVersion
        request.modeName = UIDevice.current.lu.modelName()
        let channelTF = Bundle.main.infoDictionary?["DOWNLOAD_CHANNEL"] as? String ?? ""
        request.isTestFlight = channelTF == "testflight"

        if let kaChannel = kaChannel {
            request.ka = kaChannel
        }

        return self.client.sendAsyncRequest(request) { (response: GetNewVersionResponse) -> RustPB.Basic_V1_GetNewVersionResponse in
            return response
        }
        .subscribeOn(scheduler)
    }

    func getVersionNote(version: String, platform: String) -> Observable<RustPB.Basic_V1_VersionData> {
        var request = RustPB.Basic_V1_GetVersionNoteRequest()
        request.version = version
        request.platform = platform
        return self.client.sendAsyncRequest(request) { (response: GetVersionNoteResponse) -> RustPB.Basic_V1_VersionData in
            return response.data
        }
        .subscribeOn(scheduler)
    }

    private func handleTranslateSettingLogging(settings: TranslateLanguageSetting) {
        let srcLanguagesConfigInfo = settings.srcLanguagesConfig
            .map { (key: String, srcConfig: RustPB.Im_V1_SrcLanguageConfig) -> (key: String,
                scopes: Int32,
                rule: Int) in
                return (key, srcConfig.scopes, srcConfig.rule.rawValue)
            }
        let trgLanguagesConfigInfo = settings.trgLanguagesConfig
            .map { (key: String, trgConfig: RustPB.Im_V1_TrgLanguageConfig) -> (key: String,
                translateDoc: String) in
                return (key, trgConfig.translationDoc)
            }

        RustConfigurationAPI.logger.debug("translate: fetchSetting",
                                          additionalData: ["autoTranslateGlobalSwitch": "\(settings.autoTranslateGlobalSwitch)",
                                            "srcLanguagesConfig": "\(srcLanguagesConfigInfo)",
                                            "srcLanugages": "\(settings.srcLanugages)",
                                            "imageLanguageKeys": "\(settings.imageLanguageKeys)",
                                            "webLanguageKeys": "\(settings.webLanguageKeys)",
                                            "trgLanguagesConfig": "\(trgLanguagesConfigInfo)"])

    }
}
