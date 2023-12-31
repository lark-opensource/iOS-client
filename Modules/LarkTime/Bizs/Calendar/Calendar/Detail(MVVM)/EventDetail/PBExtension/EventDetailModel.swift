//
//  EventDetailModel.swift
//  Calendar
//
//  Created by Rico on 2021/4/20.
//

import Foundation
import EventKit
import RustPB
import LarkContainer
import CalendarFoundation
/*
 三种数据源
 1. 系统本地日程
 2. 飞书服务端日程（lark + 三方）
 3. 会议室无权限的日程
 */

enum EventDetailModel {
    /// 本地日程
    case local(EKEvent)
    /// 非本地普通PB日程
    case pb(EventDetail.Event, EventDetail.Instance)
    /// 会议室无权限日程
    case meetingRoomLimit(RoomViewInstance)
}

extension EventDetailModel {

    var isThirdParty: Bool {
        switch self {
        case let .pb(event, _): return event.dt.isThirdParty
        default: return false
        }
    }

    var startTime: Int64 {
        switch self {
        case let .local(event): return Int64(event.startDate?.timeIntervalSince1970 ?? 0)
        case let .pb(_, instance): return instance.startTime
        case let .meetingRoomLimit(instance): return instance.startTime
        }
    }

    var endTime: Int64 {
        switch self {
        case let .local(event): return Int64(event.endDate?.timeIntervalSince1970 ?? 0)
        case let .pb(_, instance): return instance.endTime
        case let .meetingRoomLimit(instance): return instance.endTime
        }
    }

    var displayType: EventDetail.Event.DisplayType {
        switch self {
        case let .local(event):
            //目前我没有找到使用caldav方式订阅无权限日历的方法，如果有这里还要改~
            return event.calendar?.type ?? .subscription == .subscription ? .limited : .full
        case let .pb(event, _): return event.displayType
        case .meetingRoomLimit: return .full
        }
    }

    var reminderCount: Int {
        switch self {
        case let .local(local): return local.alarms?.count ?? 0
        case let .pb(event, _): return event.reminders.count
        case .meetingRoomLimit: return 0
        }
    }

    var location: CalendarLocation {
        switch self {
        case let .local(local): return local.structuredLocation?.toCalendarLocation() ?? CalendarLocation()
        case let .pb(event, _): return event.location
        case .meetingRoomLimit: return CalendarLocation()
        }
    }

    var visibility: EventDetail.Event.Visibility {
        switch self {
        case .local: return .default
        case let .pb(event, _): return event.visibility
        case .meetingRoomLimit: return .default
        }
    }

    var calendarId: String {
        switch self {
        case let .local(local): return local.calendar?.calendarIdentifier ?? ""
        case let .pb(event, _): return event.calendarID
        case let .meetingRoomLimit(instance): return instance.currentUserAccessibleCalendarID
        }
    }

    var key: String {
        switch self {
        case .local: return ""
        case let .pb(event, _): return event.key
        case let .meetingRoomLimit(instance): return instance.key
        }
    }

    var originalTime: Int64 {
        switch self {
        case let .local(local): return Int64(local.occurrenceDate?.timeIntervalSince1970 ?? 0)
        case let .pb(event, _): return event.originalTime
        case let .meetingRoomLimit(instance): return instance.originalTime
        }
    }

    var organizerCalendarId: String {
        switch self {
        case let .local(local): return "\(local.organizer.hashValue)"
        case let .pb(event, _): return event.organizerCalendarID
        case .meetingRoomLimit: return ""
        }
    }

    var creatorCalendarId: String {
        switch self {
        case .local: return ""
        case let .pb(event, _): return event.creatorCalendarID
        case .meetingRoomLimit: return ""
        }
    }

    var isLarkEvent: Bool {
        switch self {
        case .local: return false
        case let .pb(event, _): return !(event.source == .google) && !(event.source == .exchange)
        case .meetingRoomLimit: return true
        }
    }

    var displayTitle: String {
        switch self {
        case let .local(local):
            if displayType == .full {
                return (local.title ?? "").isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : (local.title ?? "")
            } else {
                return BundleI18n.Calendar.Calendar_Detail_Busy
            }
        case let .pb(event, _):
            return event.dt.displayTitle
        case let .meetingRoomLimit(instance):
            if instance.displayType == .undecryptable {
                return I18n.Calendar_EventExpired_GreyText
            } else if instance.pb.category == .resourceRequisition {
                return BundleI18n.Calendar.Calendar_Edit_MeetingRoomInactiveCantReserve
            } else if instance.pb.category == .resourceStrategy {
                return BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomCantReservePeriod
            } else if instance.pb.currentUserAccessibility == .summaryVisible {
                return instance.summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : instance.summary
            } else {
                return I18n.Calendar_Edit_MeetingRoomReserved
            }
        }
    }

