//
//  TrackerUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/2.
//

import XCTest
import Foundation
import LKCommonsTracker // Tracker

/// Tracker新增单测
final class TrackerUnitTest: CanSkipTestCase {
    func testStartEnd() {
        Tracker.shared.start(token: "token")
        XCTAssertNotNil(Tracker.shared.end(token: "token"))
    }

    func testRegister() {
        // .tea里没有注册的MyTracker1，但有注册好的TeaMonitorService
        XCTAssertNotNil(Tracker.shared.tracker(key: .tea))
        // .slardar里没有注册的MyTracker2，但有注册好的SlardarMonitorService
        XCTAssertNotNil(Tracker.shared.tracker(key: .slardar))

        let expectation = LKTestExpectation(description: "@test register")
        expectation.expectedFulfillmentCount = 2
        Tracker.register(key: .tea, tracker: MyTracker1(expectation))
        Tracker.register(key: .slardar, tracker: MyTracker2(expectation))
        DispatchQueue.global().async {
            Tracker.post(TeaEvent("test tea event"))
            Tracker.post(SlardarEvent(name: "test slardar event", metric: [:], category: [:], extra: [:]))
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }
}

final class MyTracker1: TrackerService {
    private let expectation: XCTestExpectation
    init(_ expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    func post(event: LKCommonsTracker.Event) {
        self.expectation.fulfill()
    }
}
final class MyTracker2: TrackerService {
    private let expectation: XCTestExpectation
    init(_ expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    func post(event: LKCommonsTracker.Event) {
        self.expectation.fulfill()
    }
}
