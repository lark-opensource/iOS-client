////
////  CalendarModelTest.swift
////  CalendarDemoEEUnitTest
////
////  Created by harry zou on 2019/2/20.
////
//
//import XCTest
//@testable import Calendar
//
//class CalendarModelTest: XCTestCase {
//    var calendars: [CalendarModel] = []
//
//    override func setUp() {
//        super.setUp()
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//        let names = ["akiko", "あきこ", "アキコ", "明子", "佐藤", "山下", "山田", "John Doe", "无名氏", "韩梅梅"]
//        var weights: [Int] = []
//        for _ in 0...9 {
//            weights.append(abs(Int(arc4random() % 100)))
//        }
//        let role: [MockCalendarEntity.AccessRole] = [.owner, .owner, .owner, .owner, .freeBusyReader, .freeBusyReader, .freeBusyReader, .freeBusyReader, .freeBusyReader, .freeBusyReader]
//        let userId = [1, 1, 1, 1, 2, 3, 4, 5, 5, 7]
//        let type: [MockCalendarEntity.CalendarType] =
//            [.primary, .other, .google, .google, .primary,
//             .primary, .primary, .primary, .google, .primary]
//        var j = 0
//        for i in 0...9 {
//            let calendarModel = MockCalendarEntity()
//            calendarModel.localizedSummary = names[i]
//            calendarModel.weight = Int32(weights[i])
//            calendarModel.selfAccessRole = role[i]
//            if type[i] == .google {
//                calendarModel.externalAccountName = "googleEmail_\(j)"
//                j += 1
//            }
//
//            calendarModel.userId = String(userId[i])
//            calendarModel.type = type[i]
//            calendars.append(calendarModel)
//        }
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        super.tearDown()
//        calendars = []
//    }
//
//    func testClassifyCalendars() {
//        let classifiedCals = calendars.classifyCalendars()
//        XCTAssertEqual(classifiedCals.mineCalendars.count, 2)
//        XCTAssertEqual(classifiedCals.bookedCalendars.count, 6)
//        XCTAssertEqual(classifiedCals.googleCalendars.count, 2)
//    }
//
//    func testMergeCalendars() {
//        let mergedCals = calendars.merge(userId: "1", isVisible: { (name) -> Bool in
//            return name == "googleEmail_0"
//        })
//        XCTAssertEqual(mergedCals.count, 8)
//        for cal in mergedCals {
//            XCTAssert(cal.displayName() != "无名氏")
//        }
//    }
//}
