//
//  LanguagesConfigurationSettingViewModel.swift
//  LarkMine
//
//  Created by 李勇 on 2019/5/14.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkSDKInterface
import RustPB

/// 翻译效果设置vm
final class LanguagesConfigurationSettingViewModel {
    private let disposeBag = DisposeBag()
    let userGeneralSettings: UserGeneralSettings
    /// 和当前翻译效果不同的所有语言，比如：全局设置展示原文+译文，那么此属性存只展示译文的语言。
    var otherConfigurationLanguages: Set<String> = Set<String>()
    /// 当前所有服务器支持的语言key，从languageKeys和supportedLanguages中筛选，排除掉当前用户的翻译目标语言
    var allNeedShowSupportedLanguages: [String] = []

    /// 刷新表格视图信号
    var reloadDataDriver: Driver<Void> { return reloadDataPublish.asDriver(onErrorJustReturn: ()) }
    private var reloadDataPublish = PublishSubject<Void>()

    init(userGeneralSettings: UserGeneralSettings) {
        self.userGeneralSettings = userGeneralSettings
        /// 得到服务端支持的语言
        self.userGeneralSettings.translateLanguageSetting.languageKeys.forEach { (language) in
            guard self.userGeneralSettings.translateLanguageSetting.supportedLanguages.keys.contains(language) else { return }
            /// 排除掉当前用户的翻译目标语言
            if language == self.userGeneralSettings.translateLanguageSetting.targetLanguage { return }
            self.allNeedShowSupportedLanguages.append(language)
        }
        /// 和当前翻译效果不同的所有语言，排除掉当前用户的翻译目标语言
        self.allNeedShowSupportedLanguages.forEach { (language) in
            /// 没单独设置过翻译效果的使用全局语言
            guard let config = self.userGeneralSettings.translateLanguageSetting.languagesConf[language] else { return }
            /// 规则和全局规则不一致
            if config.rule != self.userGeneralSettings.translateLanguageSetting.globalConf.rule {
                self.otherConfigurationLanguages.insert(language)
            }
        }
        /// 监听最新的数据，我们需要过滤数据
        self.userGeneralSettings.translateLanguageSettingDriver.skip(1).drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.setTranslateLanguageSettingDriver()
        }).disposed(by: self.disposeBag)
    }

    /// 监听最新的数据，我们需要过滤数据
    private func setTranslateLanguageSettingDriver() {
        /// 获取最新的数据
        var tempNeedShowLanguages: [String] = []
        self.userGeneralSettings.translateLanguageSetting.languageKeys.forEach { (language) in
            guard self.userGeneralSettings.translateLanguageSetting.supportedLanguages.keys.contains(language) else { return }
            /// 排除掉当前用户的翻译目标语言
            if language == self.userGeneralSettings.translateLanguageSetting.targetLanguage { return }
            tempNeedShowLanguages.append(language)
        }
        /// 之前选中的现在服务器不支持了，则需要去掉
        var tempOtherConfigurationLanguages: Set<String> = Set<String>()
        self.otherConfigurationLanguages.forEach { (language) in
            guard tempNeedShowLanguages.contains(language) else { return }
            tempOtherConfigurationLanguages.insert(language)
        }
        /// 刷新表格视图
        self.allNeedShowSupportedLanguages = tempNeedShowLanguages
        self.otherConfigurationLanguages = tempOtherConfigurationLanguages
        self.reloadDataPublish.onNext(())
    }

    /// 当前用户全局的翻译效果
    func currConfigurationValue() -> String {
        if self.userGeneralSettings.translateLanguageSetting.globalConf.rule == .withOriginal {
            return BundleI18n.LarkMine.Lark_Chat_TranslationOnly
        }
        return BundleI18n.LarkMine.Lark_Chat_TranslationAndOriginalMessage
    }

    /// 得到当前用户选中的语言key对应的内容
    func currConfigurationLanguageValues() -> ([String], [String]) {
        var tempLanguages: [String] = []
        var tempLanguageValues: [String] = []
        self.allNeedShowSupportedLanguages.forEach { (language) in
            guard self.otherConfigurationLanguages.contains(language) else { return }
            guard let languageValue = self.userGeneralSettings.translateLanguageSetting.supportedLanguages[language] else { return }
            tempLanguages.append(language)
            tempLanguageValues.append(languageValue)
        }
        return (tempLanguages, tempLanguageValues)
    }

    /// 处理选中的语言
    func handlerSelectLanguage(language: String) {
        if self.otherConfigurationLanguages.contains(language) {
            self.otherConfigurationLanguages.remove(language)
        } else {
            self.otherConfigurationLanguages.insert(language)
        }
        self.reloadDataPublish.onNext(())
    }

    /// 请求接口，设置翻译效果
    func requestSetTranslateConfiguration() -> Observable<Void> {
        /// 在currConfigurationLanguages中的language使用与全局翻译效果设置相反的规则
        let currConf = self.userGeneralSettings.translateLanguageSetting.globalConf
        var otherConf = RustPB.Im_V1_LanguagesConfiguration()
        otherConf.rule = currConf.rule == RustPB.Basic_V1_DisplayRule.withOriginal ? RustPB.Basic_V1_DisplayRule.onlyTranslation : RustPB.Basic_V1_DisplayRule.withOriginal
        /// 组装参数
        var languagesConf: [String: RustPB.Im_V1_LanguagesConfiguration] = [:]
        self.allNeedShowSupportedLanguages.forEach { (language) in
            languagesConf[language] = self.otherConfigurationLanguages.contains(language) ? otherConf : currConf
        }
        return self.userGeneralSettings.updateLanguagesConfiguration(globalConf: nil, languagesConf: languagesConf)
    }
}
