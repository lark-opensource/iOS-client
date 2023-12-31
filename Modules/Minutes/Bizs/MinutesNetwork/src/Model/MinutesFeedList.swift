//
//  MinutesFeedList.swift
//  MinutesFoundation
//
//  Created by Todd Cheng on 2021/2/25.
//

import Foundation

public struct MinutesFeedList: Codable, Equatable {

    public var hasMore: Bool
    public let timestamp: String
    public var list: [MinutesFeedListItem]

    private enum CodingKeys: String, CodingKey {
        case hasMore = "has_more"
        case timestamp = "timestamp"
        case list = "list"
    }
}

public struct MinutesFeedListItem: Codable, Equatable {

    public let url: String
    public let objectToken: String
    public var topic: String
    public let videoCover: String
    public let startTime: Int?
    public let shareTime: Int?
    public var duration: Int
    public var objectStatus: ObjectStatus
    public var reviewStatus: ReviewStatus
    public var objectType: ObjectType
    public let showExternalTag: Bool
    public let mediaType: MediaType
    public let isRecordingDevice: Bool?

    private enum CodingKeys: String, CodingKey {
        case url = "url"
        case objectToken = "object_token"
        case topic = "topic"
        case videoCover = "video_cover"
        case startTime = "start_time"
        case shareTime = "share_time"
        case duration = "duration"
        case objectType = "object_type"
        case objectStatus = "status"
        case reviewStatus = "review_status"
        case showExternalTag = "show_external_tag"
        case mediaType = "media_type"
        case isRecordingDevice = "is_recording_device"
    }

    public init(url: String,
                objectToken: String,
                topic: String,
                videoCover: String,
                startTime: Int,
                shareTime: Int,
                duration: Int,
                objectStatus: ObjectStatus,
                objectType: ObjectType,
                reviewStatus: ReviewStatus,
                showExternalTag: Bool,
                mediaType: MediaType,
                isRecordingDevice: Bool?) {
        self.url = url
        self.objectToken = objectToken
        self.topic = topic
        self.videoCover = videoCover
        self.startTime = startTime
        self.shareTime = shareTime
        self.duration = duration
        self.objectStatus = objectStatus
        self.objectType = objectType
        self.reviewStatus = reviewStatus
        self.showExternalTag = showExternalTag
        self.mediaType = mediaType
        self.isRecordingDevice = isRecordingDevice
    }
}
