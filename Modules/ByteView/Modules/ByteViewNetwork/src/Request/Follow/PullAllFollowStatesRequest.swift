//
//  PullAllFollowStatesResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - PULL_ALL_FOLLOW_STATES
/// - ServerPB_Videochat_PullAllFollowStatesRequest
public struct PullAllFollowStatesRequest {
    public static let command: NetworkCommand = .server(.pullAllFollowStates)
    public typealias Response = PullAllFollowStatesResponse

    public init(meetingId: String, breakoutRoomId: String?, shareId: String) {
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
        self.shareId = shareId
    }

    public var meetingId: String

    /// 分组会议id
    public var breakoutRoomId: String?

    public var shareId: String
}


/// ServerPB_Videochat_PullAllFollowStatesResponse
public struct PullAllFollowStatesResponse {
    public init(states: [FollowState], downVersion: Int32) {
        self.states = states
        self.downVersion = downVersion
    }
    public var states: [FollowState]

    public var downVersion: Int32
}

extension PullAllFollowStatesRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_PullAllFollowStatesRequest
    func toProtobuf() throws -> ServerPB_Videochat_PullAllFollowStatesRequest {
        var request = ProtobufType()
        request.shareID = shareId
        request.meetingID = meetingId
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.associateType = .breakoutMeeting
            request.breakoutMeetingID = id
        } else {
            request.associateType = .meeting
        }
        return request
    }
}

extension PullAllFollowStatesResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_PullAllFollowStatesResponse
    init(pb: ServerPB_Videochat_PullAllFollowStatesResponse) throws {
        self.states = pb.states.map({ $0.vcType })
        self.downVersion = pb.downVersion
    }
}
