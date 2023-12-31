//
//  VoteStatisticInfo.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/10/25.
//

import Foundation

/// ServerPB_Videochat_vote_ChooseStatus
public enum ChooseStatus: Int, Hashable {

    ///未投票
    case unknownChoose // = 0

    ///投票成功
    case success // = 1

    ///已放弃
    case giveUp // = 2
}

/// Videoconference_V1_VideochatVote_UserChooseInfo
/// ServerPB_Videochat_vote_UserChooseInfo
public struct UserChooseInfo: Equatable {
    public var optionID: String?

    public init() {}

    public init(optionID: String?) {
        self.optionID = optionID
    }
}

/// ServerPB_Videochat_vote_VoteDataType
public enum VoteDataType: Int, Hashable {
    case unknownData // = 0

    ///参与新投票:只包含投票基本数据，标题、选项、匿名、单选多选、状态等
    case meetingVoteJoin // = 1

    ///提醒投票：主持人一键提醒触发，数据同type1
    case meetingVoteJoinNotice // = 2

    ///离会重新入会、入主会场触发，且有未参与的投票，数据同type1
    case meetingVoteRejoin // = 3

    ///投票创建或更新(自己创建的投票多端推送)：数据同type1
    case meetingVoteCreate // = 4

    ///投票状态变更（结束）：只更改投票状态vote_status
    case meetingVoteStatus // = 5

    ///投票统计信息（主持人、创建者、公开的投票）：每个选项投票人数Num、投票userID、总参与人数JoinNum
    case meetingVoteStatistic // = 6

    ///总人数变更（主持人、创建者、公开的投票）：会中总参与人数变化TotalNum
    case meetingVoteTotalNum // = 7

    ///投票结果公布/停止：变更setting中vote_stat_publish字段
    case meetingVoteSetting // = 8

    ///公布：所有人推送type=8（包含type=6）
    ///取消：所有人推送type=8
    case meetingVoteParticipate // = 9
}

/// ServerPB_Videochat_vote_VoteVersionType
public enum VoteVersionType: Int, Hashable {
    case unknownVersion // = 0
    case voteBasic // = 1
    case voteStatus // = 2
    case voteStat // = 3
    case voteSetting // = 4
}

/// ServerPB_Videochat_vote_VoteStatisticInfo
public struct VoteStatisticInfo: Equatable {

    public var voteInfo: MeetingVoteInfo?

    ///总参与人数
    public var voteTotalNum: Int32?

    ///已投票人数
    public var voteJoinNum: Int32?

    ///版本号
    public var version: Int64?

    ///用户投票状态
    public var chooseStatus: ChooseStatus?

    ///用户选项列表
    public var chooseList: [UserChooseInfo] = []

    ///客户端区分推送来源
    public var dataSubType: VoteDataType?

    ///版本号类型，rust做聚合使用
    public var versionType: VoteVersionType?

    public var operatorUid: String?

    public init() {}

    public init(voteInfo: MeetingVoteInfo?, voteTotalNum: Int32?, voteJoinNum: Int32?,
                version: Int64?, chooseStatus: ChooseStatus?, chooseList: [UserChooseInfo],
                dataSubType: VoteDataType?, versionType: VoteVersionType?, operatorUid: String) {
        self.voteInfo = voteInfo
        self.voteTotalNum = voteTotalNum
        self.voteJoinNum = voteJoinNum
        self.version = version
        self.chooseStatus = chooseStatus
        self.chooseList = chooseList
        self.dataSubType = dataSubType
        self.versionType = versionType
        self.operatorUid = operatorUid
    }
}
