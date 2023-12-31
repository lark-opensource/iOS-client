//
//  PullVoteStatisticInfoRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/10/25.
//

import Foundation
import ServerPB

/// PULL_VOTE_STATISTIC_INFO= 89516
/// ServerPB_Videochat_vote_PullVoteStatisticInfoRequest
public struct PullVoteStatisticInfoRequest {
    public static let command: NetworkCommand = .server(.pullVoteStatisticInfo)
    public typealias Response = PullVoteStatisticInfoResponse

    public var voteID: String?

    public var meetingID: String?

    public init() {}
}

/// ServerPB_Videochat_vote_PullVoteStatisticInfoResponse
public struct PullVoteStatisticInfoResponse {
    public var voteStatisticInfo: VoteStatisticInfo
}

extension PullVoteStatisticInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_PullVoteStatisticInfoRequest

    func toProtobuf() throws -> ServerPB_Videochat_vote_PullVoteStatisticInfoRequest {
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

extension PullVoteStatisticInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_PullVoteStatisticInfoResponse
    init(pb: ServerPB_Videochat_vote_PullVoteStatisticInfoResponse) throws {
        self.voteStatisticInfo = pb.voteStatisticInfo.vcType
    }
}
