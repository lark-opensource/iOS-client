//
//  SubtitleSettingViewModel.swift
//  ByteViewSetting
//
//  Created by wulv on 2023/3/21.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

public enum SubtitleSettingFromSource {
    case meetSettingEntrance
    case inMeetTip
    case subtitleHistory
    case subtitlePad
    case subtitleHistoryiPad
    case handleDetectedLanguageTip

    var supportsRotate: Bool {
        switch self {
        case .subtitleHistory:
            return false
        case .inMeetTip, .meetSettingEntrance, .subtitlePad, .subtitleHistoryiPad, .handleDetectedLanguageTip:
            return true
        }
    }
}

public struct SubtitleSettingContext {
    public var fromSource: SubtitleSettingFromSource
    public init(fromSource: SubtitleSettingFromSource) {
        self.fromSource = fromSource
    }
}

final class SubtitleSettingViewModel: SettingViewModel<SubtitleSettingContext> {
    private let setting: MeetingSettingManager
    private lazy var provider = InMeetSubtitleProvider(setting: setting)
    init(setting: MeetingSettingManager, context: SubtitleSettingContext) {
        self.setting = setting
        super.init(service: setting.service, context: context)
    }

    override func setup() {
        super.setup()
        self.pageId = .subtitleSetting
        self.title = I18n.View_G_SubtitleSettings_InBoxHover
        setting.addInternalListener(self)
        setting.addComplexListener(self, for: .subtitlePhraseStatus)
    }

    override func buildSections(builder: SettingSectionBuilder) {
        builder.section(if: setting.showsSubtitleSetting)
            .gotoCell(.spokenLanguage, title: I18n.View_G_SpokenLanguage, accessoryText: provider.spokenLanguage?.desc,
                      if: self.showsSpokenLanguage, action: { [weak self] context in
                guard let self = self else { return }
                let subtitleContext = SubtitleLanguageContext(supportsRotate: self.supportsRotate, languageType: .spokenLanguage)
                let vm = SubtitleLanguageViewModel(service: context.service, context: subtitleContext)
                context.push(SettingViewController(viewModel: vm))
            })
            .gotoCell(.subtitleLanguage, title: I18n.View_MV_TranslationLanguageInto,
                      accessoryText: self.provider.subtitleLanguage.desc,
                      isEnabled: provider.isSubtitleTranslationEnabled,
                      action: { [weak self] context in
                guard let self = self else { return }
                let subtitleContext = SubtitleLanguageContext(supportsRotate: self.supportsRotate, languageType: .subtitleLanguage)
                let vm = SubtitleLanguageViewModel(service: context.service, context: subtitleContext)
                context.push(SettingViewController(viewModel: vm))
            })
            .switchCell(.subtitlePhrase, title: I18n.View_G_SmartAnnotation_Tick, subtitle: I18n.View_G_ExplainSmartAnnotation,
                        isOn: provider.isSubtitlePhraseOn, isEnabled: provider.isSubtitlePhraseEnabled, showsDisabledButton: true,
                        if: self.showsSubtitlePhrase, action: { [weak self] context in
                self?.provider.updateSubtitlePhrase(isOn: context.isOn, context: context)
            })
    }

    override var supportsRotate: Bool { context.fromSource.supportsRotate }

    var showsSpokenLanguage: Bool {
        !setting.fg.subtitleDeleteSpokenLanguage && !provider.spokenLanguageKey.isEmpty
    }

    var showsSubtitlePhrase: Bool {
        switch setting.subtitlePhraseStatus {
        case .unknown, .unavailable:
            return false
        case .disabled, .on, .off:
            return true
        }
    }
}

extension SubtitleSettingViewModel: MeetingInternalSettingListener, MeetingComplexSettingListener {
    func didChangeMyself(_ settings: MeetingSettingManager, value: Participant, oldValue: Participant?) {
        if oldValue?.settings.subtitleLanguage != value.settings.subtitleLanguage
            || oldValue?.settings.spokenLanguage != value.settings.spokenLanguage {
            reloadData()
        }
    }

