//
//  PullVoteChooseUserListRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/10/25.
//

import Foundation
import ServerPB

/// PULL_VOTE_CHOOSE_USER_LIST = 89519
/// ServerPB_Videochat_vote_PullVoteChooseUserListRequest
public struct PullVoteChooseUserListRequest {
    public static let command: NetworkCommand = .server(.pullVoteChooseUserList)
    public typealias Response = PullVoteChooseUserListResponse

    public var meetingID: String?

    public var voteID: String?

    public var optionID: String?

    public var pageSize: Int32?

    public var lastSeqID: Int64?

    public init() {}
}

/// ServerPB_Videochat_vote_PullVoteChooseUserListResponse
public struct PullVoteChooseUserListResponse {

    // TODO: 待确认 @huangtao.ht
    public var userInfos: [ByteviewUser] = []

    public var lastSeqID: Int64

    public var hasMore_p: Bool
}

extension PullVoteChooseUserListRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_PullVoteChooseUserListRequest

    func toProtobuf() throws -> ServerPB_Videochat_vote_PullVoteChooseUserListRequest {
        var request = ProtobufType()
        if let meetingID = self.meetingID {
            request.meetingID = meetingID
        }
        if let voteID = self.voteID {
            request.voteID = voteID
        }
        if let optionID = self.optionID {
            request.optionID = optionID
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

extension PullVoteChooseUserListResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_PullVoteChooseUserListResponse
    init(pb: ServerPB_Videochat_vote_PullVoteChooseUserListResponse) throws {
        // TODO: 待确认 @huangtao.ht
        self.userInfos = pb.userInfos.map { $0.byteViewUser }
        self.lastSeqID = pb.lastSeqID
        self.hasMore_p = pb.hasMore_p
    }
}

extension ServerPB_Videochat_common_ByteviewUser {
    var byteViewUser: ByteviewUser {
        self.vcType
    }
}
