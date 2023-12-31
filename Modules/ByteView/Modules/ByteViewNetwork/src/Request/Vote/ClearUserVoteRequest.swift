//
//  ClearUserVoteRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/11/14.
//

import Foundation
import ServerPB

/// 投票结果清除 CLEAR_USER_VOTE = 89521
/// ServerPB_Videochat_vote_ClearUserVoteRequest
public struct ClearUserVoteRequest {
    public static let command: NetworkCommand = .server(.clearUserVote)
    public var voteID: String?
    public var meetingID: String?
    public init() {}
}

extension ClearUserVoteRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_vote_ClearUserVoteRequest

    func toProtobuf() throws -> ServerPB_Videochat_vote_ClearUserVoteRequest {
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
