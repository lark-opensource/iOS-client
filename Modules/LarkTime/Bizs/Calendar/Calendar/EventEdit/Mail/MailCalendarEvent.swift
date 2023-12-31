//
//  MailCalendarEvent.swift
//  Calendar
//
//  Created by Rico on 2022/3/28.
//

/*
 这里主要是为了定义和桥接邮件传递的MailCalendarEvent
 */
import Foundation
import RustPB

public typealias MailCalendarEvent = (
    Calendar_V1_CalendarBasicEvent,
    Calendar_V1_CalendarLocation,
    [Calendar_V1_CalendarEventAttendee],
    Calendar_V1_VideoMeeting,
    Calendar_V1_CalendarEventRef,
    [Calendar_V1_CalendarEventReminder]
)

extension Rust.Event {

    func toMailEvent() -> MailCalendarEvent {
        (extractBasicEvent(),
         location,
         attendees.filter { $0.category == .resource },
         videoMeeting,
         extractEventRef(),
         reminders)
    }

    static func from(mailEvent: MailCalendarEvent) -> Self {
        var event = Rust.Event.from(basicEvent: mailEvent.0,
                                    eventRef: mailEvent.4)
        event.location = mailEvent.1
        event.attendees = mailEvent.2
        event.videoMeeting = mailEvent.3
        event.reminders = mailEvent.5
        return event
    }

    // 下面四个方法，新填字段要同步
    static func from(basicEvent: Calendar_V1_CalendarBasicEvent,
                     eventRef: Calendar_V1_CalendarEventRef) -> Self {
        var event = Rust.Event()
        // 透传
        event.serverID = basicEvent.eventID
        event.key = basicEvent.uniqueKey
        event.originalEventKey = basicEvent.originalEvent
        event.originalTime = basicEvent.originalTime
        event.creatorCalendarID = basicEvent.creatorCalendarID
        event.organizerCalendarID = basicEvent.organizerCalendarID
        event.summary = basicEvent.summary
        event.rrule = basicEvent.rrule
        event.startTime = basicEvent.start
        event.startTimezone = basicEvent.startTimezone
        event.endTime = basicEvent.end
        event.endTimezone = basicEvent.endTimezone
        event.status = basicEvent.status
        event.source = basicEvent.source
        event.attendeeSource = basicEvent.attendeeSource
        event.successorCalendarID = basicEvent.successorCalendarID
        event.isAllDay = basicEvent.isAllDay
        event.isCrossTenant = basicEvent.isCrossTenant
        event.guestCanModify = basicEvent.guestsCanModify
        event.guestCanInvite = basicEvent.guestsCanInviteOthers
        event.guestCanSeeOtherGuests = basicEvent.guestsCanSeeOtherGuests
        // 逻辑场景特化
        event.attendeeInfo.allIndividualAttendee = true

        event.id = eventRef.id
        event.calendarID = eventRef.calendarID
        event.selfAttendeeStatus = eventRef.selfAttendeeStatus
        event.colorIndex = eventRef.colorIndex
        event.version = Int32(eventRef.version)
        event.visibility = eventRef.visibility
        event.isFree = eventRef.isFree

        return event
    }

    private func extractBasicEvent() -> Calendar_V1_CalendarBasicEvent {
        var basicEvent = Calendar_V1_CalendarBasicEvent()
        basicEvent.eventID = self.serverID
        basicEvent.uniqueKey = self.key
        if basicEvent.uniqueKey.isEmpty {
            // 邮件特化逻辑
            basicEvent.uniqueKey = UUID().uuidString
        }
        basicEvent.originalEvent = self.originalEventKey
        basicEvent.originalTime = self.originalTime
        basicEvent.creatorCalendarID = self.creatorCalendarID
        basicEvent.organizerCalendarID = self.organizerCalendarID
        basicEvent.summary = self.summary
        basicEvent.rrule = self.rrule
        basicEvent.start = self.startTime
        basicEvent.startTimezone = self.startTimezone
        basicEvent.end = self.endTime
        basicEvent.endTimezone = self.endTimezone
        basicEvent.status = self.status
        basicEvent.source = self.source
        basicEvent.attendeeSource = self.attendeeSource
        basicEvent.successorCalendarID = self.successorCalendarID
        basicEvent.isAllDay = self.isAllDay
        basicEvent.isCrossTenant = self.isCrossTenant
        basicEvent.guestsCanModify = self.guestCanModify
        basicEvent.guestsCanInviteOthers = self.guestCanInvite
        basicEvent.guestsCanSeeOtherGuests = self.guestCanSeeOtherGuests
        return basicEvent
    }

    private func extractEventRef() -> Calendar_V1_CalendarEventRef {
        var eventRef = Calendar_V1_CalendarEventRef()
        eventRef.id = self.id
        eventRef.calendarID = self.calendarID
        eventRef.selfAttendeeStatus = self.selfAttendeeStatus
        eventRef.colorIndex = self.colorIndex
        eventRef.version = Int64(self.version)
        eventRef.visibility = self.visibility
        eventRef.isFree = self.isFree
        return eventRef
    }
}

// 邮件传递的日程
extension EventEditInput {
    static func from(mode: EventEditMode) -> Self {
        switch mode {
        case .create: return .createWithContext(EventCreateContext())
        case let .edit(mailEvent):
            let event = Rust.Event.from(mailEvent: mailEvent)
            // 这里借用详情页生成Instance的逻辑
            var instance = event.dt.makeInstance(with: nil, startTime: event.startTime, endTime: event.endTime)
            // 邮件可编辑始终为true。
            // 处理本地创建后，实际日程还没有创建出来，只是一堆组合数据，此时邮件再次进入编辑，isEditable字段不可信
            instance.isEditable = true
            return .editFrom(pbEvent: event, pbInstance: instance)
        }
    }
}
