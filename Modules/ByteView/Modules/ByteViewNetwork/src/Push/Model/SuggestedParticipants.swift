//
//  SuggestedParticipants.swift
//  ByteViewNetwork
//
//  Created by wulv on 2022/6/6.
//

import Foundation
import RustPB

/// - PUSH_SUGGESTED_PARTICIPANTS = 2397
/// - Videoconference_V1_InMeetingSuggestedParticipantsChanged
public struct InMeetingSuggestedParticipantsChanged: Equatable {

    public var meetingID: String

    public var suggestedParticipants: [Participant] = []

    public var declinedParticipants: [Participant] = []

    public var sipRooms: [String: CalendarInfo.CalendarRoom] = [:]

    /// 初始拒绝列表人数
    public var initialDeclinedCount: Int64
    /// 建议参会人数据需要立即更新
    public var needImmediateUpdate: Bool

    public var preSetInterpreterParticipants: [Participant] = []

    init(meetingID: String, suggestedParticipants: [Participant], declinedParticipants: [Participant], sipRooms: [String: CalendarInfo.CalendarRoom], initialDeclinedCount: Int64, preSetInterpreterParticipants: [Participant], needImmediateUpdate: Bool) {
        self.meetingID = meetingID
        self.suggestedParticipants = suggestedParticipants
        self.declinedParticipants = declinedParticipants
        self.sipRooms = sipRooms
        self.initialDeclinedCount = initialDeclinedCount
        self.preSetInterpreterParticipants = preSetInterpreterParticipants
        self.needImmediateUpdate = needImmediateUpdate
    }
}

extension InMeetingSuggestedParticipantsChanged: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_InMeetingSuggestedParticipantsChanged
    init(pb: Videoconference_V1_InMeetingSuggestedParticipantsChanged) {
        self.meetingID = pb.meetingID
        self.suggestedParticipants = pb.suggestedParticipants.map { $0.vcType(meetingID: pb.meetingID) }
        self.declinedParticipants = pb.declinedParticipants.map { $0.vcType(meetingID: pb.meetingID) }
        self.sipRooms = pb.sipRooms.mapValues { $0.toCalendarRoom() }
        self.initialDeclinedCount = pb.initialDeclinedCount
        self.needImmediateUpdate = pb.needImmediateUpdate
        self.preSetInterpreterParticipants = pb.preSetInterpreterParticipants.map { $0.vcType(meetingID: meetingID) }
    }
}

extension InMeetingSuggestedParticipantsChanged: CustomStringConvertible {
    public var description: String {
        String(indent: "InMeetingSuggestedParticipantsChanged",
               "meetingID: \(meetingID)",
               "suggestedParticipants: \(suggestedParticipants)",
               "declinedParticipants: \(declinedParticipants)",
               "sipRooms.count: \(sipRooms.keys.count)",
               "initialDeclinedCount: \(initialDeclinedCount)",
               "preSetInterpreterParticipants: \(preSetInterpreterParticipants)",
               "needImmediateUpdate: \(needImmediateUpdate)"
        )
    }
}
