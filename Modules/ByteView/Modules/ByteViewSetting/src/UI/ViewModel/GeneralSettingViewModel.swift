//
//  GeneralSettingViewModel.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/1.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import UniverseDesignToast
import ByteViewTracker
import ByteViewUI
import LarkLocalizations

public struct GeneralSettingContext {
    public let source: String?
    public init(source: String?) {
        self.source = source
    }
}

final class GeneralSettingViewModel: GeneralSettingBaseViewModel<GeneralSettingContext> {
    private var inMeetSetting: MeetingSettingManager? { InMeetSettingHolder.shared.currentInMeetSetting }

    override var autoJumpCell: SettingDisplayItem? {
        if context.source == "vc_share_content" {
            return .ultrasonicConnection
        }
        return nil
    }

    override func setup() {
        super.setup()
        self.pageId = .generalSetting
        self.title = I18n.View_G_CallsAndMeetings
        self.observedSettingChanges.formUnion([.suiteQuota, .adminSettings, .subtitleLanguage])
        service.refreshViewUserSetting(force: true)
        service.refreshAdminSettings(force: true)
        service.refreshSuiteQuota(force: true)
        service.refreshVoiceprintStatus()
        service.refreshVideoChatConfig(force: true)
        service.refreshSubtitleLanguage(force: true)
        self.resetProvider()
        InMeetSettingHolder.shared.addListener(self)
        if context.source == "voiceprint" {
            VCTracker.post(name: .vc_minutes_bot_click, params: [.click: "enable", "source": "voiceprint"])
        }
    }
}

extension GeneralSettingViewModel: InMeetSettingChangedListener {
    func didChangeInMeetSettingInstance(_ setting: MeetingSettingManager?, oldSetting: MeetingSettingManager?) {
        oldSetting?.removeListener(self)
        oldSetting?.removeInternalListener(self)
        self.resetProvider()
        self.reloadData()
    }

    private func resetProvider() {
        if let setting = InMeetSettingHolder.shared.currentInMeetSetting {
            self.provider = InMeetGeneralSettingProvider(setting: setting)
            setting.addListener(self, for: [.isFrontCameraEnabled])
            setting.addInternalListener(self)
        } else {
            self.provider = GeneralSettingProvider(service: service)
        }
    }
}

extension GeneralSettingViewModel: MeetingInternalSettingListener, MeetingSettingListener {
    func didChangeMyself(_ settings: MeetingSettingManager, value: Participant, oldValue: Participant?) {
        if value.settings.subtitleLanguage != oldValue?.settings.subtitleLanguage {
            reloadData()
        }
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        reloadData()
    }
}
