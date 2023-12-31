//
//  VoteOneClickReminderRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/10/25.
//

import Foundation
import ServerPB

/// VOTE_ONE_CLICK_REMINDER = 89518
/// ServerPB_Videochat_vote_VoteOneClickReminderRequest
public struct VoteOneClickReminderRequest {
    public static let command: NetworkCommand = .server(.voteOneClickReminder)
    public typealias Response = VoteOneClickReminderResponse

    public var voteID: String?

    public var meetingID: String?

    public init() {}
}

/// ServerPB_Videochat_vote_VoteOneClickReminderResponse
public struct VoteOneClickReminderResponse {
    ///所有未投票参会人已离开
    public var allNoJoinUserLeave: Bool
}

extension VoteOneClickReminderRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_VoteOneClickReminderRequest

    func toProtobuf() throws -> ServerPB_Videochat_vote_VoteOneClickReminderRequest {
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

extension VoteOneClickReminderResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_VoteOneClickReminderResponse
    init(pb: ServerPB_Videochat_vote_VoteOneClickReminderResponse) throws {
        self.allNoJoinUserLeave = pb.allNoJoinUserLeave
    }
}
