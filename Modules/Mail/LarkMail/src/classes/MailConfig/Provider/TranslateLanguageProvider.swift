//
//  TranslateLanguageProvider.swift
//  LarkMail
//
//  Created by zhaoxiongbin on 2020/6/8.
//

import Foundation
import MailSDK
import Swinject
import LarkSDKInterface
import LarkModel
import LarkFeatureGating
import RustPB
import LarkContainer
import LarkSetting

class TranslateLanguageProvider {
    private var userGeneralSetting: UserGeneralSettings? {
        #if MessengerMod
        return try? resolver.resolve(assert: UserGeneralSettings.self)
        #else
        return nil
        #endif
    }

    private var translateLanguageSetting: TranslateLanguageSetting? {
        return userGeneralSetting?.translateLanguageSetting
    }

    private let resolver: UserResolver
    private let featureGatingService: FeatureGatingService

    init(resolver: UserResolver) throws {
        self.resolver = resolver
        self.featureGatingService = try resolver.resolve(assert: FeatureGatingService.self)
    }
}

extension TranslateLanguageProvider: TranslateLanguageProxy {
    var targetLanguage: String {
        return userGeneralSetting?.translateLanguageSetting.targetLanguage ?? ""
    }

    var isEmailAutoTranslateOn: Bool {
        guard !featureGatingService.staticFeatureGatingValue(with: "larkmail.cli.hide_ai_point"),
              featureGatingService.staticFeatureGatingValue(with: "larkmail.cli.autotranslation"),
              let translateScope = translateLanguageSetting?.translateScope else { return false }
        return (translateScope & RustPB.Im_V1_TranslateScopeMask.email.rawValue) != 0
    }

    var trgLanguages: [(String, RustPB.Im_V1_TrgLanguageConfig)] {
        let languagesKey = translateLanguageSetting?.languageKeys ?? []
        return languagesKey.compactMap { (key) -> (String, RustPB.Im_V1_TrgLanguageConfig)? in
            guard let config = translateLanguageSetting?.trgLanguagesConfig[key] else { return nil }
            return (key, config)
        }
    }

    var srcLanguagesConfig: [String: RustPB.Im_V1_SrcLanguageConfig] {
        return translateLanguageSetting?.srcLanguagesConfig ?? [:]
    }

    var globalDisplayRule: RustPB.Basic_V1_DisplayRule? {
        return translateLanguageSetting?.globalConf.rule
    }

    var disableLanguages: [String] {
        return translateLanguageSetting?.languagesConf.keys.filter({ !shouldAutoTranslateFor(src: $0) }) ?? []
    }

    func shouldAutoTranslateFor(src: String) -> Bool {
        guard let scope = translateLanguageSetting?.getTranslateScope(srcLanguageKey: src) else { return false }
        return (scope & RustPB.Im_V1_TranslateScopeMask.email.rawValue) != 0
    }

    func displayRuleFor(src: String) -> RustPB.Basic_V1_DisplayRule? {
        let conf = translateLanguageSetting?.languagesConf[src]
        return conf?.rule
    }
}
