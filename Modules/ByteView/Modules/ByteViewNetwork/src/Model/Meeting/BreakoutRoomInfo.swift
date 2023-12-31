//
//  BreakoutRoomInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 分组会议信息
/// - Videoconference_V1_BreakoutRoomInfo
public struct BreakoutRoomInfo: Equatable {
    public init(breakoutRoomId: String, topic: String, startTime: Int64, channelId: String, status: Status, recordingStatus: RecordMeetingData.RecordingStatus, countDownFromStartTime: Int64, finishFromStartTime: Int64, sortId: Int64, closeReason: CloseReason) {
        self.breakoutRoomId = breakoutRoomId
        self.topic = topic
        self.startTime = startTime
        self.channelId = channelId
        self.status = status
        self.recordingStatus = recordingStatus
        self.countDownFromStartTime = countDownFromStartTime
        self.finishFromStartTime = finishFromStartTime
        self.sortId = sortId
        self.closeReason = closeReason
    }

    public var breakoutRoomId: String

    public var topic: String

    public var startTime: Int64

    public var channelId: String

    public var status: Status

    public var recordingStatus: RecordMeetingData.RecordingStatus

    /// 倒计时结束时刻，会议持续的时间，毫秒级
    public var countDownFromStartTime: Int64

    /// 分组讨论自动结束时间距离会议开始时间的时间差，毫秒级
    public var finishFromStartTime: Int64

    public var sortId: Int64

    public var closeReason: CloseReason

    public enum Status: Int, Hashable {
        case unknown // = 0
        case onTheCall // = 1
        case countDown // = 2
        case idle // = 3
    }

    public enum CloseReason: Int, Hashable {
        case unknown // = 0
        case earlyClose // = 1
        case autoFinish // = 2
    }
}

extension BreakoutRoomInfo: CustomStringConvertible {

    public var description: String {
        String(
            indent: "BreakoutRoomInfo",
            "breakoutRoomId: \(breakoutRoomId)",
            "startTime: \(startTime)",
            "channelId: \(channelId)",
            "status: \(status)",
            "countDownFromStartTime: \(countDownFromStartTime)",
            "sortId: \(sortId)",
            "closeReason: \(closeReason)"
        )
    }
}
