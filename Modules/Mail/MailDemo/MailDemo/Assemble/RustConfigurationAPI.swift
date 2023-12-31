//
//  RustConfigurationAPI.swift
//  Lark
//
//  Created by Sylar on 2017/11/15.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
import LarkAccountInterface
import LKCommonsLogging
import ServerPB

final class RustConfigurationAPI: LarkAPI, ConfigurationAPI {
    func getMostUserSetting() -> Observable<Settings_V1_GetUserSettingResponse> {
        return Observable.empty()
    }

    private static let logger = Logger.log(RustConfigurationAPI.self, category: "TranslateLanguage")

    private let deviceId: String

    init(client: SDKRustService, onScheduler: ImmediateSchedulerType?, deviceId: String) {
        self.deviceId = deviceId
        super.init(client: client, onScheduler: onScheduler)
    }

    /// 获取字节云平台指定key对应的value
    func fetchSettingsRequest(fields: [String]) -> Observable<[String: String]> {
        return Observable.empty()
    }
    

    /// 获取翻译设置 只在UserGeneralSettings中使用
    func fetchTranslateLanguageSetting(strategy: RustPB.Basic_V1_SyncDataStrategy) -> Observable<TranslateLanguageSetting> {
        return Observable.empty()
    }

    /// 设置自动翻译开关
    func setAutoTranslateGlobalSwitch(isOpen: Bool) -> Observable<Void> {
        return Observable.empty()
    }

    /// 设置翻译目标语言 只在UserGeneralSettings中使用
    func updateTranslateLanguageSetting(language: String) -> Observable<Void> {
        return Observable.empty()
    }

