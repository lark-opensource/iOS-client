//
//  UpdateMeetingVoteRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/11/14.
//

import Foundation
import ServerPB

/// 修改投票 UPDATE_MEETING_VOTE = 89520
/// ServerPB_Videochat_vote_UpdateMeetingVoteRequest
public struct UpdateMeetingVoteRequest {
    public static let command: NetworkCommand = .server(.updateMeetingVote)
    public typealias Response = UpdateMeetingVoteResponse

    public var meetingID: String?

    public var voteInfo: MeetingVoteInfo?

    public var closeVoteID: String?

    public init() {}
}

/// ServerPB_Videochat_vote_UpdateMeetingVoteResponse
public struct UpdateMeetingVoteResponse {
    /// 命中敏感词
    public var contentRisk: Bool

    public var hasLowVersion: Bool
}

extension UpdateMeetingVoteRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_UpdateMeetingVoteRequest

    func toProtobuf() throws -> ServerPB_Videochat_vote_UpdateMeetingVoteRequest {
        var request = ProtobufType()
        if let meetingID = self.meetingID {
            request.meetingID = meetingID
        }
        if let voteInfo = self.voteInfo {
            request.voteInfo = voteInfo.pbType
        }
        if let closeVoteID = self.closeVoteID {
            request.closeVoteID = closeVoteID
        }
        return request
    }
}

extension UpdateMeetingVoteResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_UpdateMeetingVoteResponse
    init(pb: ServerPB_Videochat_vote_UpdateMeetingVoteResponse) throws {
        self.contentRisk = pb.contentRisk
        self.hasLowVersion = pb.hasLowVersion_p
    }
}
