//
//  CalendarEventEntityFromLocal.swift
//  Calendar
//
//  Created by jiayi zou on 2018/9/10.
//  Copyright © 2018 EE. All rights reserved.
//
import RustPB
import Foundation
import CalendarFoundation
import EventKit

struct CalendarEventEntityFromLocal: CalendarEventEntity {
    var isEventCreatorResigned: Bool = false

    var isEventOrganizerShow: Bool = false

    var eventAttendeeStatistics: EventAttendeeStatistics {
        return getPBModel().attendeeInfo
    }

    var schemaCollection: Rust.SchemaCollection? {
        return nil
    }

    var inviteOperatorLocalizedName: String = ""

    var shouldShowEditButton: Bool?

    var editButtonDisabled: Bool = false

    var isDeleteable: Bool?

    var isTransferable: Bool?

    var isVideoMeetingAvailable: Bool?

    var isCreatedByMeetingRoom: (strategy: Bool, requisition: Bool) = (false, false)

    var isReportable: Bool?

    var hasSuccessor: Bool = false

    var hasOrganizer: Bool = false

    var hasCreator: Bool = false

    var willCreatorAttend: Bool = false

    var willOrganizerAttend: Bool = false

    var willSuccessorAttend: Bool = false

    let videoMeeting: VideoMeeting? = nil
    var docsToken: String = ""

    var hasSelfAttendeeStatus: Bool {
        return localEvent.getSelfAttendee()?.participantStatus.toCalendarEvnetAttendeeStatus() != nil
    }

    var notificationType: NotificationType {
        get { return .defaultNotificationType }
        set { _ = newValue }
    }

    var isCrossTenant: Bool = false

    var successor: CalendarEventAttendeeEntity {
        return PBAttendee(pb: CalendarEventAttendee())
    }

    private var colorIndex: ColorIndex {
        if let cgColor = localEvent.calendar?.cgColor {
            return LocalCalHelper.getColor(color: cgColor)
        }
        assertionFailureLog()
        return .carmine
    }

    var docsDescription: String {
        get { return "" }
        set { _ = newValue }
    }

    func getPBModel() -> CalendarEvent {
        assertionFailureLog()
        return CalendarEvent()
    }

    func canDeleteAll() -> Bool {
        return isEditable
    }

    func getDataSource() -> DataSource {
        return .system
    }

    var id: String {
        get { return localEvent.eventIdentifier ?? "" }
        set {
            assertionFailureLog("you must not modify local event ID")
            _ = newValue
        }
    }

    var originalTime: Int64 {
        return Int64(localEvent.occurrenceDate?.timeIntervalSince1970 ?? 0)
    }

    //need further test

    /// 是否有完整编辑权限
    var isEditable: Bool {
        //优先使用系统权限, 如果不行则使用Plan B
        //前提条件：日历可修改
        //如果一个日程没有organizer，那么大概率是自己创建的日程（小概率是订阅的，但是那样日历不可修改）
        //或者organizer是自身
        //这里暂时先不考虑writer编辑的情况
        if let result = localEvent.value(forKey: "isEditable") as? Bool {
            return result
        }
        guard let calendar = localEvent.calendar else {
            return false
        }
        return calendar.allowsContentModifications &&
            ((localEvent.organizer == nil) || (localEvent.organizer?.isCurrentUser ?? false ))
    }

    var creatorCalendarId: String {
        get {
            //since EKevent don't have related parameter, DO NOT USE creatorCalendarID for local Events
            assertionFailureLog("you must not use local evevt creatorCalendarId")
            return ""
        }
        set {
            assertionFailureLog("you must not modify local event creatorCalendarId")
            _ = newValue
        }
    }

    var calendarId: String {
        get {
            return localEvent.calendar?.calendarIdentifier ?? ""
        }
        set {
            assertionFailureLog("you must not modify local event CalendarId")
            _ = newValue
        }
    }

    var organizerCalendarId: String {
        get {
            if let organizer = localEvent.organizer {
                return "\(organizer.hashValue)"
            }
            return "Do not have a organizer \(arc4random())"
        }
        set {
            assertionFailureLog("you must not modify local event organizerCalendarId")
            _ = newValue
        }
    }

    var organizer: CalendarEventAttendeeEntity {
        return PBAttendee(pb: CalendarEventAttendee())
    }

    var serverId: String {
        //assertionFailureLog("you must not use local event serverId")
        return "you must not use local event serverId"
    }

    var selfAttendeeStatus: CalendarEventAttendee.Status {
        return localEvent.getSelfAttendee()?.participantStatus.toCalendarEvnetAttendeeStatus() ?? .accept
    }

