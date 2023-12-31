//
//  UserSettings.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/27.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

struct UserSettings {
    let diskCache: TypedLocalStorage<UserSettingStorageKey>
    var videoChatConfig: PullVideoChatConfigResponse?
    var adminPermissionInfo: GetAdminPermissionInfoResponse?
    var callmePhone: GetCallmePhoneResponse?

    private(set) var subtitleLanguage: GetSubtitleLanguageResponse?
    private(set) var myVoiceprintStatus: VoiceprintStatus = .none
    private(set) var translateLanguageSetting: TranslateLanguageSetting

    private(set) var userSetting: ViewUserSetting?
    private(set) var deviceSetting: ViewDeviceSetting?
    private(set) var appConfig: GetAppConfigResponse?

    private(set) var adminSettings: GetAdminSettingsResponse?
    private(set) var tenantAdminSettings: [String: GetAdminSettingsResponse] = [:]

    private(set) var suiteQuota: GetSuiteQuotaResponse?
    private(set) var meetingSuiteQuotas: [String: GetSuiteQuotaResponse] = [:]

    init(dependency: UserSettingDependency) {
        self.translateLanguageSetting = dependency.translateLanguageSetting
        self.diskCache = dependency.storage.toStorage(UserSettingStorageKey.self)
    }

    mutating func updateViewUserSettings(user: ViewUserSetting, device: ViewDeviceSetting) -> [UserSettingChange] {
        var changes: [UserSettingChange] = []
        let oldUser = self.userSetting
        if oldUser != user {
            self.userSetting = user
            changes.append(.viewUserSetting(.init(value: user, oldValue: oldUser)))
            if user.meetingGeneral.ringtone != oldUser?.meetingGeneral.ringtone {
                updateLocalSetting(user.meetingGeneral.ringtone, forKey: .customizeRingtoneForRing)
            }
        }
        let oldDevice = self.deviceSetting
        if oldDevice != device {
            self.deviceSetting = device
            changes.append(.viewDeviceSetting(.init(value: device, oldValue: oldDevice)))
        }
        return changes
    }

    mutating func updateSuiteQuota(_ resp: GetSuiteQuotaResponse, for request: GetSuiteQuotaRequest) -> [UserSettingChange] {
        if let meetingId = request.meetingID, !meetingId.isEmpty {
            let oldValue = self.meetingSuiteQuotas.updateValue(resp, forKey: meetingId)
            return resp != oldValue ? [.suiteQuota(.init(request: request, value: resp, oldValue: oldValue))] : []
        } else {
            let oldValue = self.suiteQuota
            if resp != oldValue {
                self.suiteQuota = resp
                return [.suiteQuota(.init(request: request, value: resp, oldValue: oldValue))]
            }
            return []
        }
    }

    mutating func updateAdminSettings(_ resp: GetAdminSettingsResponse, for request: GetAdminSettingsRequest) -> [UserSettingChange] {
        if let tenantId = request.tenantID {
            let oldValue = self.tenantAdminSettings.updateValue(resp, forKey: tenantId.description)
            return resp != oldValue ? [.adminSettings(.init(request: request, value: resp, oldValue: oldValue))] : []
        } else {
            let oldValue = self.adminSettings
            if resp != oldValue {
                self.adminSettings = resp
                return [.adminSettings(.init(request: request, value: resp, oldValue: oldValue))]
            }
            return []
        }
    }

    mutating func updateSubtitleLanguage(_ resp: GetSubtitleLanguageResponse) -> [UserSettingChange] {
        let oldValue = self.subtitleLanguage
        if resp != oldValue {
            self.subtitleLanguage = resp
            return [.subtitleLanguage(.init(value: resp, oldValue: oldValue))]
        }
        return []
    }

    mutating func updateMyVoiceprintStatus(_ value: VoiceprintStatus) -> [UserSettingChange] {
        let oldValue = self.myVoiceprintStatus
        if value != oldValue {
            self.myVoiceprintStatus = value
            return [.myVoiceprintStatus(.init(value: value, oldValue: oldValue))]
        }
        return []
    }