    var shouldShowLocalActionBar: Bool {
        switch self {
        case .pb, .meetingRoomLimit: return false
        case let .local(ekEvent):
            // 本地rsvp暂时关闭
            return false
//            return (ekEvent.getSelfAttendee()?.participantStatus.toCalendarEvnetAttendeeStatus() ?? .accept) != .removed
//                && !(ekEvent.organizer?.isCurrentUser ?? false)
//                && ekEvent.getSelfAttendee() != nil
        }
    }

    var selfAttendeeStatus: CalendarEventAttendee.Status {
        switch self {
        case let .local(local): return local.getSelfAttendee()?.participantStatus.toCalendarEvnetAttendeeStatus() ?? .accept
        case let .pb(event, _): return event.selfAttendeeStatus
        case .meetingRoomLimit: return .decline
        }
    }

    var isFromGoogle: Bool {
        switch self {
        case let .pb(event, _): return event.dt.isFromGoogle
        default: return false
        }
    }

    var isFromExchange: Bool {
        switch self {
        case let .pb(event, _): return event.dt.isFromExchange
        default: return false
        }
    }

    func getCalendar(calendarManager: CalendarManager?) -> EventDetail.Calendar? {
        switch self {
        case .meetingRoomLimit, .pb:
            return calendarManager?.calendar(with: calendarId)
        case let .local(local):
            if let calendar = local.calendar {
                return CalendarFromLocal(localCalendar: calendar)
            } else {
                return nil
            }
        }
    }

    var readableRrule: String? {
        let rrule: String?
        switch self {
        case let .local(event): rrule = event.dt.rrule
        case let .pb(event, _): rrule = event.rrule
        case .meetingRoomLimit: rrule = nil
        }
        if let rRule = rrule.flatMap({ EKRecurrenceRule.recurrenceRuleFromString($0) }) {
            return rRule.getReadableString()
        }
        return nil
    }

    var isAllDay: Bool {
        switch self {
        case let .local(event): return event.isAllDay
        case let .pb(event, _): return event.isAllDay
        case let .meetingRoomLimit(instance): return instance.isAllDay
        }
    }

    var eventDescription: String {
        switch self {
        case .meetingRoomLimit: return ""
        case .local(let event): return event.notes ?? ""
        case .pb(let event, _): return event.description_p
        }
    }

    var docsDescription: String {
        switch self {
        case .meetingRoomLimit, .local: return ""
        case .pb(let event, _): return event.docsDescription
        }
    }

    var isRecurrence: Bool {
        switch self {
        case .meetingRoomLimit: return false
        case .pb(let event, _): return event.dt.isRecurrence
        case .local(let event): return event.dt.isRecurrence
        }
    }

    var isException: Bool {
        switch self {
        case .meetingRoomLimit: return false
        case .pb(let event, _): return event.dt.isException
        case .local(let event): return event.dt.isException
        }
    }

    var isWebinar: Bool {
        switch self {
        case .pb(let event, _):
            return event.category == .webinar
        default:
            return false
        }
    }

    var isMeetingLinkParsable: Bool {
        switch self {
        case .meetingRoomLimit, .local: return false
        case .pb(let event, _):
            if event.location.location.isEmpty && event.description_p.isEmpty { return false }
            if event.videoMeeting.videoMeetingType == .noVideoMeeting {
                EventDetail.logInfo("isMeetingLinkParsable, meetingType matched: true")
                return true
            } else {
                let sourceMatched = [.email, .exchange].contains(event.source)
                EventDetail.logInfo("isMeetingLinkParsable, source matched: \(sourceMatched)")
                return sourceMatched
            }
        }
    }
}

// MARK: - Attendees
extension EventDetailModel {
    var hasVisibleAttendees: Bool {
        return !visibleAttendees.isEmpty
    }

    var visibleAttendees: [CalendarEventAttendeeEntity] {
        let attendees: [CalendarEventAttendeeEntity]
        switch self {
        case let .local(event):
            var organizerHashValue = "0"
            if let organizer = event.organizer {
                organizerHashValue = "\(organizer.url)"
            }
            attendees = event.attendees?.map {
                AttendeeFromLocal(localAttendee: $0, organizerHash: organizerHashValue)
            } ?? []
        case let .pb(event, _):
            attendees = event.attendees.map {
                PBAttendee(pb: $0, displayOrganizerCalId: event.dt.realOrganizerCalId)
            }
        case .meetingRoomLimit:
            attendees = []
        }
        return attendees.filter { !$0.isResource && !($0.status == .removed) }
    }

