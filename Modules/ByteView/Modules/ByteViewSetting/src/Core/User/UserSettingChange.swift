//
//  UserSettingChange.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/14.
//

import Foundation
import ByteViewNetwork

public enum UserSettingChange {
    case suiteQuota(NetworkSettingChange<GetSuiteQuotaRequest>)
    case adminSettings(NetworkSettingChange<GetAdminSettingsRequest>)
    case viewUserSetting(SettingChange<ViewUserSetting>)
    case viewDeviceSetting(SettingChange<ViewDeviceSetting>)
    case subtitleLanguage(SettingChange<GetSubtitleLanguageResponse>)
    case myVoiceprintStatus(SettingChange<VoiceprintStatus>)
    case translateLanguageSetting(SettingChange<TranslateLanguageSetting>)

    case micSpeakerDisabled
    case displayFPS
    case displayCodec
    case meetingHDVideo
    case pip

    case useCellularImproveAudioQuality
    case autoHideToolStatusBar
    case ultrawave
    case needAdjustAnnotate
    case userjoinAudioOutputSetting
    case reactionDisplayMode

    public var type: UserSettingChangeType {
        switch self {
        case .suiteQuota(let change):
            return change.request.meetingID == nil ? .suiteQuota : .meetingSuiteQuota
        case .adminSettings(let change):
            return change.request.tenantID == nil ? .adminSettings : .tenantAdminSettings
        case .viewUserSetting:
            return .viewUserSetting
        case .viewDeviceSetting:
            return .viewDeviceSetting
        case .subtitleLanguage:
            return .subtitleLanguage
        case .myVoiceprintStatus:
            return .myVoiceprintStatus
        case .translateLanguageSetting:
            return .translateLanguageSetting
        case .micSpeakerDisabled:
            return .micSpeakerDisabled
        case .displayFPS:
            return .displayFPS
        case .displayCodec:
            return .displayCodec
        case .meetingHDVideo:
            return .meetingHDVideo
        case .pip:
            return .pip
        case .useCellularImproveAudioQuality:
            return .useCellularImproveAudioQuality
        case .autoHideToolStatusBar:
            return .autoHideToolStatusBar
        case .ultrawave:
            return .ultrawave
        case .needAdjustAnnotate:
            return .needAdjustAnnotate
        case .userjoinAudioOutputSetting:
            return .userjoinAudioOutputSetting
        case .reactionDisplayMode:
            return .reactionDisplayMode
        }
    }
}

public enum UserSettingChangeType: String, CustomStringConvertible {
    case suiteQuota
    case meetingSuiteQuota
    case adminSettings
    case tenantAdminSettings
    case viewUserSetting
    case viewDeviceSetting
    case subtitleLanguage
    case myVoiceprintStatus
    case translateLanguageSetting
    case userjoinAudioOutputSetting

    // MARK: - local
    case micSpeakerDisabled
    case displayFPS
    case displayCodec
    case meetingHDVideo
    case pip

    // MARK: - local
    case useCellularImproveAudioQuality
    case autoHideToolStatusBar
    case ultrawave
    case needAdjustAnnotate
    case reactionDisplayMode

    public var description: String { rawValue }
}
