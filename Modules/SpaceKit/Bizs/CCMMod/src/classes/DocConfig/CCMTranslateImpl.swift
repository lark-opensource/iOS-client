//
//  CCMTranslateImpl.swift
//  CCMMod
//
//  Created by tanyunpeng on 2023/8/8.
//  


import Foundation
import EENavigator
import RxSwift
import RxCocoa
import LarkUIKit
import LarkContainer
import SpaceInterface
import LarkAIInfra
import SKFoundation
import SKCommon
import SKInfra
import LarkLocalizations
#if MessengerMod
import LarkSDKInterface
#endif

class CCMTranslateImpl: CCMTranslateService {
    let resolver: Resolver
    
    init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    #if MessengerMod
    private var userGeneralSettings: UserGeneralSettings? {
        return try? resolver.resolve(assert: UserGeneralSettings.self)
    }
    #endif
    
    public var targetLanguage: String? {
#if MessengerMod
        let lang = self.userGeneralSettings?.translateLanguageSetting.targetLanguage ?? ""
        let trgLanguageMap = self.userGeneralSettings?.translateLanguageSetting.trgLanguagesConfig.first(where: {$0.key == lang
        })
        let i18nLanguageName = trgLanguageMap?.value.i18NLanguage[LanguageManager.currentLanguage.localeIdentifier.lowercased()] ??
            (trgLanguageMap?.value.i18NLanguage[trgLanguageMap?.value.defaultLocale ?? Lang.en_US.rawValue.lowercased()] ?? "")
        return i18nLanguageName
#else
        return ""
#endif
    }
    
    public var targetLanguageKey: String? {
#if MessengerMod
        let lang = self.userGeneralSettings?.translateLanguageSetting.targetLanguage ?? ""
        return lang
#else
        return ""
#endif
    }
    
    var config: CCMTranslateConfig? {
        #if MessengerMod
        guard let translateSetting = userGeneralSettings?.translateLanguageSetting else { return nil }
        return Self.convert(translateSetting: translateSetting)
        #else
        nil
        #endif
    }

    var configUpdated: Driver<CCMTranslateConfig> {
#if MessengerMod
        guard let userGeneralSettings else { return .never() }
        return userGeneralSettings.translateLanguageSettingDriver.map(Self.convert(translateSetting:))
#else
        .never()
#endif
    }


    #if MessengerMod
    private static func convert(translateSetting: TranslateLanguageSetting) -> CCMTranslateConfig {
        let targetLanguageKey = translateSetting.targetLanguage
        let targetLanguageMap = translateSetting.trgLanguagesConfig.first(where: { $0.key == targetLanguageKey })
        let targetLanguage = if let targetLanguageMap = targetLanguageMap {
            targetLanguageMap.value.i18NLanguage[LanguageManager.currentLanguage.localeIdentifier.lowercased()]
            ?? targetLanguageMap.value.i18NLanguage[targetLanguageMap.value.defaultLocale]
            ?? ""
        } else {
            ""
        }
        DocsLogger.info("converting translateSetting",
                        extraInfo: [
                            "targetLanguage": targetLanguage,
                            "targetLanguageKey": targetLanguageKey,
                            "docEnableAutoTranslate": translateSetting.docBodySwitch
                        ],
                        component: LogComponents.translate)
        return CCMTranslateConfig(targetLanguage: targetLanguage,
                                  targetLanguageKey: targetLanguageKey,
                                  enableAutoTranslate: translateSetting.docBodySwitch)

    }
    #endif

}
