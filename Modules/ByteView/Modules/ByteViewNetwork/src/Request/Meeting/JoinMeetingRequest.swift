//
//  JoinMeetingRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 加入会议
/// - JOIN_MEETING = 2333
/// - Videoconference_V1_JoinMeetingRequest
///
/// 目前， 有这几种会议发起的方式：
/// - (C1) 在1v1的聊天中发起1v1会议（可能会被升级成多人会议）- CreateVideoChatRequest
/// - (C2) 在群聊中发起会议 - CreateVideoChatRequest
/// - (C3) 通过日历详情页发起会议 - JoinCalendarGroupMeetingRequest
/// - (C4) 通过日历群发起会议 - JoinCalendarGroupMeetingRequest
/// - (C5) View Room创建会议 - CreateVideoChatRequest
/// - (C6) Docs 唤起lark创建会议
/// 
/// 加入会议的方式包含:
/// - (J1) 接受邀请 (1v1或者多人会议的邀请) - UpdateVideoChatRequest
/// - (J2) 通过会议卡片的形式加入会议 - PreviewJoinVideoChatRequest
/// - (J3) 通过日历卡片的形式加入会议 - JoinCalendarGroupMeetingRequest
/// - (J4) 通过日历详情卡片的形式加入会议 - JoinCalendarGroupMeetingRequest
/// - (J5) 通过会议号的形式加入会议 - JoinByMeetingNumberRequest
/// - (J6) 通过会议链接加入会议 (新增)
/// - (J7) 通过群上方视频按钮加入会议 （新增）
/// - (J8) 加入语音聊天室
/// - (J9) 通过预约ID加入会议
public struct JoinMeetingRequest {
    public static let command: NetworkCommand = .rust(.joinMeeting)
    public typealias Response = JoinMeetingResponse

    public init(joinType: JoinType, selfParticipantInfo: SelfParticipantInfo, topicInfo: TopicInfo?,
                targetToJoinTogether: ByteviewUser?,
                webinarBecomeParticipantOffer: Bool? = nil,
                isE2EeMeeting: Bool? = nil,
                joinedDevicesLeaveInMeeting: Bool? = nil) {
        self.joinType = joinType
        self.selfParticipantInfo = selfParticipantInfo
        self.topicInfo = topicInfo
        self.targetToJoinTogether = targetToJoinTogether
        self.webinarBecomeParticipantOffer = webinarBecomeParticipantOffer
        self.isE2EeMeeting = isE2EeMeeting
        self.joinedDevicesLeaveInMeeting = joinedDevicesLeaveInMeeting
    }

    /// 入会类型 (场景信息)
    public var joinType: JoinType

    /// 自身参会信息
    public var selfParticipantInfo: SelfParticipantInfo

    public var topicInfo: TopicInfo?

    public var targetToJoinTogether: ByteviewUser?

    public var webinarBecomeParticipantOffer: Bool?

    public var isE2EeMeeting: Bool?

    public var joinedDevicesLeaveInMeeting: Bool?

    public enum JoinType: Equatable {
        case meetingId(String, JoinSource?)
        case groupId(String)
        case meetingNumber(String)
        case reserveId(String)
        // 本地case
        case interviewId(String)
        case uniqueId(String)
    }

    public enum JoinSourceType: Int {
        case unknown // = 0

        /// 通过视频会议卡片入会
        case card // = 1

        /// 通过群组右上角绿色图标入会
        case chat // = 2

        /// 通过独立tab入会
        case tab // = 3

        /// 通过日程会议开始通知入会
        case calendarNotice // = 4

        /// 通过会中等候室入会
        case lobby // = 5

        /// 通过会前等候室入会
        case preLobby // = 6
    }

    public struct JoinSource: Equatable {
        /// 入会来源
        public var sourceType: JoinSourceType

        /// source_type为CARD时需要赋值，对应视频会议卡片消息的ID
        public var messageID: String

        /// source_type为CHAT时需要赋值，对应会话ID。source_type为CARD时需要赋值，对应视频会议卡片消息存在的会话id
        public var chatID: String

        public init(sourceType: JoinSourceType = .unknown, messageID: String? = nil, chatID: String? = nil) {
            self.sourceType = sourceType
            self.messageID = messageID ?? ""
            self.chatID = chatID ?? ""
        }
    }

    public struct TopicInfo {
        public init(topic: String, isCustomized: Bool) {
            self.topic = topic
            self.isCustomized = isCustomized
        }

        public var topic: String

        public var isCustomized: Bool
    }

    public struct SelfParticipantInfo {
        public init(participantType: ParticipantType, participantSettings: UpdatingParticipantSettings) {
            self.participantType = participantType
            self.participantSettings = participantSettings
        }

        public var participantType: ParticipantType

        public var participantSettings: UpdatingParticipantSettings
    }
}

/// JoinMeetingResponse
public struct JoinMeetingResponse {
    public var type: TypeEnum

    public var videoChatInfo: VideoChatInfo?

    public var lobbyInfo: LobbyInfo?

    public enum TypeEnum: Int, Equatable {
        case unknown // = 0
        case success // = 1
        case vcBusy // = 2
        case voipBusy // = 3
        case participantLimitExceed // = 4
        case meetingEnded // = 5
        case meetingOutOfDate // = 6
        case meetingNeedExtension // = 7
        case versionLow // = 8
        case meetingNumberInvalid // = 9

        /// 当前设备在响铃状态
        case deviceRinging // = 10

        /// 会议已被锁定
        case meetingLocked // = 11

        /// 群禁言，无权限发起视频会议
        case chatPostNoPermission // = 12

        /// 租户被拉入黑名单，不能发起视频会议
        case tenantInBlacklist // = 13

