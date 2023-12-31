//
//  AutoTranslateGuideViewModel.swift
//  LarkChat
//
//  Created by 李勇 on 2019/7/18.
//

import Foundation
import RxSwift
import LarkSDKInterface
import LarkModel
import RustPB

final class AutoTranslateGuideViewModel {
    /// 用户常用设置
    private let userGeneralSettings: UserGeneralSettings
    /// 当前用户选中的目标语言key
    var selectdTargetLanguage: String
    /// 当前所有服务器支持的语言key，从languageKeys和supportedLanguages中筛选
    var allNeedShowSupportedLanguages: [String] = []

    init(userGeneralSettings: UserGeneralSettings) {
        self.userGeneralSettings = userGeneralSettings
        self.selectdTargetLanguage = self.userGeneralSettings.translateLanguageSetting.targetLanguage
        self.userGeneralSettings.translateLanguageSetting.languageKeys.forEach { (language) in
            guard self.userGeneralSettings.translateLanguageSetting.supportedLanguages.keys.contains(language) else { return }
            self.allNeedShowSupportedLanguages.append(language)
        }
    }

    /// 获取该语言的展示value
    func languageValue(language: String) -> String {
        guard let languageValue = self.userGeneralSettings.translateLanguageSetting.supportedLanguages[language] else {
            return ""
        }
        return languageValue
    }

    /// 修改目标语言 & 打开全局翻译开关
    func changeTargetLanguageAndOpenAutoTranslateGlobaSwitch() -> Observable<Void> {
        let switchOb = self.userGeneralSettings.updateTranslateLanguageSetting(language: self.selectdTargetLanguage)
        let scope = self.userGeneralSettings.translateLanguageSetting.translateScope | RustPB.Im_V1_TranslateScopeMask.larkMessageMask.rawValue
        let targetOb = self.userGeneralSettings.updateAutoTranslateScope(scope: scope)
        return switchOb.flatMap({ (_) -> Observable<Void> in targetOb })
    }
}
