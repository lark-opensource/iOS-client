//
//  ChatLanguageViewModel.swift
//  ByteViewSetting
//
//  Created by wulv on 2023/3/15.
//

import Foundation
import ByteViewTracker

final class ChatLanguageViewModel: SettingViewModel<SettingSourceContext> {
    override func setup() {
        super.setup()
        self.pageId = .chatLanguage
        self.title = I18n.View_MV_AutoTranslation_Feature
        self.observedSettingChanges = [.translateLanguageSetting, .viewUserSetting]
    }

    override func buildSections(builder: SettingSectionBuilder) {
        let selectedDisplay = service.chatLanguageDisplay
        builder.section()
            .checkmark(.chatLanguage, title: I18n.View_G_NoTranslation_DropMenu, isOn: I18n.View_G_NoTranslation_DropMenu == selectedDisplay) { [weak self] _ in
                guard let self = self else { return }
                self.trackSelectLanguage("source")
                self.service.updateTranslateLanguage(isAutoTranslationOn: false)
                self.reloadData()
            }
        service.translateLanguageSetting.availableLanguages.forEach { language in
            builder.checkmark(.chatLanguage, title: language.name, isOn: language.name == selectedDisplay) { [weak self] _ in
                guard let self = self else { return }
                self.trackSelectLanguage(language.key)
                self.service.updateTranslateLanguage(isAutoTranslationOn: true, targetLanguage: language.key)
                self.reloadData()
            }
        }
    }

    override var supportsRotate: Bool {
        context.supportsRotate
    }

    private func trackSelectLanguage(_ language: String) {
        VCTracker.post(name: .vc_meeting_setting_click, params: [.click: "vc_chat_translate", "language": language])
    }
}
