////
////  CalendarEventInstanceEntityFromPBTest.swift
////  CalendarTests
////
////  Created by zhouyuan on 2018/11/20.
////  Copyright © 2018 EE. All rights reserved.
////
//
//import XCTest
//@testable import Calendar
//import RustPB
//@testable import CalendarFoundation
//// swiftlint:disable number_separator
//func mockCalendarEventInstancePB() -> CalendarEventInstance {
//    var instance = CalendarEventInstance()
//    instance.id = "163"
//    instance.eventID = "338"
//    instance.calendarID = "1591560057517060"
//    instance.organizerID = "1591560057517060"
//    instance.startTime = 1542700800
//    instance.startTimezone = "Asia/Shanghai"
//    instance.endTime = 1542706200
//    instance.endTimezone = "Asia/Shanghai"
//    instance.startDay = 2458443
//    instance.endDay = 2458443
//    instance.startMinute = 960
//    instance.endMinute = 1050
//    instance.key = "d1c9a989-5d5c-4057-870d-87ae950f3ce9"
//    instance.originalTime = 0
//    instance.color = -9852417
//    instance.calForegroundColor = -13553359
//    instance.calBackgroundColor = -9852417
//    instance.summary = "123吧，吧"
//    instance.isAllDay = false
//    instance.status = .confirmed
//    instance.selfAttendeeStatus = .accept
//    instance.isFree = false
//    instance.calAccessRole = .owner
//    instance.eventServerID = "3688745"
//    instance.isEditable = true
//    instance.visibility = .default
//    instance.isSubscriber = true
//    instance.displayType = .full
//    instance.source = .iosApp
//    instance.location = CalendarLocation()
//
//    var mappingColor = MappingColor()
//    mappingColor.backgroundColor = -9852417
//    mappingColor.foregroundColor = -16761187
//    mappingColor.eventCardColor = -10510865
//    mappingColor.eventColorIndex = "6"
//    instance.eventColor = mappingColor
//    instance.calColor = mappingColor
//    return instance
//}
//
//class CalendarEventInstanceEntityFromPBTest: XCTestCase {
//
//    var instancePB: CalendarEventInstance!
//
//    override func setUp() {
//        super.setUp()
//        instancePB = mockCalendarEventInstancePB()
//    }
//
//    override func tearDown() {
//        super.tearDown()
//        instancePB = nil
//    }
//
//    func testNormalInstance() {
//        let instance: CalendarEventInstanceEntity
//            = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//        XCTAssertEqual(instancePB.id, instance.id)
//        XCTAssertEqual(instancePB.summary, instance.displaySummary())
//        XCTAssertEqual(instancePB.displayType, instance.displayType)
//        XCTAssertEqual(Date(timeIntervalSince1970: TimeInterval(instancePB.startTime)),
//                       instance.startDate)
//        XCTAssertEqual(Date(timeIntervalSince1970: TimeInterval(instancePB!.endTime)),
//                       instance.endDate)
//        XCTAssertTrue(instance.canEdit())
//        XCTAssertFalse(instance.isOverOneDay)
//        XCTAssertFalse(instance.isLocalEvent())
//        XCTAssertFalse(instance.isMoreThan24Hours())
//        XCTAssertTrue(instance.isBelongsTo(startTime: instance.startDate.dayStart(),
//                                           endTime: (instance.startDate + 1.day)!))
//    }
//
//    func testNoTitle() {
//        instancePB.summary = ""
//        let instance: CalendarEventInstanceEntity
//            = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//        XCTAssertEqual("(\(BundleI18n.Calendar.Calendar_Detail_NoTitle))", instance.displaySummary())
//    }
//
//    func testDisplayLimited() {
//        instancePB.displayType = .limited
//        instancePB.isFree = false
//        let instance: CalendarEventInstanceEntity
//            = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//        XCTAssertEqual(BundleI18n.Calendar.Calendar_Detail_Busy, instance.displaySummary())
//
//        instancePB.isFree = true
//        let instance1: CalendarEventInstanceEntity
//            = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//        XCTAssertEqual(BundleI18n.Calendar.Calendar_Detail_Free, instance1.displaySummary())
//    }
//
//    func testAllDayDate() {
//        instancePB.isAllDay = true
//        instancePB.startTime = 1542067200 // 北京 2018/11/13 8:0:0
//        instancePB.endTime = 1543276800 // 北京 2018/11/27 8:0:0
//        instancePB.startDay = 2458436
//        instancePB.endDay = 2458449
//        instancePB.startMinute = 0
//        instancePB.endMinute = 1440
//        let instance: CalendarEventInstanceEntity
//            = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//        XCTAssertEqual(Date(timeIntervalSince1970: 1542038400), instance.startDate)
//        XCTAssertEqual(Date(timeIntervalSince1970: 1543248000), instance.endDate)
//        XCTAssertTrue(instance.isMoreThan24Hours())
//        XCTAssertTrue(instance.shouldShowAsAllDayEvent())
//    }
//
//    func testCanEdit() {
//        instancePB.calAccessRole = .reader
//        let instance: CalendarEventInstanceEntity
//            = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//        XCTAssertFalse(instance.canEdit())
//    }
//
//    /// 全天日程添加会议室后变成非全天日程的显示
//    func testShouldShowAsAllDayEvent() {
//        do {
//            instancePB.isAllDay = false
//            instancePB.startTime = 1542038400 // 北京 2018/11/13 0:0:0
//            instancePB.endTime = 1542124800 // 北京 2018/11/13 24:00:00
//            instancePB.startDay = 2458436
//            instancePB.endDay = 2458436
//            instancePB.startMinute = 0
//            instancePB.endMinute = 1440
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertTrue(instance.isMoreThan24Hours())
//            XCTAssertTrue(instance.shouldShowAsAllDayEvent())
//        }
//        do {
//            instancePB.isAllDay = false
//            instancePB.startTime = 1542038400 // 北京 2018/11/13 0:0:0
//            instancePB.endTime = 1542124800 - 60 // 北京 2018/11/13 23:59:00
//            instancePB.startDay = 2458436
//            instancePB.endDay = 2458436
//            instancePB.startMinute = 0
//            instancePB.endMinute = 1439
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertFalse(instance.isMoreThan24Hours())
//            XCTAssertTrue(instance.shouldShowAsAllDayEvent())
//        }
//    }
//
//    func testCornerColor() {
//        instancePB.source = .google
//        let instance: CalendarEventInstanceEntity
//            = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//        XCTAssertTrue(instance.isGoogleEvent())
//        instancePB.selfAttendeeStatus = .decline
//        XCTAssertTrue(instance.isGoogleEvent())
//    }
//
//    func testIsBelongsTo() {
//        let startDate = Date(timeIntervalSince1970: 1542038400) // 北京 2018/11/13 0:0:0
//        let endDate = Date(timeIntervalSince1970: 1542124800) // 北京 2018/11/13 24:00:00
//        do {
//            instancePB.startTime = 1542038400 // 北京 2018/11/13 0:0:0
//            instancePB.endTime = 1542124800 // 北京 2018/11/13 24:00:00
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertTrue(instance.isBelongsTo(startTime: startDate, endTime: endDate))
//        }
//        do {
//            instancePB.startTime = 1542038400 // 北京 2018/11/13 0:0:0
//            instancePB.endTime = 1542124800 + 60 // 北京 2018/11/14 00:01:00
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertTrue(instance.isBelongsTo(startTime: startDate, endTime: endDate))
//        }
//        do {
//            instancePB.startTime = 1542038400 // 北京 2018/11/13 0:0:0
//            instancePB.endTime = 1542124800 - 60 // 北京 2018/11/13 23:59:00
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertTrue(instance.isBelongsTo(startTime: startDate, endTime: endDate))
//        }
//
//        do {
//            instancePB.startTime = 1542038400 + 60 // 北京 2018/11/13 00:01:00
//            instancePB.endTime = 1542124800 // 北京 2018/11/13 24:00:00
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertTrue(instance.isBelongsTo(startTime: startDate, endTime: endDate))
//        }
//        do {
//            instancePB.startTime = 1542038400 - 60 // 北京 2018/11/12 23:59:00
//            instancePB.endTime = 1542124800 // 北京 2018/11/13 24:00:00
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertTrue(instance.isBelongsTo(startTime: startDate, endTime: endDate))
//        }
//
//        do {
//            instancePB.startTime = 1542038400 + 60 // 北京 2018/11/13 00:01:00
//            instancePB.endTime = 1542124800 - 60 // 北京 2018/11/13 23:59:00
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertTrue(instance.isBelongsTo(startTime: startDate, endTime: endDate))
//        }
//        do {
//            instancePB.startTime = 1542038400 - 60 // 北京 2018/11/12 23:59:00
//            instancePB.endTime = 1542124800 - 60 // 北京 2018/11/13 23:59:00
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertTrue(instance.isBelongsTo(startTime: startDate, endTime: endDate))
//        }
//        do {
//            instancePB.startTime = 1542038400 - 60 // 北京 2018/11/12 23:59:00
//            instancePB.endTime = 1542124800 + 60 // 北京 2018/11/14 00:01:00
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertTrue(instance.isBelongsTo(startTime: startDate, endTime: endDate))
//        }
//        do {
//            instancePB.startTime = 1542038400 + 60 // 北京 2018/11/13 00:01:00
//            instancePB.endTime = 1542124800 + 60 // 北京 2018/11/14 00:01:00
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertTrue(instance.isBelongsTo(startTime: startDate, endTime: endDate))
//        }
//
//        do {
//            instancePB.startTime = 1542124800 // 北京 2018/11/14 00:00:00
//            instancePB.endTime = 1542124800 + 60 // 北京 2018/11/14 00:01:00
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertFalse(instance.isBelongsTo(startTime: startDate, endTime: endDate))
//        }
//
//        do {
//            instancePB.startTime = 1542038400 - 120 // 北京 2018/11/12 23:58:00
//            instancePB.endTime = 1542038400 - 60 // 北京 2018/11/12 23:59:00
//            let instance: CalendarEventInstanceEntity
//                = CalendarEventInstanceEntityFromPB(withInstance: instancePB)
//            XCTAssertFalse(instance.isBelongsTo(startTime: startDate, endTime: endDate))
//        }
//    }
//
//}
