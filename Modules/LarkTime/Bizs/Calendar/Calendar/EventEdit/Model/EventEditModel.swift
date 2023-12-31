//
//  EventEditModel.swift
//  Calendar
//
//  Created by 张威 on 2020/2/13.
//

import CalendarFoundation
import EventKit
import LarkLocationPicker
import RustPB
import LarkContainer

typealias EventEditAttachment = CalendarEventAttachmentEntity
struct EventEditModel {
    typealias PBModel = RustPB.Calendar_V1_CalendarEvent

    private let pb: PBModel
    private var ekEvent: EKEvent?

    var calendar: EventEditCalendar?
    var summary: String?
    var startDate: Date = Date()
    var endDate: Date = Date()
    var isAllDay: Bool = false
    var color: ColorIndex? { customizedColor ?? calendar?.color }
    var visibility: EventVisibility = .default
    var freeBusy: EventFreeBusy = .busy
    var location: EventEditLocation?
    var attendees: [EventEditAttendee] = []
    var speakers: [EventEditAttendee] = []
    var audiences: [EventEditAttendee] = []
    var meetingRooms: [CalendarMeetingRoom] = []
    var reminders: [EventEditReminder] = []
    var rrule: EventRecurrenceRule?
    var attachments: [EventEditAttachment] = []
    var notes: EventNotes?
    var timeZone: TimeZone = .current
    var customizedColor: ColorIndex?        // 日程自定义颜色
    var organizerCalendarId: String = ""    // 日程组织者的 calendarId
    var creatorCalendarId: String = ""      // 日程创建者的 calendarId
    var guestCanModify: Bool = SettingService.shared().guestPermission >= .guestCanModify
    var guestCanInvite: Bool = SettingService.shared().guestPermission >= .guestCanInvite
    var guestCanSeeOtherGuests: Bool = SettingService.shared().guestPermission >= .guestCanSeeOtherGuests
    /// 参与人创建会议纪要权限
    var meetingNotesConfig: Rust.MeetingNotesConfig = {
        var config = Rust.MeetingNotesConfig()
        config.createNotesPermission = .defaultValue()
        return config
    }()
    var eventAttendeeStatistics: EventAttendeeStatistics?
    var eventSpeakerStatistics: EventAttendeeStatistics?
    var eventAudienceStatistics: EventAttendeeStatistics?
    var videoMeeting: Rust.VideoMeeting = Rust.VideoMeeting()
    var checkInConfig: Rust.CheckInConfig = Rust.CheckInConfig.initialValue
    var category: Rust.Event.Category = .defaultCategory
    var eventID: String = ""
    var span: Rust.Span = .noneSpan {
        didSet {
            switch span {
            case .thisEvent:
                rrule = nil
            case .allEvents:
                self.startDate = Date(timeIntervalSince1970: TimeInterval(pb.startTime))
                self.endDate = Date(timeIntervalSince1970: TimeInterval(pb.endTime))
            case .futureEvents, .noneSpan:
                return
            @unknown default:
                break
            }
        }
    }

    var isEditable: Bool {
        self.pb.isEditable
    }

    var isWebinar: Bool {
        self.pb.category == .webinar
    }
    
    var source: Rust.Event.Source {
        self.pb.source
    }
    
    var aiStyleInfo: AIGenerateEventInfoNeedHightLight = AIGenerateEventInfoNeedHightLight()

    init(category: Rust.Event.Category = .defaultCategory) {
        var pb = PBModel()
        pb.id = "0"
        pb.key = ""
        pb.originalTime = 0
        pb.isEditable = true
        pb.startTimezone = TimeZone.current.identifier
        pb.endTimezone = TimeZone.current.identifier
        pb.category = category
        self.category = category
        self.pb = pb
        videoMeeting.videoMeetingType = .noVideoMeeting
    }
}

extension EventEditModel: PBModelConvertible {

