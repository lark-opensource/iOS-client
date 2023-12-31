//
//  Vote+Rust.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/10/25.
//

import Foundation
import RustPB
import ServerPB

typealias PBVoteType = Videoconference_V1_VideochatVote_VoteType
typealias PBVoteStatus = Videoconference_V1_VideochatVote_VoteStatus
typealias PBVoteOptionInfo = Videoconference_V1_VideochatVote_VoteOptionInfo
typealias PBVoteSetting = Videoconference_V1_VideochatVote_VoteSetting
typealias PBMeetingVoteInfo = Videoconference_V1_VideochatVote_MeetingVoteInfo
typealias PBChooseStatus = Videoconference_V1_VideochatVote_ChooseStatus
typealias PBUserChooseInfo = Videoconference_V1_VideochatVote_UserChooseInfo
typealias PBVoteDataType = Videoconference_V1_VideochatVote_VoteDataType
typealias PBVoteVersionType = Videoconference_V1_VideochatVote_VoteVersionType
typealias PBVoteStatisticInfo = Videoconference_V1_VideochatVote_VoteStatisticInfo
//typealias PBUserVoteInfo = Videoconference_V1_VideochatVote_UserVoteInfo

typealias ServerPBVoteType = ServerPB_Videochat_vote_VoteType
typealias ServerPBVoteStatus = ServerPB_Videochat_vote_VoteStatus
typealias ServerPBVoteOptionInfo = ServerPB_Videochat_vote_VoteOptionInfo
typealias ServerPBVoteSetting = ServerPB_Videochat_vote_VoteSetting
typealias ServerPBMeetingVoteInfo = ServerPB_Videochat_vote_MeetingVoteInfo
typealias ServerPBChooseStatus = ServerPB_Videochat_vote_ChooseStatus
typealias ServerPBUserChooseInfo = ServerPB_Videochat_vote_UserChooseInfo
typealias ServerPBVoteDataType = ServerPB_Videochat_vote_VoteDataType
typealias ServerPBVoteVersionType = ServerPB_Videochat_vote_VoteVersionType
typealias ServerPBVoteStatisticInfo = ServerPB_Videochat_vote_VoteStatisticInfo
typealias ServerPBUserVoteInfo = ServerPB_Videochat_vote_UserVoteInfo

extension PBVoteType {
    var vcType: VoteType {
        .init(rawValue: self.rawValue) ?? .unknownType
    }
}

extension ServerPBVoteType {
    var vcType: VoteType {
        .init(rawValue: self.rawValue) ?? .unknownType
    }
}

extension PBVoteStatus {
    var vcType: VoteStatus {
        .init(rawValue: self.rawValue) ?? .unknownStatus
    }
}

extension ServerPBVoteStatus {
    var vcType: VoteStatus {
        .init(rawValue: self.rawValue) ?? .unknownStatus
    }
}

extension PBVoteOptionInfo {
    var vcType: VoteOptionInfo {
        .init(optionID: self.optionID,
              optionNo: self.optionNo,
              optionContent: self.optionContent,
              num: self.num,
              userIds: self.userIds)
    }
}

extension ServerPBVoteOptionInfo {
    var vcType: VoteOptionInfo {
        .init(optionID: self.optionID,
              optionNo: self.optionNo,
              optionContent: self.optionContent,
              num: self.num,
              userIds: self.userIds)
    }
}

extension PBVoteSetting {
    var vcType: VoteSetting {
        .init(ownerNotJoin: self.ownerNotJoin,
              voteStatPublish: self.voteStatPublish,
              allowUserUpdateChoose: self.allowUserUpdateChoose,
              voteStatAfterJoined: self.voteStatAfterJoined,
              allowAttendeeJoin: self.allowAttendeeJoin,
              allowAttendeeViewPublishResult: self.allowAttendeeViewPublishResult)
    }
}

extension ServerPBVoteSetting {
    var vcType: VoteSetting {
        .init(ownerNotJoin: self.ownerNotJoin,
              voteStatPublish: self.voteStatPublish,
              allowUserUpdateChoose: self.allowUserUpdateChoose,
              voteStatAfterJoined: self.voteStatAfterJoined,
              allowAttendeeJoin: self.allowAttendeeJoin,
              allowAttendeeViewPublishResult: self.allowAttendeeViewPublishResult)
    }
}

