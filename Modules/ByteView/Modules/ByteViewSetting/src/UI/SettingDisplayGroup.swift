//
//  SettingDisplayGroup.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/2/28.
//

import Foundation

/// 设置项
enum SettingDisplayGroup: String {
    /// 临时分组，无特殊设置（header/footer/items）
    case unknown
    /// 入会设置，calendarMeetingStartNotify、playEnterExitChimes
    case joinMeeting
    /// 字幕设置，turnOnSubtitleWhenJoin
    case subtitle
    /// 音频设置，micSpeakerDisabled
    case audio
    /// 录制设置，groupMeetingAutoRecord、singleMeetingAutoRecord、recordCompliancePopup、recordLayoutType、hideCamMutedParticipantInRecording
    case record
    /// 声纹设置，enableVoiceprintRecognition、myVoiceprint
    case voiceprint
    /// 未接会议提醒，missedCallReminder
    case missedCall
    /// 网络设置，useCellularImproveAudioQuality
    case network
    /// 添加主持人，含meetingOwner
    case meetingOwner
    /// 添加译员，含addInterpreter、editInterpreter
    case interpreter
    /// 问题反馈
    case feedback
    /// 锁定会议，lockMeeting
    case lockMeeting
    /// 入会范围，securityLevel
    case securityLevel
    /// 等候室权限，lobbyOnEntry
    case lobbyPermission
    /// 发言权限，muteOnEntry、allowPartiUnmute
    case speakingPermission
    /// 共享权限，onlyHostCanShare、onlyHostCanReplaceShare、onlyPresenterCanAnnotate
    case sharePermission
    /// 参会人权限，isPartiChangeNameForbidden、allowSendReaction、allowRequestRecord、allowSendMessage
    case participantPermission
    /// 嘉宾权限，allowPartiUnmute、isPartiChangeNameForbidden、allowSendReaction、allowRequestRecord、allowSendMessage
    case panelistPermission
    /// 观众权限，allowAttendeeSendMessage、allowAttendeeSendReaction
    case attendeePermission
}

extension SettingDisplayGroup: CustomStringConvertible {
    var description: String { rawValue }
}
