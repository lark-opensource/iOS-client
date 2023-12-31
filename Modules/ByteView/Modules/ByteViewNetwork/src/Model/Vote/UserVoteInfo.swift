//
//  UserVoteInfo.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/10/25.
//

import Foundation

/// ServerPB_Videochat_vote_UserVoteInfo
public struct UserVoteInfo: Equatable {

    public var voteInfo: MeetingVoteInfo?

    ///用户投票状态
    public var chooseStatus: ChooseStatus?

    ///用户选项列表
    public var chooseList: [UserChooseInfo] = []

    public init() {}

    public init(voteInfo: MeetingVoteInfo?, chooseStatus: ChooseStatus?, chooseList: [UserChooseInfo]) {
        self.voteInfo = voteInfo
        self.chooseStatus = chooseStatus
        self.chooseList = chooseList
    }
}
