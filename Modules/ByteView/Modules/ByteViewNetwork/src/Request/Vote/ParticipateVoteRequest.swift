//
//  ParticipateVoteRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/10/25.
//

import Foundation
import ServerPB

/// PARTICIPATE_VOTE = 89514
/// ServerPB_Videochat_vote_ParticipateVoteRequest
public struct ParticipateVoteRequest {
    public static let command: NetworkCommand = .server(.participateVote)

    ///投票ID
    public var voteID: String?

    public var meetingID: String?

    ///用户选项列表
    public var chooseList: [UserChooseInfo] = []

    public init() {}
}

extension ParticipateVoteRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_vote_ParticipateVoteRequest

    func toProtobuf() throws -> ServerPB_Videochat_vote_ParticipateVoteRequest {
        var pb = ProtobufType()
        if let voteID = self.voteID {
            pb.voteID = voteID
        }
        if let meetingID = self.meetingID {
            pb.meetingID = meetingID
        }
        pb.chooseList = self.chooseList.map { $0.pbType }
        return pb
    }
}

extension UserChooseInfo {
    var pbType: ServerPB_Videochat_vote_UserChooseInfo {
        var pb = ServerPB_Videochat_vote_UserChooseInfo()
        if let optionID = self.optionID {
            pb.optionID = optionID
        }
        return pb
    }
}
