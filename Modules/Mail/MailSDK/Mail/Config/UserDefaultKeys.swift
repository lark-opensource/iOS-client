//
//  UserDefaultKeys.swift
//  DocsSDK
//
//  Created by huahuahu on 2018/11/15.
//

import Foundation

struct UserDefaultKeys {
    static let prefixStr = "MailCoreDefaultPrefix"
    private static func generateKeyFor(major: Int, minor: Int, patch: Int, keyIndex: Int) -> String {
        let maxNumerPerDigit = 100
        let uniqueID = ((major * maxNumerPerDigit + minor) * maxNumerPerDigit + patch) * maxNumerPerDigit + keyIndex
        return UserDefaultKeys.prefixStr + "\(uniqueID)"
    }

    private static func generateKeyFor(_ key: String) -> String {
        return UserDefaultKeys.prefixStr + key
    }

    static let deviceID = UserDefaultKeys.generateKeyFor(major: 0, minor: 3, patch: 1, keyIndex: 0)
    static let appConfigForFrontEnd = UserDefaultKeys.generateKeyFor(major: 0, minor: 6, patch: 0, keyIndex: 1)
    static let shouldShowOpenFileBasicInfo = UserDefaultKeys.generateKeyFor(major: 0, minor: 6, patch: 0, keyIndex: 2)

    /// 用户的域名
    static let domainKey = UserDefaultKeys.generateKeyFor(major: 0, minor: 9, patch: 0, keyIndex: 1)

    /// 用户当前的国家。
    static let userCountryKey = UserDefaultKeys.generateKeyFor(major: 0, minor: 9, patch: 0, keyIndex: 5)

    static let clientVarCacheMetaInfoKey = UserDefaultKeys.generateKeyFor(major: 0, minor: 8, patch: 0, keyIndex: 3)

    /// 用户点击了outbox提醒的dismiss
    static let dismissMillOutboxTip = UserDefaultKeys.generateKeyFor("dismissMillOutboxTip")
    /// feedcard点击了outbox提醒的dismiss
    static let dismissfeedMailOutboxTip = UserDefaultKeys.generateKeyFor("dismissfeedMailOutboxTip")

    /// outbox lastUpdateTime
    static let mailOutboxLastUpdateTime = UserDefaultKeys.generateKeyFor("mailOutboxLastUpdateTime")
    /// mail config
    static let mailConfig = UserDefaultKeys.generateKeyFor("mailConfig")
    /// MailSetting
    static let mailSettingInfo = UserDefaultKeys.generateKeyFor("mailSettingInfo")
    static let mailDualOnboardingInterval = UserDefaultKeys.generateKeyFor("mailDualOnboardingInterval")
    static let mailAIChatId = UserDefaultKeys.generateKeyFor("mailAIChatId")
    static let mailAIChatModeId = UserDefaultKeys.generateKeyFor("mailAIChatModeId")
    static let mailAIChatOpen = UserDefaultKeys.generateKeyFor("mailAIChatOpen")
}
