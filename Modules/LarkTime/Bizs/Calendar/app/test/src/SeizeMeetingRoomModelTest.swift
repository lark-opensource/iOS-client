////
////  SeizeMeetingRoomModelTest.swift
////  CalendarDemoEEUnitTest
////
////  Created by harry zou on 2019/5/8.
////
//
//import XCTest
//@testable import Calendar
////swiftlint:disable function_body_length
//class SeizeMeetingRoomModelTest: XCTestCase {
//
//    func testName() {
//        let model = SeizeMeetingRoomModel(meetingRoom: MeetingRoom(id: "",
//                                                                   name: "test",
//                                                                   buildingId: "1",
//                                                                   attendeeCalendarId: "100",
//                                                                   isAvailable: true,
//                                                                   isRemoved: false,
//                                                                   buildingName: "test",
//                                                                   floorName: "F1",
//                                                                   capacity: 10,
//                                                                   weight: 0,
//                                                                   status: .accept,
//                                                                   isNewAdd: false,
//                                                                   tenantId: "1",
//                                                                   calendarId: "1",
//                                                                   isEditable: true,
//                                                                   isDisabled: false),
//                                          seizeTime: 600,
//                                          currentTimeStamp: 1_557_300_172, //2019/5/8 15:22:52
//            shouldShowConfirm: false,
//            instances: [])
//        let name = "F1-test test"
//        XCTAssertEqual(name, model.getMeetingRoomTitle())
//    }
//
//    func testGetCountdownInfo() {
//        let model = SeizeMeetingRoomModel(meetingRoom: MeetingRoom(id: "",
//                                                                   name: "test",
//                                                                   buildingId: "1",
//                                                                   attendeeCalendarId: "100",
//                                                                   isAvailable: true,
//                                                                   isRemoved: false,
//                                                                   buildingName: "test",
//                                                                   floorName: "F1",
//                                                                   capacity: 10,
//                                                                   weight: 0,
//                                                                   status: .accept,
//                                                                   isNewAdd: false,
//                                                                   tenantId: "1",
//                                                                   calendarId: "1",
//                                                                   isEditable: true,
//                                                                   isDisabled: false),
//                                          seizeTime: 600,
//                                          currentTimeStamp: 1_557_300_172, //2019/5/8 15:22:52
//            shouldShowConfirm: false,
//            instances: [])
//        let info = (0, 1_557_300_172, 1_557_331_199, false)
//        XCTAssertEqual(try model.getCountdownInfo().0, info.0)
//        XCTAssertEqual(try model.getCountdownInfo().1, info.1)
//        XCTAssertEqual(try model.getCountdownInfo().2, info.2)
//        XCTAssertEqual(try model.getCountdownInfo().3, info.3)
//
//        var instance = mockCalendarEventInstancePB()
//        instance.startTime = 1_557_300_152
//        instance.endTime = 1_557_301_152
//        var instance2 = mockCalendarEventInstancePB()
//        instance2.startTime = 1_557_331_100
//        instance2.endTime = 1_557_301_300
//
//        let model2 = SeizeMeetingRoomModel(meetingRoom: MeetingRoom(id: "",
//                                                                    name: "test",
//                                                                    buildingId: "1",
//                                                                    attendeeCalendarId: "100",
//                                                                    isAvailable: true,
//                                                                    isRemoved: false,
//                                                                    buildingName: "test",
//                                                                    floorName: "F1",
//                                                                    capacity: 10,
//                                                                    weight: 0,
//                                                                    status: .accept,
//                                                                    isNewAdd: false,
//                                                                    tenantId: "1",
//                                                                    calendarId: "1",
//                                                                    isEditable: true,
//                                                                    isDisabled: false),
//                                           seizeTime: 600,
//                                           currentTimeStamp: 1_557_300_172, //2019/5/8 15:22:52
//            shouldShowConfirm: false,
//            instances: [CalendarEventInstanceEntityFromPB(withInstance: instance)])
//        let info2 = (580, 1_557_300_752, 1_557_331_199, true)
//        XCTAssertEqual(try model2.getCountdownInfo().0, info2.0)
//        XCTAssertEqual(try model2.getCountdownInfo().1, info2.1)
//        XCTAssertEqual(try model2.getCountdownInfo().2, info2.2)
//        XCTAssertEqual(try model2.getCountdownInfo().3, info2.3)
//
//        let model3 = SeizeMeetingRoomModel(meetingRoom: MeetingRoom(id: "",
//                                                                    name: "test",
//                                                                    buildingId: "1",
//                                                                    attendeeCalendarId: "100",
//                                                                    isAvailable: true,
//                                                                    isRemoved: false,
//                                                                    buildingName: "test",
//                                                                    floorName: "F1",
//                                                                    capacity: 10,
//                                                                    weight: 0,
//                                                                    status: .accept,
//                                                                    isNewAdd: false,
//                                                                    tenantId: "1",
//                                                                    calendarId: "1",
//                                                                    isEditable: true,
//                                                                    isDisabled: false),
//                                           seizeTime: 600,
//                                           currentTimeStamp: 1_557_300_172, //2019/5/8 15:22:52
//            shouldShowConfirm: false,
//            instances: [CalendarEventInstanceEntityFromPB(withInstance: instance),
//                        CalendarEventInstanceEntityFromPB(withInstance: instance2)])
//        let info3 = (580, 1_557_300_752, 1_557_331_100, true)
//        print(model2)
//        print(model3)
//        XCTAssertEqual(try model2.getCountdownInfo().0, info2.0)
//        XCTAssertEqual(try model2.getCountdownInfo().1, info2.1)
//        XCTAssertEqual(try model2.getCountdownInfo().2, info2.2)
//        XCTAssertEqual(try model2.getCountdownInfo().3, info2.3)
//        let model4 = SeizeMeetingRoomModel(meetingRoom: MeetingRoom(id: "",
//                                                                    name: "test",
//                                                                    buildingId: "1",
//                                                                    attendeeCalendarId: "100",
//                                                                    isAvailable: true,
//                                                                    isRemoved: false,
//                                                                    buildingName: "test",
//                                                                    floorName: "F1",
//                                                                    capacity: 10,
//                                                                    weight: 0,
//                                                                    status: .accept,
//                                                                    isNewAdd: false,
//                                                                    tenantId: "1",
//                                                                    calendarId: "1",
//                                                                    isEditable: true,
//                                                                    isDisabled: false),
//                                           seizeTime: 600,
//                                           currentTimeStamp: 1_557_300_172, //2019/5/8 15:22:52
//            shouldShowConfirm: false,
//            instances: [CalendarEventInstanceEntityFromPB(withInstance: instance2)])
//        let info4 = (0, 1_557_300_172, 1_557_331_100, false)
//        XCTAssertEqual(try model2.getCountdownInfo().0, info2.0)
//        XCTAssertEqual(try model2.getCountdownInfo().1, info2.1)
//        XCTAssertEqual(try model2.getCountdownInfo().2, info2.2)
//        XCTAssertEqual(try model2.getCountdownInfo().3, info2.3)
//
//    }
//}
