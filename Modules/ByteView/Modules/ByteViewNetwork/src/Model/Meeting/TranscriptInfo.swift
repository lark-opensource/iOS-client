//
//  TranscriptInfo.swift
//  ByteViewNetwork
//
//  Created by yangyao on 2023/6/19.
//

import Foundation

/// Videoconference_V1_TranscriptInfo
public struct TranscriptInfo: Equatable {
    public init(type: TranscriptMeetingDataType,
                requester: ByteviewUser,
                policyURL: String,
                transcriptStopV2: MsgInfo?,
                transcriptStatus: TranscriptStatus) {
        self.type = type
        self.requester = requester
        self.policyURL = policyURL
        self.transcriptStopV2 = transcriptStopV2
        self.transcriptStatus = transcriptStatus
    }

    public var type: TranscriptMeetingDataType

    /// 请求转录参会人
    public var requester: ByteviewUser

    /// 隐私政策
    public var policyURL: String

    /// 转录停止i18n v2
    public var transcriptStopV2: MsgInfo?

    public var transcriptStatus: TranscriptStatus

    public enum TranscriptMeetingDataType: Int, Hashable {
        case unknown // = 0

        /// 转录状态变更 开始录制/停止录制
        case statusChange // = 1

        /// 参会人请求
        case participantRequest // = 2

        /// 主持人回复
        case hostResponse // = 3
    }

    public enum TranscriptStatus: Int, Hashable {
        /// 未知
        case unknown // = 0

        /// 未转录
        case none // = 1

        /// 发起中
        case initializing // = 2

        /// 转录中
        case ing // = 3

        /// 已暂停
        case pause // = 4
    }
}

extension TranscriptInfo {
    public var isTranscribing: Bool {
        transcriptStatus == .ing
    }
}
