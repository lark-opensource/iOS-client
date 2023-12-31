//
//  MinutesFeedListStatus.swift
//  MinutesFoundation
//
//  Created by Todd Cheng on 2021/3/2.
//

import Foundation

public struct MinutesFeedListStatus: Codable, Equatable {

    public let status: [MinutesFeedListItemStatus]

    private enum CodingKeys: String, CodingKey {
        case status = "status"
    }
}

public struct MinutesFeedListItemStatus: Codable, Equatable {

    public let objectToken: String
    public let objectStatus: ObjectStatus
    public let topic: String
    public let duration: Int
    public let transcriptProgress: TranscriptProgress
    public let expireTime: Int
    public let inTrash: Bool
    public var schedulerType: MinutesSchedulerType
    public var schedulerDeltaExecuteTime: Int?

    private enum CodingKeys: String, CodingKey {
        case objectToken = "object_token"
        case objectStatus = "object_status"
        case topic = "topic"
        case duration = "duration"
        case transcriptProgress = "transcript_progress"
        case expireTime = "expire_time"
        case inTrash = "in_trash"
        case schedulerType = "scheduler_type"
        case schedulerDeltaExecuteTime = "scheduler_execute_delta_time"
    }
}

public struct TranscriptProgress: Codable, Equatable {
    public let current: String
    public let rate: String

    private enum CodingKeys: String, CodingKey {
        case current = "current"
        case rate = "rate"
    }
}
