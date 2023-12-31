//
//  DisableAutoTranslateLanguagesViewModel.swift
//  LarkMine
//
//  Created by 李勇 on 2019/5/13.
//

import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface

/// 不自动翻译语言设置vm
final class DisableAutoTranslateLanguagesViewModel {
    private let disposeBag = DisposeBag()
    let userGeneralSettings: UserGeneralSettings
    /// 不自动翻译的语言
    private(set) var disableAutoTranslateLanguages = Set<String>()
    /// 当前所有服务器支持的语言key，从languageKeys和supportedLanguages中筛选，排除掉当前用户的翻译目标语言
    private(set) var allNeedShowSupportedLanguages: [String] = []

    /// 刷新表格视图信号
    var reloadDataDriver: Driver<Void> { return reloadDataPublish.asDriver(onErrorJustReturn: ()) }
    private var reloadDataPublish = PublishSubject<Void>()

    init(userGeneralSettings: UserGeneralSettings) {
        self.userGeneralSettings = userGeneralSettings
        /// 创建数据源
        self.userGeneralSettings.translateLanguageSetting.languageKeys.forEach { (language) in
            guard self.userGeneralSettings.translateLanguageSetting.supportedLanguages.keys.contains(language) else { return }
            /// 排除掉当前用户的翻译目标语言
            if language == self.userGeneralSettings.translateLanguageSetting.targetLanguage { return }
            self.allNeedShowSupportedLanguages.append(language)
        }
        self.userGeneralSettings.translateLanguageSetting.disAutoTranslateLanguagesConf.forEach { (language) in
            guard self.allNeedShowSupportedLanguages.contains(language) else { return }
            self.disableAutoTranslateLanguages.insert(language)
        }
        /// 监听最新的数据，我们需要过滤数据
        self.userGeneralSettings.translateLanguageSettingDriver.skip(1).drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.setTranslateLanguageSettingDriver()
        }).disposed(by: self.disposeBag)
    }

    /// 得到当前用户选中的语言key对应的内容
    func disableAutoTranslateLanguageValues() -> ([String], [String]) {
        var tempLanguages: [String] = []
        var tempLanguageValues: [String] = []
        self.allNeedShowSupportedLanguages.forEach { (language) in
            guard self.disableAutoTranslateLanguages.contains(language) else { return }
            guard let languageValue = self.userGeneralSettings.translateLanguageSetting.supportedLanguages[language] else { return }
            tempLanguages.append(language)
            tempLanguageValues.append(languageValue)
        }
        return (tempLanguages, tempLanguageValues)
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
        var tempDisableAutoTranslateLanguages: Set<String> = Set<String>()
        self.disableAutoTranslateLanguages.forEach { (language) in
            guard tempNeedShowLanguages.contains(language) else { return }
            tempDisableAutoTranslateLanguages.insert(language)
        }
        /// 刷新表格视图
        self.allNeedShowSupportedLanguages = tempNeedShowLanguages
        self.disableAutoTranslateLanguages = tempDisableAutoTranslateLanguages
        self.reloadDataPublish.onNext(())
    }

    /// 处理选中的语言
    func handlerSelectLanguage(language: String) {
        if self.disableAutoTranslateLanguages.contains(language) {
            self.disableAutoTranslateLanguages.remove(language)
        } else {
            self.disableAutoTranslateLanguages.insert(language)
        }
        self.reloadDataPublish.onNext(())
    }

    /// 请求接口，设置不自动翻译语言
    func requestDisableAutoTranslateLanguages() -> Observable<Void> {
        return self.userGeneralSettings.updateDisableAutoTranslateLanguages(
            languages: Array(self.disableAutoTranslateLanguages)
        )
    }
}
