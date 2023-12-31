////
////  InstanceBaseInfoTest.swift
////  CalendarTests
////
////  Created by heng zhu on 2019/1/6.
////  Copyright © 2019 EE. All rights reserved.
////
//
//import XCTest
//@testable import Calendar
//
//class InstanceBaseInfoTest: XCTestCase {
//
//    func testInstanceInfoFullTitle() {
//        var instance = mockCalendarEventInstancePB()
//        instance.displayType = .full
//        let title = InstanceBaseFunc.getTitleFromModel(
//            model: CalendarEventInstanceEntityFromPB(withInstance: instance),
//            calendar: MockCalendarEntity())
//        XCTAssertEqual(title, "123吧，吧")
//    }
//
//    func testInstanceInfoFullNoTitle() {
//        var instance = mockCalendarEventInstancePB()
//        instance.displayType = .full
//        instance.summary = ""
//        let title = InstanceBaseFunc.getTitleFromModel(
//            model: CalendarEventInstanceEntityFromPB(withInstance: instance),
//            calendar: nil)
//        XCTAssertEqual(title, "(\(BundleI18n.Calendar.Calendar_Detail_NoTitle))")
//    }
//
//    func testInstanceInfoLimitedTitle() {
//        var instance = mockCalendarEventInstancePB()
//        let entity = MockCalendarEntity()
//        instance.displayType = .limited
//        instance.displayType = .limited
//        do {
//            entity.type = .googleResource
//            let title = InstanceBaseFunc.getTitleFromModel(
//                model: CalendarEventInstanceEntityFromPB(withInstance: instance),
//                calendar: entity)
//            XCTAssertEqual(title, "zhouyuan\(BundleI18n.Calendar.Calendar_Meeting_Reserved)")
//        }
//
//        do {
//            entity.type = .resources
//            let title = InstanceBaseFunc.getTitleFromModel(
//                model: CalendarEventInstanceEntityFromPB(withInstance: instance),
//                calendar: entity)
//            XCTAssertEqual(title, "zhouyuan\(BundleI18n.Calendar.Calendar_Meeting_Reserved)")
//        }
//
//        do {
//            entity.type = .other
//            let title = InstanceBaseFunc.getTitleFromModel(
//                model: CalendarEventInstanceEntityFromPB(withInstance: instance),
//                calendar: entity)
//            XCTAssertEqual(title, "zhouyuan")
//        }
//
//        do {
//            entity.type = .other
//            let title = InstanceBaseFunc.getTitleFromModel(
//                model: CalendarEventInstanceEntityFromPB(withInstance: instance),
//                calendar: nil)
//            XCTAssertEqual(title, BundleI18n.Calendar.Calendar_Detail_Busy)
//        }
//
//        do {
//            entity.type = .primary
//            let title = InstanceBaseFunc.getTitleFromModel(
//                model: CalendarEventInstanceEntityFromPB(withInstance: instance),
//                calendar: entity)
//            XCTAssertEqual(title, "zhouyuan, \(BundleI18n.Calendar.Calendar_Detail_Busy)")
//        }
//
//        do {
//            entity.type = .unknownType
//            let title = InstanceBaseFunc.getTitleFromModel(
//                model: CalendarEventInstanceEntityFromPB(withInstance: instance),
//                calendar: entity)
//            XCTAssertEqual(title, "zhouyuan, \(BundleI18n.Calendar.Calendar_Detail_Busy)")
//        }
//    }
//}
