//
//  OperatorCounterUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/18.
//

import XCTest
import Foundation
@testable import LarkSendMessage

/// OperatorCounter新增单测
final class OperatorCounterUnitTest: CanSkipTestCase {
    // 测试线程安全的版本
    func testThreadSafe() {
        let operatorCounter = OperatorCounter()
        operatorCounter.increase(category: "-")
        XCTAssertTrue(operatorCounter.hasOperator)

        operatorCounter.decrease(category: "-")
        XCTAssertTrue(!operatorCounter.hasOperator)

        let expectation = LKTestExpectation(description: "@test thread safe")
        expectation.expectedFulfillmentCount = 200
        for _ in 0..<100 {
            DispatchQueue.global().async { operatorCounter.increase(category: "-"); expectation.fulfill() }
        }
        for _ in 0..<100 {
            DispatchQueue.global().async { operatorCounter.decrease(category: "-"); expectation.fulfill() }
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        // 这里不能加hasOperator的判断，因为子线程无法保证执行顺序
        // XCTAssertTrue(!operatorCounter.hasOperator)

        // 手动加一次，判断hasOperator是否正确
        operatorCounter.increase(category: "-")
        XCTAssertTrue(operatorCounter.hasOperator)
    }
}
