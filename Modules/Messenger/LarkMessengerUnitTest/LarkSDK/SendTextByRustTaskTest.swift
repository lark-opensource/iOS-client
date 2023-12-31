//
//  SendTextCreateQuasiMsgTaskTest.swift
//  LarkSDK-Unit-Tests
//
//  Created by JackZhao on 2022/3/2.
//

import Foundation
import XCTest
import RustPB
import RxSwift
import LarkModel
import Swinject
@testable import LarkSDK
@testable import LarkRustClient
@testable import LarkSDKInterface
import LarkAccountInterface

class SendTextCreateQuasiMsgTaskTest: XCTestCase {
    private var task: SendTextCreateQuasiMsgTask<SendTextCreateQuasiMsgTaskTest>!
    private var input: SendMessageProcessInput<SendTextModel>!
    var client: SDKRustService = {
        MockRustClient()
    }()
    var queue: DispatchQueue = DispatchQueue(label: "RustSendMessageAPI", qos: .utility)
    var currentChatter: Chatter = {
        SendMessageTestModel.mockChatter()
    }()

    override func setUp() {
        super.setUp()
        let content = RustPB.Basic_V1_RichText.text("content")
        input = SendMessageProcessInput<SendTextModel>(context: APIContext(contextID: "123"),
                                                        model: SendTextModel(content: content,
                                                                             cid: SendMessageTestModel.mockCid,
                                                                             chatId: SendMessageTestModel.chatId,
                                                                             threadId: nil))

        task = SendTextCreateQuasiMsgTask(context: self)
    }

    override func tearDown() {
        super.tearDown()
        task = nil
    }

    func test_createMsg_result() {
        let expectation = self.expectation(description: "test_createMsg")
        task.onEnd { value in
            if case .success(let res) = value {
                guard res.message != nil else {
                    return
                }
                guard res.model.cid != nil else {
                    return
                }
                expectation.fulfill()
            }
        }
        task.run(input: input)
        wait(for: [expectation], timeout: 1)
    }
}

extension SendTextCreateQuasiMsgTaskTest: SendTextCreateQuasiMsgTaskContext {
    var createAndSendCombine: Bool {
        true
    }

    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in (letters.randomElement() ?? "a") })
    }

    func adjustLocalStatus(message: LarkModel.Message, stateHandler: ((SendMessageState) -> Void)?) {
    }
}
