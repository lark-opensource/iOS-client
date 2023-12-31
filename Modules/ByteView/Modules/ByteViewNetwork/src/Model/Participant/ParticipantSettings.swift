//
//  ParticipantSettings.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/18.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 参会者的设置
public struct ParticipantSettings: Equatable {
    /// 麦克风开/关
    public var isMicrophoneMuted: Bool

    /// 摄像头开/关
    public var isCameraMuted: Bool

    /// 麦克风状态
    public var microphoneStatus: EquipmentStatus

    /// 摄像头状态
    public var cameraStatus: EquipmentStatus

    /// 其他人进出/离开会议时是否有提示音
    public var playEnterExitChimes: Bool?

    /// 是否正在跟随follow分享
    public var followingStatus: Bool

    /// 应为is_subtitle_on: 是/否打开字幕
    public var isTranslationOn: Bool?

    /// 字幕显示语言（设备维度）
    public var subtitleLanguage: String

    /// 参会者口说语言（设备维度）
    public var spokenLanguage: String

    /// 用户会中昵称
    public var nickname: String

    /// 是/否开启字幕音频录制（作为训练集/测试集提升字幕效果）
    public var enableSubtitleRecord: Bool

    /// 参会者真实使用的口说语言（设备维度）
    public var appliedSpokenLanguage: String

    /// 转录显示语言（设备维度）
    public var transcriptLanguage: String

    public var handsStatus: ParticipantHandsStatus

    /// rtc上行流模式
    public var rtcMode: RtcMode

    public var interpreterSetting: InterpreterSetting?

    public var inMeetingName: String

    public var audioMode: AudioMode

    public var targetToJoinTogether: ByteviewUser?

    public var roomPeopleCnt: Int32?

    public var conditionEmojiInfo: ConditionEmojiInfo?

    public var cameraHandsStatus: ParticipantHandsStatus

    public var mobileCallingStatus: MobileCallingStatus
    public var attendeeSettings: WebinarAttendeeSettings?
    public var refuseReply: String?

    // lark 是否有绑定的 room
    public var isBindScreenCastRoom: Bool

    public var localRecordSettings: LocalRecordSettings?

    public enum EquipmentStatus: Int, Hashable {
        case unknown // = 0

        /// 没有设备
        case notExist // = 1

        /// 有设备但没有权限
        case noPermission // = 2

        /// 有设备有权限但是设备不可用
        case unavailable // = 3

        /// 设备正常work
        case normal // = 4
    }

    public enum RtcMode: Int, Hashable {
        case unknown // = 0
        case normal // = 1
        case audience // = 2
    }

    public enum AudioMode: Int, Hashable {
        case unknown // = 0
        /// 本地音频
        case internet // = 1
        /// 电话音频
        case pstn // = 2
        /// 无音频
        case noConnect // = 3
    }

    enum AudioNoConnectType: Int, Hashable {
        case unknown // = 0
        /// 展示无音频麦克风图标
        case `default`
        /// 不展示麦克风图标
        case none
    }

    public struct ConditionEmojiInfo: Equatable {
        /// 是否暂时离开
        public var isStepUp: Bool?

        /// 是否举手
        public var isHandsUp: Bool?

        /// 举手时间
        public var handsUpTime: Int64?

        /// 举手表情皮肤
        public var handsUpEmojiKey: String

        public init(isStepUp: Bool? = nil, isHandsUp: Bool? = nil, handsUpTime: Int64? = nil, handsUpEmojiKey: String = "HandsUp") {
            self.isStepUp = isStepUp
            self.isHandsUp = isHandsUp
            self.handsUpTime = handsUpTime
            self.handsUpEmojiKey = handsUpEmojiKey
        }
    }

    public enum MobileCallingStatus: Int, Hashable {
        case unknown // = 0
        ///
        case idle // = 1
        /// 未接/结束通话
        case busy // = 2
        /// 正在系统通话
    }

