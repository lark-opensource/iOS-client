////
////  MapMeetingRoomTest.swift
////  CalendarDemo
////
////  Created by heng zhu on 2019/1/30.
////
//
//import Foundation
//import XCTest
//@testable import Calendar
//import RustPB
////swiftlint:disable line_length
//class MapMeetingRoomTest: XCTestCase, SubscribeAble {
//
//    func mockMeetingRooms() -> [MeetingRoom] {
//        let meetingRoom1 = MeetingRoom(id: "1", name: "dfgdfgadf", buildingId: "", attendeeCalendarId: "", isAvailable: true, isRemoved: false, buildingName: "sdfaadaas", floorName: "asdfasdf", capacity: 1, weight: 1, status: .accept, isNewAdd: true, tenantId: "", calendarId: "1", isEditable: false, isDisabled: false)
//        let meetingRoom2 = MeetingRoom(id: "2", name: "", buildingId: "", attendeeCalendarId: "", isAvailable: true, isRemoved: false, buildingName: "", floorName: "", capacity: 1, weight: 1, status: .accept, isNewAdd: true, tenantId: "", calendarId: "222", isEditable: false, isDisabled: false)
//        let meetingRoom3 = MeetingRoom(id: "3", name: "", buildingId: "", attendeeCalendarId: "", isAvailable: true, isRemoved: false, buildingName: "", floorName: "", capacity: 1, weight: 1, status: .accept, isNewAdd: true, tenantId: "", calendarId: "3", isEditable: false, isDisabled: false)
//
//        return [meetingRoom1, meetingRoom2, meetingRoom3]
//    }
//
//    func mockCalendars() -> [CalendarModel] {
//
//        var calendarPB = RustPB.Calendar_V1_Calendar()
//        ///owner
//        let calendar1 = MockCalendarEntity()
//        calendar1.id = "1"
//        calendar1.serverId = "1"
//        calendarPB.serverID = "1"
//        calendar1.calendarPB = calendarPB
//        calendar1.type = .google
//        calendar1.selfAccessRole = .owner
//
//        ///owner
//        let calendar2 = MockCalendarEntity()
//        calendar2.id = "2"
//        calendar2.serverId = "2"
//        calendarPB.serverID = "2"
//        calendar2.calendarPB = calendarPB
//        calendar2.type = .google
//        calendar2.selfAccessRole = .owner
//
//        ///
//        let calendar3 = MockCalendarEntity()
//        calendar3.id = "3"
//        calendar3.serverId = "3"
//        calendar3.userId = "3"
//        calendar3.type = .primary
//        calendar3.selfAccessRole = .freeBusyReader
//        return [calendar1, calendar2, calendar3]
//    }
//
//    func testMapMeetingRoom() {
//        let meetingRooms = mockMeetingRooms()
//
//        let result = meetingRooms.mapMeetingRoom(mockCalendars())
//        let meeting1 = result[0]
//        let meeting2 = result[1]
//        let meeting3 = result[2]
//
//        XCTAssert(meeting1.isOwner == true)
//        XCTAssert(meeting2.isOwner == false)
//        XCTAssert(meeting3.isOwner == false)
//        XCTAssert(meeting1.subscribeStatus == .subscribed)
//        XCTAssert(meeting2.subscribeStatus == .noSubscribe)
//        XCTAssert(meeting3.subscribeStatus == .subscribed)
//
//        XCTAssert(meeting1.calendarID == meetingRooms[0].calendarId)
//        XCTAssert(meeting1.floorName == meetingRooms[0].floorName)
//        XCTAssert(meeting1.name == meetingRooms[0].name)
//        XCTAssert(meeting1.buildingName == meetingRooms[0].buildingName)
//        XCTAssert(meeting1.isAvailable == meetingRooms[0].isAvailable)
//        XCTAssert(meeting1.capacity == meetingRooms[0].capacity)
//    }
//
//}
