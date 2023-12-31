//
//  SDKRustServiceUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/31.
//

import XCTest
import Foundation
import LarkContainer // InjectedLazy
import LarkRustClient // RequestPacket
import LarkSDKInterface // SDKRustService
import ThreadSafeDataStructure // SafeArray
@testable import LarkSendMessage // SendMessageRequest

/// SDKRustService新增单测
final class SDKRustServiceUnitTest: CanSkipTestCase {
    @InjectedLazy private var rustService: SDKRustService
    private let responseCount: SafeArray<String> = [] + .readWriteLock

    /// 测试serialToken是否生效
    func testSerialToken() {
        let expectation = LKTestExpectation(description: "@test serial token")
        // expectation.expectedFulfillmentCount = 6
        // 拥有相同的serialToken发起请求，SDKRustService内部会保证回调顺序和发送顺序相同
        var pack = RequestPacket(message: SendMessageRequest()); pack.serialToken = 10
        self.rustService.async(pack, callback: { [weak self] _ in
            guard let `self` = self else { return }
            XCTAssertEqual(self.responseCount.count, 0)
            self.responseCount.append("0")
            expectation.fulfill()
        })
        // callback的不一定是按照async顺序的
        /* self.rustService.async(pack, callback: { [weak self] _ in
         guard let `self` = self else { return }
         XCTAssertEqual(self.responseCount.count, 1)
         self.responseCount.append("0")
         expectation.fulfill()
         })
         self.rustService.async(pack, callback: { [weak self] _ in
         guard let `self` = self else { return }
         XCTAssertEqual(self.responseCount.count, 2)
         self.responseCount.append("0")
         expectation.fulfill()
         })
         self.rustService.async(pack, callback: { [weak self] _ in
         guard let `self` = self else { return }
         XCTAssertEqual(self.responseCount.count, 3)
         self.responseCount.append("0")
         expectation.fulfill()
         })
         self.rustService.async(pack, callback: { [weak self] _ in
         guard let `self` = self else { return }
         XCTAssertEqual(self.responseCount.count, 4)
         self.responseCount.append("0")
         expectation.fulfill()
         })
         self.rustService.async(pack, callback: { [weak self] _ in
         guard let `self` = self else { return }
         XCTAssertEqual(self.responseCount.count, 5)
         self.responseCount.append("0")
         expectation.fulfill()
         }) */
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }
}