    var sortedVisibleAttendees: [CalendarEventAttendeeEntity] {
        return visibleAttendees.sorted {
            type(of: $0).attendeeCompareable($0, $1)
        }
    }

    var visibleAttendeeCount: Int {
        switch self {
        case .local: return visibleAttendees.count
        case let .pb(event, _): return Int(event.attendeeInfo.totalNo)
        case .meetingRoomLimit: return 0
        }
    }

    var canDeleteAll: Bool {
        switch self {
        case .meetingRoomLimit: return false
        case let .pb(event, _): return event.isDeletable == .all
        case let .local(event): return event.dt.canDeleteAll
        }
    }

    var isFree: Bool {
        switch self {
        case .meetingRoomLimit: return false
        case let .local(event): return event.dt.isFree
        case let .pb(event, _): return event.isFree
        }
    }
}

// MARK: - Convenience Model

extension EventDetailModel {
    var localEvent: EKEvent? {
        switch self {
        case let .local(event): return event
        case .meetingRoomLimit, .pb: return nil
        }
    }

    var event: EventDetail.Event? {
        switch self {
        case .local, .meetingRoomLimit: return nil
        case let .pb(event, _): return event
        }
    }

    var instance: EventDetail.Instance? {
        switch self {
        case .local, .meetingRoomLimit: return nil
        case let .pb(_, instance): return instance
        }
    }

    var roomLimitInstance: RoomViewInstance? {
        switch self {
        case let .meetingRoomLimit(instance): return instance
        default: return nil
        }
    }

    var isRoomLimit: Bool {
        switch self {
        case .meetingRoomLimit: return true
        default: return false
        }
    }

    var isLocal: Bool {
        switch self {
        case .local: return true
        default: return false
        }
    }

    var isPb: Bool {
        switch self {
        case .pb: return true
        default: return false
        }
    }
}

//// compatibility
extension EventDetailModel {

    func shouldHideAttendees(for calendar: EventDetail.Calendar?) -> Bool {
        let canRead = (calendar?.canRead() ?? false)

        if self.displayType == .limited { return false }
        if canRead && self.calendarId == self.organizerCalendarId {
            return false
        }
        switch self {
        case .local: return false
        case let .pb(event, _):
            return !event.guestCanSeeOtherGuests
        case .meetingRoomLimit: return false
        }
    }
}

extension EventDetailModel: CustomStringConvertible, CustomDebugStringConvertible {

    var description: String {
        switch self {
        case let .local(event): return event.description
        case let .pb(event, instance): return event.dt.description + "instance: \(instance.startTime) - \(instance.endTime)"
        case let .meetingRoomLimit(instance): return "MeetingRoomLimit: \(instance.description)"
        }
    }

    // 仅调试用 不能用于线上
    var debugDescription: String {
        switch self {
        case let .local(event): return event.debugDescription
        case let .pb(event, instance): return event.debugDescription + "instance: \(instance.startTime) - \(instance.endTime)"
        case let .meetingRoomLimit(instance): return "MeetingRoomLimit: \(instance.debugDescription)"
        }
    }
}

extension EventDetailModel {

    var colorCombo: ColorCombo {
        let colorCombo: ColorCombo
        switch self {
        case .meetingRoomLimit:
            // 会议室无权限日程固定灰色
            colorCombo = ColorCombo.colorCombo(fromColorIndex: .neutral)
        case let .local(event):
            if let color = event.calendar?.cgColor {
                colorCombo = ColorCombo.colorCombo(fromColorIndex: LocalCalHelper.getColor(color: color))
            } else {
                assertionFailureLog()
                colorCombo = ColorCombo.colorCombo(fromColorIndex: .carmine)
            }
        case let .pb(event, ins):
            let isThirdPartyType = (event.source == .exchange || event.source == .google)
            let isStrategy = event.category == .resourceStrategy
            let isRequisition = event.category == .resourceRequisition
            let accessRole = ins.calAccessRole
            let isLimitAceessRole = accessRole == .freeBusyReader || accessRole == .unknownAccessRole
            let useEventColor = !event.colorIndex.isNoneColor && (!isThirdPartyType || isStrategy || isRequisition) && !isLimitAceessRole
            if event.displayType == .undecryptable {
                colorCombo = ColorCombo.colorCombo(fromColorIndex: .neutral)
            } else {
                colorCombo = ColorCombo.colorCombo(fromColorIndex: useEventColor ? event.colorIndex : event.calColorIndex)
            }
        }
        return colorCombo
    }

    var auroraColor: AuroraEventDetailColor {
        colorCombo.auroraEventDetailColor
    }

}
