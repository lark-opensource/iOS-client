//
//  DeadlockIntegrationTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2022/12/29.
//

import Foundation
import XCTest
import LarkContainer // InjectedSafeLazy
@testable import LarkSendMessage

/// 测试RustSendMessageAPI部分方法多线程调用不会导致死锁
final class DeadlockIntegrationTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI

    func testDeadlock() {
        /// 发消息不上屏问题：https://bytedance.sg.feishu.cn/docx/doxcnqWdxjujJdPZQ7a3c9ihBad
        /// 该问题主要由于多线程调用函数dealPushMessage、adjustLocalStatus所致
        /// 本case对RustSendMessageAPI中所有使用锁的函数进行多线程调用并检测是否存在死锁
        let expectation = LKTestExpectation(description: "@test test dead lock")
        /// 设置运行的子线程数量
        let count = 10
        /// 共计4个被测函数，因此fulfill执行的总数为count * 4
        expectation.expectedFulfillmentCount = count * 4
        /// 构造测试消息
        let msg = MockDataCenter.genMessage()
        for _ in 1...count {
            DispatchQueue.global().async {
                _ = self.sendMessageAPI.dealPushMessage(message: msg)
                expectation.fulfill()
            }
        }
        for _ in 1...count {
            DispatchQueue.global().async {
                self.sendMessageAPI.adjustLocalStatus(message: msg, stateHandler: nil)
                expectation.fulfill()
            }
        }
        for _ in 1...count {
            DispatchQueue.global().async {
                self.sendMessageAPI.preSendMessage(cid: RandomString.random(length: 10))
                expectation.fulfill()
            }
        }
        for _ in 1...count {
            DispatchQueue.global().async {
                self.sendMessageAPI.resendMessage(message: msg)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
    }
}
