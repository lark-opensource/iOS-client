//
//  FeatureGatingKey.swift
//  LarkMine
//
//  用于管理仅在LarkMine业务中使用的FeatureGatingKey。
//  Created by 李勇 on 2020/4/3.
//

import Foundation
import LarkSetting

extension FeatureGatingManager.Key {
    static let capabilityPermissionGate: Self = "lark.core.anquan.xitongquanxian"
    static let personalInfoCollectedGate: Self = "lark.core.anquan.personal_information"
    static let openSourceNotice: Self = "lark.core.open_source_notice"
    static let redPacket: Self = "hongbao.enable"
    static let ttPay: Self = "tt_pay"
    static let suiteJoinFunction: Self = "suite_join_function"
    static let suitePoweredBy: Self = "suite_powered_by"
    static let suiteHelpService: Self = "suite_help_service"
    static let whenPhoneChecked: Self = "messenger.message_settings_viewphone_notification"
    static let notificationSound: Self = "core.ios_setting.sound"
    static let versionDisplayBugfix: Self = "lark.core.version.bugfix"
    static let larkPrivacySettingAddfriendsByMail: Self = "lark.messenger.setting.privacy.mail.addfriends"
    /// 翻译设置新版本总开关
    static let translateSettingsV2Enable: Self = "translate.settings.v2.enable"
    /// 语音转文字开关
    static let suiteVoice2Text: Self = "suite_voice2text"
    static let audioToTextEnable: Self = "audio.convert.to.text"

    /// 自动翻译设置网页入口开关
    static let translateSettingsV2WebEnable: Self = "translate.settings.v2.auto_translate.web.enable"
    /// 自动翻译设置 Mail 入口开关
    static let translateSettingsMailEnable: Self = "larkmail.cli.autotranslation"
    /// 联系人优化 UI/入口调整
    static let contactOptForUI: Self = "lark.client.contact.opt.ui"

    /// “关于”-发现新版本
    static let suiteAboutSoftwareupdate: Self = "suite_about_softwareupdate"

    /// "关于"-更新日志
    static let suiteAboutReleasenote: Self = "suite_about_releasenote"

    /// "关于"-安全白皮书
    static let suiteAboutWhitepaper: Self = "suite_about_whitepaper"

    /// "关于"-应用权限说明
    static let suiteAboutAppPermission: Self = "suite_about_app_permission"

    /// "关于"-第三方SDK列表
    static let suiteAboutThirdpartySdk: Self = "suite_about_thirdparty_sdk"

    /// “软件隐私协议” 是否需要关闭
    static let suiteSoftwarePrivacyAgreement: Self = "suite_software_privacy_agreement"

    /// "软件用户协议" 是否需要关闭
    static let suiteSoftwareUserAgreement: Self = "suite_software_user_agreement"

    /// 特色功能介绍
    static let suiteSpecialFunction: Self = "suite_special_function"

    /// 最佳实践
    static let suiteBestPractice: Self = "suite_best_practice"
}
