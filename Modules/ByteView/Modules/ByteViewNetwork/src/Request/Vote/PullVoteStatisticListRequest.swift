//
//  PullVoteStatisticListRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/10/25.
//

import Foundation
import ServerPB

/// PULL_VOTE_STATISTIC_LIST = 89515
/// ServerPB_Videochat_vote_PullVoteStatisticListRequest
public struct PullVoteStatisticListRequest {
    public static let command: NetworkCommand = .server(.pullVoteStatisticList)
    public typealias Response = PullVoteStatisticListResponse

    public var meetingID: String?

    public var pageSize: Int32?

    public var lastSeqID: String?

    public init() {}
}

/// ServerPB_Videochat_vote_PullVoteStatisticListResponse
public struct PullVoteStatisticListResponse {
    public var voteStatisticList: [VoteStatisticInfo] = []

    public var hasMore_p: Bool
}

extension PullVoteStatisticListRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_PullVoteStatisticListRequest

    func toProtobuf() throws -> ServerPB_Videochat_vote_PullVoteStatisticListRequest {
        var request = ProtobufType()
        if let meetingID = self.meetingID {
            request.meetingID = meetingID
        }
        if let pageSize = self.pageSize {
            request.pageSize = pageSize
        }
        if let lastSeqID = self.lastSeqID {
            request.lastSeqID = lastSeqID
        }
        return request
    }
}

extension PullVoteStatisticListResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_PullVoteStatisticListResponse
    init(pb: ServerPB_Videochat_vote_PullVoteStatisticListResponse) throws {
        self.voteStatisticList = pb.voteStatisticList.map { $0.vcType }
        self.hasMore_p = pb.hasMore_p
    }
}