    init(from pb: PBModel) {
        self.pb = pb
        self.eventID = pb.serverID
        self.summary = pb.summary
        if !pb.colorIndex.isNoneColor { self.customizedColor = pb.colorIndex }
        self.startDate = Date(timeIntervalSince1970: TimeInterval(pb.startTime))
        self.endDate = Date(timeIntervalSince1970: TimeInterval(pb.endTime))
        self.isAllDay = pb.isAllDay
        self.visibility = pb.visibility
        self.freeBusy = pb.isFree ? .free : .busy
        self.reminders = pb.reminders.map { EventEditReminder(from: $0) }
        self.rrule = pb.rrule.isEmpty ? nil : EKRecurrenceRule.recurrenceRuleFromString(pb.rrule)
        self.location = EventEditLocation(from: pb.location)
        self.attendees = EventEditAttendee.makeAttendees(from: pb.attendees)
        self.meetingRooms = pb.attendees
            .filter { $0.category == .resource }
            .map { CalendarMeetingRoom(from: $0) }
        self.attachments = pb.attachments.map { EventEditAttachment(pb: $0) }
        self.organizerCalendarId = pb.organizerCalendarID
        self.creatorCalendarId = pb.creatorCalendarID
        self.eventAttendeeStatistics = pb.attendeeInfo
        self.eventSpeakerStatistics = pb.webinarInfo.speakers.eventAttendeeInfo
        self.eventAudienceStatistics = pb.webinarInfo.audiences.eventAttendeeInfo
        self.videoMeeting = pb.videoMeeting
        self.checkInConfig = pb.checkInConfig
        self.category = pb.category
        self.guestCanModify = pb.guestCanModify
        self.guestCanInvite = pb.guestCanInvite
        self.guestCanSeeOtherGuests = pb.guestCanSeeOtherGuests
        self.meetingNotesConfig = pb.meetingNotesConfig
    }

    init(from pb: PBModel, instance: Rust.Instance) {
        self.init(from: pb)
        self.startDate = Date(timeIntervalSince1970: TimeInterval(instance.startTime))
        self.endDate = Date(timeIntervalSince1970: TimeInterval(instance.endTime))
    }

    init(copyFrom copyPb: PBModel, instance: Rust.Instance) {
        // 使用原日程pb构建复制日程的model
        var pb = PBModel()
        pb.id = "0"
        pb.key = ""
        pb.originalTime = 0
        pb.isEditable = true
        pb.summary = copyPb.summary
        pb.startTime = instance.startTime
        pb.endTime = instance.endTime
        pb.isAllDay = copyPb.isAllDay
        pb.visibility = copyPb.visibility
        pb.isFree = copyPb.isFree
        pb.reminders = copyPb.reminders
        pb.location = copyPb.location
        pb.colorIndex = copyPb.colorIndex
        if !(copyPb.source == .google || copyPb.source == .exchange) {
            pb.attachments = copyPb.attachments
        }
        pb.checkInConfig = Rust.CheckInConfig.initialValue
        pb.guestCanInvite = copyPb.guestCanInvite
        pb.guestCanSeeOtherGuests = copyPb.guestCanSeeOtherGuests
        pb.guestCanModify = copyPb.guestCanModify
        pb.category = copyPb.category
        pb.meetingNotesConfig = copyPb.meetingNotesConfig
        self.init(from: pb)
        self.videoMeeting.videoMeetingType = .vchat
    }

    func getPBModel() -> PBModel {
        var pb = self.pb
        pb.summary = self.summary ?? ""
        pb.startTime = Int64(self.startDate.timeIntervalSince1970)
        pb.endTime = Int64(self.endDate.timeIntervalSince1970)
        pb.isAllDay = self.isAllDay
        if let color = customizedColor { pb.colorIndex = color }
        pb.startTimezone = self.timeZone.identifier
        pb.endTimezone = self.timeZone.identifier
        pb.visibility = self.visibility
        pb.isFree = self.freeBusy == .free
        pb.reminders = self.reminders.map { $0.getPBModel() }
        pb.checkInConfig = self.checkInConfig
        pb.rrule = self.rrule?.iCalendarString() ?? ""
        pb.location = self.location?.getPBModel() ?? EventEditLocation.PBModel()
        let attendeePbs = EventEditAttendee.getPBModels(from: self.attendees)
        let meetingRoomPbs = self.meetingRooms.map { $0.getPBModel() }
        pb.attendees = attendeePbs + meetingRoomPbs
        pb.attachments = self.attachments.map { $0.pb }
        if let notes = self.notes {
            switch notes {
            case .docs(let data, let plainText):
                pb.docsDescription = data
                pb.description_p = plainText
            case .html(let text), .plain(let text):
                pb.docsDescription = ""
                pb.description_p = text
            }
        } else {
            pb.docsDescription = ""
            pb.description_p = ""
        }
        pb.organizerCalendarID = self.organizerCalendarId
        pb.creatorCalendarID = self.creatorCalendarId
        pb.calendarID = calendar?.id ?? ""
        pb.notificationType = .defaultNotificationType
        pb.videoMeeting = videoMeeting
        pb.category = self.category
        pb.attendeeInfo.totalNo = Int32(EventEditAttendee.allBreakedUpAttendeeCount(of: self.attendees))
        if pb.category == .webinar {
            // webinar 参与人相关
            pb.webinarInfo.speakers.attendees = EventEditAttendee.getPBModels(from: self.speakers)
            pb.webinarInfo.speakers.eventAttendeeInfo.totalNo = Int32(EventEditAttendee.allBreakedUpAttendeeCount(of: self.speakers))
            pb.webinarInfo.audiences.attendees = EventEditAttendee.getPBModels(from: self.audiences)
            pb.webinarInfo.audiences.eventAttendeeInfo.totalNo = Int32(EventEditAttendee.allBreakedUpAttendeeCount(of: self.audiences))
        }
        pb.guestCanModify = self.guestCanModify
        pb.guestCanInvite = self.guestCanInvite
        pb.guestCanSeeOtherGuests = self.guestCanSeeOtherGuests
        if self.meetingNotesConfig.hasCreateNotesPermission {
            pb.meetingNotesConfig.createNotesPermission = self.meetingNotesConfig.createNotesPermission
        }
        return pb
    }

}

