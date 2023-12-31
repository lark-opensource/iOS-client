//
//  ViewUserSetting.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

typealias PBViewUserSettingIntelligentMeetingSetting = Videoconference_V1_ViewUserSetting.MeetingAdvanced.UserIntelligentMeetingSetting
typealias PBViewUserSettingFeatureStatus = Videoconference_V1_ViewUserSetting.MeetingAdvanced.UserIntelligentMeetingSetting.FeatureStatus

typealias ViewUserSettingIntelligentMeetingSetting = ViewUserSetting.MeetingAdvanced.ViewUserSettingIntelligentMeetingSetting
typealias ViewUserSettingFeatureStatus = ViewUserSetting.MeetingAdvanced.ViewUserSettingFeatureStatus

/// Videoconference_V1_ViewUserSetting
public struct ViewUserSetting: Equatable {
    public init() {}

    public var audio: Audio = Audio()

    public var meetingGeneral: MeetingGeneral = MeetingGeneral()

    public var meetingAdvanced: MeetingAdvanced = MeetingAdvanced()

    public var emojiSetting: InMeetingEmojiSetting = InMeetingEmojiSetting()

    public struct Audio: Equatable {
        public init() {}

        /// 允许声纹识别
        public var enableVoiceprintRecognition: Bool = false
    }

    public enum DisplayStatus: Int, Hashable, Equatable {
        case normal // 展示且可选
        case disabled  // 展示且置灰
        case hidden // 不展示
    }

    public struct DisplayBoolOption: Equatable {
        public var displayStatus: DisplayStatus = .normal
        public var optionalValue: Bool = false
    }

    public enum RecordLayoutType: Int {
        case sideLayout
        case fullScreenLayout
        case speakerLayout
        case galleryLayout
    }

    public struct MeetingGeneral: Equatable {
        public init() {}

        ///进出会议时播放声音提醒
        public var playEnterExitChimes: Bool = false

        ///日程会议入会提醒
        public var calendarMeetingStartNotify: Bool = false

        ///视频会议自定义铃声
        public var ringtone: String?

        public var enableSelfAsActiveSpeaker: Bool = false

        /// 用户该设备是否曾经设置过铃声
        public var deviceEverSetRingtone: Bool = false
    }

    public struct MeetingAdvanced: Equatable {
        public init() {}

        public var subtitle: Subtitle = Subtitle()

        public var interpretation: Interpretation = Interpretation()

        public var recording: Recording = Recording()

        public var missedCallReminder: MissedCallReminder = MissedCallReminder()

        public var intelligentMeetingSetting: ViewUserSettingIntelligentMeetingSetting = ViewUserSettingIntelligentMeetingSetting()

        public struct Subtitle: Equatable {
            public init() {}

            ///默认入会开启字幕
            public var turnOnSubtitleWhenJoin: Bool = false
        }

        /// 新增针对传译的全局配置项
        public struct Interpretation: Equatable {
            public init() {}

            public var canOpenInterpretation: Bool = false
        }

        public struct Recording: Equatable {
            public init() {}

            /// 默认发起多人会议时自动开启录制
            public var groupMeetingAutoRecord: Bool = false

            /// 默认1v1接通后自动开启录制
            public var singleMeetingAutoRecord: Bool = false

            /// 接收会议录制提醒
            public var recordCompliancePopup: DisplayBoolOption = DisplayBoolOption()
            /// 允许语音提醒
            public var recordComplianceVoicePrompt: DisplayBoolOption = DisplayBoolOption()

            /// 录制布局
            public var recordLayoutType: RecordLayoutType = .sideLayout

            /// 是否隐藏非摄像头用户
            public var hideCamMutedParticipant: Bool = false

            public var smartNoteSwitchDisplay: Bool = false

            public var smartNoteOpen: Bool = false
        }

