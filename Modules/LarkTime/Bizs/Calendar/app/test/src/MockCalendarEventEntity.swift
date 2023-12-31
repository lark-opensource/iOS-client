////
////  MockCalendarEventEntity.swift
////  CalendarTests
////
////  Created by zhouyuan on 2018/11/20.
////  Copyright © 2018 EE. All rights reserved.
////
//
//import Foundation
//import EventKit
//@testable import Calendar
//import RustPB
//
//// swiftlint:disable number_separator
//struct MockCalendarEventEntity: CalendarEventEntity {
//    var videoMeeting: VideoMeeting?
//
//    var userInviteOperatorID: String?
//
//    var inviteOperatorLocalizedName: String = ""
//
//    var attachments: [CalendarEventAttachmentEntity] = [CalendarEventAttachmentEntity]()
//
//    var shouldShowEditButton: Bool?
//
//    var isShareable: Bool?
//
//    var isDeleteable: Bool?
//
//    var isTransferable: Bool?
//
//    var isMeetingChatAvailable: Bool = false
//
//    var isVideoMeetingAvailable: Bool?
//
//    var isMeetingMinuteAvailable: Bool?
//
//    var isReportable: Bool?
//
//    var hasSelfAttendeeStatus: Bool {
//        return true
//    }
//
//    var notificationType: NotificationType
//    var willCreatorAttend: Bool {
//        return false
//    }
//
//    var willOrganizerAttend: Bool {
//        return false
//    }
//
//    var isCrossTenant: Bool = false
//
//    func canDeleteAll() -> Bool {
//        return false
//    }
//
//    func canDeleteSelf() -> Bool {
//        return false
//    }
//    var videoChat: VideoChatModel
//
//    var docsToken: String
//    init() {
//        videoChat = VideoChatModel(uniqueID: "1111", meetingNumber: "2222", isExpired: false)
//        docsToken = ""
//        id = "338"
//        originalTime = 0
//        isEditable = true
//        creatorCalendarId = "1591560057517060"
//        calendarId = "1591560057517060"
//        organizerCalendarId = "1591560057517060"
//        serverId = "3688745"
//        selfAttendeeStatus = .accept
//        key = "d1c9a989-5d5c-4057-870d-87ae950f3ce9"
//        color = -9852417
//        needUpdate = false
//        summary = "123吧，吧"
//        description = "1122333"
//        isAllDay = false
//        startTime = 1539676800
//        startTimezone = "Asia/Shanghai"
//        endTime = 1539682200
//        endTimezone = "Asia/Shanghai"
//        status = .confirmed
//        rrule = "FREQ=DAILY;INTERVAL=1"
//        attendees = []
//        location = CalendarLocation()
//        reminders = []
//        displayType = .full
//        visibility = .default
//        isFree = false
//        type = .defaultType
//        source = .iosApp
//        calendarID = "1591560057517060"
//        serverID = "3688745"
//        notificationType = .defaultNotificationType
//
//        var mappingColor = MappingColor()
//        mappingColor.backgroundColor = -9852417
//        mappingColor.foregroundColor = -16761187
//        mappingColor.eventCardColor = -10510865
//        mappingColor.eventColorIndex = "6"
//        calColor = mappingColor
//        eventColor = mappingColor
//        colorMap = mappingColor
//        guestCanInvite = true
//        guestCanModify = false
//        guestCanSeeOtherGuests = true
//        docsDescription = ""
//        displayOrganizerCalId = "1591560057517060"
//        creator = MockCalendarEventAttendeeEntity()
//
//        var a = MockCalendarEventAttendeeEntity()
//        a.attendeeCalendarId = ""
//        successor = a
//    }
//
//    var id: String
//    var originalTime: Int64
//    var isEditable: Bool
//    var creatorCalendarId: String
//    var calendarId: String
//    var organizerCalendarId: String
//    var organizer: CalendarEventAttendeeEntity {
//        return MockCalendarEventAttendeeEntity()
//    }
//    var serverId: String
//    var selfAttendeeStatus: CalendarEventAttendee.Status
//    var key: String
//    var color: Int32
//    var needUpdate: Bool
//    var summary: String
//    var summaryIsEmpty: Bool {
//        return summary.isEmpty
//    }
//    var description: String
//    var isAllDay: Bool
//    var startTime: Int64
//    var startTimezone: String
//    var endTime: Int64
//    var endTimezone: String
//    var status: CalendarEvent.Status
//    var rrule: String
//    var displayOrganizerCalId: String
//    var attendees: [CalendarEventAttendeeEntity]
//    var location: CalendarLocation
//    var reminders: [Reminder]
//    var displayType: CalendarEvent.DisplayType
//    var visibility: CalendarEvent.Visibility
//    var isFree: Bool
//    var type: CalendarEvent.TypeEnum
//    var source: CalendarEvent.Source
//    var calendarID: String
//    var serverID: String
//    var calColor: MappingColor
//
//    var eventColor: MappingColor
//
//    var guestCanInvite: Bool
//
//    var guestCanModify: Bool
//
//    var guestCanSeeOtherGuests: Bool
//
//    var isSharable: Bool {
//        return false
//    }
//
//    var docsDescription: String
//
//    var creator: CalendarEventAttendeeEntity
//    var colorMap: MappingColor
//    var successor: CalendarEventAttendeeEntity
//    func getTitle() -> String {
//        return ""
//    }
//
//    func debugMessage() -> String {
//        return ""
//    }
//
//    func getDataSource() -> DataSource {
//        return .system
//    }
//
//    func getPBModel() -> CalendarEvent {
//        return CalendarEvent()
//    }
//
//    func getEKEvent() -> EKEvent? {
//        return nil
//    }
//}
