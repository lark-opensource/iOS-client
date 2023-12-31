//
//  MyAIOnboardingResourceManager.swift
//  LarkAI
//
//  Created by Hayden on 2023/6/5.
//

import UIKit
import LarkSetting
import LarkContainer
import LKCommonsLogging
import LarkLocalizations
import LarkAccountInterface

struct AvatarInfo: Equatable {
    /// 静态资源图的 key
    var staticImageKey: String
    /// 动图(webp) key
    var dynamicImageKey: String
    /// 动图的 placeholder key
    var dynamicImagePlaceholderKey: String
    /// 头像排列顺序
    var order: Int

    static var `default`: AvatarInfo = AvatarInfo(staticImageKey: "", dynamicImageKey: "", dynamicImagePlaceholderKey: "", order: 0)
}

struct MyAIResourceManager {

    private static let logger = Logger.log(MyAIResourceManager.self, category: "LarkAI.MyAI")

    /// My AI 服务协议：https://www.larksuite.com/serviceterms_ai
    static var serviceTermsURL: URL?

    /// 默认头像的 key
    static var defaultAvatarKey = ""

    /// My AI 预置的名称
    static var presetNames: [String] = []

    /// My AI 预置的头像
    static var presetAvatars: [AvatarInfo] = []

    static func loadResourcesFromSetting(userResolver: UserResolver, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        DispatchQueue.global().async {
            parseResources(userResolver: userResolver, maxRetryTimes: 5, onSuccess: onSuccess, onFailure: onFailure)
        }
    }

