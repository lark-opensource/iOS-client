//
//  LiveInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public struct LiveInfo: Equatable {
    public init(liveID: Int64, liveSessionID: String, liveName: String, liveURL: String, isLiving: Bool,
                liveVote: LiveVote?,
                sid: Int64, privilege: LivePrivilege, defaultPrivilege: LivePrivilege,
                layoutStyle: LiveLayout, defaultLayoutStyle: LiveLayout,
                enableLiveComment: Bool, enablePlayback: Bool, defaultEnableLiveComment: Bool, livePermissionMemberChanged: Bool) {
        self.liveID = liveID
        self.liveSessionID = liveSessionID
        self.liveName = liveName
        self.liveURL = liveURL
        self.isLiving = isLiving
        self.liveVote = liveVote
        self.sid = sid
        self.privilege = privilege
        self.defaultPrivilege = defaultPrivilege
        self.layoutStyle = layoutStyle
        self.defaultLayoutStyle = defaultLayoutStyle
        self.enableLiveComment = enableLiveComment
        self.enablePlayback = enablePlayback
        self.defaultEnableLiveComment = defaultEnableLiveComment
        self.livePermissionMemberChanged = livePermissionMemberChanged
    }

    public var liveID: Int64

    public var liveSessionID: String

    /// 直播名称
    public var liveName: String

    /// 直播地址
    public var liveURL: String

    /// 直播状态
    public var isLiving: Bool

    /// 直播投票情况
    public var liveVote: LiveVote?

    public var sid: Int64

    public var privilege: LivePrivilege

    public var layoutStyle: LiveLayout

    public var defaultLayoutStyle: LiveLayout

    public var enableLiveComment: Bool

    public var enablePlayback: Bool

    public var defaultEnableLiveComment: Bool

    public var defaultPrivilege: LivePrivilege

    public var livePermissionMemberChanged: Bool
}

public struct LiveVote: Equatable {
    public init(voteID: String, isVoting: Bool, reason: LiveVote.Reason, sponsorID: String) {
        self.voteID = voteID
        self.isVoting = isVoting
        self.reason = reason
        self.sponsorID = sponsorID
    }

    public var voteID: String
    public var isVoting: Bool
    public var reason: LiveVote.Reason
    public var sponsorID: String

    public enum Reason: Int, Hashable {
        case unknown // = 0
        case cancel // = 1
        case refused // = 2
        case accept // = 3
    }
}

public enum LivePrivilege: Int, Hashable {
    case unknown // = 0
    case anonymous // = 1
    case employee // = 2
    case chat // = 3
    case custom // = 4
    case other // = 5
}

public enum LiveLayout: Int, Hashable {
    case unknown // = 0
    case list // = 1

    ///gallery
    case gallery // = 2
    case simple // = 3

    ///portrait
    case portrait // = 4
    case float // = 5 camera float on content
    case focus // = 6 content only (if has, otherwise camera only)
    case speaker // = 7 meeting speaker
}

extension LiveInfo: CustomStringConvertible {

    public var description: String {
        String(
            indent: "LiveInfo",
            "liveId: \(liveID)",
            "isLiving: \(isLiving)",
            "liveVote: \(liveVote)",
            "sid: \(sid)"
        )
    }
}

extension LiveVote: CustomStringConvertible {
    public var description: String {
        String(indent: "LiveVote",
               "voteId: \(voteID)",
               "isVoting: \(isVoting)",
               "reason: \(reason)",
               "sponsorId: \(sponsorID)"
        )
    }
}
