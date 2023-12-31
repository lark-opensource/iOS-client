//
//  GeneralSettingPushHandler.swift
//  LarkMine
//
//  Created by ZhangHongyun on 2021/3/4.
//

import Foundation
import RustPB
import ServerPB
import LarkRustClient
import LKCommonsLogging
import LarkStorage
import LarkContainer
import LarkFeatureGating
import LarkSearchCore

public typealias PushASSetting = ServerPB.ServerPB_As_setting_PushUserASSetting

final class EnterpriseEntityWordSettingPushHandler: UserPushHandler {
    private static let logger = Logger.log(EnterpriseEntityWordSettingPushHandler.self, category: "LarkMine.EnterpriseEntityWordSettingPushHandler")

    func process(push message: PushASSetting) throws {
        let setting = message.setting.nautilusSetting
        KVPublic.Setting.enterpriseEntityTenantSwitch.setValue(setting.isTenantEnabled, forUser: userResolver.userID)
        KVPublic.Setting.enterpriseEntityTenantSwitch.setValue(true, forUser: userResolver.userID)
        KVPublic.Setting.enterpriseEntityMessage.setValue(setting.messengerSetting.isEnabled, forUser: userResolver.userID)
        if AIFeatureGating.eewInMinutes.isUserEnabled(userResolver: userResolver) {
            KVPublic.Setting.enterpriseEntityMinutes.setValue(setting.minutesSetting.isEnabled, forUser: userResolver.userID)
        }
        if AIFeatureGating.eewInDoc.isUserEnabled(userResolver: userResolver) {
            KVPublic.Setting.enterpriseEntityDoc.setValue(setting.docsSetting.isEnabled, forUser: userResolver.userID)
        }
        Self.logger.info("EnterpriseEntityWordSettingPushHandler receive setting, isTenantEnabled: \(setting.isTenantEnabled), im:  \(setting.messengerSetting.isEnabled), doc: \(setting.docsSetting)")
    }
}

public typealias PushSmartCorrectSetting = ServerPB.ServerPB_Correction_PushCorrectionSetting

final class SmartCorrectPushHandler: UserPushHandler {
    private static let logger = Logger.log(SmartCorrectPushHandler.self, category: "LarkMine.SmartCorrectPushHandler")

    func process(push message: PushSmartCorrectSetting) throws {
        let setting = message.correctionSetting
        if AIFeatureGating.smartCorrect.isUserEnabled(userResolver: userResolver) {
            KVPublic.Setting.smartCorrect.setValue(setting.messengerSetting.isEnabled, forUser: userResolver.userID)
        }
        Self.logger.info("SmartCorrectPushHandler receive setting \(setting.messengerSetting.isEnabled)")
    }
}

public typealias PushSmartComposeSetting = ServerPB.ServerPB_Composer_PushComposerSetting

final class SmartComposePushHandler: UserPushHandler {
    private static let logger = Logger.log(SmartComposePushHandler.self, category: "LarkMine.SmartComposePushHandler")

    func process(push message: PushSmartComposeSetting) throws {
        if AIFeatureGating.smartCompose.isUserEnabled(userResolver: userResolver) {
            KVPublic.Setting.smartComposeMessage.setValue(message.composerSetting.isMessengerEnabled, forUser: userResolver.userID)
        }
        Self.logger.info("SmartComposePushHandler receive setting \(message.composerSetting.isMessengerEnabled)")

    }
}
