//
//  MinutesClipList.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2022/5/10.
//

import Foundation

public struct MinutesClipList: Codable, Equatable {

    public var total: Int?
    public var list: [MinutesClipListItem]

    private enum CodingKeys: String, CodingKey {
        case total = "total"
        case list = "list"
    }
}

public struct MinutesClipCreator: Codable, Equatable {
    public var name: String
    public var avatarUrl: String

    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case avatarUrl = "avatar_url"
    }
}

public struct MinutesClipListItem: Codable, Equatable {

    public let url: String
    public let objectToken: String
    public let topic: String
    public let videoCover: String
    public var duration: Int
    public let visitorNumber: Int
    public let creator: MinutesClipCreator
    public let mediaType: MediaType
    public let permissionStatus: Int
    public let generateStatus: Int

    private enum CodingKeys: String, CodingKey {
        case url = "url"
        case objectToken = "object_token"
        case topic = "topic"
        case videoCover = "video_cover"
        case duration = "duration"
        case visitorNumber = "visitor_num"
        case creator = "creator"
        case mediaType = "media_type"
        case permissionStatus = "permission_status"
        case generateStatus = "generate_status"
    }

    public init(url: String,
                objectToken: String,
                topic: String,
                videoCover: String,
                duration: Int,
                visitorNumber: Int,
                creator: MinutesClipCreator,
                mediaType: MediaType,
                permissionStatus: Int,
                generateStatus: Int) {
        self.url = url
        self.objectToken = objectToken
        self.topic = topic
        self.videoCover = videoCover
        self.duration = duration
        self.visitorNumber = visitorNumber
        self.creator = creator
        self.mediaType = mediaType
        self.permissionStatus = permissionStatus
        self.generateStatus = generateStatus
    }
}