        public struct MissedCallReminder: Equatable {
            public enum Reminder: Int {
                case unknown
                /// 会议助手消息通知
                case bot
                /// 导航栏红点
                case redPoint
            }

            public init() {}

            /// 未接呼叫提醒
            public var reminder: Reminder = .unknown
        }

        public struct ViewUserSettingIntelligentMeetingSetting: Equatable {
            /// 在妙记中生成智能会议纪要
            public var generateMeetingSummaryInMinutes: ViewUserSettingFeatureStatus = .unknown
            /// 在纪要文档中生成智能会议纪要
            public var generateMeetingSummaryInDocs: ViewUserSettingFeatureStatus = .unknown
            /// 在会议中使用 AI 对话
            public var chatWithAiInMeeting: ViewUserSettingFeatureStatus = .unknown

            public init() {}
        }

        public enum ViewUserSettingFeatureStatus: Int {
            /// 按照DISABLED状态处理，不展示开关
            case unknown // = 0
            /// 用户不在服务端FG范围内，功能开关不展示
            case disabled // = 1
            /// 功能打开
            case on // = 2
            /// 功能关闭
            case off // = 3

            public var isOn: Bool {
                switch self {
                case .on: return true
                default: return false
                }
            }

            public var isOff: Bool {
                switch self {
                case .off: return true
                default: return false
                }
            }

            public var isValid: Bool {
                switch self {
                case .on, .off: return true
                default: return false
                }
            }
        }
    }

    public struct InMeetingEmojiSetting: Equatable {
        /// 举手表情皮肤
        public var handsUpEmojiKey = "HandsUp"
    }
}

extension ViewUserSetting: ProtobufDecodable {
    typealias ProtobufType = Videoconference_V1_ViewUserSetting

    init(pb: Videoconference_V1_ViewUserSetting) {
        self.audio.enableVoiceprintRecognition = pb.audio.enableVoiceprintRecognition
        self.meetingGeneral.playEnterExitChimes = pb.meetingGeneral.playEnterExitChimes
        self.meetingGeneral.enableSelfAsActiveSpeaker = pb.meetingGeneral.enableSelfAsActiveSpeaker
        self.meetingGeneral.deviceEverSetRingtone = pb.meetingGeneral.deviceEverSetRingtone
        if pb.meetingGeneral.hasRingtone {
            self.meetingGeneral.ringtone = pb.meetingGeneral.ringtone
        }
        self.meetingGeneral.calendarMeetingStartNotify = pb.meetingGeneral.calendarMeetingStartNotify
        self.meetingAdvanced.subtitle.turnOnSubtitleWhenJoin = pb.meetingAdvanced.subtitle.turnOnSubtitleWhenJoin
        self.meetingAdvanced.interpretation.canOpenInterpretation = pb.meetingAdvanced.interpretation.canOpenInterpretation
        self.meetingAdvanced.recording.groupMeetingAutoRecord = pb.meetingAdvanced.recording.groupMeetingAutoRecord
        self.meetingAdvanced.recording.singleMeetingAutoRecord = pb.meetingAdvanced.recording.singleMeetingAutoRecord
        self.meetingAdvanced.recording.recordCompliancePopup = DisplayBoolOption(displayStatus: DisplayStatus(rawValue: pb.meetingAdvanced.recording.recordCompliancePopup.displayStatus.rawValue) ?? .normal, optionalValue: pb.meetingAdvanced.recording.recordCompliancePopup.optionValue)
        self.meetingAdvanced.recording.recordComplianceVoicePrompt = DisplayBoolOption(displayStatus: DisplayStatus(rawValue: pb.meetingAdvanced.recording.recordComplianceVoicePrompt.displayStatus.rawValue) ?? .normal, optionalValue: pb.meetingAdvanced.recording.recordComplianceVoicePrompt.optionValue)
        self.meetingAdvanced.recording.recordLayoutType = .init(rawValue: pb.meetingAdvanced.recording.recordLayoutType.rawValue) ?? .speakerLayout
        self.meetingAdvanced.recording.hideCamMutedParticipant = pb.meetingAdvanced.recording.hideCamMutedParticipant
        self.meetingAdvanced.recording.smartNoteSwitchDisplay = pb.meetingAdvanced.recording.smartNoteSwitchDisplay
        self.meetingAdvanced.recording.smartNoteOpen = pb.meetingAdvanced.recording.smartNoteOpen
        self.meetingAdvanced.missedCallReminder.reminder = .init(rawValue: pb.meetingAdvanced.missedCallReminder.reminder.rawValue) ?? .unknown
        self.meetingAdvanced.intelligentMeetingSetting.generateMeetingSummaryInMinutes = .init(rawValue: pb.meetingAdvanced.intelligentMeetingSetting.generateMeetingSummaryInMinutes.rawValue) ?? .unknown
        self.meetingAdvanced.intelligentMeetingSetting.generateMeetingSummaryInDocs = .init(rawValue: pb.meetingAdvanced.intelligentMeetingSetting.generateMeetingSummaryInDocs.rawValue) ?? .unknown
        self.meetingAdvanced.intelligentMeetingSetting.chatWithAiInMeeting = .init(rawValue: pb.meetingAdvanced.intelligentMeetingSetting.chatWithAiInMeeting.rawValue) ?? .unknown
        self.emojiSetting.handsUpEmojiKey = pb.emojiSetting.handsUpEmojiKey
    }
}

