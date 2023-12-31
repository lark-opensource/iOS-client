//
//  EventShareModelImpl.swift
//  Calendar
//
//  Created by zoujiayi on 2019/6/26.
//

import Foundation
import LarkModel
import RustPB

struct EventShareModelImpl: ShareEventCardModel {

    var content: EventShareContent
    let message: LarkModel.Message
    let chatId: String

    init(content: EventShareContent,
         message: LarkModel.Message,
         chatId: String) {
        self.content = content
        self.message = message
        self.chatId = chatId
    }

    var isJoined: Bool {
        get { return content.isJoined }
        set { content.isJoined = newValue }
    }

    var isInvalid: Bool {
        get { return content.isInvalid }
        set { content.isInvalid = newValue }
    }

    var eventID: String { return content.eventID }

    var hasReaction: Bool { return !message.reactions.isEmpty }

    var calendarID: String { return content.calendarID }

    var key: String { return content.key }

    var originalTime: Int { return content.originalTime }

    var messageId: String { return content.messageId }

    var startTime: Int64? { return content.startTime }

    var endTime: Int64? { return content.endTime }

    var isAllDay: Bool? { return content.isAllDay }

    var isShowConflict: Bool { return content.isShowConflict }

    var isShowRecurrenceConflict: Bool { return content.isShowRConflict }

    var conflictTime: Int64 { return content.conflictTime }

    var color: Int32 { return content.color }

    var title: String { return content.title }

    var location: String? {
        if content.location.isEmpty {
            return nil
        }
        return content.location
    }

    var meetingRoom: String? {
        if content.meetingRoom.isEmpty {
            return nil
        }
        return content.meetingRoom
    }

    var desc: String { return content.description }

    var rrule: String? {
        if content.rrepeat.isEmpty {
            return nil
        }
        return content.rrepeat
    }

    var attendeeNames: [String] { return content.attendeeNames }

    var isCrossTenant: Bool { return content.isCrossTenant }

    var isWebinar: Bool { return content.isWebinar }

    var status: CalendarEventAttendee.Status {
        get {
            return content.status
        }
        set {
            content.status = newValue
        }
    }

    var currentUsersMainCalendarId: String {
        return content.currentUserMainCalendarId
    }

    var relationTag: String? {
        if isCrossTenant {
            return BundleI18n.Calendar.Calendar_Detail_External
        }
        return nil
    }
}
