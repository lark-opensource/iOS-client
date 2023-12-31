//
//  File.swift
//  LarkChat
//
//  Created by shane on 2019/4/26.
//

// code_file tag CryptChat

import Foundation
import LarkModel
import LKCommonsLogging
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer
import SuiteAppConfig
import LarkFeatureGating
import LarkSafety
import UIKit
import LarkSetting

private let expireDays = 7 * 24 * 3600 // 7天

public final class SecretChatServiceImp: SecretChatService {
    private let userAppConfig: UserAppConfig
    private let fgService: FeatureGatingService
    public init(userAppConfig: UserAppConfig, fgService: FeatureGatingService) {
        self.userAppConfig = userAppConfig
        self.fgService = fgService
    }

    public var keyboardItemsTintColor: UIColor {
        return UDMessageColorTheme.imMessageSecrectKeyBoardItemTint
    }

    public var navigationBackgroundColor: UIColor {
        return UIColor.ud.staticBlack.withAlphaComponent(0.8)
    }

    /// 当前用户是否能够使用密聊
    public var secretChatEnable: Bool {
        // 该租户开通了密聊功能
        guard self.userAppConfig.appConfig?.billingPackage.hasSecretChat_p ?? false else { return false }
        // 未被精简模式关闭密聊功能
        guard AppConfigManager.shared.feature(for: .secrectChat).isOn else { return false }

        // 是否使用新的密聊判断规则
        if fgService.staticFeatureGatingValue(with: .init(key: .newSecretControlRule)) {
            // 判断appConfig下发的可用性
            return self.userAppConfig.appConfig?.cryptoChatState ?? .unknown == .allow
        } else {
            // 判断老FG
            return fgService.staticFeatureGatingValue(with: .init(key: .secretChat))
        }
    }

    public func featureIntroductions(secureViewIsWork: Bool) -> [String] {
        if secureViewIsWork {
            return [BundleI18n.LarkMessageCore.Lark_Server_SystemContent_CryptoMessageNoticeBurnAfterReading,
                    BundleI18n.LarkMessageCore.Lark_Server_SystemContent_CryptoMessageNoticeSevenDays,
                    BundleI18n.LarkMessageCore.Lark_Server_SystemContent_CryptoMessagePreventScreenCaptureOnMobileDevices]
        }
        return [BundleI18n.LarkMessageCore.Lark_Server_SystemContent_CryptoMessageNoticeBurnAfterReading,
                BundleI18n.LarkMessageCore.Lark_Server_SystemContent_CryptoMessageLeaveNoTrace,
                BundleI18n.LarkMessageCore.Lark_Server_SystemContent_CryptoMessageNoticeSevenDays,
                BundleI18n.LarkMessageCore.Lark_Server_SystemContent_CryptoMessageNoticeNoTransmit,
                BundleI18n.LarkMessageCore.Lark_Server_SystemContent_CryptoMessageScreenshotNotify]
    }
}
