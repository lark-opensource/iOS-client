//
//  JoinCalendarMeetingRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/11/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 加入日历视频会议
/// - JOIN_CALENDAR_GROUP_MEETING = 2217
/// - Videoconference_V1_JoinCalendarGroupMeetingRequest
public struct JoinCalendarMeetingRequest {
    public static let command: NetworkCommand = .rust(.joinCalendarGroupMeeting)
    public typealias Response = JoinCalendarMeetingResponse

    /// - parameter uniqueId: 日历申请meetingNO时，视频会议分配个日历的一个UID
    public init(uniqueId: String, entrySource: EntrySource,
                participantSettings: UpdatingParticipantSettings,
                targetToJoinTogether: ByteviewUser?,
                calendarInstanceIdentifier: CalendarInstanceIdentifier?,
                joinedDevicesLeaveInMeeting: Bool?) {
        self.uniqueId = uniqueId
        self.entrySource = entrySource
        self.participantSettings = participantSettings
        self.targetToJoinTogether = targetToJoinTogether
        self.calendarInstanceIdentifier = calendarInstanceIdentifier
        self.joinedDevicesLeaveInMeeting = joinedDevicesLeaveInMeeting
    }

    /// 日历申请meetingNO时，视频会议分配个日历的一个UID
    public var uniqueId: String
    public var entrySource: EntrySource
    public var participantSettings: UpdatingParticipantSettings
    public var targetToJoinTogether: ByteviewUser?
    public var calendarInstanceIdentifier: CalendarInstanceIdentifier?
    public var joinedDevicesLeaveInMeeting: Bool?

    public enum EntrySource: Int, Equatable {
        case fromUnknown // = 0
        case fromCalendarDetail // = 1
        case fromCard // = 2
        case fromGroup // = 3
    }
}

public struct JoinCalendarMeetingResponse {
    public init(type: TypeEnum, videoChatInfo: VideoChatInfo?, lobbyInfo: LobbyInfo?) {
        self.type = type
        self.videoChatInfo = videoChatInfo
        self.lobbyInfo = lobbyInfo
    }

    public var type: TypeEnum
    public var videoChatInfo: VideoChatInfo?
    public var lobbyInfo: LobbyInfo?

    public enum TypeEnum: Int, Equatable {
        case unknown // = 0
        case calendarSuccess // = 1
        case calendarVcBusy // = 2
        case calendarVoipBusy // = 3
        case calendarMeetingEnded // = 4
        case calendarParticipantLimitExceed // = 5

        /// 会议number已回收，不可延长 @陈可蓉 文案
        case calendarMeetingOutOfDate // = 6

        /// 会议number已回收，但可以续约延长
        case calendarMeetingNeedExtension // = 7

        /// 新增字段，版本低
        case calendarVersionLow // = 8

        /// 同步入会的目标信息
        case invalidTargetToJoinTogether // = 9
    }
}

extension JoinCalendarMeetingRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_JoinCalendarGroupMeetingRequest
    func toProtobuf() throws -> Videoconference_V1_JoinCalendarGroupMeetingRequest {
        var request = ProtobufType()
        request.uniqueID = uniqueId
        request.entrySource = .init(rawValue: entrySource.rawValue) ?? .fromUnknown
        request.partiType = .larkUser
        request.participantSettings = participantSettings.pbType
        if let target = targetToJoinTogether {
            request.targetToJoinTogether = target.pbType
        }
        if let calendarInstance = calendarInstanceIdentifier {
            request.calendarInstanceIdentifier = calendarInstance.pbType
        }
        if let joinedDevicesLeaveInMeeting = joinedDevicesLeaveInMeeting {
            request.joinedDevicesLeaveInMeeting = joinedDevicesLeaveInMeeting
        }
        return request
    }
}

extension JoinCalendarMeetingResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_JoinCalendarGroupMeetingResponse
    init(pb: Videoconference_V1_JoinCalendarGroupMeetingResponse) throws {
        self.type = .init(rawValue: pb.type.rawValue) ?? .unknown
        self.videoChatInfo = pb.hasVideoChatInfo ? pb.videoChatInfo.vcType : nil
        self.lobbyInfo = pb.hasJoinMeetingLobby ? pb.joinMeetingLobby.vcType : nil
    }
}