    func didChangeComplexSetting(_ settings: MeetingSettingManager, key: MeetingComplexSettingKey, value: Any, oldValue: Any?) {
        reloadData()
    }
}

class GeneralSubtitleProvider {
    fileprivate static let notTranslateKey = PullVideoChatConfigResponse.SubtitleLanguage.notTranslated.language

    let service: UserSettingManager
    init(service: UserSettingManager) {
        self.service = service
    }

    var isSubtitleTranslationEnabled: Bool { service.isSubtitleTranslationEnabled }
    var videoChatConfig: PullVideoChatConfigResponse { service.videoChatConfig }
    var subtitleLanguageKey: String { service.subtitleLanguage?.subtitleLanguage.language ?? "" }
    var spokenLanguageKey: String { "" }
    var isSubtitlePhraseEnabled: Bool { false }
    var isSubtitlePhraseOn: Bool { false }

    var allSpokenLanguages: [PullVideoChatConfigResponse.SubtitleLanguage] { videoChatConfig.allSpokenLanguages }
    var allSubtitleLanguages: [PullVideoChatConfigResponse.SubtitleLanguage] { videoChatConfig.allSubtitleLanguages }

    var spokenLanguage: PullVideoChatConfigResponse.SubtitleLanguage? {
        let key = self.spokenLanguageKey
        if !key.isEmpty, let subtitle = self.allSpokenLanguages.first(where: { $0.language == key }) {
            return subtitle
        }
        return nil
    }

    var subtitleLanguage: PullVideoChatConfigResponse.SubtitleLanguage {
        let key = self.subtitleLanguageKey
        if !key.isEmpty, isSubtitleTranslationEnabled, let subtitle = self.allSubtitleLanguages.first(where: { $0.language == key }) {
            return subtitle
        }
        return .notTranslated
    }

    func updateSubtitleLanguage(_ language: String) {
        service.updateSubtitleLanguage(language)
    }

    func updateSpokenLanguage(_ language: String) {}
    func updateSubtitlePhrase(isOn: Bool, context: SettingRowActionContext) {}
}

class InMeetSubtitleProvider: GeneralSubtitleProvider {
    let setting: MeetingSettingManager
    init(setting: MeetingSettingManager) {
        self.setting = setting
        super.init(service: setting.service)
    }

    override var isSubtitleTranslationEnabled: Bool { setting.fg.isSubtitleTranslationEnabled }
    override var videoChatConfig: PullVideoChatConfigResponse { setting.videoChatConfig }
    override var subtitleLanguageKey: String { setting.subtitleLanguage }
    override var spokenLanguageKey: String { setting.spokenLanguage }
    override var isSubtitlePhraseEnabled: Bool { setting.subtitlePhraseStatus != .disabled && subtitleLanguageKey == Self.notTranslateKey }
    override var isSubtitlePhraseOn: Bool { setting.subtitlePhraseStatus == .on }

    override func updateSubtitleLanguage(_ language: String) {
        setting.updateParticipantSettings {
            $0.earlyPush = false
            $0.participantSettings.subtitleLanguage = language
        }
    }

    override func updateSpokenLanguage(_ language: String) {
        setting.updateParticipantSettings {
            $0.earlyPush = false
            $0.participantSettings.spokenLanguage = language
        }
    }

    override func updateSubtitlePhrase(isOn: Bool, context: SettingRowActionContext) {
        if !isSubtitlePhraseEnabled {
            context.showToast(I18n.View_G_SmartAnnotationTooltip)
            return
        }
        /// 字幕设置页开关智能注释
        VCTracker.post(name: .vc_meeting_setting_click, params: [.click: "subtitle_annotation", "is_checked": isOn ? "true" : "false"])
        setting.updateSubtitlePhraseStatus(isOn: isOn)
    }
}