    /// 设置翻译语言key->翻译效果 只在UserGeneralSettings中使用
    func updateLanguagesConfiguration(globalConf: RustPB.Im_V1_LanguagesConfiguration?, languagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]?) -> Observable<Void> {
        return Observable.empty()
    }

    /// 设置翻译显示翻译效果开关(一级)
    func updateGlobalLanguageDisplayConfig(globalConf: RustPB.Im_V1_LanguagesConfiguration) -> Observable<Void> {
        return updateLanguagesConfiguration(globalConf: globalConf, languagesConf: nil)
    }

    /// 设置翻译源语言(三级) 的翻译效果
    func updateLanguagesConfigurationV2(srcLanguagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]) -> Observable<Void> {
        return Observable.empty()
    }

    /// 修改源语种自动翻译设置(三级)scopes范围
    func updateSrcLanguageScopes(srcLanguagesScope: Int, language: String) -> Observable<Void> {
        return Observable.empty()
    }

    /// 设置TranslateScope，解释见TranslateLanguageSetting
    func updateAutoTranslateScope(scope: Int) -> Observable<Void> {
        return Observable.empty()
    }

    /// 设置不自动翻译的语言 只在UserGeneralSettings中使用
    func updateDisableAutoTranslateLanguages(languages: [String]) -> Observable<[String]> {
        return Observable.empty()
    }

    /// 获取某条消息的其他语言翻译内容 （原文, [译文]）
    func fetchMessageTranslateInfos(messageId: String) -> Observable<(MessageTranslateInfo, [MessageTranslateInfo])> {
        return Observable.empty()
    }

    func updateDeviceSetting(language: String) -> Observable<DeviceSetting> {
        var request = RustPB.Device_V1_SetDeviceSettingRequest()
        request.deviceID = deviceId
        request.localeIdentifier = language
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Device_V1_SetDeviceSettingResponse) -> DeviceSetting in
            return DeviceSetting(language: response.localeIdentifier)
        }).subscribeOn(scheduler)
    }

    func getSystemMessageTemplate(language: String) -> Observable<Void> {
        var request = RustPB.Im_V1_GetSystemMessageTemplateRequest()
        request.localeIdentifier = language
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getWorkStatusSetting() -> Observable<Bool> {
        return Observable.empty()
    }

    func getExternalDisplayTimezone() -> Observable<RustPB.Settings_V1_ExternalDisplayTimezoneSetting> {
        return Observable.empty()
    }

    func setWorkStatusSetting(isUpdate: Bool) -> Observable<Void> {
        return Observable.empty()
    }

    /// 获取消息通知设置
    func getNotificationSetting() -> (Observable<(RustPB.Settings_V1_NotificationSetting, Bool)>) {
        return Observable.empty()
    }

    /// 设置消息通知 会中电话中免打扰
    func setNotificationSetting(setting: RustPB.Settings_V1_NotificationSetting?, messageNotificationsOffDuringCallsSetting: Bool?) -> Observable<Void> {
        return Observable.empty()
    }

    /// 获取消息通知设置v2
    func getNotificationSettingV2() -> Observable<RustPB.Settings_V1_NotificationSettingV2> {
        return Observable.empty()
    }

    /// 设置消息通知v2
    func setNotificationSettingV2(setting: RustPB.Settings_V1_NotificationSettingV2) -> Observable<Void> {
        return Observable.empty()
    }

    /// 获取邮件通知设置
    func getMailNotificationSetting() -> Observable<RustPB.Email_Client_V1_MailNotificationSettings> {
        return Observable.empty()
    }

    /// 设置邮件通知
    func setMailNotificationSetting(setting: RustPB.Email_Client_V1_MailNotificationSettings) -> Observable<Void> {
        return Observable.empty()
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
        return (Observable.empty(), Observable.empty())
    }

    func setBadgeStyle(_ badgeStyle: RustPB.Settings_V1_BadgeStyle) -> Observable<Void> {
        return Observable.empty()
    }

    /// 设置是否显示主导航免打扰 badge
    func setShowTabMuteBadge(_ showMuteBadge: Bool) -> Observable<Void> {
        return Observable.empty()
    }

    /// 获取是否显示主导航免打扰 badge
    func fetchShowTabMuteBadge() -> Observable<Bool> {
        return Observable.empty()
    }

    /// 本地获取一次好友隐私设置，找到/添加我
    func getAddFriendPrivateConfig() -> Observable<RustPB.Settings_V1_GetAddFriendPrivateConfigResponse> {
        return Observable.empty()
    }

    /// 远程获取好友隐私设置，找到/添加我
    func fetchAddFriendPrivateConfig() -> Observable<RustPB.Settings_V1_GetAddFriendPrivateConfigResponse> {
        return Observable.empty()
    }

    /// 设置如何找到我
    func setWayToFindMeSetting(id: String, enable: Bool, verifyToken: String) -> Observable<Void> {
        return Observable.empty()
    }

    /// 设置如何添加我
    func setWayToAddMeSetting(addMeType: RustPB.Settings_V1_WayToAddMeSettingItem.TypeEnum, enable: Bool) -> Observable<Void> {
        return Observable.empty()
    }

    func fetchTimeFormat() -> Observable<RustPB.Settings_V1_TimeFormatSetting.TimeFormat> {
        return Observable.empty()
    }

    func setTimeFormat(_ timeFormat: RustPB.Settings_V1_TimeFormatSetting.TimeFormat) -> Observable<Void> {
        return Observable.empty()
    }

    /// 获取勿扰模式截止ntp时间
    func fetchDoNotDisturbEndTime() -> Observable<Int64> {
        return Observable.empty()
    }

    /// 设置勿扰模式截止ntp时间，单位ms
    func setDoNotDisturbEndTime(time: Int64) -> Observable<Void> {
        return Observable.empty()
    }
    /// 设置语音自动转文字
    func setAudioToTextSetting(enable: Bool) -> Observable<Void> {
        return Observable.empty()
    }

    /// 获取语音自动转文字设置
    func getAudioToTextSetting(isFromServer: Bool) -> Observable<Bool> {
        return Observable.empty()
    }

    func setSmsPhoneUrgent(accept: Bool) -> Observable<Void> {
        return Observable.empty()
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

    // Smart Compose
    /// 拉取Smart Compose配置
    func getSmartComposeConfig() -> Observable<RustPB.Ai_V1_GetComposerSettingResponse> {
        let request = RustPB.Ai_V1_GetComposerSettingRequest()
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
    /// 设置Smart Compose配置
    func setSmartComposeConfig(messageEnabled: Bool?, emailEnabled: Bool?, docEnabled: Bool?) -> Observable<RustPB.Ai_V1_SetComposerSettingResponse> {
        var setting = Ai_V1_MobileComposerSetting()
        if let messageEnabled = messageEnabled {
            setting.isMessengerEnabled = messageEnabled
        }
        if let emailEnabled = emailEnabled {
            setting.isMailEnabled = emailEnabled
        }
        if let docEnabled = docEnabled {
            setting.isDocsEnabled = docEnabled
        }
        var request = RustPB.Ai_V1_SetComposerSettingRequest()
        request.mobileComposerSetting = setting
        request.composerSetting = Ai_V1_ComposerSetting()
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    // Smart Reply Setting
    /// 拉取Smart Reply配置
    func getSmartReplyConfig() -> Observable<ServerPB.ServerPB_Smart_reply_GetSmartReplySettingResponse> {
        let request = ServerPB.ServerPB_Smart_reply_GetSmartReplySettingRequest()
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .getSmartReplySetting)
            .subscribeOn(scheduler)
    }
    /// 设置Smart Reply配置
    func setSmartReplyConfig(replyEnabled: Bool?, actionEnabled: Bool?) -> Observable<ServerPB.ServerPB_Smart_reply_SetSmartReplySettingResponse> {
        var smartReplySetting = ServerPB.ServerPB_Smart_reply_SmartReplySetting()
        if let replyEnabled = replyEnabled {
            smartReplySetting.smartReplyEnabled = replyEnabled
        }
        if let actionEnabled = actionEnabled {
            smartReplySetting.smartActionEnabled = actionEnabled
        }
        var request = ServerPB.ServerPB_Smart_reply_SetSmartReplySettingRequest()
        request.smartReplySetting = smartReplySetting
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .setSmartReplySetting)
            .subscribeOn(scheduler)
    }

    /// 拉取企业实体词配置
    func getEnterpriseEntityWordConfig() -> Observable<ServerPB.ServerPB_As_setting_GetUserASSettingResponse> {
        var request = ServerPB.ServerPB_As_setting_GetUserASSettingRequest()
        request.featureType = .nautilus
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .getAsSetting)
            .subscribeOn(scheduler)
    }

    /// 设置企业实体词配置
    func setEnterpriseEntityWordConfig(messageEnabled: Bool?, docEnabled: Bool?) -> Observable<ServerPB.ServerPB_As_setting_SetUserASSettingResponse> {
        var setting = ServerPB_As_setting_UserASSetting()
        if let messageEnabled = messageEnabled {
            setting.nautilusSetting.messengerSetting.isEnabled = messageEnabled
        }
        if let docEnabled = docEnabled {
            setting.nautilusSetting.docsSetting.isEnabled = docEnabled
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

        if let kaChannel = kaChannel {
            request.ka = kaChannel
        }

        return self.client.sendAsyncRequest(request) { (response: RustPB.Basic_V1_GetNewVersionResponse) -> RustPB.Basic_V1_GetNewVersionResponse in
            return response
        }
        .subscribeOn(scheduler)
    }

    func getVersionNote(version: String, platform: String) -> Observable<RustPB.Basic_V1_VersionData> {
        var request = RustPB.Basic_V1_GetVersionNoteRequest()
        request.version = version
        request.platform = platform
        return self.client.sendAsyncRequest(request) { (response: RustPB.Basic_V1_GetVersionNoteResponse) -> RustPB.Basic_V1_VersionData in
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
