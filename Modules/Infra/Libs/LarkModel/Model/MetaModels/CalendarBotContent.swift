//
//  CalendarBotContent.swift
//
//
//  Created by 朱衡 on 2019/3/7.
//

import Foundation
import RustPB

public struct CalendarBotContentUpdatedDiff {
    public var startTime: Int64
    public var endTime: Int64
    public var isAllDay: Bool
    public var rruleText: String?
    public var loctionText: String?
    public var meetingRoomTexts: [String]
}

public protocol CalendarBotContent: MessageContent {
    var title: String { get }
    var summary: String { get }
    var time: String { get }
    var rrepeat: String? { get }
    var attendeeIDs: [String]? { get }
    var desc: String? { get }
    var needAction: Bool { get }
    var calendarId: String? { get }

    var key: String? { get }

    var originalTime: Int? { get }

    var location: String? { get }

    var meetingRoom: String? { get }

    var meetingRoomsInfo: [(name: String, isDisabled: Bool)] { get }

    var acceptButtonColor: String? { get }

    var declineButtonColor: String? { get }

    var tentativeButtonColor: String? { get }

    var startTime: Int64? { get }

    var endTime: Int64? { get }

    var isAllDay: Bool? { get }

    var isAccepted: Bool { get }

    var isDeclined: Bool { get }

    var isTentatived: Bool { get }

    var isOptional: Bool { get }

    var isConflict: Bool { get }

    var isRecurrenceConflict: Bool { get }

    var conflictTime: Int64 { get }

    var messageType: Int? { get }

    var eventId: String? { get }

    var senderUserId: String? { get }

    var isCrossTenant: Bool { get }

    var chatNames: [String: String] { get }

    var attendeeCount: Int { get }

    var richText: RustPB.Basic_V1_RichText? { get }

    var selfId: String { get set }

    var showReplyInviterEntry: Bool { get }

    var userInviteOperatorId: String? { get }

    var inviteOperatorLocalizedName: String? { get }

    var isInvalid: Bool { get }

    var updatedDiff: CalendarBotContentUpdatedDiff? { get }

    var relationTag: String? { get }

    // 专门给 senderUserName attendeeNames rsvpCommentUserName 计算用
    // 因为上层有FG控制逻辑，不能在LarkModel里面做，所以把chatter抛出去，业务自己使用
    var chattersForUserNames: [String: Basic_V1_Chatter] { get }

    // webinar
    var isWebinar: Bool { get }
    // webinar 嘉宾（个人）的 id
    var speakerChatterIDs: [String] { get }
    // webinar 嘉宾（群）的 id:name
    var speakerChatNames: [String: String] { get }

    var successorUserID: String? { get }
    
    var organizerUserID: String? { get }

    var creatorUserID: String? { get }
}
