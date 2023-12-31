//
//  InMeetingUpdateMessage.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 全量参会人
/// - PUSH_MEETING_INFO = 87103
/// - TRIG_PUSH_FULL_MEETING_INFO = 87102
/// - Videoconference_V1_InMeetingUpdateMessage
public struct InMeetingUpdateMessage {

    public let meetingID: String
    public let participants: [Participant]
    public let viewList: WebinarAttendeeViewList?
    /// 观众人数
    public var webinarAttendeeNum: Int64?
    /// 观众列表
    public var webinarAttendeeList: [Participant] = []
}

extension InMeetingUpdateMessage: CustomStringConvertible {

    public var description: String {
        let participantsInfo: String
        if participants.count > 10 {
            participantsInfo = "count=\(participants.count)"
        } else {
            participantsInfo = "\(participants)"
        }

        return String(
            indent: "InMeetingUpdateMessage",
            "meetingID: \(meetingID)",
            "participants: \(participantsInfo)"
        )
    }
}

extension InMeetingUpdateMessage: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_InMeetingUpdateMessage
    public init(pb: Videoconference_V1_InMeetingUpdateMessage) {
        let meetingID = pb.meetingID
        self.meetingID = meetingID
        self.participants = pb.participants.map({ $0.vcType(meetingID: meetingID) })
        self.viewList = WebinarAttendeeViewList(panels: pb.webinarViewList.map { $0.vcType(meetingID: meetingID) })
        self.webinarAttendeeNum = pb.hasWebinarAttendeeNum ? pb.webinarAttendeeNum : nil
        self.webinarAttendeeList = pb.webinarAttendeeList.map { $0.vcType(meetingID: meetingID) }
    }
}
