//
//  PullUserVoteInfoRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/10/25.
//

import Foundation
import ServerPB

/// PULL_USER_VOTE_INFO = 89517
/// ServerPB_Videochat_vote_PullUserVoteInfoRequest
public struct PullUserVoteInfoRequest {
    public static let command: NetworkCommand = .server(.pullUserVoteInfo)
    public typealias Response = PullUserVoteInfoResponse

    public var voteID: String?

    public var meetingID: String?

    public init() {}
}

/// ServerPB_Videochat_vote_PullUserVoteInfoResponse
public struct PullUserVoteInfoResponse {
    public var userVoteInfo: UserVoteInfo
}

extension PullUserVoteInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_PullUserVoteInfoRequest

    func toProtobuf() throws -> ServerPB_Videochat_vote_PullUserVoteInfoRequest {
        var request = ProtobufType()
        if let voteID = self.voteID {
            request.voteID = voteID
        }
        if let meetingID = self.meetingID {
            request.meetingID = meetingID
        }
        return request
    }
}

extension PullUserVoteInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_PullUserVoteInfoResponse
    init(pb: ServerPB_Videochat_vote_PullUserVoteInfoResponse) throws {
        self.userVoteInfo = pb.userVoteInfo.vcType
    }
}
