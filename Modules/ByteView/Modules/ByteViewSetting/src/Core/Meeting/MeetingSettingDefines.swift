//
//  MeetingSettingDefines.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/23.
//

import Foundation
import ByteViewNetwork

public enum MeetingSettingPrestartContext {
    case videoChatInfo(VideoChatInfo)
    case meetingType(MeetingType)
    case lobbyInfo(LobbyInfo)
}

/// 变化原因，用于生成changedKeys
enum MeetingSettingChangeReason: CaseIterable {
    case host
    case cohost
    case breakoutRoom
    case webinarAttendee
    case participantSettings
    case featureConfig
    case videoChatSettings
    case meetingType
    case adminSettings
    case sponsorAdminSettings
    case adminOrgSettings
    case suiteQuota
    case viewUserSetting
    case viewDeviceSetting
    case videoChatConfig
    case extraData
    case debug
}

public enum DataMode {
    case standardMode
    case ecoMode
    case voiceMode
}

/// 关键影响因子
struct MeetingSettingControl: OptionSet {
    let rawValue: Int8
    init(rawValue: Int8) {
        self.rawValue = rawValue
    }

    static let host = MeetingSettingControl(rawValue: 1 << 0)
    static let cohost = MeetingSettingControl(rawValue: 1 << 1)
    /// 用户是否在讨论组（不含主会场）
    static let breakoutRoom = MeetingSettingControl(rawValue: 1 << 2)
    /// 是否是webinar观众
    static let webinarAttendee = MeetingSettingControl(rawValue: 1 << 3)

    func toChangeReasons() -> [MeetingSettingChangeReason] {
        var reasons: [MeetingSettingChangeReason] = []
        if self.contains(.host) {
            reasons.append(.host)
        }
        if self.contains(.cohost) {
            reasons.append(.cohost)
        }
        if self.contains(.breakoutRoom) {
            reasons.append(.breakoutRoom)
        }
        if self.contains(.webinarAttendee) {
            reasons.append(.webinarAttendee)
        }
        return reasons
    }
}

/// 设置改变依赖的额外数据
struct MeetingSettingExtraData: Equatable {
    var isLargeMeetingTriggered: Bool = false
    var hasVote: Bool = false
    var isFrontCameraEnabled: Bool = true
    var isSystemPhoneCalling: Bool = false
    var isInMeetCameraMuted: Bool = true
    var isInMeetMicrophoneMuted: Bool = true
    var isInMeetCameraEffectOn: Bool = false
    var isSharingDocument: Bool = false
    var isSharingScreen: Bool = false
    var isSharingWhiteboard: Bool = false
    var isExternalMeeting: Bool?
    var dataMode: DataMode = .standardMode
}
