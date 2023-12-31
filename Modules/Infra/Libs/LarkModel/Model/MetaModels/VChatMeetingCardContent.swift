//
//  VChatMeetingCardContent.swift
//  LarkModel
//
//  Created by chentao on 2019/3/4.
//

import Foundation
import RustPB
import LKCommonsLogging

public struct VChatMeetingCardContent: MessageContent {
    static let logger = Logger.log(VChatMeetingCardContent.self)
    public typealias PBModel = RustPB.Basic_V1_Message
    public typealias MeetingParticipant = RustPB.Basic_V1_VideoChatContent.MeetingCard.MeetingParticipant
    public typealias Status = RustPB.Basic_V1_VideoChatContent.MeetingCard.Status
    public typealias MeetingSource = RustPB.Basic_V1_VideoChatContent.MeetingCard.MeetingSource
    public typealias MeetingCard = RustPB.Basic_V1_VideoChatContent.MeetingCard
    typealias MeetingSubtype = RustPB.Videoconference_V1_VideoChatSettings.SubType
    public typealias ParticipantType = MeetingCard.ParticipantType
    public let meetingID: String
    public let status: Status
    public let topic: String
    public let sponsorID: String
    public let startTimeMs: Int64
    public let participants: [MeetingParticipant]
    public let meetingSource: MeetingSource
    public let calendarUid: String
    public let endTimeMs: Int64
    public let hostID: String
    public let meetNumber: String
    public let maxParticipantCount: Int32
    public let isLocked: Bool
    public let meetingOwnerId: String?
    public let meetingOwnerType: ParticipantType?
    public let totalParticipantNum: Int64
    public let webinarAttendeeNum: Int
    public let allParticipantTenant: [Int64]
    public let isCrossWithKa: Bool
    public let meetingSubtype: Int32
    public let chatID: String
    public let messageID: String

    public init(
        meetingId: String,
        status: Status,
        topic: String,
        sponsorId: String,
        startTime: Int64,
        participants: [MeetingParticipant],
        meetingSource: MeetingSource = .cardFromUser,
        calendarUid: String = "",
        endTime: Int64 = 0,
        hostId: String = "",
        meetNumber: String = "",
        maxParticipantCount: Int32 = 0,
        isLocked: Bool = false,
        meetingOwnerId: String? = nil,
        meetingOwnerType: ParticipantType? = nil,
        totalParticipantNum: Int64,
        webinarAttendeeNum: Int,
        allParticipantTenant: [Int64],
        isCrossWithKa: Bool,
        meetingSubtype: Int32,
        chatID: String,
        messageID: String
        ) {
        self.meetingID = meetingId
        self.status = status
        self.topic = topic
        self.sponsorID = sponsorId
        self.startTimeMs = startTime
        self.meetingSource = meetingSource
        self.calendarUid = calendarUid
        self.participants = participants
        self.endTimeMs = endTime
        self.hostID = hostId
        self.meetNumber = meetNumber
        self.maxParticipantCount = maxParticipantCount
        self.isLocked = isLocked
        self.meetingOwnerId = meetingOwnerId
        self.meetingOwnerType = meetingOwnerType
        self.totalParticipantNum = totalParticipantNum
        self.webinarAttendeeNum = webinarAttendeeNum
        self.allParticipantTenant = allParticipantTenant
        self.isCrossWithKa = isCrossWithKa
        self.meetingSubtype = meetingSubtype
        self.chatID = chatID
        self.messageID = messageID
        Self.logger.debug("init VChatMeetingCardContent topicLength:\(topic.count) status:\(status), meetingID:\(meetingID), chatID:\(chatID), messageID: \(messageID), meetingSubtype: \(meetingSubtype)")
    }

    public init(meetingCard: MeetingCard, chatID: String, messageID: String) {
        self.init(
            meetingId: meetingCard.meetingID,
            status: meetingCard.status,
            topic: meetingCard.topic,
            sponsorId: meetingCard.sponsorID,
            startTime: meetingCard.startTimeMs,
            participants: meetingCard.participants,
            meetingSource: meetingCard.meetingSource,
            calendarUid: meetingCard.calendarUid,
            endTime: meetingCard.endTimeMs,
            hostId: meetingCard.hostID,
            meetNumber: meetingCard.meetNumber,
            maxParticipantCount: meetingCard.maxParticipantCount,
            isLocked: (meetingCard.isLocked && !meetingCard.isOpenLobby),
            meetingOwnerId: meetingCard.hasOwnerUserID ? meetingCard.ownerUserID : nil,
            meetingOwnerType: meetingCard.hasOwnerType ? meetingCard.ownerType : nil,
            totalParticipantNum: meetingCard.totalParticipantNum,
            webinarAttendeeNum: Int(meetingCard.webinarAttendeeNum),
            allParticipantTenant: meetingCard.allParticipantTenant,
            isCrossWithKa: meetingCard.isCrossWithKa,
            meetingSubtype: meetingCard.meetingSubType,
            chatID: chatID,
            messageID: messageID
        )
    }

    public static func transform(pb: PBModel) -> VChatMeetingCardContent {
        let content = pb.content.videochatContent.meetingCard
        let chatID = pb.chatID
        return VChatMeetingCardContent(meetingCard: content, chatID: chatID, messageID: pb.id)
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {}

    public var isWebinar: Bool { Int(meetingSubtype) == MeetingSubtype.webinar.rawValue }
}
