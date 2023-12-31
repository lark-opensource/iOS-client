//
//  TranslateLanguagesConfigurationV2PushHandler.swift
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

/// 翻译效果三级设置数据V2
final class TranslateLanguagesConfigurationV2PushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    private var featureGatingService: FeatureGatingService? { try? userResolver.resolve(assert: FeatureGatingService.self) }

    func process(push message: PushLanguagesConfigurationNoticeV2) {
        guard featureGatingService?.staticFeatureGatingValue(with: "translate.settings.v2.enable") ?? false else { return }
        let languagesConfiguration: PushLanguagesConfigurationV2 = PushLanguagesConfigurationV2(
            languagesConf: message.srcLanguagesConf)
        self.pushCenter?.post(languagesConfiguration)
    }
}
