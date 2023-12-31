//
//  MeetingChannels.swift
//  MinutesFoundation
//
//  Created by ByteDance on 2023/9/7.
//

import Foundation

public struct MeetingChannels: Codable {
    public let channels: [MeetingChannelInfo]

    private enum CodingKeys: String, CodingKey {
        case channels = "group_meeting_urls"
    }
}

public struct MeetingChannelInfo: Codable {
    public let videoCover: String
    public let permissionStatus: Int
    public let generateStatus: Int
    public let url: String
    public let topic: String
    public let duration: Int64

    private enum CodingKeys: String, CodingKey {
        case videoCover = "video_cover"
        case permissionStatus = "permission_status"
        case generateStatus = "generate_status"
        case url = "url"
        case topic = "topic"
        case duration = "duration"
    }
}