extension PBMeetingVoteInfo {
    var vcType: MeetingVoteInfo {
        .init(voteID: self.voteID,
              meetingID: self.meetingID,
              voteOwnerID: self.voteOwnerID,
              voteTopic: self.voteTopic,
              voteType: self.voteType.vcType,
              voteMinPickNum: self.voteMinPickNum,
              voteMaxPickNum: self.voteMaxPickNum,
              voteIsAnonymous: self.voteIsAnonymous,
              voteStatus: self.voteStatus.vcType,
              optionList: self.optionList.map { $0.vcType },
              createTime: self.createTime,
              updateTime: self.updateTime,
              setting: self.setting.vcType)
    }
}

extension ServerPBMeetingVoteInfo {
    var vcType: MeetingVoteInfo {
        .init(voteID: self.voteID,
              meetingID: self.meetingID,
              voteOwnerID: self.voteOwnerID,
              voteTopic: self.voteTopic,
              voteType: self.voteType.vcType,
              voteMinPickNum: self.voteMinPickNum,
              voteMaxPickNum: self.voteMaxPickNum,
              voteIsAnonymous: self.voteIsAnonymous,
              voteStatus: self.voteStatus.vcType,
              optionList: self.optionList.map { $0.vcType },
              createTime: self.createTime,
              updateTime: self.updateTime,
              setting: self.setting.vcType)
    }
}

extension PBChooseStatus {
    var vcType: ChooseStatus {
        .init(rawValue: self.rawValue) ?? .unknownChoose
    }
}

extension ServerPBChooseStatus {
    var vcType: ChooseStatus {
        .init(rawValue: self.rawValue) ?? .unknownChoose
    }
}

extension PBUserChooseInfo {
    var vcType: UserChooseInfo {
        .init(optionID: self.optionID)
    }
}

extension ServerPBUserChooseInfo {
    var vcType: UserChooseInfo {
        .init(optionID: self.optionID)
    }
}

extension PBVoteDataType {
    var vcType: VoteDataType {
        .init(rawValue: self.rawValue) ?? .unknownData
    }
}

extension ServerPBVoteDataType {
    var vcType: VoteDataType {
        .init(rawValue: self.rawValue) ?? .unknownData
    }
}

extension PBVoteVersionType {
    var vcType: VoteVersionType {
        .init(rawValue: self.rawValue) ?? .unknownVersion
    }
}

extension ServerPBVoteVersionType {
    var vcType: VoteVersionType {
        .init(rawValue: self.rawValue) ?? .unknownVersion
    }
}

extension PBVoteStatisticInfo {
    var vcType: VoteStatisticInfo {
        .init(voteInfo: self.voteInfo.vcType,
              voteTotalNum: self.voteTotalNum,
              voteJoinNum: self.voteJoinNum,
              version: self.version,
              chooseStatus: self.chooseStatus.vcType,
              chooseList: self.chooseList.map { $0.vcType },
              dataSubType: self.dataSubType.vcType,
              versionType: self.versionType.vcType,
              operatorUid: self.operatorUid)
    }
}

extension ServerPBVoteStatisticInfo {
    var vcType: VoteStatisticInfo {
        .init(voteInfo: self.voteInfo.vcType,
              voteTotalNum: self.voteTotalNum,
              voteJoinNum: self.voteJoinNum,
              version: self.version,
              chooseStatus: self.chooseStatus.vcType,
              chooseList: self.chooseList.map { $0.vcType },
              dataSubType: self.dataSubType.vcType,
              versionType: self.versionType.vcType,
              operatorUid: self.operatorUid)
    }
}

extension ServerPBUserVoteInfo {
    var vcType: UserVoteInfo {
        .init(voteInfo: self.voteInfo.vcType,
              chooseStatus: self.chooseStatus.vcType,
              chooseList: self.chooseList.map { $0.vcType })
    }
}
