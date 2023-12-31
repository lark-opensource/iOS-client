////
////  PBCalendarEventEntityTest.swift
////  CalendarTests
////
////  Created by zhouyuan on 2018/11/26.
////  Copyright © 2018 EE. All rights reserved.
////
//
//import XCTest
//@testable import Calendar
//import RustPB
//
//func getMockCalendarEventPB() -> CalendarEvent {
//    var calendarEventPB = CalendarEvent()
//    calendarEventPB.id = "213"
//    return calendarEventPB
//}
//
//class PBCalendarEventEntityTest: XCTestCase {
//    var calendarEventPB: CalendarEvent!
//    override func setUp() {
//        super.setUp()
//        calendarEventPB = getMockCalendarEventPB()
//    }
//
//    override func tearDown() {
//        super.tearDown()
//        calendarEventPB = nil
//    }
//
//    func testNormalEvent() {
//        let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//        XCTAssertEqual(calendarEventPB.id, calendarEventEvntity.id)
//        XCTAssertEqual(DataSource.sdk, calendarEventEvntity.getDataSource())
//        XCTAssertFalse(calendarEventEvntity.isLocalEvent())
//        XCTAssertFalse(calendarEventEvntity.isGoogleEvent())
//        XCTAssertNil(calendarEventEvntity.getEKEvent())
//
//    }
//
//    func testSummry() {
//        do {
//            let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//            XCTAssertEqual("(\(BundleI18n.Calendar.Calendar_Detail_NoTitle))", calendarEventEvntity.summary)
//            XCTAssertTrue(calendarEventEvntity.summaryIsEmpty)
//            XCTAssertEqual("(\(BundleI18n.Calendar.Calendar_Detail_NoTitle))", calendarEventEvntity.getTitle())
//        }
//        do {
//            calendarEventPB.summary = "123"
//            let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//            XCTAssertEqual("123", calendarEventEvntity.summary)
//            XCTAssertFalse(calendarEventEvntity.summaryIsEmpty)
//            XCTAssertEqual("123", calendarEventEvntity.getTitle())
//        }
//    }
//
//    func testSharability() {
//        do {
//            calendarEventPB.sharability = .sharable
//            let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//            XCTAssertTrue(calendarEventEvntity.isSharable)
//        }
//        do {
//            calendarEventPB.sharability = .forbiddenPrivate
//            let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//            XCTAssertFalse(calendarEventEvntity.isSharable)
//        }
//        do {
//            calendarEventPB.sharability = .forbiddenNotAccessible
//            let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//            XCTAssertFalse(calendarEventEvntity.isSharable)
//        }
//    }
//
//    func testRecurrence() {
//        do {
//            calendarEventPB.rrule = "123"
//            calendarEventPB.originalTime = 0
//            let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//            XCTAssertTrue(calendarEventEvntity.isRecurrence())
//            XCTAssertTrue(calendarEventEvntity.isRepetitive())
//            XCTAssertFalse(calendarEventEvntity.isException())
//        }
//
//        do {
//            calendarEventPB.rrule = ""
//            calendarEventPB.originalTime = 1234
//            let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//            XCTAssertFalse(calendarEventEvntity.isRecurrence())
//            XCTAssertTrue(calendarEventEvntity.isRepetitive())
//            XCTAssertTrue(calendarEventEvntity.isException())
//        }
//
//        do {
//            calendarEventPB.rrule = ""
//            calendarEventPB.originalTime = 0
//            let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//            XCTAssertFalse(calendarEventEvntity.isRecurrence())
//            XCTAssertFalse(calendarEventEvntity.isRepetitive())
//            XCTAssertFalse(calendarEventEvntity.isException())
//        }
//    }
//
//    func testVisibility() {
//        do {
//            calendarEventPB.visibility = .private
//            let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//            XCTAssertEqual(BundleI18n.Calendar.Calendar_Edit_Private,
//                           calendarEventEvntity.visibility.readableString())
//        }
//        do {
//            calendarEventPB.visibility = .public
//            let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//            XCTAssertEqual(BundleI18n.Calendar.Calendar_Edit_Public,
//                           calendarEventEvntity.visibility.readableString())
//        }
//        do {
//            calendarEventPB.visibility = .default
//            let calendarEventEvntity = PBCalendarEventEntity(pb: calendarEventPB)
//            XCTAssertEqual(BundleI18n.Calendar.Calendar_Edit_DefalutVisibility,
//                           calendarEventEvntity.visibility.readableString())
//        }
//    }
//
//}
