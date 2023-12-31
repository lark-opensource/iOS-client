//
//  EventDeleteProtocol.swift
//  Calendar
//
//  Created by heng zhu on 2019/3/13.
//
import Foundation
import CalendarFoundation
import RxSwift
import RustPB

protocol EventDeleteProtocol {
    var isRecurrence: Bool { get }
    var isEditable: Bool { get }
    var isLocalEvent: Bool { get }
    var canDeleteAll: Bool { get }
    var attendeeUnableDelete: Bool { get }
    var organizerUnableDelete: Bool { get }
    var isMeeting: Bool { get }
    var hasMeetingMinuteUrl: Bool { get }
    var isException: Bool { get }
    var calendarId: String { get }
    var notificationType: NotificationType { get }
    var key: String { get }
    var startTime: Int64 { get }
    var eventId: String { get }
    var isCrossTenant: Bool { get }
    var thirdPartyAttendeeCount: Int { get }
    var mtgroomCount: Int { get }
    var span: Rust.Span? { get }
    var isMeetingLiving: Bool { get }
}

struct EventDeleteModel: EventDeleteProtocol {
    var isCrossTenant: Bool
    var eventId: String
    var isRecurrence: Bool
    var isEditable: Bool
    var isLocalEvent: Bool
    var attendeeUnableDelete: Bool
    var organizerUnableDelete: Bool
    var canDeleteAll: Bool
    var isException: Bool
    var calendarId: String
    var notificationType: NotificationType
    var isMeeting: Bool
    var isMeetingLiving: Bool
    var key: String
    var startTime: Int64
    var hasMeetingMinuteUrl: Bool
    var thirdPartyAttendeeCount: Int
    var mtgroomCount: Int
    var span: Rust.Span?

    static func eventDeleteModel(event: CalendarEventEntity, instance: CalendarEventInstanceEntity, isException: Bool, isMeeting: Bool, isMeetingLiving: Bool = false, span: Rust.Span? = nil) -> EventDeleteProtocol {
        let thirdPartyAttendeeCount = event.visibleAttendees().filter({ $0.isThirdParty }).count
        var isRecurrence = event.isRecurrence()

        let undecryptable = event.displayType == .undecryptable
        let disableEncrypt = event.getPBModel().disableEncrypt
        let eventCanDeleteAll = event.getPBModel().isDeletable == .all

        //参与者日程秘钥失效
        let attendeeUnableDelete = (undecryptable || disableEncrypt) && !eventCanDeleteAll

        //组织者日程秘钥失效
        let organizerUnableDelete = (undecryptable || disableEncrypt) && eventCanDeleteAll

        return EventDeleteModel(isCrossTenant: event.isCrossTenant,
                                eventId: event.serverID,
                                isRecurrence: event.isRecurrence(),
                                isEditable: instance.isEditable,
                                isLocalEvent: event.isLocalEvent(),
                                attendeeUnableDelete: attendeeUnableDelete,
                                organizerUnableDelete: organizerUnableDelete,
                                canDeleteAll: event.canDeleteAll(),
                                isException: isException,
                                calendarId: event.calendarId,
                                notificationType: event.notificationType,
                                isMeeting: isMeeting,
                                isMeetingLiving: isMeetingLiving,
                                key: event.key,
                                startTime: instance.startTime,
                                hasMeetingMinuteUrl: !event.docsToken.isEmpty,
                                thirdPartyAttendeeCount: thirdPartyAttendeeCount,
                                mtgroomCount: event.meetingRoomArray().count,
                                span: span)
    }

}