        /// 会议发起人不是认证租户,此时禁止游客入会(Neo中使用)
        case meetingNumberNotCertificated // = 14

        /// 会中有不兼容的端(lark中暂时用不到，为了和neo保持一致)
        case versionIncompatible // = 15

        /// 同步入会目标无效
        case invalidTargetToJoinTogether // = 16
    }
}

extension JoinMeetingRequest.JoinType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .meetingId(let voucher, let joinSource):
            return "meetingId(\(voucher)), joinSource(\(joinSource))"
        case .groupId(let voucher):
            return "groupId(\(voucher))"
        case .meetingNumber(let voucher):
            return "meetingNumber(\(voucher))"
        case .reserveId(let voucher):
            return "reserveId(\(voucher))"
        case .interviewId(let voucher):
            return "interviewId(\(voucher))"
        case .uniqueId(let voucher):
            return "uniqueId(\(voucher))"
        }
    }

    public var value: String {
        switch self {
        case .meetingId(let voucher, _):
            return voucher
        case .groupId(let voucher):
            return voucher
        case .meetingNumber(let voucher):
            return voucher
        case .reserveId(let voucher):
            return voucher
        case .interviewId(let voucher):
            return voucher
        case .uniqueId(let voucher):
            return voucher
        }
    }
}

extension JoinMeetingRequest: CustomStringConvertible {

    public var description: String {
        String(
            indent: "JoinMeetingRequest",
            "joinType: \(joinType.description)",
            "selfParticipantInfo: \(selfParticipantInfo)",
            "targetToJoinTogether: \(targetToJoinTogether)",
            "joinedDevicesLeaveInMeeting: \(joinedDevicesLeaveInMeeting)"
        )
    }
}

extension JoinMeetingRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_JoinMeetingRequest
    func toProtobuf() throws -> Videoconference_V1_JoinMeetingRequest {
        var request = ProtobufType()
        let (t, handle) = joinType.pbType
        // 入会类型
        request.joinType = t
        // 入会凭证
        request.handle = handle
        // invitee
        request.invitee = ProtobufType.Invitee()
        //自身参会信息
        request.selfParticipantInfo = selfParticipantInfo.pbType
        // 入会来源（meetingID 入会需要）
        if case .meetingId(_, let s) = joinType, let joinSource = s {
            request.joinSource = joinSource.pbType
        }
        // 会议本身信息 (仅group 入会时需要)
        if let topicInfo = topicInfo {
            var creationMetaData = ProtobufType.CreationMetaData()
            creationMetaData.type = .meet
            creationMetaData.topic = topicInfo.topic
            if topicInfo.isCustomized { // 用户自定义主题
                creationMetaData.meetingSettings = .init()
                creationMetaData.meetingSettings.topic = topicInfo.topic
            }
            request.creationMetaData = creationMetaData
        }
        if let target = targetToJoinTogether {
            request.targetToJoinTogether = target.pbType
        }
        if let webinarBecomeParticipantOffer = self.webinarBecomeParticipantOffer {
            request.selfParticipantInfo.participantSettings.attendeeSettings.becomeParticipantOffer = webinarBecomeParticipantOffer
        }
        // 是否是加密会议
        if let isE2EeMeeting = self.isE2EeMeeting {
            request.selfParticipantInfo.isE2EeMeeting = isE2EeMeeting
            request.creationMetaData.meetingSettings.isE2EeMeeting = isE2EeMeeting
        }
        if let joinedDevicesLeaveInMeeting = self.joinedDevicesLeaveInMeeting {
            request.joinedDevicesLeaveInMeeting = joinedDevicesLeaveInMeeting
        }
        return request
    }
}

extension JoinMeetingResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_JoinMeetingResponse
    init(pb: Videoconference_V1_JoinMeetingResponse) throws {
        self.type = .init(rawValue: pb.type.rawValue) ?? .unknown
        self.videoChatInfo = pb.hasVideoChatInfo ? pb.videoChatInfo.vcType : nil
        self.lobbyInfo = pb.hasJoinMeetingLobby ? pb.joinMeetingLobby.vcType : nil
    }
}

extension JoinMeetingRequest.JoinType {
    var pbType: (Videoconference_V1_JoinMeetingRequest.JoinType, Videoconference_V1_JoinMeetingRequest.Handle) {
        var handle = Videoconference_V1_JoinMeetingRequest.Handle()
        switch self {
        case .meetingId(let voucher, _):
            handle.meetingID = voucher
            return (.joinVcViaMeetingID, handle)
        case .groupId(let voucher):
            handle.groupID = voucher
            return (.joinVcViaGroupID, handle)
        case .meetingNumber(let voucher):
            handle.meetingNo = voucher
            return (.joinVcViaMeetingNumber, handle)
        case .reserveId(let voucher):
            handle.uniqueID = voucher
            return (.joinVcViaReserveID, handle)
        default:
            handle.uniqueID = ""
            return (.joinVcViaReserveID, handle)
        }
    }
}

extension JoinMeetingRequest.JoinSource {
    var pbType: Videoconference_V1_JoinMeetingRequest.JoinSource {
        var joinSource = Videoconference_V1_JoinMeetingRequest.JoinSource()
        joinSource.chatID = chatID
        joinSource.messageID = messageID
        joinSource.sourceType = Videoconference_V1_JoinMeetingRequest.JoinSource.SourceType(rawValue: sourceType.rawValue) ?? .unknownSource
        return joinSource
    }
}

private extension JoinMeetingRequest.SelfParticipantInfo {
    var pbType: Videoconference_V1_JoinMeetingRequest.SelfParticipantInfo {
        var info = Videoconference_V1_JoinMeetingRequest.SelfParticipantInfo()
        info.participantType = participantType.pbType
        info.participantSettings = participantSettings.pbType
        return info
    }
}
