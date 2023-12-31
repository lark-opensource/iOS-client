//
//  SendThreadAPIUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/31.
//

import XCTest
import Foundation
import RustPB
import RxSwift // DisposeBag
import LarkModel // Message
import LarkContainer // InjectedLazy
import LarkSDKInterface // ThreadMessage
@testable import LarkSendMessage

/// SendThreadAPI新增单测
final class SendThreadAPIUnitTest: CanSkipTestCase {
    @InjectedLazy var sendThreadAPI: SendThreadAPI

    /// 测试statusDriver能否正常回调
    func testStatusDriverForSendError() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test status driver")
        self.sendThreadAPI.statusDriver.drive { (_, error) in
            XCTAssertNil(error)
            expectation.fulfill()
        }.disposed(by: disposeBag)
        self.sendThreadAPI.sendError(value: (ThreadMessage(thread: Basic_V1_Thread(), rootMessage: Message.transform(pb: Message.PBModel())), .threadChat, nil))
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试statusDriver能否正常回调
    func testStatusDriverForDealPush() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test status driver")
        let randomCid = RandomString.random(length: 10)
        self.sendThreadAPI.statusDriver.drive { (message, error) in
            guard message.rootMessage.cid == randomCid else { return }
            XCTAssertNil(error)
            XCTAssertEqual(message.rootMessage.cid, randomCid)
            expectation.fulfill()
        }.disposed(by: disposeBag)
        let message = Message.transform(pb: Message.PBModel()); message.cid = randomCid
        self.sendThreadAPI.addSendingCids(cid: randomCid)
        _ = self.sendThreadAPI.dealPush(thread: ThreadMessage(thread: Basic_V1_Thread(), rootMessage: message), sendThreadType: .threadChat)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试statusDriver能否正常回调
    func testStatusDriverForDealSending() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test status driver")
        let randomCid = RandomString.random(length: 10)
        self.sendThreadAPI.statusDriver.drive { (message, error) in
            guard message.rootMessage.cid == randomCid else { return }
            XCTAssertNil(error)
            XCTAssertEqual(message.rootMessage.cid, randomCid)
            expectation.fulfill()
        }.disposed(by: disposeBag)
        let message = Message.transform(pb: Message.PBModel()); message.cid = randomCid
        self.sendThreadAPI.dealSending(thread: ThreadMessage(thread: Basic_V1_Thread(), rootMessage: message), sendThreadType: .threadChat)
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }
}
