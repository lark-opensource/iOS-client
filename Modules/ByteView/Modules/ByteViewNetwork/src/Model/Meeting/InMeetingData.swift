//
//  InMeetingData.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 会议中的信息，通过VideoChatExtraInfo推送
/// - Videoconference_V1_InMeetingData
public struct InMeetingData: Equatable {

    public var seqID: Int64

    public var type: InMeetingDataType

    public var meetingID: String

    public var settingsChangedData: SettingsChangedData?

    public var hostTransferData: HostTransferredData?

    public var muteAllData: AllMicrophoneMutedData?

    public var recordingData: RecordMeetingData?

    public var transcriptInfo: TranscriptInfo?

    public var subtitleStatusData: SubtitleStatusData?

    public var liveData: LiveMeetingData?

    public var meetingOwner: ByteviewUser?

    public var minutesStatusData: MinutesStatusData?

    public var focusVideoData: FocusVideoData?

    public var videoChatDisplayOrderInfo: VideoChatDisplayOrderInfo?

    public var unsafeLeaveParticipant: Participant?

    public var participantsChangedData: ParticipantsChangedData?

    /// 会中倒计时数据
    public var countDownInfo: CountDownInfo?

    /// 观众人数, type=WEBINAR_ATTENDEE_NUM_CHANGED时关注
    public var attendeeNum: Int64?

    public var stageInfo: WebinarStageInfo?

    ///会中投票
    public var voteStatistic: VoteStatisticInfo?

    /// 会议纪要
    public var notesInfo: NotesInfo?
    public var notesPermission: NotesPermission?
    /// 智能会议设置
    public var intelligentMeetingSetting: IntelligentMeetingSetting?

    public enum InMeetingDataType: Int, Hashable {
        case unknown = 0
        case settingsChanged = 1
        case participantsChanged = 2
        case hostTransferred = 3
        case allMicrophoneMuted = 4
        case unmuteCameraConfirmed = 6
        /// 后端推送通知会议升级 目前只要是多人会议就会附带这个类型的InMeetingData
        ///  rust会在升级为meet后，丢弃该数据
        case upgradeMeeting = 7

        case unmuteMicrophoneConfirmed = 10

        /// 视频会议录制
        case recordMeeting = 11
        case requestFollowToken = 12
        case grantFollowToken = 13

        /// extra info
        case subtitleStatusConfirmed = 14

        /// 视频会议直播
        case liveMeeting = 16

        /// 面试速记
        case minutesStatus = 25

        /// 焦点视频信息更新
        case focusVideoChanged = 26

        /// 倒计时更新
        case inMeetingCountdown = 27

        /// 网络研讨会观众数量
        case webinarAttendeeNumChanged = 50
        /// 网络研讨会观众列表更新 嘉宾专用
        case webinarAttendeeListChanged = 51
        /// 观众的视图列表变化 观众专用
        case webinarAttendeeViewListChanged = 52

        ///投票
        case meetingVote = 30

        case videoChatOrderInfo = 31

        /// 会议纪要
        case notesInfo = 32
        case notesPermission = 34

        /// 智能会议权限
        case intelligentMeetingSetting = 35

        /// 转录
        case transcript = 60

        /// TYPE USED FOR LOCAL ONLY
        case hostMuteMic = 101
        case hostMuteCamera = 102

        /// 主持人修改了参会人的会中名称
        case hostChangePartiName = 105

        /// 不安全主持人设备被移出会议，主持人自动转移
        case unsafeLeaveParticipant = 106

        /// 主持人放下了自己的状态表情-举手
        case hostConditionEmojiHandsDown = 107
    }

    public struct SettingsChangedData: Equatable {
        public init(meetingSettings: VideoChatSettings) {
            self.meetingSettings = meetingSettings
        }

        public var meetingSettings: VideoChatSettings
    }

