//
//  TranslationInfoProvider.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/11/16.
//

import Foundation
import ByteViewNetwork
import ByteViewSetting

protocol TranslationInfoProviderDelegate: AnyObject {
    /// 翻译展示规则变化
    func translationDisplayRuleDidChange(rule: TranslateDisplayRule)
    /// 自动翻译开关变化，本期只包括全局开关，不包括按语言设置里的 VC 开关
    func autoTranslationSwitchDidChange(isOn: Bool)
    /// 翻译的默认目标语言变化
    func translationLanguageDidChange(language: String)
}

/// 与主站之间通信，将消息暴露给 VC 内部
class TranslationInfoProvider {
    private let listeners = Listeners<TranslationInfoProviderDelegate>()

    // 下面三个变量会依据推送而变化，由于我们监听推送与主站监听推送可能有时序上的问题，因此自己维护自己的变量，除了初始值以外，不从主站读取

    var targetLanguage: String

    var isVCAutoTranslationOn: Bool

    var translationDisplayRule: TranslateDisplayRule

    var availableLanguages: [TranslateLanguage] {
        meeting.setting.translateLanguageSetting.availableLanguages
    }

    let meeting: InMeetMeeting
    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        let settings = meeting.setting.translateLanguageSetting
        // 默认从主站取值
        targetLanguage = settings.targetLanguage
        isVCAutoTranslationOn = settings.isAutoTranslationOn
        translationDisplayRule = settings.globalConf.rule
        meeting.setting.addComplexListener(self, for: .translateLanguageSetting)
    }

    func updateVCAutoTranslation(isOn: Bool) {
        meeting.setting.updateSettings({ $0.isAutoTranslationOn = isOn })
    }

    func updateTargetLanguage(_ key: String) {
        meeting.setting.updateSettings({ $0.targetTranslateLanguage = key })
    }

    func languageName(for key: String) -> String {
        availableLanguages.first { $0.key == key }?.name ?? key
    }

    func addListener(_ listener: TranslationInfoProviderDelegate) {
        listeners.addListener(listener)
    }
}

extension TranslationInfoProvider: MeetingComplexSettingListener {
    func didChangeComplexSetting(_ settings: MeetingSettingManager, key: MeetingComplexSettingKey, value: Any, oldValue: Any?) {
        guard key == .translateLanguageSetting, let newValue = value as? TranslateLanguageSetting else { return }
        if newValue.isAutoTranslationOn != isVCAutoTranslationOn {
            isVCAutoTranslationOn = newValue.isAutoTranslationOn
            listeners.forEach { $0.autoTranslationSwitchDidChange(isOn: isVCAutoTranslationOn) }
        }
        if newValue.targetLanguage != targetLanguage {
            targetLanguage = newValue.targetLanguage
            listeners.forEach { $0.translationLanguageDidChange(language: targetLanguage) }
        }
        if newValue.globalConf.rule != translationDisplayRule {
            translationDisplayRule = newValue.globalConf.rule
            listeners.forEach { $0.translationDisplayRuleDidChange(rule: translationDisplayRule) }
        }
    }
}
