//
//  TranscriptLanguageViewModel.swift
//  ByteViewSetting
//
//  Created by 陈乐辉 on 2023/6/19.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

public struct TranscriptLanguageContext {

    public init() {}

}

final class TranscriptLanguageViewModel: SettingViewModel<TranscriptLanguageContext> {
    typealias SubtitleLanguage = PullVideoChatConfigResponse.SubtitleLanguage
    private lazy var provider: GeneralTranscriptProvider = GeneralTranscriptProvider(setting: setting)
    private let setting: MeetingSettingManager

    var allLanguages: [SubtitleLanguage] {
        provider.allTranscriptLanguages
    }

    init(setting: MeetingSettingManager, context: TranscriptLanguageContext) {
        self.setting = setting
        super.init(service: setting.service, context: context)
        resetProvider()
        InMeetSettingHolder.shared.addListener(self)
    }

    override func setup() {
        super.setup()
        self.title = I18n.View_G_TranslateTranscriptionInto_Title
        observedSettingChanges = [.subtitleLanguage]
    }

    override func buildSections(builder: SettingSectionBuilder) {
        let selectedLanguage = self.provider.transcriptLanguageKey
        builder.section()
        allLanguages.forEach { subtitle in
            builder.checkmark(.subtitleLanguage, title: subtitle.desc, isOn: subtitle.language == selectedLanguage) { [weak self] _ in
                guard let self = self else { return }
                self.selectLanguage(subtitle.language)
            }
        }
    }

    func selectLanguage(_ language: String) {
        let oldValue = self.provider.transcriptLanguageKey
        if language == oldValue { return }
        provider.updateTranscriptLanguage(language)
    }
}

extension TranscriptLanguageViewModel: InMeetSettingChangedListener {

    func didChangeInMeetSettingInstance(_ setting: MeetingSettingManager?, oldSetting: MeetingSettingManager?) {
        oldSetting?.removeInternalListener(self)
        self.resetProvider()
        self.reloadData()
    }

    private func resetProvider() {
        if let setting = InMeetSettingHolder.shared.currentInMeetSetting {
            self.provider = GeneralTranscriptProvider(setting: setting)
            setting.addInternalListener(self)
        }
    }
}

extension TranscriptLanguageViewModel: MeetingInternalSettingListener {
    func didChangeMyself(_ settings: MeetingSettingManager, value: Participant, oldValue: Participant?) {
        if value.settings.transcriptLanguage != oldValue?.settings.transcriptLanguage {
            reloadData()
        }
    }
}


class GeneralTranscriptProvider: GeneralSubtitleProvider {

    let setting: MeetingSettingManager

    override var videoChatConfig: PullVideoChatConfigResponse { setting.videoChatConfig }
    var allTranscriptLanguages: [PullVideoChatConfigResponse.SubtitleLanguage] {
        allSubtitleLanguages
    }

    var transcriptLanguageKey: String { setting.transcriptLanguage.isEmpty ? "source" : setting.transcriptLanguage }

    init(setting: MeetingSettingManager) {
        self.setting = setting
        super.init(service: setting.service)
    }

    var transcriptLanguage: PullVideoChatConfigResponse.SubtitleLanguage {
        let key = self.transcriptLanguageKey
        if !key.isEmpty, let transcript = self.allTranscriptLanguages.first(where: { $0.language == key }) {
            return transcript
        }
        return .notTranslated
    }

    func updateTranscriptLanguage(_ language: String) {
        setting.updateParticipantSettings {
            $0.earlyPush = false
            $0.participantSettings.transcriptLanguage = language
        }
    }

}
