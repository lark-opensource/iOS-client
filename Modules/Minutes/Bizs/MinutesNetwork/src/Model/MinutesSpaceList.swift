//
//  MinutesSpaceList.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/7/9.
//

import Foundation

public struct MinutesSpaceList: Codable, Equatable {

    public var total: Int?
    public var size: Int
    public var hasMore: Bool
    public let timestamp: String
    public var list: [MinutesSpaceListItem]
    public var hasDeleteTag: Bool

    private enum CodingKeys: String, CodingKey {
        case total = "total"
        case size = "size"
        case hasMore = "has_more"
        case timestamp = "timestamp"
        case list = "list"
        case hasDeleteTag = "has_delete_tag"
    }
}

public struct MinutesSpaceListItem: Codable, Equatable {

    public let url: String
    public let objectToken: String
    public var topic: String
    public let videoCover: String
    public var time: Int
    public var createTime: Int?
    public var shareTime: Int?
    public var openTime: Int?
    public var expireTime: Int?
    public var startTime: Int?
    public var stopTime: Int?
    public var duration: Int
    public var objectStatus: ObjectStatus
    public var reviewStatus: ReviewStatus
    public var objectType: ObjectType
    public var showExternalTag: Bool
    public let mediaType: MediaType
    public let isRecordingDevice: Bool?
    public var ownerName: String?
    public var ownerId: Int?
    public var isOwner: Bool?
    public var isEncryptKeyDeleted: Bool?
    public var schedulerType: MinutesSchedulerType
    public var schedulerDeltaExecuteTime: Int?
    public var schedulerExecuteTimestamp: Int?
    public var isRisk: Bool?
    public let displayTag: DisplayTag?

    private enum CodingKeys: String, CodingKey {
        case url = "url"
        case objectToken = "object_token"
        case topic = "topic"
        case videoCover = "video_cover"
        case time = "time"
        case createTime = "create_time"
        case shareTime = "share_time"
        case openTime = "open_time"
        case expireTime = "expire_time"
        case startTime = "start_time"
        case stopTime = "stopTime"
        case duration = "duration"
        case objectType = "object_type"
        case objectStatus = "status"
        case reviewStatus = "review_status"
        case showExternalTag = "show_external_tag"
        case mediaType = "media_type"
        case isRecordingDevice = "is_recording_device"
        case ownerName = "owner_name"
        case ownerId = "owner_id"
        case isOwner = "is_owner"
        case isEncryptKeyDeleted = "is_encrypt_key_deleted"
        case schedulerType = "scheduler_type"
        case schedulerDeltaExecuteTime = "scheduler_execute_delta_time"
        case schedulerExecuteTimestamp = "scheduler_execute_timestamp"
        case isRisk = "is_risk"
        case displayTag = "display_tag"
    }

    public init(url: String,
                objectToken: String,
                topic: String,
                videoCover: String,
                time: Int,
                createTime: Int,
                shareTime: Int,
                openTime: Int,
                expireTime: Int,
                duration: Int,
                objectStatus: ObjectStatus,
                objectType: ObjectType,
                reviewStatus: ReviewStatus,
                showExternalTag: Bool,
                mediaType: MediaType,
                isRecordingDevice: Bool?,
                schedulerType: MinutesSchedulerType,
                schedulerDeltaExecuteTime: Int,
                displayTag: DisplayTag?) {
        self.url = url
        self.objectToken = objectToken
        self.topic = topic
        self.videoCover = videoCover
        self.time = time
        self.createTime = createTime
        self.shareTime = shareTime
        self.openTime = openTime
        self.expireTime = expireTime
        self.duration = duration
        self.objectStatus = objectStatus
        self.objectType = objectType
        self.reviewStatus = reviewStatus
        self.showExternalTag = showExternalTag
        self.mediaType = mediaType
        self.isRecordingDevice = isRecordingDevice
        self.schedulerType = schedulerType
        self.schedulerDeltaExecuteTime = -1
        self.displayTag = displayTag
    }
}
