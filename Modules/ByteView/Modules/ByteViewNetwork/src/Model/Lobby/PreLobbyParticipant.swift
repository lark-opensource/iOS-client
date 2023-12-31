//
//  PreLobbyParticipant.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 会前等候室成员信息
/// - Videoconference_V1_VCPreLobbyParticipant
public struct PreLobbyParticipant: Equatable {
    public init(meetingId: String, isStatusWait: Bool, user: ByteviewUser,
                isLarkGuest: Bool, joinLobbyTime: Int64, leaveReason: LeaveReason,
                targetToJoinTogether: ByteviewUser?,
                participantMeetingRole: Participant.MeetingRole,
                participantSettings: ParticipantSettings) {
        self.meetingId = meetingId
        self.isStatusWait = isStatusWait
        self.user = user
        self.isLarkGuest = isLarkGuest
        self.joinLobbyTime = joinLobbyTime
        self.leaveReason = leaveReason
        self.targetToJoinTogether = targetToJoinTogether
        self.participantMeetingRole = participantMeetingRole
        self.participantSettings = participantSettings
    }

    public var meetingId: String

    /// 用户是否位于等候室
    public var isStatusWait: Bool

    public var user: ByteviewUser

    /// 是不是匿名游客, 1是, 空指针或者其他值(包括空值)表示不是匿名游客
    public var isLarkGuest: Bool

    /// 加入等候室的时间，单位ms
    public var joinLobbyTime: Int64

    /// 离开等候室原因
    public var leaveReason: LeaveReason

    /// 同步入会的参会人（等候室）
    public var targetToJoinTogether: ByteviewUser?

    public var participantMeetingRole: Participant.MeetingRole

    /// 参会者设置 将req里面的信息再返回给端上，主要是为了端上两个窗口间数据同步
    public var participantSettings: ParticipantSettings

    public enum LeaveReason: Int, Hashable {
        case unknown // = 0
        case leave // = 1
        case meetingStart // = 2
        case heartbeatStop // = 3
    }
}

extension PreLobbyParticipant: CustomStringConvertible {
    public var description: String {
        String(
            indent: "PreLobbyParticipant",
            "meetingId: \(meetingId)",
            "user: \(user)",
            "Settings(wait=\(isStatusWait.toInt))",
            "joinLobbyTime: \(joinLobbyTime)",
            "guest: \(isLarkGuest)",
            "leaveReason: \(leaveReason)",
            "targetToJoinTogether: \(targetToJoinTogether)"
        )
    }
}
