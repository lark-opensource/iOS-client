////
////  FreeBusyFooterViewModelTest.swift
////  CalendarDemoEEUnitTest
////
////  Created by harry zou on 2019/3/20.
////
//
//import XCTest
//@testable import Calendar
//import LarkLocalizations
//
//class FreeBusyFooterViewModelTest: XCTestCase {
//    let newModel: ([String], Int) -> ArrangementFooterViewModel = { names, count -> ArrangementFooterViewModel in
//        let model = ArrangementFooterViewModel(startTime: Date(),
//                                               endTime: Date(),
//                                               totalAttendeeCnt: count,
//                                               unAvailableAttendeeNames: names,
//                                               hasNotWorkingHours: false,
//                                               textMaxWidth: 0,
//                                               is12HourStyle: false)
//        return model
//    }
//
//    func testColor() {
//        do {
//            let model = newModel([], 5)
//    //            - 如果所有参与者都有空，则显示“所有参与者都有空”，文字为[蓝色]
//            XCTAssertEqual(model.situationTextColor(), UIColor.lk.colorfulBlue)
//        }
//        do {
////        model.totalAttendeeCnt = 1
////        model.unAvailableAttendeeNames.append("John Doe")
//////            - 如果所有参与者都没空，则显示“所有参与者都没空”，文字为[红色]
//            let model = newModel(["A"], 1)
//            XCTAssertEqual(model.situationTextColor(), UIColor.lk.colorfulRed)
//        }
//        do {
//////            - 如果参与人中只有1-2个人没空
//////        - 参与人总数≥5时，则显示“除了XXX、XXX，其他人都有空”，文字为[灰色]
//////        - 参与人总数＜5时，则显示“NN名参与者中有MM人没空”，文字为[灰色]
//////        - 如果参与人有3个及以上没空，则显示“NN名参与者中，MM人没空”，文字为[灰色]
//            let model = newModel(["A"], 3)
//            XCTAssertEqual(model.situationTextColor(), UIColor.lk.N500)
//        }
//    }
//
//    func testSituationText() {
//        LanguageManager.setCurrentLanguage(.zh_CN, isSystem: false)
//
//        do {
//            let model = newModel([], 5)
//            XCTAssertEqual(model.subTitleAttributedText.string, "所有参与者都有空")
//        }
//        do {
//            let model = newModel(["A", "B", "C", "D", "E"], 5)
//            XCTAssertEqual(model.subTitleAttributedText.string, "所有参与者都没空")
//        }
//        do {
//            let model = newModel(["A", "B", "C", "D"], 5)
//            XCTAssertEqual(model.subTitleAttributedText.string, "5名参与者中，4人没空")
//        }
//        do {
//            let model = newModel(["A"], 5)
//        XCTAssertEqual(model.subTitleAttributedText.string, "除了A，其他人都有空")
//        }
//        do {
//            let model = newModel(["A", "B"], 5)
//            XCTAssertEqual(model.subTitleAttributedText.string, "除了A、B，其他人都有空")
//        }
//        do {
//            let model = newModel(["A", "B"], 4)
//            XCTAssertEqual(model.subTitleAttributedText.string, "4名参与者中，2人没空")
//        }
//        do {
//            let model = newModel(["A"], 4)
//            XCTAssertEqual(model.subTitleAttributedText.string, "4名参与者中，1人没空")
//        }
//    }
//
////    func testTimeText() {
////        LanguageManager.setCurrentLanguage(.zh_CN, isSystem: false)
////        var model = ArrangementFooterViewModel(startTime: Date(timeIntervalSince1970: 2_524_608_000),
////                                               endTime: Date(timeIntervalSince1970: 2_524_611_600),
////                                               totalAttendeeCnt: 5,
////                                               unAvailableAttendeeNames: [],
////                                               hasNotWorkingHours: false,
////                                               textMaxWidth: 0,
////                                               is12HourStyle: false)
////        XCTAssertEqual(model.timeText, "2050年1月1日（周六）08:00 - 09:00")
////        model = ArrangementFooterViewModel(startTime: Date(timeIntervalSince1970: 1_546_304_400),
////                                           endTime: Date(timeIntervalSince1970: 1_546_308_000),
////                                           totalAttendeeCnt: 5,
////                                           unAvailableAttendeeNames: [],
////                                           hasNotWorkingHours: false,
////                                           textMaxWidth: 0,
////                                           is12HourStyle: false)
////        XCTAssertEqual(model.timeText, "2019年1月1日（周二）09:00 - 10:00")
////    }
//}
