//
//  TranslateLanguageSettingPushHandler.swift
//  Lark
//
//  Created by 姚启灏 on 2018/7/12.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

/// 部分翻译设置数据
final class TranslateLanguageSettingPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: PushTranslateLanguageNotice) {
        let translateLanguageSetting: PushTranslateLanguageSetting = PushTranslateLanguageSetting(
            targetLanguage: message.targetLanguage,
            languageKeys: message.languageKeys,
            supportedLanguages: message.supportedLanguages)
        self.pushCenter?.post(translateLanguageSetting)
    }
}
