//
//  RecordMeetingData.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/24.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_InMeetingData.RecordMeetingData
public struct RecordMeetingData: Equatable {
    public init(type: RecordMeetingDataType,
                isRecording: Bool,
                requester: ByteviewUser,
                policyURL: String,
                needUploadTimezone: Bool,
                recordingStopV2: MsgInfo?,
                recordingStatus: RecordingStatus) {
        self.type = type
        self.isRecording = isRecording
        self.requester = requester
        self.policyURL = policyURL
        self.needUploadTimezone = needUploadTimezone
        self.recordingStopV2 = recordingStopV2
        self.recordingStatus = recordingStatus
    }

    public var type: RecordMeetingDataType

    /// 录制状态（ Type + 录制状态 确定请求类型）
    public var isRecording: Bool

    /// 请求录制参会人
    public var requester: ByteviewUser

    /// 隐私政策
    public var policyURL: String

    /// 是否需要上报客户端时区
    public var needUploadTimezone: Bool

    /// 录制停止i18n v2
    public var recordingStopV2: MsgInfo?

    public var recordingStatus: RecordingStatus

    public enum RecordMeetingDataType: Int, Hashable {

        case unknown // = 0

        /// 录制状态变更 开始录制/停止录制
        case recordingStatusChange // = 1

        /// 参会人请求
        case participantRequest // = 2

        /// 主持人回复
        case hostResponse // = 3

        /// 请求本地录制(1v1场景)
        case requestLocal = 5

        /// 录制会中信息
        case recordingInfo = 10
    }

    public enum RecordingStatus: Int, Hashable {

        case unknown // = 0

        /// 会议未录制
        case none // = 1

        /// 会议仅存在云录制
        case meetingRecording // = 2

        /// 会议仅存在本地录制
        case localRecording // = 3

        /// 会议既存在云录制，又存在本地录制
        case multiRecording // = 4

        /// 云录制启动中（仅存在云录制）
        case meetingRecordInitializing // = 5
    }
}

extension RecordMeetingData: CustomStringConvertible {
    public var description: String {
        String(
            indent: "RecordMeetingData",
            "type: \(type)",
            "isRecording: \(isRecording)",
            "requester: \(requester)",
            "stop: \(recordingStopV2)",
            "recordingStatus: \(recordingStatus)"
        )
    }
}
