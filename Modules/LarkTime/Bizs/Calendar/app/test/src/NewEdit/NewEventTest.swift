////
////  NewEventTest.swift
////  CalendarTests
////
////  Created by zhuchao on 2019/1/4.
////  Copyright © 2019 EE. All rights reserved.
////
//
//import XCTest
//import EventKit
//@testable import Calendar
//import RustPB
//
//class NewEventTest: XCTestCase {
//
//    var newEvent: NewEvent!
//
//    override func setUp() {
//        super.setUp()
//        let event = MockCalendarEventEntity()
//        self.newEvent = NewEventModel(eventModel: event,
//                                      startTime: getDateFromInt64(event.startTime),
//                                      endTime: getDateFromInt64(event.startTime),
//                                      editPermission: .createrEdit, skinType: .dark)
//    }
//
//    override func tearDown() {
//        super.tearDown()
//    }
//
//    func testDateRange() {
//        func convertDate(_ date: Date) -> Date {
//            let timeStamp = Int64((date.timeIntervalSince1970))
//            return Date(timeIntervalSince1970: TimeInterval(timeStamp))
//        }
//        let start = Date()
//        let end = Date() + 10
//        newEvent.startTime = start
//        newEvent.endTime = end
//        let dateRange = newEvent.dateRange()
//        XCTAssert(dateRange.startTime == convertDate(start))
//        XCTAssert(dateRange.endTime == convertDate(end))
//    }
//
//    func testAlarmText() {
//        newEvent.reminders = [Reminder(minutes: 5, isAllDay: false)]
//        XCTAssert(newEvent.alarmText(is12HourStyle: false) == "5分钟前" || newEvent.alarmText(is12HourStyle: false) == "5 mins before")
//        newEvent.reminders = [Reminder(minutes: -480, isAllDay: true)]
//        XCTAssert(newEvent.alarmText(is12HourStyle: false) == "当天08:00" || newEvent.alarmText(is12HourStyle: false) == "On day of event at 8:00")
//    }
//
//    func testIsRepeat() {
//        XCTAssert(newEvent.isRepeatEvent())
//        newEvent.rrule = nil
//        XCTAssert(!newEvent.isRepeatEvent())
//    }
//
//    func testNotRemovedAttendee() {
//        let attendee1 = MockCalendarEventAttendeeEntity()
//        var attendee2 = MockCalendarEventAttendeeEntity()
//        attendee2.status = .removed
//        newEvent.attendees = [attendee1, attendee2]
//        XCTAssertTrue(newEvent.notRemovedAttendees().count == 1)
//        XCTAssertTrue(newEvent.notRemovedAttendees().first!.isEqual(to: attendee1))
//    }
//
//    func testClearRepeat() {
//        newEvent.clearRepeat()
//        XCTAssertNil(newEvent.rrule)
//    }
//
//    //swiftlint:disable line_length
//    func testMeetingRoomChanged() {
//        let meetingRoom = MeetingRoom(id: "1", name: "", buildingId: "", attendeeCalendarId: "", isAvailable: true, isRemoved: false, buildingName: "", floorName: "", capacity: 1, weight: 1, status: .accept, isNewAdd: true, tenantId: "", calendarId: "1", isEditable: false, isDisabled: false)
//        newEvent.meetingRooms = [meetingRoom]
//        XCTAssertTrue(newEvent.meetingRoomChanged())
//        newEvent.originalMeetingRooms = [meetingRoom]
//        XCTAssertTrue(!newEvent.meetingRoomChanged())
//    }
//
//    func testIsFromNew() {
//        let event = MockCalendarEventEntity()
//        do {
//            let newEvent = NewEventModel(eventModel: event,
//                                          startTime: getDateFromInt64(event.startTime),
//                                          endTime: getDateFromInt64(event.startTime),
//                                          editPermission: .new,
//                                          skinType: .dark)
//            XCTAssertTrue(newEvent.isFromNew())
//        }
//        do {
//            let newEvent = NewEventModel(eventModel: event,
//                                         startTime: getDateFromInt64(event.startTime),
//                                         endTime: getDateFromInt64(event.startTime),
//                                         editPermission: .createrEdit,
//                                         skinType: .dark)
//            XCTAssertFalse(newEvent.isFromNew())
//        }
//    }
//
//    //swiftlint:disable line_length
//    func testlVisibleMeetingRooms() {
//        let meetingRoom1 = MeetingRoom(id: "1", name: "", buildingId: "", attendeeCalendarId: "", isAvailable: true, isRemoved: false, buildingName: "", floorName: "", capacity: 1, weight: 1, status: .accept, isNewAdd: true, tenantId: "", calendarId: "1", isEditable: false, isDisabled: false)
//        let meetingRoom2 = MeetingRoom(id: "1", name: "", buildingId: "", attendeeCalendarId: "", isAvailable: true, isRemoved: true, buildingName: "", floorName: "", capacity: 1, weight: 1, status: .accept, isNewAdd: true, tenantId: "", calendarId: "2", isEditable: false, isDisabled: false)
//        newEvent.meetingRooms = [meetingRoom1, meetingRoom2]
//        XCTAssertTrue(newEvent.visibleMeetingRooms().count == 1)
//        XCTAssertTrue(newEvent.visibleMeetingRooms().first! == meetingRoom1)
//    }
//
//    func testVisibleAttendees() {
//        let attendee1 = MockCalendarEventAttendeeEntity()
//        var attendee2 = MockCalendarEventAttendeeEntity()
//        attendee2.status = .removed
//        newEvent.attendees = [attendee1, attendee2]
//        XCTAssertTrue(newEvent.visibleAttendees().count == 1)
//        XCTAssertTrue(newEvent.visibleAttendees().first!.isEqual(to: attendee1))
//    }
//
//    func testIsSelectingSharedCalendar() {
//        let calendar = MockCalendarEntity()
//        calendar.type = .other
//        let selectedCalendar = NewEventCalendarModel(calendar: calendar)
//        newEvent.selectedCalendar = selectedCalendar
//        XCTAssertTrue(newEvent.isSelectingSharedCalendar())
//        calendar.type = .primary
//        XCTAssertFalse(newEvent.isSelectingSharedCalendar())
//    }
//
//    func testFreeBusyString() {
//        newEvent.isFree = true
//        XCTAssertTrue(newEvent.freeBusyString() == BundleI18n.Calendar.Calendar_Detail_Free)
//        newEvent.isFree = false
//        XCTAssertTrue(newEvent.freeBusyString() == BundleI18n.Calendar.Calendar_Detail_Busy)
//    }
//
//    func testIsFromRepeatOrExceptionEvent() {
//        XCTAssertTrue(newEvent.isFromRepeatOrExceptionEvent())
//        var event = MockCalendarEventEntity()
//        event.originalTime = 1
//        self.newEvent = NewEventModel(eventModel: event,
//                                      startTime: Date(),
//                                      endTime: Date(),
//                                      editPermission: .createrEdit, skinType: .dark)
//        self.newEvent.clearRepeat()
//        XCTAssertTrue(newEvent.isFromRepeatOrExceptionEvent())
//
//        event = MockCalendarEventEntity()
//        event.originalTime = 0
//        self.newEvent = NewEventModel(eventModel: event,
//                                      startTime: Date(),
//                                      endTime: Date(),
//                                      editPermission: .createrEdit, skinType: .dark)
//        self.newEvent.clearRepeat()
//        XCTAssertFalse(newEvent.isFromRepeatOrExceptionEvent())
//    }
//
//    func testDisplayColor() {
//        newEvent.eventColor = UIColor.red
//        XCTAssertTrue(newEvent.displayColor() == UIColor.red)
//        newEvent.eventColor = nil
//        let calendar = MockCalendarEntity()
//        var selectedCalendar = NewEventCalendarModel(calendar: calendar)
//        selectedCalendar.eventColor = UIColor.red
//        newEvent.selectedCalendar = selectedCalendar
//        XCTAssertTrue(newEvent.displayColor() == UIColor.red)
//    }
//
//    func testUpdateTime() {
//        let date = Date()
//        let newDate = date.utcToLocalDate(TimeZone(identifier: "Asia/Shanghai")!)
//        XCTAssertTrue(Int(floor(date.timeIntervalSince(newDate))) == 3600 * 8)
//    }
//
//    func testMergeSetting() {
//        let event = MockCalendarEventEntity()
//        let newEvent = NewEventModel(eventModel: event,
//                                     startTime: getDateFromInt64(event.startTime),
//                                     endTime: getDateFromInt64(event.startTime),
//                                     editPermission: .new,
//                                     skinType: .dark)
//        var setting = SettingModel()
//        setting.defaultEventDuration = 120
//        newEvent.endTime = Date(timeIntervalSince1970: 0)
//        newEvent.mergeSetting(setting: setting)
//        XCTAssertTrue(Int(newEvent.endTime.timeIntervalSince(newEvent.startTime)) == Int(setting.defaultEventDuration * 60))
//    }
//
//    func testUpdateReminder() {
//        var setting = SettingModel()
//        setting.defaultNoneAllDayReminder = 5
//        setting.defaultAllDayReminder = -480
//        XCTAssertNotNil(setting.allDayReminder)
//        XCTAssertNotNil(setting.noneAllDayReminder)
//        newEvent.updateReminder(with: setting, isAllDay: true)
//        XCTAssertEqual(newEvent.reminders.first!, setting.allDayReminder!)
//        newEvent.updateReminder(with: setting, isAllDay: false)
//        XCTAssertEqual(newEvent.reminders.first!, setting.noneAllDayReminder!)
//    }
//
//    func testIsOrganizer() {
//        let calendarId = "123"
//        var event = MockCalendarEventEntity()
//        event.organizerCalendarId = calendarId
//        newEvent = NewEventModel(eventModel: event, startTime: Date(), endTime: Date(), editPermission: .createrEdit, skinType: .dark)
//        XCTAssertTrue(newEvent.isOrganizer(with: calendarId))
//    }
//
//    func testIsAnAttendee() {
//        var attendee1 = MockCalendarEventAttendeeEntity()
//        let calendarId = "123"
//        attendee1.attendeeCalendarId = calendarId
//        var attendee2 = MockCalendarEventAttendeeEntity()
//        attendee2.status = .removed
//        newEvent.attendees = [attendee1, attendee2]
//        XCTAssertTrue(newEvent.isAnAttendee(with: calendarId))
//    }
//
//    func testIsInvitedAttendee() {
//        XCTAssertTrue(newEvent.isInvitedAttendee(isAttendee: true, isOrganizer: false, editPermission: .participantEdit))
//        XCTAssertTrue(newEvent.isInvitedAttendee(isAttendee: true, isOrganizer: false, editPermission: .participantEdit))
//    }
//
//    func testAutoAddedIdTuple() {
//        XCTAssertNil(newEvent.autoAddedIdTuple(allAttendees: [], selectedCalendar: nil))
//        XCTAssertNil(newEvent.autoAddedIdTuple(allAttendees: [MockCalendarEventAttendeeEntity()], selectedCalendar: nil))
//        let calendar = MockCalendarEntity()
//        calendar.type = .other
//        let selectedCalendar = NewEventCalendarModel(calendar: calendar)
//        XCTAssertNil(newEvent.autoAddedIdTuple(allAttendees: [MockCalendarEventAttendeeEntity()], selectedCalendar: selectedCalendar))
//    }
//
//    func testAutoAddedIdTuple2() {
//        let calendar = MockCalendarEntity()
//        calendar.type = .primary
//        let selectedCalendar = NewEventCalendarModel(calendar: calendar)
//        XCTAssertNotNil(newEvent.autoAddedIdTuple(allAttendees: [], selectedCalendar: selectedCalendar))
//    }
//
//    func testAutoAddedIdTuple3() {
//        let calendarId = "123"
//        var attendee = MockCalendarEventAttendeeEntity()
//        attendee.attendeeCalendarId = calendarId
//        attendee.status = .removed
//        let calendar = MockCalendarEntity()
//        calendar.serverId = calendarId
//        calendar.type = .primary
//        let selectedCalendar = NewEventCalendarModel(calendar: calendar)
//        XCTAssertNil(newEvent.autoAddedIdTuple(allAttendees: [attendee], selectedCalendar: selectedCalendar))
//    }
//
//    func testIsRRuleValid() {
//        let rrule = EKRecurrenceRule()
//        XCTAssertTrue(newEvent.isRRuleValid(rrule: rrule, containsMeetingRoom: false))
//
//        XCTAssertFalse(newEvent.isRRuleValid(rrule: rrule, containsMeetingRoom: true))
//
//        rrule.recurrenceEnd = EKRecurrenceEnd(end: Date())
//        XCTAssertTrue(newEvent.isRRuleValid(rrule: rrule, containsMeetingRoom: true))
//
//        let endDate = Calendar.gregorianCalendar.date(byAdding: .day, value: 731, to: Date())!
//        rrule.recurrenceEnd = EKRecurrenceEnd(end: endDate)
//        XCTAssertFalse(newEvent.isRRuleValid(rrule: rrule, containsMeetingRoom: true))
//    }
//
//    func testHasDescription() {
//        newEvent.docsDescription = ""
//        newEvent.description = ""
//        XCTAssertFalse(newEvent.hasDescription())
//
//        newEvent.docsDescription = "123"
//        XCTAssertTrue(newEvent.hasDescription())
//
//        newEvent.docsDescription = ""
//        newEvent.description = "123"
//        XCTAssertTrue(newEvent.hasDescription())
//    }
//
//    func testOnlyEditMeetingRoomOrAttendees() {
//        newEvent.participantEditSingleEvent = nil
//        XCTAssertFalse(newEvent.onlyEditMeetingRoomOrAttendees())
//        newEvent.participantEditSingleEvent = false
//        XCTAssertFalse(newEvent.onlyEditMeetingRoomOrAttendees())
//        newEvent.participantEditSingleEvent = true
//        XCTAssertTrue(newEvent.onlyEditMeetingRoomOrAttendees())
//    }
//
//    func testCanSearchOuterAttendee() {
//        newEvent.isMeeting = true
//        XCTAssertFalse(newEvent.canSearchOuterAttendee())
//        newEvent.isMeeting = false
//        XCTAssertTrue(newEvent.canSearchOuterAttendee())
//    }
//
//    func testShouldShowInviteeUpdateMeetingRoomSheet() {
//        XCTAssertTrue(newEvent.shouldShowInviteeUpdateMeetingRoomSheet(meetingRoomChanged: true, isRRuleValid: false, onlyEditMeetingRoomOrAttendees: true))
//    }
//
//    func testAttendeesIds() {
//        var attendee1 = MockCalendarEventAttendeeEntity()
//        attendee1.attendeeCalendarId = "1"
//
//        var attendee2 = MockCalendarEventAttendeeEntity()
//        attendee2.status = .removed
//        attendee1.attendeeCalendarId = "2"
//        var attendee3 = MockCalendarEventAttendeeEntity()
//        attendee3.groupId = "3"
//        attendee3.isGroup = true
//        newEvent.attendees = [attendee1, attendee2, attendee3]
//        let result = newEvent.attendeesIds()
//        XCTAssert(result == ([attendee3.groupId], [attendee1.attendeeCalendarId]))
//    }
//
//    func testClearChanges() {
//        newEvent.clearChanges()
//        XCTAssertFalse(newEvent.changed)
//        XCTAssertNil(newEvent.participantEditSingleEvent)
//    }
//
//    //swiftlint:disable function_body_length
//    func testAttendeePermission() {
//        var permission = AttendeePermission(editPermission: .new,
//                                            isLocalEvent: false,
//                                            isGoogleEvent: false,
//                                            guestCanInvite: true,
//                                            guestCanSeeOtherGuests: true,
//                                            isAttendeeEmpty: true)
//        XCTAssertTrue(permission.isRemoveDeleteItem)
//        XCTAssertFalse(permission.isHideAttendeeView)
//        XCTAssertFalse(permission.isDisableAttendeeSelect)
//        XCTAssertFalse(permission.isDisableTitleEdit)
//        XCTAssertFalse(permission.isDisableDateSelect)
//        XCTAssertFalse(permission.isDisableMeetingRomm)
//        XCTAssertFalse(permission.isDisableLocation)
//        XCTAssertFalse(permission.isDisableRRule)
//        XCTAssertFalse(permission.isDisableDesc)
//        XCTAssertFalse(permission.isRemoveCalendarView)
//
//        permission = AttendeePermission(editPermission: .createrEdit,
//                                        isLocalEvent: false,
//                                        isGoogleEvent: false,
//                                        guestCanInvite: true,
//                                        guestCanSeeOtherGuests: true,
//                                        isAttendeeEmpty: true)
//        XCTAssertFalse(permission.isRemoveDeleteItem)
//        XCTAssertFalse(permission.isHideAttendeeView)
//        XCTAssertFalse(permission.isDisableAttendeeSelect)
//        XCTAssertFalse(permission.isDisableTitleEdit)
//        XCTAssertFalse(permission.isDisableDateSelect)
//        XCTAssertFalse(permission.isDisableMeetingRomm)
//        XCTAssertFalse(permission.isDisableLocation)
//        XCTAssertFalse(permission.isDisableRRule)
//        XCTAssertFalse(permission.isDisableDesc)
//        XCTAssertFalse(permission.isRemoveCalendarView)
//
//        permission = AttendeePermission(editPermission: .createrEdit,
//                                        isLocalEvent: true,
//                                        isGoogleEvent: false,
//                                        guestCanInvite: true,
//                                        guestCanSeeOtherGuests: true,
//                                        isAttendeeEmpty: true)
//        XCTAssertTrue(permission.isHideAttendeeView)
//        XCTAssertFalse(permission.isRemoveDeleteItem)
//        XCTAssertFalse(permission.isDisableAttendeeSelect)
//        XCTAssertFalse(permission.isDisableTitleEdit)
//        XCTAssertFalse(permission.isDisableDateSelect)
//        XCTAssertTrue(permission.isDisableMeetingRomm)
//        XCTAssertFalse(permission.isDisableLocation)
//        XCTAssertFalse(permission.isDisableRRule)
//        XCTAssertFalse(permission.isDisableDesc)
//        XCTAssertTrue(permission.isRemoveCalendarView)
//
//        permission = AttendeePermission(editPermission: .createrEdit,
//                                                 isLocalEvent: true,
//                                                 isGoogleEvent: false,
//                                                 guestCanInvite: true,
//                                                 guestCanSeeOtherGuests: true,
//                                                 isAttendeeEmpty: false)
//        XCTAssertTrue(permission.isDisableAttendeeSelect)
//        XCTAssertFalse(permission.isRemoveDeleteItem)
//        XCTAssertFalse(permission.isHideAttendeeView)
//        XCTAssertFalse(permission.isDisableTitleEdit)
//        XCTAssertFalse(permission.isDisableDateSelect)
//        XCTAssertTrue(permission.isDisableMeetingRomm)
//        XCTAssertFalse(permission.isDisableLocation)
//        XCTAssertFalse(permission.isDisableRRule)
//        XCTAssertFalse(permission.isDisableDesc)
//        XCTAssertTrue(permission.isRemoveCalendarView)
//
//        //participantEdit
//        permission = AttendeePermission(editPermission: .participantEdit,
//                                                 isLocalEvent: false,
//                                                 isGoogleEvent: false,
//                                                 guestCanInvite: true,
//                                                 guestCanSeeOtherGuests: true,
//                                                 isAttendeeEmpty: false)
//        XCTAssertTrue(permission.isDisableTitleEdit)
//        XCTAssertTrue(permission.isDisableDateSelect)
//        XCTAssertTrue(permission.isDisableLocation)
//        XCTAssertTrue(permission.isDisableRRule)
//        XCTAssertTrue(permission.isDisableDesc)
//        XCTAssertFalse(permission.isRemoveDeleteItem)
//        XCTAssertFalse(permission.isHideAttendeeView)
//        XCTAssertFalse(permission.isDisableAttendeeSelect)
//        XCTAssertFalse(permission.isDisableMeetingRomm)
//        XCTAssertFalse(permission.isRemoveCalendarView)
//
//        permission = AttendeePermission(editPermission: .participantEdit,
//                                                 isLocalEvent: false,
//                                                 isGoogleEvent: false,
//                                                 guestCanInvite: true,
//                                                 guestCanSeeOtherGuests: true,
//                                                 isAttendeeEmpty: false,
//                                                 isAllDay: true)
//        XCTAssertTrue(permission.isDisableTitleEdit)
//        XCTAssertTrue(permission.isDisableDateSelect)
//        XCTAssertTrue(permission.isDisableLocation)
//        XCTAssertTrue(permission.isDisableRRule)
//        XCTAssertTrue(permission.isDisableDesc)
//        XCTAssertFalse(permission.isRemoveDeleteItem)
//        XCTAssertFalse(permission.isHideAttendeeView)
//        XCTAssertFalse(permission.isDisableAttendeeSelect)
//        XCTAssertTrue(permission.isDisableMeetingRomm)
//        XCTAssertFalse(permission.isRemoveCalendarView)
//
//        permission = AttendeePermission(editPermission: .participantEdit,
//                                                 isLocalEvent: false,
//                                                 isGoogleEvent: false,
//                                                 guestCanInvite: false,
//                                                 guestCanSeeOtherGuests: true,
//                                                 isAttendeeEmpty: true)
//        XCTAssertTrue(permission.isHideAttendeeView)
//        XCTAssertFalse(permission.isDisableMeetingRomm)
//        XCTAssertTrue(permission.isDisableTitleEdit)
//        XCTAssertTrue(permission.isDisableDateSelect)
//        XCTAssertTrue(permission.isDisableLocation)
//        XCTAssertTrue(permission.isDisableRRule)
//        XCTAssertTrue(permission.isDisableDesc)
//        XCTAssertFalse(permission.isRemoveDeleteItem)
//        XCTAssertFalse(permission.isDisableAttendeeSelect)
//        XCTAssertFalse(permission.isRemoveCalendarView)
//
//        permission = AttendeePermission(editPermission: .participantEdit,
//                                                 isLocalEvent: false,
//                                                 isGoogleEvent: false,
//                                                 guestCanInvite: false,
//                                                 guestCanSeeOtherGuests: true,
//                                                 isAttendeeEmpty: false)
//        XCTAssertTrue(permission.isDisableAttendeeSelect)
//        XCTAssertTrue(permission.isDisableTitleEdit)
//        XCTAssertTrue(permission.isDisableDateSelect)
//        XCTAssertTrue(permission.isDisableLocation)
//        XCTAssertTrue(permission.isDisableRRule)
//        XCTAssertTrue(permission.isDisableDesc)
//        XCTAssertFalse(permission.isDisableMeetingRomm)
//        XCTAssertFalse(permission.isRemoveDeleteItem)
//        XCTAssertFalse(permission.isHideAttendeeView)
//        XCTAssertFalse(permission.isRemoveCalendarView)
//
//        permission = AttendeePermission(editPermission: .participantEdit,
//                                                 isLocalEvent: false,
//                                                 isGoogleEvent: false,
//                                                 guestCanInvite: false,
//                                                 guestCanSeeOtherGuests: false,
//                                                 isAttendeeEmpty: false)
//        XCTAssertFalse(permission.isDisableMeetingRomm)
//        XCTAssertTrue(permission.isHideAttendeeView)
//        XCTAssertTrue(permission.isDisableTitleEdit)
//        XCTAssertTrue(permission.isDisableDateSelect)
//        XCTAssertTrue(permission.isDisableLocation)
//        XCTAssertTrue(permission.isDisableRRule)
//        XCTAssertTrue(permission.isDisableDesc)
//        XCTAssertFalse(permission.isRemoveDeleteItem)
//        XCTAssertFalse(permission.isDisableAttendeeSelect)
//        XCTAssertFalse(permission.isRemoveCalendarView)
//
//        permission = AttendeePermission(editPermission: .participantEdit,
//                                                 isLocalEvent: true,
//                                                 isGoogleEvent: false,
//                                                 guestCanInvite: false,
//                                                 guestCanSeeOtherGuests: false,
//                                                 isAttendeeEmpty: true)
//        XCTAssertTrue(permission.isHideAttendeeView)
//        XCTAssertTrue(permission.isDisableTitleEdit)
//        XCTAssertTrue(permission.isDisableDateSelect)
//        XCTAssertTrue(permission.isDisableLocation)
//        XCTAssertTrue(permission.isDisableRRule)
//        XCTAssertTrue(permission.isDisableDesc)
//        XCTAssertTrue(permission.isDisableMeetingRomm)
//        XCTAssertFalse(permission.isRemoveDeleteItem)
//        XCTAssertFalse(permission.isDisableAttendeeSelect)
//        XCTAssertTrue(permission.isRemoveCalendarView)
//
//        permission = AttendeePermission(editPermission: .participantEdit,
//                                                 isLocalEvent: true,
//                                                 isGoogleEvent: false,
//                                                 guestCanInvite: false,
//                                                 guestCanSeeOtherGuests: false,
//                                                 isAttendeeEmpty: false)
//        XCTAssertTrue(permission.isDisableAttendeeSelect)
//        XCTAssertTrue(permission.isDisableMeetingRomm)
//        XCTAssertTrue(permission.isDisableTitleEdit)
//        XCTAssertTrue(permission.isDisableDateSelect)
//        XCTAssertTrue(permission.isDisableLocation)
//        XCTAssertTrue(permission.isDisableRRule)
//        XCTAssertTrue(permission.isDisableDesc)
//        XCTAssertFalse(permission.isRemoveDeleteItem)
//        XCTAssertFalse(permission.isHideAttendeeView)
//        XCTAssertTrue(permission.isRemoveCalendarView)
//    }
//}