    public struct HostTransferredData: Equatable {
        public init(hostID: String, hostType: ParticipantType, hostDeviceID: String) {
            self.host = ByteviewUser(id: hostID, type: hostType, deviceId: hostDeviceID)
        }

        /// 变更后的主持人, 3.2版本后使用host_device_id
        public var host: ByteviewUser
    }

    public struct AllMicrophoneMutedData: Equatable {
        public init(isMuted: Bool, operationUser: ByteviewUser, breakoutRoomID: String) {
            self.isMuted = isMuted
            self.operationUser = operationUser
            self.breakoutRoomID = breakoutRoomID
        }

        /// 全员禁麦开/关
        public var isMuted: Bool

        /// 操作人
        public var operationUser: ByteviewUser

        public var breakoutRoomID: String
    }

    public struct LiveMeetingData: Equatable {
        public init(type: LiveMeetingDataType, liveInfo: LiveInfo, requester: ByteviewUser) {
            self.type = type
            self.liveInfo = liveInfo
            self.requester = requester
        }

        /// type为2和3 推extra_info
        public var type: LiveMeetingDataType
        /// 直播详情
        public var liveInfo: LiveInfo
        /// 请求直播参会人
        public var requester: ByteviewUser

        public enum LiveMeetingDataType: Int, Hashable {
            case unknown // = 0
            /// 状态变更 开始直播/停止直播
            case liveInfoChange // = 1
            /// 参会人请求
            case participantRequest // = 2
            /// 主持人回复
            case hostResponse // = 3
        }
    }

    public struct ParticipantsChangedData: Equatable {
        public init(participants: [Participant], operationSource: OperationSource) {
            self.participants = participants
            self.operationSource = operationSource
        }

        /// 变更的参会人信息
        public var participants: [Participant] = []

        /// 参会人信息变更的原因
        public var operationSource: OperationSource

        public enum OperationSource: Int, Hashable {
            case unknownSource // = 0

            /// 参会人自己关闭了麦克风
            case participantMuteMic // = 1

            /// 参会人自己关闭了摄像头
            case participantMuteCamera // = 2

            /// 主持人关闭了参会人的麦克风
            case hostMuteMic // = 3

            /// 主持人关闭了参会人的摄像头
            case hostMuteCamera // = 4

            /// 主持人设置全员静音
            case hostMuteAllMic // = 5

            /// 参会人修改自己的会中名称
            case partiChangeOwnName // = 6

            /// 主持人修改了参会人的会中名称
            case hostChangePartiName // = 7

            /// 主持人放下了自己的状态表情-举手
            case hostConditionEmojiHandsDown // = 8

            /// 主持人关闭参会人本地录制
            case hostStopLocalRecord // = 9
        }
    }
}

extension InMeetingData: CustomStringConvertible {

    public var description: String {
        String(
            indent: "InMeetingData",
            "type: \(type)",
            "meetingId: \(meetingID)",
            "settingsChangedData: \(settingsChangedData?.meetingSettings)",
            "hostTransferData: \(hostTransferData)",
            "muteAllData: \(muteAllData)",
            "recordingData: \(recordingData)",
            "subtitleStatusData: \(subtitleStatusData)",
            "liveData: \(liveData)",
            "seqID: \(seqID)",
            "meetingOwner: \(meetingOwner)",
            "minutesStatusData: \(minutesStatusData)",
            "hasFocusVideo: \(focusVideoData != nil)",
            "CountDownInfo: \(countDownInfo)",
            "attendeeNum: \(attendeeNum)",
            "unsafeLeaveParticipant: \(unsafeLeaveParticipant)",
            "participantsChangedData: \(participantsChangedData)",
            "voteStatistic: \(voteStatistic)",
            "displayOrderInfo: \(videoChatDisplayOrderInfo)",
            "notesInfo: \(notesInfo)",
            "notesPermission: \(notesPermission)",
            "intelligentMeetingSetting: \(intelligentMeetingSetting)"
        )
    }
}
