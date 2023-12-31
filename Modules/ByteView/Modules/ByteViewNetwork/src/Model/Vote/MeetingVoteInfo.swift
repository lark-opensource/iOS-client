//
//  MeetingVoteInfo.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/10/25.
//

import Foundation

/// ServerPB_Videochat_vote_VoteType
public enum VoteType: Int, Hashable {
    case unknownType // = 0
    ///单选
    case single // = 1
    ///多选
    case multi // = 2
}

/// ServerPB_Videochat_vote_VoteStatus
public enum VoteStatus: Int, Hashable {
    case unknownStatus // = 0
    ///创建-draft
    case create // = 1
    ///发布-ing
    case publish // = 2
    ///结束-end
    case close // = 3
}

/// ServerPB_Videochat_vote_VoteOptionInfo
public struct VoteOptionInfo: Equatable {
    ///选项ID
    public var optionID: String?

    ///选项序号
    public var optionNo: String?

    ///选项描述
    public var optionContent: String?

    ///投票人数
    public var num: Int32?

    ///投票用户列表,最多返回6个
    public var userIds: [String] = []

    public init() {}

    public init(optionID: String?, optionNo: String?, optionContent: String?, num: Int32?, userIds: [String]) {
        self.optionID = optionID
        self.optionNo = optionNo
        self.optionContent = optionContent
        self.num = num
        self.userIds = userIds
    }
}

/// ServerPB_Videochat_vote_VoteSetting
public struct VoteSetting: Equatable {
    ///owner是否不参与
    public var ownerNotJoin: Bool?

    ///投票结果公布
    public var voteStatPublish: Bool?

    ///投票者可更改自己的投票
    public var allowUserUpdateChoose: Bool?

    ///投票后可查看结果
    public var voteStatAfterJoined: Bool?

    ///观众可参与投票
    public var allowAttendeeJoin: Bool?

    ///观众可查看公布的投票结果
    public var allowAttendeeViewPublishResult: Bool?

    public init() {}

    public init(ownerNotJoin: Bool?,
                voteStatPublish: Bool?,
                allowUserUpdateChoose: Bool?,
                voteStatAfterJoined: Bool?,
                allowAttendeeJoin: Bool?,
                allowAttendeeViewPublishResult: Bool?) {
        self.ownerNotJoin = ownerNotJoin
        self.voteStatPublish = voteStatPublish
        self.allowUserUpdateChoose = allowUserUpdateChoose
        self.voteStatAfterJoined = voteStatAfterJoined
        self.allowAttendeeJoin = allowAttendeeJoin
        self.allowAttendeeViewPublishResult = allowAttendeeViewPublishResult
    }
}

/// ServerPB_Videochat_vote_MeetingVoteInfo
public struct MeetingVoteInfo: Equatable {
    ///投票ID
    public var voteID: String?

    ///会议ID
    public var meetingID: String?

    ///创建者
    public var voteOwnerID: String?

    ///投票标题
    public var voteTopic: String?

    ///投票类型
    public var voteType: VoteType?

    ///最少选择数
    public var voteMinPickNum: Int32?

    ///最多选择数
    public var voteMaxPickNum: Int32?

    ///是否匿名
    public var voteIsAnonymous: Bool?

    ///投票状态
    public var voteStatus: VoteStatus?

    ///选项信息
    public var optionList: [VoteOptionInfo] = []

    public var createTime: Int64?

    public var updateTime: Int64?

    public var setting: VoteSetting?

    public init() {}

    public init(voteID: String?, meetingID: String?, voteOwnerID: String?, voteTopic: String?,
                voteType: VoteType?, voteMinPickNum: Int32?, voteMaxPickNum: Int32?,
                voteIsAnonymous: Bool?, voteStatus: VoteStatus?, optionList: [VoteOptionInfo],
                createTime: Int64?, updateTime: Int64?, setting: VoteSetting?) {
        self.voteID = voteID
        self.meetingID = meetingID
        self.voteOwnerID = voteOwnerID
        self.voteTopic = voteTopic
        self.voteType = voteType
        self.voteMinPickNum = voteMinPickNum
        self.voteMaxPickNum = voteMaxPickNum
        self.voteIsAnonymous = voteIsAnonymous
        self.voteStatus = voteStatus
        self.optionList = optionList
        self.createTime = createTime
        self.updateTime = updateTime
        self.setting = setting
    }
}
