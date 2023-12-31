//
//  TranslateLanguagesAutoTranslateScopePushHandler.swift
//  LarkSDK
//
//  Created by zhenning on 2020/02/25.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LarkSDKInterface
import LarkFeatureGating
import LarkSetting

/// 自动翻译Scope设置V2
final class TranslateLanguagesAutoTranslateScopePushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    private var featureGatingService: FeatureGatingService? { try? userResolver.resolve(assert: FeatureGatingService.self) }

    func process(push message: PushLanguageAutoTranslateScopeNotify) {
        guard featureGatingService?.staticFeatureGatingValue(with: "translate.settings.v2.enable") ?? false else { return }

        let srcLanguagesScopeSettings: PushAutoTranslateSrcLanguageScope = PushAutoTranslateSrcLanguageScope(
            srcLanguagesScope: message.srcLanguagesScope)
        self.pushCenter?.post(srcLanguagesScopeSettings)
    }
}
