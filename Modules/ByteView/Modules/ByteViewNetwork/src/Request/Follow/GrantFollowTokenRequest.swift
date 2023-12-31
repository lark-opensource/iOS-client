//
//  GrantFollowTokenRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - GRANT_FOLLOW_TOKEN
/// - ServerPB_Videochat_GrantFollowTokenRequest
public struct GrantFollowTokenRequest {
    public static let command: NetworkCommand = .server(.grantFollowToken)
    public init(meetingId: String, breakoutRoomId: String?, token: String, url: String) {
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
        self.token = token
        self.url = url
    }

    public var meetingId: String

    /// 分组会议id
    public var breakoutRoomId: String?

    public var token: String

    public var url: String
}

extension GrantFollowTokenRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_GrantFollowTokenRequest
    func toProtobuf() throws -> ServerPB_Videochat_GrantFollowTokenRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.url = url
        request.token = token
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.associateType = .breakoutMeeting
            request.breakoutMeetingID = id
        } else {
            request.associateType = .meeting
        }
        let timeInterval = Date().timeIntervalSince1970
        request.timestampMs = Int64(timeInterval * 1000)
        return request
    }
}

extension GrantFollowTokenRequest: CustomStringConvertible {
    public var description: String {
        String(indent: "GrantFollowTokenRequest",
               "meetingId: \(meetingId)",
               "breakoutRoomId: \(breakoutRoomId)",
               "token: \(token.hash)",
               "url: \(url.hash)")
    }
}
