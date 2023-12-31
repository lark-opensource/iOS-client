//
//  DisableAutoTranslateLanguagePushHandler.swift
//  LarkSDK
//
//  Created by 李勇 on 2019/5/13.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LarkSDKInterface

/// 部分翻译设置数据
final class DisableAutoTranslateLanguagePushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushDisableAutoTranslateLanguagesNotice) {
        let disableAutoTranslateLanguages: PushDisableAutoTranslateLanguages = PushDisableAutoTranslateLanguages(
            disAutoTranslateLanguagesConf: message.languageKeys)
        self.pushCenter?.post(disableAutoTranslateLanguages)
    }
}
