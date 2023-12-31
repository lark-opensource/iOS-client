//
//  MockFeedsAutomaticCases.swift
//  LarkMessengerDemoMockFeedsUITests
//
//  Created by bytedance on 2020/5/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest

class MockFeedsAutomaticCases: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func wait(for duration: TimeInterval) {
        let waitExpection = expectation(description: "Pure waiting...")

        let when = DispatchTime.now() + duration
        DispatchQueue.main.asyncAfter(deadline: when) {
            waitExpection.fulfill()
        }

        wait(for: [waitExpection], timeout: duration + 1)
    }

    // MARK: Test cases

    func testInboxCardsTwoUpdatesOneDelete() throws {
        let app = XCUIApplication()
        let cellsOriginalCount = 15
        app.launchArguments = ["InboxCardsTwoUpdatesOneDeleteMockFeedAPI", String(cellsOriginalCount), String(0)]
        app.launch()

        // 等待35秒，然后检查cells总数量 == 14，然后排第1个的cell unreadCount == 89，排第5个的cell unreadCount == 31
        wait(for: 35)

        let table = app.tables.element(boundBy: 0)
        XCTAssert(table.cells.count == cellsOriginalCount - 1, "TableCell应该要删掉1个")

        let firstCell = table.cells.element(boundBy: 0)
        let firstPredicate = NSPredicate(format: "label CONTAINS[c] %@", "89")
        let firstCellBadge = firstCell.staticTexts.containing(firstPredicate)
        XCTAssert(firstCellBadge.count == 1, "符合未读数是89的feed应该只有1个")

        let fifthCell = table.cells.element(boundBy: 4)
        let fifthPredicate = NSPredicate(format: "label CONTAINS[c] %@", "31")
        let fifthCellBadge = fifthCell.staticTexts.containing(fifthPredicate)
        XCTAssert(fifthCellBadge.count == 1, "符合未读数是31的feed应该也只有1个")
    }
}
