//
//  GroupMeetingListResponse.swift
//  MinutesFoundation
//
//  Created by yangyao on 2023/5/16.
//

import Foundation

public struct GroupMeeting: Codable {
    public let topic: String
    public let objectToken: String
    public let url: String
    public let videoCover: String
    public let permissionStatus: Int
    public let generateStatus: Int

    private enum CodingKeys: String, CodingKey {
        case topic = "topic"
        case objectToken = "object_token"
        case url = "url"
        case videoCover = "video_cover"
        case permissionStatus = "permission_status"
        case generateStatus = "generate_status"
    }
}

public struct GroupMeetingListResponse: Codable {
    public let groupMeetings: [GroupMeeting]?

    private enum CodingKeys: String, CodingKey {
        case groupMeetings = "group_meeting_urls"
    }
}
