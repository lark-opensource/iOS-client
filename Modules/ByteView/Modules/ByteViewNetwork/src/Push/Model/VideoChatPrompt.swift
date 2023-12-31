//
//  VideoChatPrompt.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 推送提醒
/// - PUSH_VIDEO_CHAT_PROMPT = 2371
/// - Videoconference_V1_VideoChatPrompt
public struct VideoChatPrompt {

    public var type: TypeEnum

    public var action: Action

    public var promptID: String

    /// 服务端推送的sid，打点用
    public var pushSid: String

    public var calendarStartPrompt: CalendarStartPrompt?

    public enum TypeEnum: Int, Hashable {
        case unknown // = 0

        /// 日程会议的入会提醒
        case calendarStart // = 1

    }

    public enum Action: Int, Hashable {
        case unknown // = 0
        case show // = 1
        case dismiss // = 2
    }

    public struct CalendarStartPrompt: Equatable {

        /// 日程id
        public var uniqueID: String

        /// 会议id
        public var meetingID: String

        /// 日程开始时间
        public var eventStartTime: Int64

        /// 日程标题
        public var eventTitle: String

        /// 第一个入会的user
        public var startUser: ByteviewUser

        /// 提醒生成时间
        public var promptCreateTime: Int64

        public var subtype: MeetingSubType

        public var backupHostUids: [String]

        public var interpreterUids: [String]

        public var role: Participant.MeetingRole
    }
}

extension VideoChatPrompt: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VideoChatPrompt
    init(pb: Videoconference_V1_VideoChatPrompt) {
        self.promptID = pb.promptID
        self.type = .init(rawValue: pb.type.rawValue) ?? .unknown
        self.action = .init(rawValue: pb.action.rawValue) ?? .unknown
        self.pushSid = pb.pushSid
        self.calendarStartPrompt = pb.hasCalendarStartPrompt ? CalendarStartPrompt(pb: pb.calendarStartPrompt) : nil
    }
}

extension VideoChatPrompt.CalendarStartPrompt: ProtobufDecodable {
    typealias ProtobufType = Videoconference_V1_VideoChatPrompt.CalendarStartPrompt
    init(pb: Videoconference_V1_VideoChatPrompt.CalendarStartPrompt) {
        self.uniqueID = pb.uniqueID
        self.meetingID = pb.meetingID
        self.eventStartTime = pb.eventStartTime
        self.eventTitle = pb.eventTitle
        self.startUser = pb.startUser.vcType
        self.promptCreateTime = pb.promptCreateTime
        self.subtype = pb.subType.vcType
        self.backupHostUids = pb.backupHostUids
        self.interpreterUids = pb.interpreterUids
        self.role = Participant.MeetingRole(rawValue: pb.role.rawValue) ?? .participant
    }
}

extension VideoChatPrompt: CustomStringConvertible {
    public var description: String {
        String(indent: "VideoChatPrompt",
               "promptId: \(promptID)",
               "type: \(type)",
               "action: \(action)",
               "pushSid: \(pushSid)",
               "calendar: \(calendarStartPrompt)"
        )
    }
}

extension VideoChatPrompt.CalendarStartPrompt: CustomStringConvertible {
    public var description: String {
        String(indent: "CalendarStartPrompt",
               "meetingId: \(meetingID)",
               "uniqueId: \(uniqueID)",
               "startTime: \(eventStartTime)",
               "createTime: \(promptCreateTime)",
               "startUser: \(startUser)",
               "subtype: \(subtype.rawValue)",
               "backupHostUids: \(backupHostUids)",
               "interpreterUids: \(interpreterUids)"
        )
    }
}
