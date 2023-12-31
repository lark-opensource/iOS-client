//
//  CalendarContent.swift
//  Kingfisher
//
//  Created by liuwanlin on 2018/3/26.
//

import Foundation
import RustPB

public typealias CalendarContent = RustPB.Basic_V1_CalendarContent

private extension Dictionary where Key == String {
    func unWrapper(by key: String) -> [String: Any]? {
        self[key] as? [String: Any]
    }

    func unWrapper(by paths: String...) -> [String: Any]? {
        var tmp: [String: Any] = self

        for key in paths {
            if let next = tmp[key] as? [String: Any] {
                tmp = next
            } else {
                return nil
            }
        }

        return tmp
    }
}

public struct CalendarBotCardContent: CalendarBotContent {
    public var showReplyInviterEntry: Bool {
        return self.pb.eventCard.showReplyInviterEntry
    }

    public var userInviteOperatorId: String? {
        return self.pb.eventCard.userInviteOperatorID.isEmpty ? nil : self.pb.eventCard.userInviteOperatorID
    }

    // for rsvp reply card
    public var inviteOperatorLocalizedName: String?

    public var meetingRoomsInfo: [(name: String, isDisabled: Bool)] {
        return Array(zip(pb.eventCard.meetingRooms, pb.eventCard.isMeetingRoomsDisabled))
    }

    /// 返回 dic["contents"]?["elements"]
    /// 没有 usdDic 的判定，需要使用的地方自行判定
    @inline(__always)
    private var dicContentElements: [String: Any]? {
        dic.unWrapper(by: "contents", "elements")
    }

    // 原始字段
    public var title: String {
        if self.useDic {
            return dic.unWrapper(by: "title", "elements", "title", "property")?["content"] as? String ?? ""
        }
        return ""
    }

    public var summary: String {
        if self.useDic {
            return dicContentElements?.unWrapper(by: "summary_content", "property")?["content"] as? String ?? ""
        }
        return self.pb.eventCard.summary
    }

    public var time: String {
        if self.useDic {
            return dicContentElements?.unWrapper(by: "time_content", "property")?["content"] as? String ?? ""
        }
        return ""
    }

    public var rrepeat: String? {
        if self.useDic {
            return dicContentElements?.unWrapper(by: "recurrence_content", "property")?["content"] as? String
        }
        return self.pb.eventCard.rrule
    }

    public var attendeeIDs: [String]? {
        if self.useDic {
            return dicContentElements?.unWrapper(by: "attendees_content")?["child_ids"] as? [String]
        }
        return self.pb.eventCard.attendeeUserIds
    }

    public var desc: String? {
        if self.useDic {
           return dicContentElements?.unWrapper(by: "description_content", "property")?["content"] as? String
        }
        return self.pb.eventCard.description_p
    }

    private var actionDic: [String: Any]? {
        return dicActionElements?.unWrapper(by: "accept", "action", "payload")
    }

    private var useDic: Bool {
        return self.pb.messageVersion == .v1 || self.pb.messageVersion == .v2
    }

    public var needAction: Bool {
        if self.useDic {
            return self.actionDic != nil
        }
        return self.pb.messageType != .eventDelete && !self.isInvalid
    }

    public var calendarId: String? {
        if self.useDic {
            return self.actionDic?["calendar_id"] as? String
        }
        return "\(self.pb.eventCard.calendarID)"
    }

    public var key: String? {
        if self.useDic {
            return self.actionDic?["key"] as? String
        }
        return self.pb.eventCard.eventKey
    }

    public var originalTime: Int? {
        if self.useDic {
            return self.actionDic?["original_time"] as? Int
        }
        return Int(self.pb.eventCard.originalTime)
    }

    public var location: String? {
        if self.useDic {
            return dicContentElements?.unWrapper(by: "location_content", "property")?["content"] as? String
        }
        return self.pb.eventCard.location
    }

    public var meetingRoom: String? {
        if self.useDic {
            return dicContentElements?.unWrapper(by: "meeting_room_content", "property")?["content"] as? String
        }
        return self.pb.eventCard.meetingRooms.joined(separator: "\n")
    }

    /// 返回 dic["contents"]?["elements"]
    /// 没有 usdDic 的判定，需要使用的地方自行判定
    @inline(__always)
    private var dicActionElements: [String: Any]? {
        dic.unWrapper(by: "actions", "elements")
    }

    public var acceptButtonColor: String? {
        if self.useDic {
            return dicActionElements?.unWrapper(by: "accept", "style")?["color"] as? String
        }
        return nil
    }

    public var declineButtonColor: String? {
        if self.useDic {
            return dicActionElements?.unWrapper(by: "decline", "style")?["color"] as? String
        }
        return nil
    }

