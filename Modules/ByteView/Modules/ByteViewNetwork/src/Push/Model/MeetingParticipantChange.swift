//
//  MeetingParticipantChange.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 参会人变化
/// - PUSH_MEETING_PARTICIPANT_CHANGE = 87101
/// - Videoconference_V1_MeetingParticipantChange
public struct MeetingParticipantChange: Equatable {

    /// 端上判断是不是现在的meeting的兜底
    public var meetingID: String
    public var upsertParticipants: [Participant]
    public var removeParticipants: [Participant]
    /// 参会人角色
    public var role: Participant.MeetingRole
    /// 观众人数，仅非观众角色需要关注
    public var attendeeNum: Int64?
}

extension MeetingParticipantChange: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_MeetingParticipantChange
    public init(pb: Videoconference_V1_MeetingParticipantChange) {
        let meetingID = pb.meetingID
        self.meetingID = meetingID
        self.upsertParticipants = pb.upsertParticipants.map({ $0.vcType(meetingID: meetingID) })
        self.removeParticipants = pb.removeParticipants.map({ $0.vcType(meetingID: meetingID) })
        self.role = Participant.MeetingRole(rawValue: pb.role.rawValue) ?? .participant
        self.attendeeNum = pb.hasAttendeeNum ? pb.attendeeNum : nil
    }
}
