//
//  GeneralCalendarContent.swift
//  LarkModel
//
//  Created by heng zhu on 2019/2/26.
//

import Foundation
import RustPB

public typealias GeneralCalendarContent = RustPB.Basic_V1_GeneralCalendarContent

extension GeneralCalendarContent {
    public var isUnknownType: Bool {
        return self.calendarType == .unknown
    }
}

public struct GeneralCalendarBotCardContent: CalendarBotContent {
    public var showReplyInviterEntry: Bool {
        return false
    }

    public var rsvpCommentUserName: String?

    public var userInviteOperatorId: String? {
        return nil
    }

    public var inviteOperatorLocalizedName: String?

    public var title: String {
        return ""
    }

    public var time: String {
        return ""
    }

    public var acceptButtonColor: String? {
        return nil
    }

    public var declineButtonColor: String? {
        return nil
    }

    public var tentativeButtonColor: String? {
        return nil
    }

    public var messageType: Int? {
        return self.pb.calendarType.rawValue + 100
    }

    public var richText: RustPB.Basic_V1_RichText? {
        return nil
    }

    public var summary: String {
        return self.pb.eventCard.summary
    }

    public var rrepeat: String? {
        return self.pb.eventCard.rrule
    }

    public var attendeeIDs: [String]? {
        return self.pb.eventCard.attendeeChatterIds
    }

    public var desc: String? {
        return self.pb.eventCard.description_p
    }

    public var needAction: Bool {
        return self.pb.calendarType != .transferCalendarEvent
    }

    public var calendarId: String? {
        return "\(self.pb.eventCard.calendarID)"
    }

    public var key: String? {
        return self.pb.eventCard.key
    }

    public var selfId: String = ""

    public var originalTime: Int? {
        return Int(self.pb.eventCard.originalTime)
    }

    public var location: String? {
        return self.pb.eventCard.location
    }

    public var meetingRoom: String? {
        return self.pb.eventCard.meetingRooms.joined(separator: "\n")
    }

    public var meetingRoomsInfo: [(name: String, isDisabled: Bool)] {
        return Array(zip(self.pb.eventCard.meetingRooms, self.pb.eventCard.isMeetingRoomsDisabled))
    }

    public var startTime: Int64? {
        return self.pb.eventCard.startTime
    }

    public var endTime: Int64? {
        return self.pb.eventCard.endTime
    }

    public var isAllDay: Bool? {
        return self.pb.eventCard.isAllDay
    }

    public var isAccepted: Bool {
        return self.pb.eventCard.selfAttendeeStatus == 2
    }

    public var isDeclined: Bool {
        return self.pb.eventCard.selfAttendeeStatus == 4
    }

    public var isTentatived: Bool {
        return self.pb.eventCard.selfAttendeeStatus == 3
    }

    public var isOptional: Bool {
        return self.pb.eventCard.isOptional
    }

    public var isConflict: Bool {
        return self.pb.eventCard.conflictType == .normal
    }

    public var isRecurrenceConflict: Bool {
        return self.pb.eventCard.conflictType == .recurrence
    }

    public var conflictTime: Int64 {
        return self.pb.eventCard.conflictTime
    }

    public var eventId: String? {
        return self.pb.eventCard.id
    }

    public var senderUserId: String? {
        return self.pb.eventCard.senderID
    }

    public var isCrossTenant: Bool {
        return self.pb.eventCard.isCrossTenant
    }

    public var calendarType: Int {
        return self.pb.calendarType.rawValue + 100
    }

    public var chatNames: [String: String] {
        return self.pb.eventCard.chatNames
    }

    public var attendeeCount: Int {
        return Int(self.pb.eventCard.attendeeCount)
    }

    public var responderUserID: String? {
        switch self.pb.extraCardInfo {
        case let .rsvpCommentCardInfo(info): return info.responderUserID
        @unknown default: return nil
        }
    }

    public var relationTag: String? {
        return nil
    }

    // 附加字段

    public var isInvalid: Bool = false

    public var chattersForUserNames: [String: Basic_V1_Chatter] = [:]

    public var updatedDiff: CalendarBotContentUpdatedDiff?

    // webinar
    public var isWebinar: Bool {
        return self.pb.eventCard.isWebinar
    }
    public var speakerChatterIDs: [String] {
        return self.pb.eventCard.speakerChatterIds
    }
    public var speakerChatNames: [String: String] {
        return self.pb.eventCard.speakerChatNames
    }

    private var pb: GeneralCalendarContent

    public init(pb: GeneralCalendarContent) {
        self.pb = pb
    }

    public mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        guard let pb = entity.messages[message.id] else {
            return
        }

        var chatters = entity.chatChatters[pb.chatID]?.chatters ?? [:]
        // 话题转发卡片（合并转发等场景）需要展示日历卡片，此时chatter放在entity.chatters中，需要merge下
        chatters.merge(entity.chatters, uniquingKeysWith: { chatChatter, _ in chatChatter })
        chattersForUserNames = chatters
    }

    // 新增字段
    public var successorUserID: String? {
        return nil
    }

    public var organizerUserID: String? {
        return nil
    }

    public var creatorUserID: String? {
        return nil
    }
}
