////
////  GoogleDetailTableModelTest.swift
////  CalendarTests
////
////  Created by zhouyuan on 2018/11/19.
////  Copyright © 2018 EE. All rights reserved.
////
//
//import XCTest
//@testable import Calendar
//import RustPB
//
//class GoogleDetailTableModelTest: XCTestCase {
//
//    var event: MockCalendarEventEntity!
//    var instancePB: CalendarEventInstance!
//    var calendar: MockCalendarEntity!
//    override func setUp() {
//        super.setUp()
//        instancePB = mockCalendarEventInstancePB()
//        instancePB.source = .google
//        calendar = MockCalendarEntity()
//
//        event = MockCalendarEventEntity()
//        event.source = .google
//        calendar.type = .google
//    }
//
//    override func tearDown() {
//        super.tearDown()
//        instancePB = nil
//        event = nil
//        calendar = nil
//    }
//
//    func getDetailTableModel(event: CalendarEventEntity,
//                             instancePB: CalendarEventInstance,
//                             calendar: CalendarModel?)
//        -> (EventComponentViewControllerModel, ThirdPartyDetailTableModel) {
//            let instance = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            let eventDetailViewModel = CalendarEventDetailViewModel(fromEntity: event,
//                                                                    instance: instance,
//                                                                    calendar: calendar)
//            let componentModel = EventComponentViewControllerModel(eventDetailViewModel: eventDetailViewModel)
//            let detailTableModel = ThirdPartyDetailTableModel(model: componentModel, currentTenantId: "1", is12HourStyle: false)
//            return (componentModel, detailTableModel)
//    }
//
//    func testTime() {
//        let (componentModel, detailTableModel) = getDetailTableModel(event: event,
//                                                                     instancePB: instancePB,
//                                                                     calendar: nil)
//        XCTAssertEqual(getDateFromInt64(componentModel.eventDetailViewModel.eventInstanceStartTime),
//                       detailTableModel.time.startTime)
//        XCTAssertEqual(getDateFromInt64(componentModel.eventDetailViewModel.eventInstanceEndTime),
//                       detailTableModel.time.endTime)
//        XCTAssertEqual(componentModel.eventDetailViewModel.readableRRule,
//                       detailTableModel.time.subTitle)
//        XCTAssertEqual(componentModel.eventDetailViewModel.isAllDay,
//                       detailTableModel.time.isAllDay)
//    }
//
//    func testReminder() {
//        do {
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.reminder)
//        }
//
//        do {
//            event.reminders = [Reminder(minutes: 15, isAllDay: false)]
//            let (componentModel, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertEqual(componentModel.eventDetailViewModel.getReminderString(false, is12HourStyle: false),
//                           detailTableModel.reminder?.title)
//        }
//    }
//
//    func testLocation() {
//        do {
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.location)
//        }
//        do {
//            instancePB.displayType = .limited
//            event.displayType = .limited
//            var location = CalendarLocation()
//            location.location = "123"
//            location.address = "123"
//            location.latitude = 360.0
//            location.longitude = 360.0
//            event.location = location
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.location)
//        }
//        do {
//            instancePB.displayType = .full
//            event.displayType = .full
//            var location = CalendarLocation()
//            location.location = "123"
//            location.address = "123"
//            location.latitude = 360.0
//            location.longitude = 360.0
//            event.location = location
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertEqual(location.location, detailTableModel.location?.location)
//            XCTAssertEqual(location.address, detailTableModel.location?.address)
//            XCTAssertEqual(location.longitude, detailTableModel.location?.longitude)
//            XCTAssertEqual(location.latitude, detailTableModel.location?.latitude)
//        }
//    }
//
//    func testIsShowChat() {
//        let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                        instancePB: instancePB,
//                                                        calendar: nil)
//        XCTAssertFalse(detailTableModel.isShowChat)
//    }
//
//    func testMeetingConditions() {
//        do {
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: calendar)
//            XCTAssertNil(detailTableModel.meetingConditions)
//        }
//    }
//
//    func testDesc() {
//        do {
//            event.docsDescription = ""
//            event.description = ""
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.desc)
//        }
//        do {
//            event.docsDescription = "123"
//            event.description = ""
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertEqual("123", detailTableModel.desc?.docsData)
//            XCTAssertEqual("", detailTableModel.desc?.desc)
//        }
//        do {
//            event.displayType = .limited
//            instancePB.displayType = .limited
//            event.docsDescription = "123"
//            event.description = ""
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.desc)
//        }
//    }
//
//    func testCreater() {
//        let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                        instancePB: instancePB,
//                                                        calendar: nil)
//        XCTAssertNil(detailTableModel.creater)
//    }
//
//    func testFreeBusy() {
//        do {
//            event.isFree = false
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.freeBusy)
//        }
//        do {
//            event.isFree = true
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertEqual(BundleI18n.Calendar.Calendar_Detail_Free, detailTableModel.freeBusy?.freeBusyString)
//        }
//    }
//
//    func testVisibility() {
//        do {
//            event.visibility = .default
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.visibility)
//        }
//        do {
//            event.visibility = .public
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertEqual(BundleI18n.Calendar.Calendar_Edit_Public, detailTableModel.visibility?.visibilityString)
//        }
//        do {
//            event.visibility = .private
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertEqual(BundleI18n.Calendar.Calendar_Edit_Private, detailTableModel.visibility?.visibilityString)
//        }
//    }
//
//    func testIsAttendeeHidden() {
//        do {
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.attendee)
//        }
//        do {
//            event.displayType = .limited
//            instancePB.displayType = .limited
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            guard let attendeeModel = detailTableModel.attendee,
//                case DetailAttendee.attendeeHidden = attendeeModel else {
//                    XCTAssert(false)
//                    return
//            }
//        }
//        do {
//            event.displayType = .full
//            instancePB.displayType = .full
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.attendee)
//        }
//        do {
//            event.displayType = .full
//            instancePB.displayType = .full
//            event.organizerCalendarId = "0000"
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.attendee)
//        }
//        do {
//            event.displayType = .full
//            instancePB.displayType = .full
//            event.organizerCalendarId = "0000"
//            event.guestCanInvite = false
//            event.guestCanModify = false
//            event.guestCanSeeOtherGuests = false
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            guard let attendeeModel = detailTableModel.attendee,
//                case DetailAttendee.attendeeHidden = attendeeModel else {
//                    XCTAssert(false)
//                    return
//            }
//        }
//    }
//
//    func testMeetingRoom() {
//        do {
//            event.attendees = []
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.meetingRoom)
//        }
//        do {
//            var meeting1 = MockCalendarEventAttendeeEntity()
//            meeting1.isResource = true
//            meeting1.localizedDisplayName = "123"
//            meeting1.status = .accept
//            event.attendees = [meeting1]
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertEqual(1, detailTableModel.meetingRoom?.rooms.count)
//            XCTAssertEqual("123", detailTableModel.meetingRoom?.rooms[0].title)
//        }
//        do {
//            var meeting1 = MockCalendarEventAttendeeEntity()
//            meeting1.isResource = true
//            meeting1.localizedDisplayName = "123"
//            meeting1.status = .accept
//            var meeting2 = MockCalendarEventAttendeeEntity()
//            meeting2.isResource = true
//            meeting2.localizedDisplayName = "321"
//            meeting2.status = .removed
//            event.attendees = [meeting1, meeting2]
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertEqual(1, detailTableModel.meetingRoom?.rooms.count)
//            XCTAssertEqual("123", detailTableModel.meetingRoom?.rooms[0].title)
//        }
//        do {
//            var meeting1 = MockCalendarEventAttendeeEntity()
//            meeting1.isResource = true
//            meeting1.localizedDisplayName = "123"
//            meeting1.status = .accept
//            var meeting2 = MockCalendarEventAttendeeEntity()
//            meeting2.isResource = true
//            meeting2.localizedDisplayName = "321"
//            meeting2.status = .removed
//            event.attendees = [meeting1, meeting2]
//            event.displayType = .limited
//            instancePB.displayType = .limited
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.meetingRoom)
//        }
//    }
//
//    func testMeetingRoomAttendee() {
//        do {
//            calendar.type = .primary
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: calendar)
//            XCTAssertNil(detailTableModel.contactAttendee)
//        }
//
//        do {
//            calendar.type = .googleResource
//            var creator = MockCalendarEventAttendeeEntity()
//            creator.localizedDisplayName = "zhouyuan"
//            event.creator = creator
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: calendar)
//            if let contactAttendee = detailTableModel.contactAttendee,
//                case let ContactAttendee.contactInfo(attendee) = contactAttendee {
//                XCTAssertEqual("zhouyuan", attendee.avatar.avatar.userName)
//            } else {
//                XCTFail("出错!")
//            }
//        }
//    }
//
//    func testIsAttendeeInvisible() {
//        do {
//            calendar.type = .primary
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: calendar)
//            XCTAssertNil(detailTableModel.contactAttendee)
//        }
//        do {
//            event.visibility = .private
//            calendar.type = .googleResource
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: calendar)
//            if let contactAttendee = detailTableModel.contactAttendee,
//                case let ContactAttendee.contactInfo(attendee) = contactAttendee {
//                XCTAssertEqual("zhouyuan", attendee.avatar.avatar.userName)
//            } else {
//                XCTFail("出错!")
//            }
//        }
//    }
//
//    func testCalendar() {
//        do {
//            calendar.localizedSummary = "zhouyuan"
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: calendar)
//            XCTAssertEqual("zhouyuan", detailTableModel.calendar?.calendarName)
//        }
//        do {
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: nil)
//            XCTAssertNil(detailTableModel.calendar)
//        }
//    }
//
//    func testAttendee() {
//        do {
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: calendar)
//            XCTAssertNil(detailTableModel.attendee)
//        }
//        do {
//            event.displayType = .limited
//            instancePB.displayType = .limited
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: calendar)
//            if let attendeeModel = detailTableModel.attendee,
//                case DetailAttendee.attendeeHidden = attendeeModel {
//            } else {
//                XCTFail("出错!")
//            }
//        }
//        do {
//            event.displayType = .full
//            instancePB.displayType = .full
//            var meeting1 = MockCalendarEventAttendeeEntity()
//            meeting1.attendeeCalendarId = "1"
//            meeting1.isResource = true
//            meeting1.localizedDisplayName = "123"
//            meeting1.status = .accept
//
//            var attendee1 = MockCalendarEventAttendeeEntity()
//            attendee1.attendeeCalendarId = "2"
//            attendee1.isResource = false
//            attendee1.localizedDisplayName = "123"
//            attendee1.status = .accept
//
//            var attendee2 = MockCalendarEventAttendeeEntity()
//            attendee2.attendeeCalendarId = "3"
//            attendee2.isResource = false
//            attendee2.localizedDisplayName = "123"
//            attendee2.status = .accept
//            event.attendees = [meeting1, attendee1, attendee2]
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: calendar)
//            if let attendeeModel = detailTableModel.attendee,
//                case let DetailAttendee.attendees(attendee) = attendeeModel {
//                XCTAssertEqual(2, attendee.totalAttendeeNumber)
//                XCTAssertEqual(2, attendee.avatars.count)
//            } else {
//                XCTFail("出错!")
//            }
//
//        }
//        do {
//            event.displayType = .full
//            instancePB.displayType = .full
//
//            var attendee1 = MockCalendarEventAttendeeEntity()
//            attendee1.isResource = false
//            attendee1.localizedDisplayName = "123"
//            attendee1.status = .decline
//
//            event.attendees = [attendee1]
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: calendar)
//            if let attendeeModel = detailTableModel.attendee,
//                case let DetailAttendee.attendees(attendee) = attendeeModel {
//                XCTAssertEqual(1, attendee.totalAttendeeNumber)
//                XCTAssertEqual(1, attendee.avatars.count)
//            } else {
//                XCTFail("出错!")
//            }
//
//        }
//
//        do {
//            calendar.type = .googleResource
//            event.displayType = .full
//            instancePB.displayType = .full
//
//            var attendee1 = MockCalendarEventAttendeeEntity()
//            attendee1.isResource = false
//            attendee1.localizedDisplayName = "123"
//            attendee1.status = .needsAction
//            event.attendees = [attendee1]
//            let (_, detailTableModel) = getDetailTableModel(event: event,
//                                                            instancePB: instancePB,
//                                                            calendar: calendar)
//            XCTAssertNil(detailTableModel.attendee)
//        }
//    }
//}