extension ViewUserSetting: CustomStringConvertible {
    public var description: String {
        String(
            indent: "ViewUserSetting",
            "\(audio)",
            "\(meetingGeneral)",
            "\(meetingAdvanced)",
            "\(emojiSetting)"
        )
    }
}

extension ViewUserSetting.Audio: CustomStringConvertible {
    public var description: String {
        String(
            indent: "Audio",
            "voiceprint=\(enableVoiceprintRecognition.toInt)"
        )
    }
}

extension ViewUserSetting.MeetingGeneral: CustomStringConvertible {
    public var description: String {
        String(
            indent: "General",
            "chime=\(playEnterExitChimes.toInt)",
            "calendarNotify=\(calendarMeetingStartNotify.toInt)"
        )
    }
}

extension ViewUserSetting.MeetingAdvanced: CustomStringConvertible {
    public var description: String {
        String(
            indent: "Advanced",
            "subtitleOnJoin=\(subtitle.turnOnSubtitleWhenJoin.toInt)",
            "interpret=\(interpretation.canOpenInterpretation.toInt)",
            "autoRec1=\(recording.singleMeetingAutoRecord.toInt)",
            "autoRecM=\(recording.groupMeetingAutoRecord.toInt)",
            "recordCompliancePopupStatus = \(recording.recordCompliancePopup.displayStatus)",
            "recordCompliancePopupValue = \(recording.recordCompliancePopup.optionalValue)",
            "recordComplianceVoicePromptStatus = \(recording.recordComplianceVoicePrompt.displayStatus)",
            "recordComplianceVoicePromptValue = \(recording.recordComplianceVoicePrompt.optionalValue)",
            "recordLayoutType = \(recording.recordLayoutType)",
            "hideCamMutedParticipant = \(recording.hideCamMutedParticipant)",
            "generateMeetingSummaryInMinutes = \(intelligentMeetingSetting.generateMeetingSummaryInMinutes)",
            "generateMeetingSummaryInDocs = \(intelligentMeetingSetting.generateMeetingSummaryInDocs)",
            "chatWithAiInMeeting = \(intelligentMeetingSetting.chatWithAiInMeeting)"
        )
    }
}

extension ViewUserSetting.InMeetingEmojiSetting: CustomStringConvertible {
    public var description: String {
        String(
            indent: "InMeetingEmojiSetting",
            "emojiSetting=\(handsUpEmojiKey)"
        )
    }
}
