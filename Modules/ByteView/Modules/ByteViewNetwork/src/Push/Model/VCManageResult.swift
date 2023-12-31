//
//  VCManageResult.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Videoconference_V1_VCManageResult
/// -  PUSH_VC_MANAGE_RESULT = 89344
public struct VCManageResult: Equatable {
    public init(meetingID: String, type: TypeEnum, action: Action, vcLobbyParticipant: LobbyParticipant?) {
        self.meetingID = meetingID
        self.type = type
        self.action = action
        self.vcLobbyParticipant = vcLobbyParticipant
    }

    public var meetingID: String

    public var type: TypeEnum

    public var action: Action

    public var vcLobbyParticipant: LobbyParticipant?

    public enum TypeEnum: Int, Hashable {
        case unknown // = 0

        /// 会议等候室
        case meetinglobby // = 1
        case meetingprelobby // = 2
        case breakoutRoomNeedHelp // = 3
        case breakoutRoomCountDown // = 4
        case interviewCoding // = 5
        case inMeetingChatChange // = 6
    }

    public enum Action: Int, Hashable {
        case unknown = 0

        /// 主持人拒绝请求
        case hostreject = 1

        /// 会议结束
        case meetingend = 2

        /// 主持人批准请求
        case hostallowed = 3

        /// 会议不支持该能力
        case vcMeetingNotSupport = 6

        /// 会议已开启，会前等候室推送使用
        case meetingStart = 7

        case moveToLobby = 10

        case inMeetingChatEnable = 11

        case inMeetingChatDisable = 12
    }
}

extension VCManageResult: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VCManageResult
    init(pb: Videoconference_V1_VCManageResult) {
        self.init(meetingID: pb.meetingID, type: .init(rawValue: pb.type.rawValue) ?? .unknown,
                  action: .init(rawValue: pb.action.rawValue) ?? .unknown, vcLobbyParticipant: pb.hasVcLobbyParticipant ? pb.vcLobbyParticipant.vcType : nil)
    }
}

extension VCManageResult: CustomStringConvertible {
    public var description: String {
        String(indent: "VCManageResult",
               "meetingId: \(meetingID)",
               "type: \(type)",
               "action: \(action)"
        )
    }
}
