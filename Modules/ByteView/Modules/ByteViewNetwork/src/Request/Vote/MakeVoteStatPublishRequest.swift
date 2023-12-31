//
//  MakeVoteStatPublishRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/11/14.
//

import Foundation
import ServerPB

/// 公布/取消投票结果 MAKE_VOTE_STAT_PUBLISH = 89522
/// ServerPB_Videochat_vote_MakeVoteStatPublishRequest
public struct MakeVoteStatPublishRequest {
    public static let command: NetworkCommand = .server(.makeVoteStatPublish)
    public typealias Response = MakeVoteStatPublishResponse

    public var voteID: String?

    public var meetingID: String?

    public var publish: Bool?

    public init() {}
}

/// ServerPB_Videochat_vote_MakeVoteStatPublishResponse
public struct MakeVoteStatPublishResponse {
    /// 会中是否有低版本用户
    public var hasLowVersion_p: Bool
}

extension MakeVoteStatPublishRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_MakeVoteStatPublishRequest

    func toProtobuf() throws -> ServerPB_Videochat_vote_MakeVoteStatPublishRequest {
        var request = ProtobufType()
        if let voteID = self.voteID {
            request.voteID = voteID
        }
        if let meetingID = self.meetingID {
            request.meetingID = meetingID
        }
        if let publish = self.publish {
            request.publish = publish
        }
        return request
    }
}

extension MakeVoteStatPublishResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_MakeVoteStatPublishResponse
    init(pb: ServerPB_Videochat_vote_MakeVoteStatPublishResponse) throws {
        self.hasLowVersion_p = pb.hasLowVersion_p
    }
}
