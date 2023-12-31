//
//  VideoChatInMeetingInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Rust从后端拉取的会中全量信息
/// - Videoconference_V1_VideoChatInMeetingInfo
public struct VideoChatInMeetingInfo: Equatable {
    public init(id: String,
                vcType: MeetingType,
                isRecording: Bool,
                hasRecorded: Bool,
                shouldPullSuggested: Bool,
                meetingURL: String,
                isSubtitleOn: Bool?,
                version: String,
                meetingSettings: VideoChatSettings,
                followInfo: FollowInfo?,
                shareScreen: ScreenSharedData?,
                whiteboardInfo: WhiteboardInfo?,
                videoChatDisplayOrderInfo: VideoChatDisplayOrderInfo?,
                liveInfo: LiveInfo?,
                recordingData: RecordMeetingData?,
                transcriptInfo: TranscriptInfo?,
                breakoutRoomInfos: [BreakoutRoomInfo],
                minutesStatusData: MinutesStatusData?,
                focusVideoData: FocusVideoData?,
                countDownInfo: CountDownInfo?,
                interpretationSetting: InterpretationSetting?,
                notesInfo: NotesInfo?,
                voteList: [VoteStatisticInfo],
                stageInfo: WebinarStageInfo?
    ) {
        self.id = id
        self.vcType = vcType
        self.isRecording = isRecording
        self.hasRecorded = hasRecorded
        self.shouldPullSuggested = shouldPullSuggested
        self.meetingURL = meetingURL
        self.isSubtitleOn = isSubtitleOn
        self.version = version
        self.meetingSettings = meetingSettings
        self.followInfo = followInfo
        self.shareScreen = shareScreen
        self.whiteboardInfo = whiteboardInfo
        self.videoChatDisplayOrderInfo = videoChatDisplayOrderInfo
        self.liveInfo = liveInfo
        self.recordingData = recordingData
        self.transcriptInfo = transcriptInfo
        self.breakoutRoomInfos = breakoutRoomInfos
        self.minutesStatusData = minutesStatusData
        self.focusVideoData = focusVideoData
        self.countDownInfo = countDownInfo
        self.interpretationSetting = interpretationSetting
        self.notesInfo = notesInfo
        self.voteList = voteList
        self.stageInfo = stageInfo
    }

    public var id: String

    /// 会议升级标志
    public var vcType: MeetingType

    /// 会议是否正在录制
    public var isRecording: Bool

    /// 会议是否已经有过录制
    public var hasRecorded: Bool

    /// 是否要拉推荐列表
    public var shouldPullSuggested: Bool

    /// 会议链接
    public var meetingURL: String

    /// 会议是否开启字幕
    public var isSubtitleOn: Bool?

    public var version: String

    public var meetingSettings: VideoChatSettings

    public var followInfo: FollowInfo?

    public var shareScreen: ScreenSharedData?

    public let whiteboardInfo: WhiteboardInfo?

    public var videoChatDisplayOrderInfo: VideoChatDisplayOrderInfo?

    public var liveInfo: LiveInfo?

    /// 录制相关
    public var recordingData: RecordMeetingData?

    /// 转录相关
    public var transcriptInfo: TranscriptInfo?

    /// reserved 26; // Magic Share临时身份信息
    public var breakoutRoomInfos: [BreakoutRoomInfo]

    public var minutesStatusData: MinutesStatusData?

    /// 焦点视频相关信息
    public var focusVideoData: FocusVideoData?

    /// 会中倒计时信息
    public var countDownInfo: CountDownInfo?

    /// 同声传译配置数据
    public var interpretationSetting: InterpretationSetting?

    /// 会议纪要
    public var notesInfo: NotesInfo?

    /// 会中投票
    public var voteList: [VoteStatisticInfo]

    /// webinar 舞台数据
    public var stageInfo: WebinarStageInfo?
}

extension VideoChatInMeetingInfo {
    public var isTranscribing: Bool {
        transcriptInfo?.transcriptStatus == .ing
    }
}

extension VideoChatInMeetingInfo: CustomStringConvertible {

    public var description: String {
        String(
            indent: "VideoChatInMeetingInfo",
            "id: \(id)",
            "shareScreenUser: \(shareScreen?.participant)",
            "meetingSettings: \(meetingSettings)",
            "followInfo: \(followInfo)",
            "whiteboardInfo: \(whiteboardInfo)",
            "shareScreenData: \(shareScreen)",
            "vcType: \(vcType)",
            "isRecording: \(isRecording)",
            "hasRecorded: \(hasRecorded)",
            "recordingData: \(recordingData)",
            "liveInfo: \(liveInfo)",
            "shouldPullSuggested: \(shouldPullSuggested)",
            "meetingURL: \(meetingURL.hash)",
            "isSubtitleOn: \(isSubtitleOn)",
            "breakoutRoomInfos: \(breakoutRoomInfos)",
            "minutesStatusData: \(minutesStatusData)",
            "hasFocusVideo: \(focusVideoData != nil)",
            "countDownInfo: \(countDownInfo)",
            "interpretationSetting: \(interpretationSetting)",
            "voteList: \(voteList)",
            "notesInfo: \(notesInfo)",
            "videoChatDisplayOrderInfo: \(videoChatDisplayOrderInfo)",
            "stageInfo: \(stageInfo?.actionV2)-\(stageInfo?.guests.count)"
        )
    }
}