    public init(isMicrophoneMuted: Bool,
                isCameraMuted: Bool,
                microphoneStatus: EquipmentStatus,
                cameraStatus: EquipmentStatus,
                playEnterExitChimes: Bool?,
                followingStatus: Bool,
                isTranslationOn: Bool?,
                subtitleLanguage: String,
                spokenLanguage: String,
                nickname: String,
                enableSubtitleRecord: Bool,
                appliedSpokenLanguage: String,
                handsStatus: ParticipantHandsStatus,
                rtcMode: RtcMode,
                interpreterSetting: InterpreterSetting?,
                inMeetingName: String,
                audioMode: AudioMode,
                targetToJoinTogether: ByteviewUser?,
                roomPeopleCnt: Int32?,
                conditionEmojiInfo: ConditionEmojiInfo?,
                mobileCallingStatus: MobileCallingStatus,
                cameraHandsStatus: ParticipantHandsStatus,
                attendeeSettings: WebinarAttendeeSettings?,
                isBindScreenCastRoom: Bool,
                localRecordSettings: LocalRecordSettings?,
                refuseReply: String?,
                transcriptLanguage: String
                ) {
        self.isMicrophoneMuted = isMicrophoneMuted
        self.isCameraMuted = isCameraMuted
        self.microphoneStatus = microphoneStatus
        self.cameraStatus = cameraStatus
        self.playEnterExitChimes = playEnterExitChimes
        self.followingStatus = followingStatus
        self.isTranslationOn = isTranslationOn
        self.subtitleLanguage = subtitleLanguage
        self.spokenLanguage = spokenLanguage
        self.nickname = nickname
        self.enableSubtitleRecord = enableSubtitleRecord
        self.appliedSpokenLanguage = appliedSpokenLanguage
        self.handsStatus = handsStatus
        self.rtcMode = rtcMode
        self.interpreterSetting = interpreterSetting
        self.inMeetingName = inMeetingName
        self.audioMode = audioMode
        self.targetToJoinTogether = targetToJoinTogether
        self.roomPeopleCnt = roomPeopleCnt
        self.conditionEmojiInfo = conditionEmojiInfo
        self.mobileCallingStatus = mobileCallingStatus
        self.cameraHandsStatus = cameraHandsStatus
        self.isBindScreenCastRoom = isBindScreenCastRoom
        self.attendeeSettings = attendeeSettings
        self.localRecordSettings = localRecordSettings
        self.refuseReply = refuseReply
        self.transcriptLanguage = transcriptLanguage
    }

    public init() {
        self.init(isMicrophoneMuted: true, isCameraMuted: true, microphoneStatus: .unknown, cameraStatus: .unknown,
                  playEnterExitChimes: nil, followingStatus: false, isTranslationOn: nil,
                  subtitleLanguage: "", spokenLanguage: "", nickname: "",
                  enableSubtitleRecord: false, appliedSpokenLanguage: "", handsStatus: .unknown,
                  rtcMode: .unknown, interpreterSetting: nil, inMeetingName: "",
                  audioMode: .unknown,
                  targetToJoinTogether: nil, roomPeopleCnt: nil,
                  conditionEmojiInfo: nil,
                  mobileCallingStatus: .unknown, cameraHandsStatus: .unknown,
                  attendeeSettings: nil, isBindScreenCastRoom: false, localRecordSettings: nil,
                  refuseReply: nil, transcriptLanguage: "")
    }
}

public extension ParticipantSettings.EquipmentStatus {
    var isUnavailable: Bool {
        self != .normal && self != .unknown
    }
}

public extension ParticipantSettings {
    /// 参会人的麦克风设备关闭或不可用
    var isMicrophoneMutedOrUnavailable: Bool {
        isMicrophoneMuted || microphoneStatus.isUnavailable
    }

    /// 参会人的摄像头设备关闭或不可用
    var isCameraMutedOrUnavailable: Bool {
        isCameraMuted || cameraStatus.isUnavailable
    }
}

extension ParticipantSettings: CustomStringConvertible {

    public var description: String {
        String(
            indent: "ParticipantSettings",
            "mic=\(isMicrophoneMuted.toInt)",
            "cam=\(isCameraMuted.toInt)",
            "micSt=\(microphoneStatus)",
            "camSt=\(cameraStatus)",
            "follow=\(followingStatus.toInt)",
            "trans=\(isTranslationOn?.toInt)",
            "rtcMode=\(rtcMode)",
            "audioMode=\(audioMode)",
            "targetToJoinTogether=\(targetToJoinTogether)",
            "inMeetingName=\(inMeetingName.hashValue),count=\(inMeetingName.count)",
            "handsStatus=\(handsStatus)",
            "interpret=\(interpreterSetting)",
            "roomPeopleCnt=\(roomPeopleCnt)",
            "conditionEmojiInfo=\(conditionEmojiInfo)",
            "mobileCallingStatus=\(mobileCallingStatus)",
            "cameraHandsStatus=\(cameraHandsStatus)",
            "isBindScreenCastRoom=\(isBindScreenCastRoom)",
            "attendeeSettings=\(attendeeSettings)",
            "localRecordSettings=\(localRecordSettings)",
            "refuseReply=\(refuseReply?.count)",
            "playChimes=\(playEnterExitChimes)"
        )
    }
}
