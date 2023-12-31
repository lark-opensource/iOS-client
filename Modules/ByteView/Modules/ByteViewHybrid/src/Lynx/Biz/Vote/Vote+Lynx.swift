//
//  Vote+Lynx.swift
//  ByteViewHybrid
//
//  Created by Tobb Huang on 2022/10/27.
//

import Foundation
import ByteViewNetwork

extension VoteOptionInfo {
    init(dict: [String: Any]) {
        self.init()
        self.optionID = dict["optionID"] as? String
        self.optionNo = dict["optionNo"] as? String
        self.optionContent = dict["optionContent"] as? String
        self.num = dict["num"] as? Int32
        self.userIds = dict["userIds"] as? [String] ?? []
    }

    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        dict["optionID"] = optionID
        dict["optionNo"] = optionNo
        dict["optionContent"] = optionContent
        dict["num"] = num
        dict["userIds"] = userIds
        return dict
    }
}

extension VoteSetting {
    init(dict: [String: Any]) {
        self.init()
        self.ownerNotJoin = dict["ownerNotJoin"] as? Bool
        self.voteStatPublish = dict["voteStatPublish"] as? Bool
        self.allowUserUpdateChoose = dict["allowUserUpdateChoose"] as? Bool
        self.voteStatAfterJoined = dict["voteStatAfterJoined"] as? Bool
        self.allowAttendeeJoin = dict["allowAttendeeJoin"] as? Bool
        self.allowAttendeeViewPublishResult = dict["allowAttendeeViewPublishResult"] as? Bool
    }

    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        dict["ownerNotJoin"] = ownerNotJoin
        dict["voteStatPublish"] = voteStatPublish
        dict["allowUserUpdateChoose"] = allowUserUpdateChoose
        dict["voteStatAfterJoined"] = voteStatAfterJoined
        dict["allowAttendeeJoin"] = allowAttendeeJoin
        dict["allowAttendeeViewPublishResult"] = allowAttendeeViewPublishResult
        return dict
    }
}

extension MeetingVoteInfo {
    init(dict: [String: Any]) {
        self.init()
        self.voteID = dict["voteID"] as? String
        self.meetingID = dict["meetingID"] as? String
        self.voteOwnerID = dict["voteOwnerID"] as? String
        self.voteTopic = dict["voteTopic"] as? String
        if let voteType = dict["voteType"] as? Int {
            self.voteType = .init(rawValue: voteType)
        }
        self.voteMinPickNum = dict["voteMinPickNum"] as? Int32
        self.voteMaxPickNum = dict["voteMaxPickNum"] as? Int32
        self.voteIsAnonymous = dict["voteIsAnonymous"] as? Bool
        if let voteStatus = dict["voteStatus"] as? Int {
            self.voteStatus = .init(rawValue: voteStatus)
        }
        self.voteID = dict["voteID"] as? String
        if let list = dict["optionList"] as? [[String: Any]] {
            self.optionList = list.map { .init(dict: $0) }
        }
        if let setting = dict["setting"] as? [String: Any] {
            self.setting = .init(dict: setting)
        }
    }

    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        if let voteID = self.voteID {
            dict["voteID"] = voteID
        }
        if let meetingID = self.meetingID {
            dict["meetingID"] = meetingID
        }
        if let voteOwnerID = self.voteOwnerID {
            dict["voteOwnerID"] = voteOwnerID
        }
        if let voteTopic = self.voteTopic {
            dict["voteTopic"] = voteTopic
        }
        if let voteType = self.voteType {
            dict["voteType"] = voteType.rawValue
        }
        if let voteMinPickNum = self.voteMinPickNum {
            dict["voteMinPickNum"] = voteMinPickNum
        }
        if let voteMaxPickNum = self.voteMaxPickNum {
            dict["voteMaxPickNum"] = voteMaxPickNum
        }
        if let voteIsAnonymous = self.voteIsAnonymous {
            dict["voteIsAnonymous"] = voteIsAnonymous
        }
        if let voteStatus = self.voteStatus {
            dict["voteStatus"] = voteStatus.rawValue
        }
        dict["optionList"] = optionList.map { $0.dict }
        if let setting = self.setting {
            dict["setting"] = setting.dict
        }
        return dict
    }
}

extension UserVoteInfo {
    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        if let voteInfo = self.voteInfo {
            dict["voteInfo"] = voteInfo.dict
        }
        if let chooseStatus = self.chooseStatus {
            dict["chooseStatus"] = chooseStatus.rawValue
        }
        dict["chooseList"] = chooseList.map { $0.dict }
        return dict
    }
}

extension UserChooseInfo {
    init(dict: [String: Any]) {
        self.init()
        self.optionID = dict["optionID"] as? String
    }

    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        dict["optionID"] = optionID
        return dict
    }
}

