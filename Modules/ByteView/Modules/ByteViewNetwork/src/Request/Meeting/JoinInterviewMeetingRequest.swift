//
//  JoinInterviewMeetingRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 加入面试会议
/// - JOIN_INTERVIEW_GROUP_MEETING =2342
/// - Videoconference_V1_JoinInterviewGroupMeetingRequest
public struct JoinInterviewMeetingRequest {
    public static let command: NetworkCommand = .rust(.joinInterviewGroupMeeting)
    public typealias Response = JoinInterviewMeetingResponse

    /// - parameter uniqueId: people申请面试房间时生成的uniqueID，从URL中解析出来
    public init(uniqueId: String, participantSettings: UpdatingParticipantSettings, role: Participant.Role?, joinedDevicesLeaveInMeeting: Bool?) {
        self.uniqueId = uniqueId
        self.participantSettings = participantSettings
        self.role = role
        self.joinedDevicesLeaveInMeeting = joinedDevicesLeaveInMeeting
    }

    /// people申请面试房间时生成的uniqueID，从URL中解析出来
    public var uniqueId: String
    public var participantSettings: UpdatingParticipantSettings
    public var role: Participant.Role?
    public var audioMode: ParticipantSettings.AudioMode?
    public var mobileCallingStatus: ParticipantSettings.MobileCallingStatus?
    public var joinedDevicesLeaveInMeeting: Bool?
}

/// Videoconference_V1_JoinInterviewGroupMeetingResponse
public struct JoinInterviewMeetingResponse {
    public init(videoChatInfo: VideoChatInfo?, lobbyInfo: LobbyInfo?) {
        self.videoChatInfo = videoChatInfo
        self.lobbyInfo = lobbyInfo
    }
    public var videoChatInfo: VideoChatInfo?
    public var lobbyInfo: LobbyInfo?
}

extension JoinInterviewMeetingRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_JoinInterviewGroupMeetingRequest
    func toProtobuf() throws -> Videoconference_V1_JoinInterviewGroupMeetingRequest {
        var request = ProtobufType()
        request.interviewUniqueID = uniqueId
        request.partiType = .larkUser
        // 多设备入会，弃用forceDeblock该参数
        request.force = false
        if let role = role {
            request.role = .init(rawValue: role.rawValue) ?? .unknowRole
        }
        request.participantSettings = participantSettings.pbType
        if let joinedDevicesLeaveInMeeting = joinedDevicesLeaveInMeeting {
            request.joinedDevicesLeaveInMeeting = joinedDevicesLeaveInMeeting
        }
        return request
    }
}

extension JoinInterviewMeetingResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_JoinInterviewGroupMeetingResponse
    init(pb: Videoconference_V1_JoinInterviewGroupMeetingResponse) throws {
        self.videoChatInfo = pb.hasVideoChatInfo ? pb.videoChatInfo.vcType : nil
        self.lobbyInfo = pb.hasJoinMeetingLobby ? pb.joinMeetingLobby.vcType : nil
    }
}