    mutating func updateJoinAudioOutputSetting(_ value: Int) -> [UserSettingChange] {
        let oldValue = diskCache.int(forKey: .preferAudioOutputSetting, defaultValue: 0)
        if value != oldValue {
            diskCache.set(value, forKey: .preferAudioOutputSetting)
            return [.userjoinAudioOutputSetting]
        }
        return []
    }

    mutating func updateTranslateLanguageSetting(_ value: TranslateLanguageSetting) -> [UserSettingChange] {
        let oldValue = self.translateLanguageSetting
        if value != oldValue {
            self.translateLanguageSetting = value
            return [.translateLanguageSetting(.init(value: value, oldValue: oldValue))]
        }
        return []
    }

    mutating func updateAppConfig(_ resp: GetAppConfigResponse) -> [UserSettingChange] {
        var resp = resp
        if resp.videochatParticipantLimit <= 0 {
            resp.videochatParticipantLimit = 6
        }
        self.appConfig = resp
        return []
    }

    @discardableResult
    mutating func updateLocalSetting<T: Codable & Equatable>(_ value: T?, forKey key: UserSettingStorageKey) -> Bool {
        let oldValue: T? = diskCache.value(forKey: key)
        diskCache.setValue(value, forKey: key)
        return oldValue != value
    }
}

extension UserSettings {
    var enterprisePhoneConfig: GetEnterprisePhoneConfigResponse? { diskCache.value(forKey: .enterprisePhoneConfig) }
    var adminMediaServerSettings: GetAdminMediaServerSettingsResponse? { diskCache.value(forKey: .adminMediaServer) }
    var rtcFeatureGating: GetRtcFeatureGatingResponse? { diskCache.value(forKey: .rtcFeatureGating) }
    var adminOrgSettings: GetAdminOrgSettingsResponse? { diskCache.value(forKey: .adminOrgSettings) }

    var viewUserSettingResponse: PullViewUserSettingResponse? {
        if let user = self.userSetting, let device = self.deviceSetting {
            return PullViewUserSettingResponse(userSetting: user, deviceSetting: device)
        } else {
            return nil
        }
    }

    var customRingtone: String {
        if let ringtone = userSetting?.meetingGeneral.ringtone {
            Logger.setting.info("ringtoneName: use viewUserSetting \(ringtone)")
            return ringtone
        } else if let ringtone = diskCache.string(forKey: .customizeRingtoneForRing) {
            Logger.setting.info("ringtoneName: use diskCache \(ringtone)")
            return ringtone
        } else {
            Logger.setting.info("ringtoneName: use defaultValue")
            return "vc_call_ringing.mp3"
        }
    }
}

extension UserSettings {
    mutating func mergeOldLocalStorage(dependency: UserSettingDependency) {
        if diskCache.bool(forKey: .mergeSettingV6v10)  { return }
        diskCache.set(true, forKey: .mergeSettingV6v10)

        let globalStorage = dependency.globalStorage
        let oldCache = globalStorage.toStorage(GlobalSettingStorageKey.self)
        let boolKeys: [GlobalSettingStorageKey] = [
            .micSpeakerDisabled, .keyboardMute, .displayFPS, .displayCodec, .meetingHDVideo, .centerStageUsed, .pip
        ]
        boolKeys.forEach { oldKey in
            if let key = UserSettingStorageKey(rawValue: oldKey.rawValue), let value = oldCache.value(forKey: oldKey, type: Bool.self) {
                diskCache.set(value, forKey: key)
            }
        }
        let intKeys: [GlobalSettingStorageKey] = [.voiceAudioDevice, .videoAudioDevice]
        intKeys.forEach { oldKey in
            if let key = UserSettingStorageKey(rawValue: oldKey.rawValue), let value = oldCache.value(forKey: oldKey, type: Int.self) {
                diskCache.set(value, forKey: key)
            }
        }
    }
}

private enum GlobalSettingStorageKey: String, LocalStorageKey {
    case micSpeakerDisabled
    case keyboardMute
    case displayFPS
    case displayCodec
    case meetingHDVideo
    /// 标记是否使用过
    case centerStageUsed
    case pip

    // 音频1v1音频设备
    case voiceAudioDevice
    // 视频1v1音频设备
    case videoAudioDevice

    var domain: LocalStorageDomain {
        .child("Core")
    }
}