extension VoteStatisticInfo {
    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        if let voteInfo = self.voteInfo {
            dict["voteInfo"] = voteInfo.dict
        }
        if let voteTotalNum = self.voteTotalNum {
            dict["voteTotalNum"] = voteTotalNum
        }
        if let voteJoinNum = self.voteJoinNum {
            dict["voteJoinNum"] = voteJoinNum
        }
        if let version = self.version {
            dict["version"] = version
        }
        if let chooseStatus = self.chooseStatus {
            dict["chooseStatus"] = chooseStatus.rawValue
        }
        dict["chooseList"] = chooseList.map { $0.dict }
        if let dataSubType = self.dataSubType {
            dict["dataSubType"] = dataSubType.rawValue
        }
        if let versionType = self.versionType {
            dict["versionType"] = versionType.rawValue
        }
        return dict
    }
}

extension CreateMeetingVoteRequest {
    init(dict: [String: Any]) {
        self.init()
        self.meetingID = dict["meetingID"] as? String
        if let info = dict["voteInfo"] as? [String: Any] {
            self.voteInfo = MeetingVoteInfo(dict: info)
        }
        if let closeVoteID = dict["closeVoteID"] as? String {
            self.closeVoteID = closeVoteID
        }
    }
}

extension CreateMeetingVoteResponse {
    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        dict["voteInfo"] = self.voteInfo.dict
        dict["contentRisk"] = self.contentRisk
        dict["hasLowVersion"] = self.hasLowVersion
        return dict
    }
}

extension ParticipateVoteRequest {
    init(dict: [String: Any]) {
        self.init()
        self.voteID = dict["voteID"] as? String
        self.meetingID = dict["meetingID"] as? String
        if let list = dict["chooseList"] as? [[String: Any]] {
            self.chooseList = list.map { UserChooseInfo(dict: $0) }
        }
    }
}

extension PullUserVoteInfoRequest {
    init(dict: [String: Any]) {
        self.init()
        self.voteID = dict["voteID"] as? String
        self.meetingID = dict["meetingID"] as? String
    }
}

extension PullUserVoteInfoResponse {
    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        dict["userVoteInfo"] = self.userVoteInfo.dict
        return dict
    }
}

extension PullVoteChooseUserListRequest {
    init(dict: [String: Any]) {
        self.init()
        self.meetingID = dict["meetingID"] as? String
        self.voteID = dict["voteID"] as? String
        self.optionID = dict["optionID"] as? String
        self.pageSize = dict["pageSize"] as? Int32
        self.lastSeqID = dict["lastSeqID"] as? Int64
    }
}

extension PullVoteChooseUserListResponse {
    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        dict["lastSeqID"] = self.lastSeqID
        dict["hasMore"] = self.hasMore_p
        dict["userList"] = self.userInfos.map { $0.dict }
        return dict
    }
}

extension PullVoteStatisticInfoRequest {
    init(dict: [String: Any]) {
        self.init()
        self.voteID = dict["voteID"] as? String
        self.meetingID = dict["meetingID"] as? String
    }
}

extension PullVoteStatisticInfoResponse {
    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        dict["voteStatisticInfo"] = self.voteStatisticInfo.dict
        return dict
    }
}

extension PullVoteStatisticListRequest {
    init(dict: [String: Any]) {
        self.init()
        self.meetingID = dict["meetingID"] as? String
        self.pageSize = dict["pageSize"] as? Int32
        self.lastSeqID = dict["lastSeqID"] as? String
    }
}

extension PullVoteStatisticListResponse {
    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        dict["voteStatisticList"] = self.voteStatisticList.map { $0.dict }
        dict["hasMore_p"] = self.hasMore_p
        return dict
    }
}

extension VoteOneClickReminderRequest {
    init(dict: [String: Any]) {
        self.init()
        self.voteID = dict["voteID"] as? String
        self.meetingID = dict["meetingID"] as? String
    }
}

extension VoteOneClickReminderResponse {
    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        dict["allNoJoinUserLeave"] = self.allNoJoinUserLeave
        return dict
    }
}

extension ByteviewUser {
    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        dict["uid"] = self.id
        dict["did"] = self.deviceId
        dict["type"] = self.type.rawValue
        return dict
    }

    init(dict: [String: Any]) {
        self.init(
            id: (dict["uid"] as? String) ?? "",
            type: .init(rawValue: (dict["type"] as? Int) ?? 0),
            deviceId: (dict["did"] as? String) ?? ""
        )
    }
}

extension UpdateMeetingVoteRequest {
    init(dict: [String: Any]) {
        self.init()
        self.meetingID = dict["meetingID"] as? String
        if let info = dict["voteInfo"] as? [String: Any] {
            self.voteInfo = MeetingVoteInfo(dict: info)
        }
        if let closeVoteID = dict["closeVoteID"] as? String {
            self.closeVoteID = closeVoteID
        }
    }
}

extension ClearUserVoteRequest {
    init(dict: [String: Any]) {
        self.init()
        self.voteID = dict["voteID"] as? String
        self.meetingID = dict["meetingID"] as? String
    }
}

extension MakeVoteStatPublishRequest {
    init(dict: [String: Any]) {
        self.init()
        self.voteID = dict["voteID"] as? String
        self.meetingID = dict["meetingID"] as? String
        self.publish = dict["publish"] as? Bool
    }
}

extension MakeVoteStatPublishResponse {
    var dict: [String: Any] {
        var dict: [String: Any] = [:]
        dict["hasLowVersion"] = self.hasLowVersion_p
        return dict
    }
}
