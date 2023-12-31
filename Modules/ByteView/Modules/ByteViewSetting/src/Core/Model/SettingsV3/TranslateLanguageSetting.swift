//
//  TranslateLanguageSetting.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/11.
//

import Foundation
import ByteViewNetwork

/// 翻译设置
public struct TranslateLanguageSetting: Equatable {
    /// 翻译设置的目标语言key 默认为系统语言
    public var targetLanguage: String
    /// 自动翻译开关，isScopeOpen for vc
    public var isAutoTranslationOn: Bool
    /// 语言key排序，保证三端展示顺序一致
    public var availableLanguages: [TranslateLanguage]
    /// 默认所有语言配置
    public var globalConf: TranslateLanguagesConfiguration

    public init(targetLanguage: String, isAutoTranslationOn: Bool, availableLanguages: [TranslateLanguage],
                globalConf: TranslateLanguagesConfiguration) {
        self.targetLanguage = targetLanguage
        self.isAutoTranslationOn = isAutoTranslationOn
        self.availableLanguages = availableLanguages
        self.globalConf = globalConf
    }

    static let empty = TranslateLanguageSetting(targetLanguage: "", isAutoTranslationOn: false, availableLanguages: [], globalConf: .init(rule: .unknown))
}

public struct TranslateLanguage: Equatable {
    /// 语言key
    public let key: String
    /// 显示文案
    public let name: String

    public init(key: String, name: String) {
        self.key = key
        self.name = name
    }
}
