//
//  PatchViewUserSettingRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Videoconference_V1_PatchViewUserSettingRequest
public struct PatchViewUserSettingRequest {
    public static let command: NetworkCommand = .rust(.patchViewUserSetting)
    public typealias Response = PatchViewUserSettingResponse

    public init() { }

    public var calendarMeetingStartNotify: Bool?
    public var playEnterExitChimes: Bool?
    public var enableSelfAsActiveSpeaker: Bool?
    public var turnOnSubtitleWhenJoin: Bool?
    public var canOpenInterpretation: Bool?
    public var canOpenVoidprintRecognition: Bool?
    public var groupMeetingAutoRecord: Bool?
    public var singleMeetingAutoRecord: Bool?
    public var isMirror: Bool?
    public var backgroundBlur: Bool?
    public var virtualBackground: String?
    public var advancedBeauty: String?
    public var recordCompliancePopup: Bool?
    public var recordComplianceVoicePrompt: Bool?
    public var recordLayoutType: ViewUserSetting.RecordLayoutType?
    public var hideCamMutedParticipant: Bool?
    public var smartNoteOpen: Bool?
    public var reminder: ViewUserSetting.MeetingAdvanced.MissedCallReminder.Reminder?
    public var customRingtone: String? // 自定义铃声
    public var handsUpEmojiKey: String?
    public var generateMeetingSummaryInMinutes: FeatureStatus? // 在妙记中生成智能会议纪要
    public var generateMeetingSummaryInDocs: FeatureStatus? // 在纪要文档中生成智能会议纪要
    public var chatWithAiInMeeting: FeatureStatus? // 在会议中使用 AI 对话
}

/// - Videoconference_V1_PatchViewUserSettingResponse
public struct PatchViewUserSettingResponse {
    public init(userSetting: ViewUserSetting, deviceSetting: ViewDeviceSetting) {
        self.userSetting = userSetting
        self.deviceSetting = deviceSetting
    }

    public var userSetting: ViewUserSetting

    public var deviceSetting: ViewDeviceSetting
}

extension PatchViewUserSettingRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_PatchViewUserSettingRequest

    func toProtobuf() -> Videoconference_V1_PatchViewUserSettingRequest {
        var request = ProtobufType()
        if let calendarMeetingStartNotify = calendarMeetingStartNotify {
            request.userSetting.meetingGeneral.calendarMeetingStartNotify = calendarMeetingStartNotify
        }
        if let playEnterExitChimes = playEnterExitChimes {
            request.userSetting.meetingGeneral.playEnterExitChimes = playEnterExitChimes
        }
        if let enableSelfAsActiveSpeaker = enableSelfAsActiveSpeaker {
            request.userSetting.meetingGeneral.enableSelfAsActiveSpeaker = enableSelfAsActiveSpeaker
        }
        if let ringtone = customRingtone {
            request.userSetting.meetingGeneral.ringtone = ringtone
        }
        if let turnOnSubtitleWhenJoin = turnOnSubtitleWhenJoin {
            request.userSetting.meetingAdvanced.subtitle.turnOnSubtitleWhenJoin = turnOnSubtitleWhenJoin
        }
        if let canOpenInterpretation = canOpenInterpretation {
            request.userSetting.meetingAdvanced.interpretation.canOpenInterpretation = canOpenInterpretation
        }
        if let canOpenVoidprintRecognition = canOpenVoidprintRecognition {
            request.userSetting.audio.enableVoiceprintRecognition = canOpenVoidprintRecognition
        }
        if let groupMeetingAutoRecord = groupMeetingAutoRecord {
            request.userSetting.meetingAdvanced.recording.groupMeetingAutoRecord = groupMeetingAutoRecord
        }
        if let singleMeetingAutoRecord = singleMeetingAutoRecord {
            request.userSetting.meetingAdvanced.recording.singleMeetingAutoRecord = singleMeetingAutoRecord
        }
        if let recordCompliancePopup = recordCompliancePopup {
            request.userSetting.meetingAdvanced.recording.recordCompliancePopup.optionValue = recordCompliancePopup
        }
        if let recordComplianceVoicePrompt = recordComplianceVoicePrompt {
            request.userSetting.meetingAdvanced.recording.recordComplianceVoicePrompt.optionValue = recordComplianceVoicePrompt
        }
        if let recordLayoutType = recordLayoutType {
            request.userSetting.meetingAdvanced.recording.recordLayoutType = .init(rawValue: recordLayoutType.rawValue) ?? .sideLayout
        }
        if let hideCamMutedParticipant = hideCamMutedParticipant {
            request.userSetting.meetingAdvanced.recording.hideCamMutedParticipant = hideCamMutedParticipant
        }
        if let smartNoteOpen = smartNoteOpen {
            request.userSetting.meetingAdvanced.recording.smartNoteOpen = smartNoteOpen
        }
        if let reminder = reminder {
            request.userSetting.meetingAdvanced.missedCallReminder.reminder = .init(rawValue: reminder.rawValue) ?? .redPoint
        }
        if let handsUpEmojiKey = handsUpEmojiKey {
            request.userSetting.emojiSetting.handsUpEmojiKey = handsUpEmojiKey
        }
        if let generateMeetingSummaryInMinutes = generateMeetingSummaryInMinutes {
            request.userSetting.meetingAdvanced.intelligentMeetingSetting.generateMeetingSummaryInMinutes = .init(rawValue: generateMeetingSummaryInMinutes.rawValue) ?? .unknown
        }
        if let generateMeetingSummaryInDocs = generateMeetingSummaryInDocs {
            request.userSetting.meetingAdvanced.intelligentMeetingSetting.generateMeetingSummaryInDocs = .init(rawValue: generateMeetingSummaryInDocs.rawValue) ?? .unknown
        }
        if let chatWithAiInMeeting = chatWithAiInMeeting {
            request.userSetting.meetingAdvanced.intelligentMeetingSetting.chatWithAiInMeeting = .init(rawValue: chatWithAiInMeeting.rawValue) ?? .unknown
        }

        if let isMirror = isMirror {
            request.deviceSetting.video.mirror = isMirror
        }
        if let backgroundBlur = backgroundBlur {
            request.deviceSetting.video.backgroundBlur = backgroundBlur
        }
        if let virtualBackground = virtualBackground {
            request.deviceSetting.video.virtualBackground = virtualBackground
        }
        if let advancedBeauty = advancedBeauty {
            request.deviceSetting.video.advancedBeauty = advancedBeauty
        }
        return request
    }
}

extension PatchViewUserSettingResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_PatchViewUserSettingResponse
    init(pb: Videoconference_V1_PatchViewUserSettingResponse) {
        self.userSetting = .init(pb: pb.userSetting)
        self.deviceSetting = .init(pb: pb.deviceSetting)
    }
}
