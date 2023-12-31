//
//  CreateMeetingVoteRequest.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/10/25.
//

import Foundation
import ServerPB

/// - CREATE_MEETING_VOTE = 89511
/// ServerPB_Videochat_vote_CreateMeetingVoteRequest
public struct CreateMeetingVoteRequest {
    public static let command: NetworkCommand = .server(.createMeetingVote)
    public typealias Response = CreateMeetingVoteResponse

    public var meetingID: String?

    public var voteInfo: MeetingVoteInfo?

    public var closeVoteID: String?

    public init() {}
}

/// ServerPB_Videochat_vote_CreateMeetingVoteResponse
public struct CreateMeetingVoteResponse {
    public var voteInfo: MeetingVoteInfo
    /// 命中敏感词
    public var contentRisk: Bool

    public var hasLowVersion: Bool
}

extension CreateMeetingVoteRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_CreateMeetingVoteRequest

    func toProtobuf() throws -> ServerPB_Videochat_vote_CreateMeetingVoteRequest {
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

extension CreateMeetingVoteResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_vote_CreateMeetingVoteResponse

    init(pb: ServerPB_Videochat_vote_CreateMeetingVoteResponse) throws {
        self.voteInfo = pb.voteInfo.vcType
        self.contentRisk = pb.contentRisk
        self.hasLowVersion = pb.hasLowVersion_p
    }
}

extension VoteType {
    var pbType: ServerPBVoteType {
        .init(rawValue: self.rawValue) ?? .unknownType
    }
}

extension VoteStatus {
    var pbType: ServerPBVoteStatus {
        .init(rawValue: self.rawValue) ?? .unknownStatus
    }
}

extension VoteOptionInfo {
    var pbType: ServerPBVoteOptionInfo {
        var pb = ServerPBVoteOptionInfo()
        if let optionID = self.optionID {
            pb.optionID = optionID
        }
        if let optionNo = self.optionNo {
            pb.optionNo = optionNo
        }

        if let optionContent = self.optionContent {
            pb.optionContent = optionContent
        }
        if let num = self.num {
            pb.num = num
        }
        pb.userIds = userIds
        return pb
    }
}

extension VoteSetting {
    var pbType: ServerPBVoteSetting {
        var pb = ServerPBVoteSetting()
        if let ownerNotJoin = self.ownerNotJoin {
            pb.ownerNotJoin = ownerNotJoin
        }
        if let voteStatPublish = self.voteStatPublish {
            pb.voteStatPublish = voteStatPublish
        }
        if let allowUserUpdateChoose = self.allowUserUpdateChoose {
            pb.allowUserUpdateChoose = allowUserUpdateChoose
        }
        if let voteStatAfterJoined = self.voteStatAfterJoined {
            pb.voteStatAfterJoined = voteStatAfterJoined
        }
        if let allowAttendeeJoin = self.allowAttendeeJoin {
            pb.allowAttendeeJoin = allowAttendeeJoin
        }
        if let allowAttendeeViewPublishResult = self.allowAttendeeViewPublishResult {
            pb.allowAttendeeViewPublishResult = allowAttendeeViewPublishResult
        }
        return pb
    }
}

extension MeetingVoteInfo {
    var pbType: ServerPBMeetingVoteInfo {
        var pb = ServerPBMeetingVoteInfo()
        if let voteID = self.voteID {
            pb.voteID = voteID
        }
        if let meetingID = self.meetingID {
            pb.meetingID = meetingID
        }
        if let voteOwnerID = self.voteOwnerID {
            pb.voteOwnerID = voteOwnerID
        }
        if let voteTopic = self.voteTopic {
            pb.voteTopic = voteTopic
        }
        if let voteType = self.voteType {
            pb.voteType = voteType.pbType
        }
        if let voteMinPickNum = self.voteMinPickNum {
            pb.voteMinPickNum = voteMinPickNum
        }
        if let voteMaxPickNum = self.voteMaxPickNum {
            pb.voteMaxPickNum = voteMaxPickNum
        }
        if let voteIsAnonymous = self.voteIsAnonymous {
            pb.voteIsAnonymous = voteIsAnonymous
        }
        if let voteStatus = self.voteStatus {
            pb.voteStatus = voteStatus.pbType
        }
        pb.optionList = self.optionList.map { $0.pbType }
        if let createTime = self.createTime {
            pb.createTime = createTime
        }
        if let updateTime = self.updateTime {
            pb.updateTime = updateTime
        }
        if let setting = self.setting {
            pb.setting = setting.pbType
        }
        return pb
    }
}