extension EventEditModel {

    private static func makeReminderFromEKAlarm(_ alarm: EKAlarm) -> EventEditReminder {
        let minutes = Int32(-1 * alarm.relativeOffset / 60)
        return .init(minutes: minutes)
    }

    private static func makeEKAlarmFromReminder(_ reminder: EventEditReminder) -> EKAlarm {
        return EKAlarm(relativeOffset: TimeInterval(reminder.minutes * -60))
    }

    static func makeFromEKEvent(_ ekEvent: EKEvent) -> Self {
        var editModel = EventEditModel()
        editModel.ekEvent = ekEvent
        editModel.summary = ekEvent.title
        editModel.startDate = ekEvent.startDate
        editModel.endDate = ekEvent.endDate
        editModel.isAllDay = ekEvent.isAllDay
        editModel.freeBusy = ekEvent.availability == .free ? .free : .busy
        editModel.visibility = .default
        editModel.rrule = ekEvent.recurrenceRules?.first
        editModel.notes = .plain(text: ekEvent.notes ?? "")
        editModel.attendees = (ekEvent.attendees ?? [])
            .filter { $0.participantType != .resource && $0.participantType != .room }
            .map { .local(EventEditLocalAttendee(ekModel: $0)) }
        if let ekLocation = ekEvent.structuredLocation {
            editModel.location = .makeFromEKLocation(ekLocation)
        }
        editModel.reminders = (ekEvent.alarms ?? []).map(Self.makeReminderFromEKAlarm(_:))
        return editModel
    }

    func getEKEvent() -> EKEvent {
        guard let ekEvent = ekEvent else {
            assertionFailureLog()
            return EKEvent()
        }
        ekEvent.title = summary
        ekEvent.startDate = startDate
        ekEvent.endDate = endDate
        ekEvent.isAllDay = isAllDay
        ekEvent.availability = freeBusy == .free ? .free : .busy
        switch freeBusy {
        case .free:
            if ekEvent.availability != .free {
                ekEvent.availability = .free
            }
        case .busy:
            if ekEvent.availability == .free {
                ekEvent.availability = .busy
            }
        }
        ekEvent.removeRecurrence()
        if let rrule = rrule {
            ekEvent.addRecurrenceRule(rrule)
        }
        if let notes = notes, case .plain(let text) = notes {
            ekEvent.notes = text
        } else {
            ekEvent.notes = nil
        }
        ekEvent.structuredLocation = location?.toEKLocation()
        ekEvent.alarms = reminders.map(Self.makeEKAlarmFromReminder(_:))

        return ekEvent
    }

    mutating func makeCreatorOrganizer(for calendar: EventEditCalendar, primaryCalendarID: String?) {
        // 创建者、组织者默认情况下为目标日历owner
        self.creatorCalendarId = calendar.id
        self.organizerCalendarId = calendar.id
        if let primaryID = primaryCalendarID,
           calendar.isShared || (calendar.isPrimary && calendar.source == .lark && calendar.id != primaryID) {
            self.creatorCalendarId = primaryID
        }
    }
}

extension EventEditModel {
    var isRecurEvent: Bool {
        /// 是重复性日程
        return rrule != nil || self.pb.originalTime != 0 || self.span == .thisEvent
    }
}

protocol EventEditModelGetterProtocol: AnyObject {
    func getEventEditModel() -> EventEditModel?
}

extension EventEditViewModel: EventEditModelGetterProtocol {
    func getEventEditModel() -> EventEditModel? {
        return eventModel?.rxModel?.value
    }
}
