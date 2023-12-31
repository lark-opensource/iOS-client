//
//  MeetingSettingManager+Internal.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/14.
//

import Foundation
import ByteViewNetwork

protocol MeetingInternalSettingListener: AnyObject {
    func didChangeSuiteQuota(_ settings: MeetingSettingManager, value: GetSuiteQuotaResponse, oldValue: GetSuiteQuotaResponse?)
    func didChangeVideoChatSettings(_ settings: MeetingSettingManager, value: VideoChatSettings, oldValue: VideoChatSettings?)
    func didChangeMyself(_ settings: MeetingSettingManager, value: Participant, oldValue: Participant?)
    func didChangeSuggestThreshold(_ settings: MeetingSettingManager, value: Int)
}

extension MeetingSettingManager {
    var deviceId: String { service.deviceId }
    var showsSubtitleSetting: Bool {
        fg.isSubtitleEnabled && adminSettings.enableSubtitle && suiteQuota.subtitle
    }

    /// 大方会管提示人数
    var suggestManageThreshold: Int32 {
        extraData.isLargeMeetingTriggered ? videoChatConfig.largeMeetingSecurityNoticeThreshold : videoChatConfig.largeMeetingSuggestThreshold
    }

    func updateSecurityLevel(_ level: VideoChatSettings.SecuritySetting.SecurityLevel, completion: ((Result<Void, Error>) -> Void)? = nil) {
        var security = self.videoChatSettings.securitySetting
        security.securityLevel = level
        updateHostManage(.setSecurityLevel, update: { $0.securitySetting = security }, completion: completion)
    }

    func updatePanelistPermission(_ update: (inout UpdatingPanelistPermission) -> Void, completion: ((Result<Void, Error>) -> Void)? = nil) {
        var panelistPermission = UpdatingPanelistPermission()
        update(&panelistPermission)
        updateHostManage(.panelistPermissionChange, update: { $0.panelistPermission = panelistPermission }, completion: completion)
    }

    func updateAttendeePermission(_ update: (inout UpdatingAttendeePermission) -> Void, completion: ((Result<Void, Error>) -> Void)? = nil) {
        var attendeePermission = UpdatingAttendeePermission()
        update(&attendeePermission)
        updateHostManage(.attendeePermissionChange, update: { $0.attendeePermission = attendeePermission }, completion: completion)
    }
}

extension MeetingInternalSettingListener {
    func didChangeSuiteQuota(_ settings: MeetingSettingManager, value: GetSuiteQuotaResponse, oldValue: GetSuiteQuotaResponse?) {}
    func didChangeVideoChatSettings(_ settings: MeetingSettingManager, value: VideoChatSettings, oldValue: VideoChatSettings?) {}
    func didChangeMyself(_ settings: MeetingSettingManager, value: Participant, oldValue: Participant?) {}
    func didChangeSuggestThreshold(_ settings: MeetingSettingManager, value: Int) {}
}