    private static func parseResources(userResolver: UserResolver, maxRetryTimes: Int, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
        guard maxRetryTimes > 0 else {
            Self.logger.error("[MyAI.Onboarding][Resource][\(#function)] parsing resource failed, retry times: \(maxRetryTimes)")
            onFailure()
            return
        }

        guard let json = try? userResolver.settings.setting(with: .make(userKeyLiteral: "myai_onboarding_config")) else {
            Self.logger.error("[MyAI.Onboarding][Resource][\(#function)] parsing JSON failed, can not find 'myai_onboarding_config'")
            parseResources(userResolver: userResolver, maxRetryTimes: maxRetryTimes - 1, onSuccess: onSuccess, onFailure: onFailure)
            return
        }
        parseDefaultAvatar(from: json)
        parsePresetAvatars(from: json)
        parsePresetNames(from: json)
        parseServiceTermURL(from: json)
        if checkResourcesIntegrity() {
            DispatchQueue.main.async {
                onSuccess()
            }
        } else {
            Self.logger.error("[MyAI.Onboarding][Resource][\(#function)] checking integrity failed: \(json)")
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                MyAIResourceManager.parseResources(userResolver: userResolver, maxRetryTimes: maxRetryTimes - 1, onSuccess: onSuccess, onFailure: onFailure)
            }
        }
    }

    // TODO: 不要硬解，用 Codable!!!!

    private static func parseServiceTermURL(from json: [String: Any]) {
        guard let serviceTerms = json["serviceTerms"] as? String else {
            Self.logger.error("[MyAI.Onboarding][Resource][\(#function)] parsing failed, attribute: myai_onboarding_config.serviceTerms")
            return
        }
        guard let serviceTermsURL = URL(string: serviceTerms) else {
            Self.logger.error("[MyAI.Onboarding][Resource][\(#function)] parsing failed, attribute: myai_onboarding_config.serviceTerms is not an valid url")
            return
        }
        self.serviceTermsURL = serviceTermsURL
    }

    private static func parseDefaultAvatar(from json: [String: Any]) {
        guard let defaultAvatar = json["defaultAvatar"] as? [String: Any] else {
            Self.logger.error("[MyAI.Onboarding][Resource][\(#function)] parsing failed, attribute: myai_onboarding_config.defaultAvatar")
            return
        }
        guard let defaultAvatarKey = defaultAvatar["avatarKey"] as? String else {
            Self.logger.error("[MyAI.Onboarding][Resource][\(#function)] parsing failed, attribute: myai_onboarding_config.defaultAvatar.avatarKey")
            return
        }
        self.defaultAvatarKey = defaultAvatarKey
    }

    private static func parsePresetAvatars(from json: [String: Any]) {
        guard let optionalAvatars = json["optionalAvatars"] as? [[String: Any]] else {
            Self.logger.error("[MyAI.Onboarding][Resource][\(#function)] parsing failed, attribute: myai_onboarding_config.optionalAvatars")
            return
        }
        var presetAvatars: [AvatarInfo] = []
        for avatar in optionalAvatars {
            if let avatarKey = avatar["avatarKey"] as? String,
               let order = avatar["order"] as? Int,
               let onBoardingAvatar = avatar["onBoardingAvatar"] as? [String: Any],
               let dynamicAvatar = onBoardingAvatar["dynamicAvatar"] as? String,
               let placeHolder = onBoardingAvatar["placeHolder"] as? String {
                presetAvatars.append(.init(staticImageKey: avatarKey,
                                           dynamicImageKey: dynamicAvatar,
                                           dynamicImagePlaceholderKey: placeHolder,
                                           order: order))
            } else {
                Self.logger.error("[MyAI.Onboarding][Resource][\(#function)][\(#function)] parsing failed, attribute: some attribute of myai_onboarding_config.optionalAvatars")
            }
        }
        if !presetAvatars.isEmpty {
            presetAvatars.append(.default)
            self.presetAvatars = presetAvatars.sorted(by: { $0.order < $1.order })
        }
    }

    static func getMyAIBrandNameFromSetting(userResolver: UserResolver) -> String {
        var aiBrandName: String
        if let aiNameSetting = try? userResolver.settings.setting(with: .make(userKeyLiteral: "my_ai_brand_name")),
           let aiNameForCurrentLanguage = aiNameSetting[LanguageManager.currentLanguage.rawValue] as? String {
            // 从 Setting 中获取配置的默认 AI 名称
            aiBrandName = aiNameForCurrentLanguage
        } else {
            // 如果未从 Setting 中获取到，则根据品牌来取默认文案
            let isFeishuBrand = (try? userResolver.resolve(assert: PassportService.self))?.isFeishuBrand ?? true
            aiBrandName = isFeishuBrand ? BundleI18n.LarkAI.MyAI_Common_Faye_AiNameFallBack : BundleI18n.LarkAI.MyAI_Common_MyAI_AiNameFallBack
        }
        // 默认 AI 名称可能前后有空格，先去除空格
        return aiBrandName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parsePresetNames(from json: [String: Any]) {
        guard let optionalNames = json["optionalNames"] as? [String: Any] else {
            Self.logger.error("[MyAI.Onboarding][Resource][\(#function)] parsing failed, attribute: myai_onboarding_config.optionalNames")
            return
        }
        var aiPresetNames: [String] = []
        switch LanguageManager.currentLanguage {
        case .zh_CN, .zh_HK, .zh_TW:
            if let zhNames = optionalNames["zh"] as? [String] {
                aiPresetNames = zhNames
            } else {
                Self.logger.error("[MyAI.Onboarding][Resource][\(#function)] parsing failed, attribute: myai_onboarding_config.optionalNames.zh")
            }
        default:
            if let enNames = optionalNames["en"] as? [String] {
                aiPresetNames = enNames
            } else {
                Self.logger.error("[MyAI.Onboarding][Resource][\(#function)] parsing failed, attribute: myai_onboarding_config.optionalNames.en")
            }
        }
        self.presetNames = aiPresetNames
    }

    static func checkResourcesIntegrity() -> Bool {
        guard !defaultAvatarKey.isEmpty else { return false }
        guard !presetAvatars.isEmpty else { return false }
        guard !presetNames.isEmpty else { return false }
        return true
    }
}