    var key: String {
        return ""
    }

    var userInviteOperatorID: String? {
        return nil
    }

    var color: Int32 {
        get {
            return getPBModel().calColor.backgroundColor
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var needUpdate: Bool {
        get {
            return false
        }
        set {
            assertionFailureLog("you must not modify local event needUpdate")
            _ = newValue
        }
    }

    var summary: String {
        get {
            return (localEvent.title ?? "").isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : localEvent.title
        }
        set {
            localEvent.title = newValue
        }
    }

    var summaryIsEmpty: Bool {
        return localEvent.title?.isEmpty ?? true
    }

    var description: String {
        get {
            return localEvent.notes ?? ""
        }
        set {
            localEvent.notes = newValue
        }
    }

    var isAllDay: Bool {
        get {
            return localEvent.isAllDay
        }
        set {
            localEvent.isAllDay = newValue
        }
    }

    var startTime: Int64 {
        get {
            return Int64(localEvent.startDate?.timeIntervalSince1970 ?? 0)
        }
        set {
            localEvent.startDate = Date(timeIntervalSince1970: TimeInterval(Int(newValue)))
        }
    }

    var startTimezone: String {
        get {
            return localEvent.timeZone?.identifier ?? ""
        }
        set {
            //all day event should use UTC
            localEvent.timeZone = localEvent.isAllDay ? TimeZone(secondsFromGMT: 0) : TimeZone(identifier: newValue)
        }
    }

    var endTime: Int64 {
        get {
            return Int64(localEvent.endDate?.timeIntervalSince1970 ?? 0)
        }
        set {
            localEvent.endDate = Date(timeIntervalSince1970: TimeInterval(Int(newValue)))
        }
    }

    var endTimezone: String {
        get {
            return localEvent.timeZone?.identifier ?? ""
        }
        set {
            //all day event should use UTC
            localEvent.timeZone = localEvent.isAllDay ? TimeZone(secondsFromGMT: 0) : TimeZone(identifier: newValue)
        }
    }

    var status: CalendarEvent.Status {
        return localEvent.status.toCalendarEventEntityStatus()
    }

    //WARNING: 因为不确定苹果内部逻辑，可能有坑！
    var rrule: String {
        get {
            if localEvent.hasRecurrenceRules {
                return localEvent.recurrenceRules?.first?.iCalendarString() ?? ""
            }
            return ""
        }
        set {
            let originalRruleStr = localEvent.recurrenceRules?.first?.iCalendarString() ?? ""
            if originalRruleStr != newValue && !newValue.isEmpty {
                localEvent.removeRecurrence()
                guard let newEKrrule = EKRecurrenceRule.recurrenceRuleFromString(newValue) else {
                    assertionFailureLog("invaild recurrenceRuleString: \(newValue)")
                    return
                }
                localEvent.addRecurrenceRule(newEKrrule)
            } else if newValue.isEmpty {
                localEvent.removeRecurrence()
            }
        }
    }

    var attendees: [CalendarEventAttendeeEntity] {
        get {
            var organizerHashValue = "0"
            if let organizer = localEvent.organizer {
                organizerHashValue = "\(organizer.url)"
            }
            return localEvent.attendees?.map({ (attendee) -> CalendarEventAttendeeEntity in
                AttendeeFromLocal(localAttendee: attendee, organizerHash: organizerHashValue)
            }) ?? []
        }
        set {
            assertionFailureLog("you must not modify local event attendees")
            _ = newValue
        }
    }

    var location: CalendarLocation {
        get {
            return localEvent.structuredLocation?.toCalendarLocation() ?? CalendarLocation()
        }
        set {
            localEvent.structuredLocation = EKStructuredLocation.fromCalendarLocation(location: newValue)
        }
    }

    var reminders: [Reminder] {
        get {
            guard let alarms = localEvent.alarms else { return [] }
            let reminders = alarms.map { (alarm) -> Reminder in
                return Reminder(minutes: Int32(-1 * alarm.relativeOffset / 60), isAllDay: localEvent.isAllDay)
            }
            return reminders
        }
        set {
            let alarms = newValue.map { (reminder) -> EKAlarm in
                return EKAlarm(relativeOffset: TimeInterval(reminder.minutes * -60))
            }
            localEvent.alarms = alarms
        }
    }

    var displayType: CalendarEvent.DisplayType {
        //目前我没有找到使用caldav方式订阅无权限日历的方法，如果有这里还要改~
        return localEvent.calendar?.type ?? .subscription == .subscription ? .limited : .full
    }

    var visibility: CalendarEvent.Visibility {
        //iOS不显示公开范围
        get {
            return .default
        }
        set {
            assertionFailureLog("you must not modify local event visibility")
            _ = newValue
        }
    }

    var isFree: Bool {
        get {
            return localEvent.availability == .free
        }
        set {
            if newValue {
                localEvent.availability = .free
            } else {
                localEvent.availability = .busy
            }
        }
    }

    var type: CalendarEvent.TypeEnum {
        get {
            return .defaultType
        }
        set {
            assertionFailureLog("you must not modify local event type")
            _ = newValue
        }
    }

    var source: CalendarEvent.Source {
        return .ios
    }

    var serverID: String {
        //assertionFailureLog("you must not user local event serverID")
        return "you must not user local event serverID"
    }

    var calColor: ColorIndex {
        //日程颜色和日历颜色一致
        return colorIndex
    }

    var eventColor: ColorIndex {
        //日程颜色和日历颜色一致
        get {
            return colorIndex
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var guestCanInvite: Bool {
        return false
    }

    var guestCanModify: Bool {
        return false
    }

    var guestCanSeeOtherGuests: Bool {
        return true
    }

    var isSharable: Bool {
        return false
    }

    var creator: CalendarEventAttendeeEntity {
        //localEvent 没有creater
//        assertionFailureLog("you must not use local event creator")
        return PBAttendee(pb: CalendarEventAttendee())
    }

    var category: CalendarEvent.Category {
        return .defaultCategory
    }

    var attachments: [CalendarEventAttachmentEntity] = []

    var isEventCreatorShow = false

    func getTitle() -> String {
        return self.summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : self.summary
    }

    func visibleAttendees() -> [CalendarEventAttendeeEntity] {
        return self.attendees.filter({ !$0.isResource && !($0.status == .removed) })
    }

    func isOrganizer(primaryCalendarId: String) -> Bool {
        return localEvent.organizer?.isCurrentUser ?? false
    }

    func isRecurrence() -> Bool {
        return (localEvent.recurrenceRules?.count ?? 0) > 0
    }

    func isException() -> Bool {
        return localEvent.isDetached
    }

    func isRepetitive() -> Bool {
        return self.isRecurrence() || self.isException()
    }


    private var localEvent: EKEvent

    init(event: EKEvent) {
        self.localEvent = event
    }

    func debugMessage() -> String {
        return """
        eventID: \(self.id),
        startTime: \(Date(timeIntervalSince1970: TimeInterval(startTime))),
        startTimeZone: \(startTimezone),
        endTime:  \(Date(timeIntervalSince1970: TimeInterval(endTime))),
        endTimezone: \(endTimezone),

        calendarId: \(calendarId),
        freebusy: \(isFree),
        self attendee status: \(selfAttendeeStatus)
        """
    }

}

extension CalendarEventEntityFromLocal {
    func getEKEvent() -> EKEvent? {
        return localEvent
    }
}

extension EKEvent {
    func removeRecurrence() {
        for rrule in self.recurrenceRules ?? [] {
            self.removeRecurrenceRule(rrule)
        }
    }

    func getSelfAttendee() -> EKParticipant? {
        return self.attendees?.first(where: { (attendee) -> Bool in
            return attendee.isCurrentUser
        })
    }
}

extension EKParticipantStatus {
    func toCalendarEvnetAttendeeStatus() -> CalendarEventAttendee.Status {
        switch self {
        case .accepted:
            return .accept
        case .declined:
            return .decline
        case .tentative:
            return .tentative
        case .pending:
            return .needsAction
        default:
            return .needsAction
        }
    }
}

extension EKEventStatus {
    func toCalendarEventEntityStatus() -> CalendarEventEntity.Status {
        switch self {
        case .confirmed:
            return .confirmed
        case .tentative:
            return .tentative
        case .none:
            return .tentative
        case .canceled:
            return .canceled
        @unknown default:
            assertionFailureLog()
            return .tentative
        }
    }
}

extension EKStructuredLocation {
    func toCalendarLocation() -> CalendarLocation {
        var location = CalendarLocation()
        location.location = self.title ?? ""
        location.address = "" //没有对应的选项，如果硬要要只能通过经纬度去找
        location.latitude = Float(self.geoLocation?.coordinate.latitude ?? 360)
        location.longitude = Float(self.geoLocation?.coordinate.longitude ?? 360)
        return location
    }

    static func fromCalendarLocation(location: CalendarLocation) -> EKStructuredLocation {
        let ekLocation = EKStructuredLocation(title: location.location)
        if location.hasLatitude {
            ekLocation.geoLocation = CLLocation(latitude: CLLocationDegrees(location.latitude),
                                                longitude: CLLocationDegrees(location.longitude))
        }
        return ekLocation
    }
}
