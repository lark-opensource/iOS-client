//
//  RejoinVideoChatResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/11/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Videoconference_V1_RejoinVideoChatRequest
public struct RejoinVideoChatRequest {
    public static let command: NetworkCommand = .rust(.rejoinVideoChat)
    public typealias Response = RejoinVideoChatResponse

    public init(meetingId: String, force: Bool, role: Participant.MeetingRole, isE2EeMeeting: Bool) {
        self.meetingId = meetingId
        self.force = force
        self.role = role
        self.isE2EeMeeting = isE2EeMeeting
    }

    /// 会议ID
    public var meetingId: String

    /// 是否强制解锁
    public var force: Bool

    /// 请求接口时候的用户角色，webinar会中需求中新增，方便后端查询是否为观众，后续请求需携带
    public var role: Participant.MeetingRole

    /// 是否是端到端加密会议
    public var isE2EeMeeting: Bool
}

public struct RejoinVideoChatResponse {
    public init(status: StatusCode, videoChatInfo: VideoChatInfo?, lobbyInfo: LobbyInfo?) {
        self.status = status
        self.videoChatInfo = videoChatInfo
        self.lobbyInfo = lobbyInfo
    }

    public var status: StatusCode
    public var videoChatInfo: VideoChatInfo?
    public var lobbyInfo: LobbyInfo?

    public enum StatusCode: Int, Equatable {
        case unknown // = 0
        case success // = 1
        case vcBusyError // = 2
        case voIpBusyError // = 3
        case meetingEndError // = 4

        /// 后续按需要扩展
        case participantLimitExceedError // = 5
    }
}

extension RejoinVideoChatRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_RejoinVideoChatRequest
    func toProtobuf() throws -> Videoconference_V1_RejoinVideoChatRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.force = force
        request.role = role.pbType
        request.isE2EeMeeting = isE2EeMeeting
        return request
    }
}

extension RejoinVideoChatResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_RejoinVideoChatResponse
    init(pb: Videoconference_V1_RejoinVideoChatResponse) throws {
        self.status = .init(rawValue: pb.status.rawValue) ?? .unknown
        self.videoChatInfo = pb.hasVideoChatInfo ? pb.videoChatInfo.vcType : nil
        self.lobbyInfo = pb.hasJoinMeetingLobby ? pb.joinMeetingLobby.vcType : nil
    }
}