    public var tentativeButtonColor: String? {
        if self.useDic {
            return dicActionElements?.unWrapper(by: "tentative", "style")?["color"] as? String
        }
        return nil
    }

    public var startTime: Int64? {
        if self.useDic {
            return dic["start_time"] as? Int64
        }
        return self.pb.eventCard.startTime
    }

    public var endTime: Int64? {
        if self.useDic {
            return dic["end_time"] as? Int64
        }
        return self.pb.eventCard.endTime
    }

    public var isAllDay: Bool? {
        if self.useDic {
            return dic["is_all_day"] as? Bool ?? false
        }
        return self.pb.eventCard.isAllDay
    }

    public var isAccepted: Bool {
        if self.useDic {
            return self.acceptButtonColor == self.selectedColorHex
        }
        return self.pb.eventCard.selfAttendeeStatus == .accept
    }

    public var isDeclined: Bool {
        if self.useDic {
            return self.declineButtonColor == self.selectedColorHex
        }
        return self.pb.eventCard.selfAttendeeStatus == .decline
    }

    public var isTentatived: Bool {
        if self.useDic {
            return self.tentativeButtonColor == self.selectedColorHex
        }
        return self.pb.eventCard.selfAttendeeStatus == .tentative
    }

    public var isOptional: Bool {
        if self.useDic {
            return false
        }
        return self.pb.eventCard.isOptional
    }

    public var isConflict: Bool {
        if self.useDic {
            return false
        }
        return self.pb.eventCard.conflictType == .normal
    }

    public var isRecurrenceConflict: Bool {
        if self.useDic {
            return false
        }
        return self.pb.eventCard.conflictType == .recurrence
    }

    public var conflictTime: Int64 {
        return self.pb.eventCard.conflictTime
    }

    public var messageType: Int? {
        if self.useDic {
            return nil
        }
        return self.pb.messageType.rawValue
    }

    public var eventId: String? {
        if self.useDic { return nil }
        return self.pb.eventCard.eventID
    }

    public var senderUserId: String? {
        if self.useDic { return nil }
        return self.pb.eventCard.senderUserID
    }

    public var isCrossTenant: Bool {
        if self.useDic { return false }
        return self.pb.eventCard.isCrossTenant
    }

    public var chatNames: [String: String] {
        if self.useDic { return [:] }
        return self.pb.eventCard.chatNames
    }

    public var attendeeCount: Int {
        return Int(self.pb.eventCard.attendeeCount)
    }

    public var richText: RustPB.Basic_V1_RichText? {
        return self.pb.eventCard.descRichText
    }

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
    public var relationTag: String? {
        if self.pb.eventCard.hasRelationTag,
           !self.pb.eventCard.relationTag.tagDataItems.isEmpty,
           let tagDataItem = self.pb.eventCard.relationTag.tagDataItems.first(where: { $0.reqTagType == .relationTag }) {
            return tagDataItem.textVal
        }
        return nil
    }

    // 附加字段
    public var selfId: String = ""

    public var isInvalid: Bool = false

    public var updatedDiff: CalendarBotContentUpdatedDiff?

    public var chattersForUserNames: [String: Basic_V1_Chatter] = [:]

    private let selectedColorHex = "#4699FF"
    private let unselectedColorHex = "#757575"

    private var pb: CalendarContent
    private var dic: [String: Any] = [:]

    public init(pb: CalendarContent) {
        self.pb = pb
        if let data = pb.payload.data(using: .utf8, allowLossyConversion: true),
           let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
            self.dic = json
        }

        self.isInvalid = pb.eventCard.cardStatus == .invalid

        if !self.isInvalid, pb.eventCard.hasCardInfoForDiff {
            self.updatedDiff = CalendarBotContentUpdatedDiff(
                startTime: pb.eventCard.cardInfoForDiff.startTime,
                endTime: pb.eventCard.cardInfoForDiff.endTime,
                isAllDay: pb.eventCard.cardInfoForDiff.isAllDay,
                rruleText: pb.eventCard.cardInfoForDiff.rrule,
                loctionText: pb.eventCard.cardInfoForDiff.location,
                meetingRoomTexts: pb.eventCard.cardInfoForDiff.meetingRooms
            )
        }
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
        return self.pb.eventCard.successorUserID.isEmpty ? nil : self.pb.eventCard.successorUserID
    }

    public var organizerUserID: String? {
        return self.pb.eventCard.organizerUserID.isEmpty ? nil : self.pb.eventCard.organizerUserID
    }

    public var creatorUserID: String? {
        return self.pb.eventCard.creatorUserID.isEmpty ? nil : self.pb.eventCard.creatorUserID
    }
}
