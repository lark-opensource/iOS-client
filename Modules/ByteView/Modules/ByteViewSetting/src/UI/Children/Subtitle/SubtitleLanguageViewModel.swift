//
//  SubtitleLanguageViewModel.swift
//  ByteViewSetting
//
//  Created by wulv on 2023/3/15.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

struct SubtitleLanguageContext {
    let supportsRotate: Bool
    let languageType: LanguageType

    enum LanguageType {
        case subtitleLanguage
        case spokenLanguage

        var title: String {
            switch self {
            case .subtitleLanguage: return I18n.View_MV_TranslationLanguageInto
            case .spokenLanguage: return I18n.View_G_SpokenLanguage
            }
        }
    }
}

final class SubtitleLanguageViewModel: SettingViewModel<SubtitleLanguageContext> {
    typealias SubtitleLanguage = PullVideoChatConfigResponse.SubtitleLanguage
    private lazy var provider: GeneralSubtitleProvider = GeneralSubtitleProvider(service: service)

    override func setup() {
        super.setup()
        self.pageId = .subtitleLanguage
        self.title = context.languageType.title
        if context.languageType == .subtitleLanguage {
            self.observedSettingChanges = [.subtitleLanguage]
        }
        resetProvider()
        InMeetSettingHolder.shared.addListener(self)
    }

    override func trackPageAppear() {
        super.trackPageAppear()
        VCTracker.post(name: .vc_meeting_subtitle_setting_page, params: [.action_name: "display", .from_source: "vc_main_settings"])
        VCTracker.post(name: .vc_meeting_setting_click, params: [.click: "subtitle_set", "setting_tab": "main"])
    }

    override func buildSections(builder: SettingSectionBuilder) {
        let selectedLanguage = self.selectedLanguageKey
        builder.section()
        allLanguages.forEach { subtitle in
            builder.checkmark(.subtitleLanguage, title: subtitle.desc, isOn: subtitle.language == selectedLanguage) { [weak self] _ in
                guard let self = self else { return }
                self.selectLanguage(subtitle.language)
            }
        }
    }

    override var supportsRotate: Bool {
        context.supportsRotate
    }

    var selectedLanguageKey: String {
        switch context.languageType {
        case .subtitleLanguage:
            return provider.subtitleLanguageKey
        case .spokenLanguage:
            return provider.spokenLanguageKey
        }
    }

    var allLanguages: [SubtitleLanguage] {
        switch context.languageType {
        case .subtitleLanguage:
            return provider.allSubtitleLanguages
        case .spokenLanguage:
            return provider.allSpokenLanguages
        }
    }

    func selectLanguage(_ language: String) {
        let oldValue = self.selectedLanguageKey
        if language == oldValue { return }
        switch context.languageType {
        case .subtitleLanguage:
            VCTracker.post(name: .vc_meeting_subtitle_setting_page, params: [
                .action_name: "subtitle_language", .extend_value: ["from_language": oldValue, "action_language": language]])
            VCTracker.post(name: .vc_meeting_setting_click, params: [.click: "translate_language", "setting_tab": "subtitle", "language": language])
            provider.updateSubtitleLanguage(language)
        case .spokenLanguage:
            VCTracker.post(name: .vc_meeting_subtitle_setting_page, params: [
                .action_name: "spoken_language", .extend_value: ["from_language": oldValue, "action_language": language]])
            VCTracker.post(name: .vc_meeting_setting_click, params: [.click: "speak_language", "setting_tab": "subtitle", "language": language])
            provider.updateSpokenLanguage(language)
        }
    }
}

extension SubtitleLanguageViewModel: InMeetSettingChangedListener {
    func didChangeInMeetSettingInstance(_ setting: MeetingSettingManager?, oldSetting: MeetingSettingManager?) {
        oldSetting?.removeInternalListener(self)
        self.resetProvider()
        self.reloadData()
    }

    private func resetProvider() {
        if let setting = InMeetSettingHolder.shared.currentInMeetSetting {
            self.provider = InMeetSubtitleProvider(setting: setting)
            setting.addInternalListener(self)
        } else {
            self.provider = GeneralSubtitleProvider(service: service)
        }
    }
}

extension SubtitleLanguageViewModel: MeetingInternalSettingListener {
    func didChangeMyself(_ settings: MeetingSettingManager, value: Participant, oldValue: Participant?) {
        if context.languageType == .subtitleLanguage, value.settings.subtitleLanguage != oldValue?.settings.subtitleLanguage {
            reloadData()
        } else if context.languageType == .spokenLanguage, value.settings.spokenLanguage != oldValue?.settings.spokenLanguage {
            reloadData()
        }
    }
}
