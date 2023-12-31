//
//  SubscribeAble.swift
//  CalendarTests
//
//  Created by heng zhu on 2019/1/29.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import XCTest
@testable import Calendar
import RustPB

struct MockActionModel: SubscribeAbleModel {
    var calendarID: String
    var subscribeStatus: SubscribeStatus
    var isOwner: Bool

}

class SubscribeAbleTest: XCTestCase, SubscribeAble {

    func testGetReloadRow() {
        let mockModel1 = MockActionModel(calendarID: "0", subscribeStatus: .noSubscribe, isOwner: false)
        let mockModel2 = MockActionModel(calendarID: "1", subscribeStatus: .noSubscribe, isOwner: false)
        let result1 = getReloadRow(content: mockModel2, contents: [mockModel1, mockModel2])
        XCTAssert(result1.row == 1)

        let result2 = getReloadRow(content: mockModel2, contents: [mockModel1])
        XCTAssert(result2.row == 0)
    }
}
