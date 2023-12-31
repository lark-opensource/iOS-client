//
//  TranslateLanguagesConfigurationPushHandler.swift
//  LarkSDK
//
//  Created by 李勇 on 2019/5/12.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LarkSDKInterface

/// 部分翻译设置数据
final class TranslateLanguagesConfigurationPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: PushLanguagesConfigurationNotice) {
        let languagesConfiguration: PushLanguagesConfiguration = PushLanguagesConfiguration(
            globalConf: message.globalLanguageConfig,
            languagesConf: message.languagesConfig)
        self.pushCenter?.post(languagesConfiguration)
    }
}
