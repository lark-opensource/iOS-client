//
//  LobbyParticipant.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VCLobbyParticipant
public struct LobbyParticipant: Equatable {

    public init(meetingId: String, interactiveId: String, user: ByteviewUser,
                isMicrophoneMuted: Bool?, isCameraMuted: Bool?,
                isStatusWait: Bool, isInApproval: Bool, isLarkGuest: Bool,
                joinLobbyTime: Int64, nickName: String, leaveReason: LeaveReason,
                tenantId: String, tenantTag: TenantTag, bindId: String, bindType: PSTNInfo.BindType,
                seqID: Int64, targetToJoinTogether: ByteviewUser?, pstnMainAddress: String?,
                participantMeetingRole: Participant.MeetingRole, joinResaon: JoinReason,
                moveOperator: ByteviewUser, inMeetingName: String,
                participantSettings: ParticipantSettings) {
        self.meetingId = meetingId
        self.interactiveId = interactiveId
        self.user = user
        self.isMicrophoneMuted = isMicrophoneMuted
        self.isCameraMuted = isCameraMuted
        self.isStatusWait = isStatusWait
        self.isInApproval = isInApproval
        self.joinLobbyTime = joinLobbyTime
        self.isLarkGuest = isLarkGuest
        self.nickName = nickName
        self.leaveReason = leaveReason
        self.tenantId = tenantId
        self.tenantTag = tenantTag
        self.bindId = bindId
        self.bindType = bindType
        self.seqId = seqID
        self.targetToJoinTogether = targetToJoinTogether
        self.pstnMainAddress = pstnMainAddress
        self.participantMeetingRole = participantMeetingRole
        self.joinReason = joinResaon
        self.moveOperator = moveOperator
        self.inMeetingName = inMeetingName
        self.participantSettings = participantSettings
    }

    public var meetingId: String

    public var interactiveId: String

    public var user: ByteviewUser

    /// 麦克风开/关
    public var isMicrophoneMuted: Bool?

    /// 摄像头开/关
    public var isCameraMuted: Bool?

    /// 用户是否位于等候室
    public var isStatusWait: Bool

    public var isInApproval: Bool

    /// 加入等候室的时间，单位ms
    public var joinLobbyTime: Int64

    /// 用户虚拟名称
    public var nickName: String

    /// 是不是匿名游客, 1是，0不是, 版本问题类型改不掉了 产品决定叫游客，技术侧统一命名
    public var isLarkGuest: Bool

    /// 离开等候室原因
    public var leaveReason: LeaveReason

    /// 参会人所属租户ID
    public var tenantId: String

    public var tenantTag: TenantTag

    public var bindId: String

    public var bindType: PSTNInfo.BindType

    public var seqId: Int64

    /// 同步入会的参会人（等候室）
    public var targetToJoinTogether: ByteviewUser?

    /// pstn info里的main address，用作type是SIP/PSTN/H323的去重
    public var pstnMainAddress: String?

    /// 会议中角色 participant_role_settings = 19; // participant的身份信息，嘉宾或者观众
    public var participantMeetingRole: Participant.MeetingRole

    /// 进入等候室原因
    public var joinReason: JoinReason

    /// 将user转移到等候室的操作者
    public var moveOperator: ByteviewUser

    /// 会中改名
    public var inMeetingName: String

    /// 参会者设置 将req里面的信息再返回给端上，主要是为了端上两个窗口间数据同步
    public var participantSettings: ParticipantSettings

    public enum LeaveReason: Int, Hashable {
        case unknown // = 0
        case hearbeatExpire // = 1
        case exit // = 2
        case hostReject // = 3
        case meetingEnd // = 4
        case hostApprove // = 5
        case vcNotSupportLobby // = 6
    }

    public enum JoinReason: Int, Hashable {
        case unknownJoinReason // = 0
        case hostMove // = 1
    }
}

extension LobbyParticipant: CustomStringConvertible {
    public var description: String {
        String(
            indent: "LobbyParticipant",
            "meetingId: \(meetingId)",
            "interactiveId: \(interactiveId)",
            "user: \(user)",
            "Settings(mic=\(isMicrophoneMuted?.toInt), cam=\(isCameraMuted?.toInt), wait=\(isStatusWait.toInt), approval=\(isInApproval.toInt))",
            "joinLobbyTime: \(joinLobbyTime)",
            "guest: \(isLarkGuest)",
            "leaveReason: \(leaveReason)",
            "tenantTag: \(tenantTag)",
            "tenantId: \(tenantId)",
            "pstn: (\(bindType), \(bindId))",
            "seqId: \(seqId)",
            "targetToJoinTogether: \(targetToJoinTogether)",
            "pstnMainAddress: \(pstnMainAddress)",
            "meetingRole: \(participantMeetingRole)",
            "joinReason: \(joinReason)",
            "moveOperator: \(moveOperator)",
            "inMeetingName=\(inMeetingName.hashValue),count=\(inMeetingName.count)"
        )
    }
}
