//
//  SendFileCreateQuasiMsgTaskTest.swift
//  LarkSDK-Unit-Tests
//
//  Created by JackZhao on 2022/3/2.
//

import Foundation
import XCTest
import RxSwift
import LarkModel
@testable import LarkSDK
@testable import LarkRustClient
@testable import LarkSDKInterface

class SendFileCreateQuasiMsgTaskTest: XCTestCase {
    private var task: SendFileCreateQuasiMsgTask<SendFileCreateQuasiMsgTaskTest>!
    private var input: SendMessageProcessInput<SendFileModel>!
    var client: SDKRustService = {
        MockRustClient()
    }()
    var queue: DispatchQueue = DispatchQueue(label: "RustSendMessageAPI", qos: .utility)
    var currentChatter: Chatter = {
        SendMessageTestModel.mockChatter()
    }()

    override func setUp() {
        super.setUp()

        var content = QuasiContent()
        content.path = "path"
        content.fileSource = .larkServer
        content.name = "name"
        let model = SendFileModel(path: "path",
                                  name: "name",
                                  chatId: SendMessageTestModel.chatId,
                                  threadId: nil,
                                  size: nil,
                                  content: content,
                                  removeOriginalFileAfterFinish: true)

        input = SendMessageProcessInput<SendFileModel>(context: APIContext(contextID: "123"),
                                                       model: model)

        task = SendFileCreateQuasiMsgTask(context: self)
    }

    override func tearDown() {
        super.tearDown()
        task = nil
    }

    func test_createMsg_result() {
        let expectation = self.expectation(description: "test_createMsg")
        task.onEnd { value in
            if case .success(let res) = value, res.message != nil {
                expectation.fulfill()
            }
        }
        task.run(input: input)
        wait(for: [expectation], timeout: 1)
    }

}

extension SendFileCreateQuasiMsgTaskTest: SendFileCreateQuasiMsgTaskContext {
    var createAndSendCombine: Bool {
        true
    }

    func addPendingMessages(id: String, value: (message: Message, filePath: String, deleteFileWhenFinish: Bool)) {
    }

    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in (letters.randomElement() ?? "a") })
    }

    func adjustLocalStatus(message: LarkModel.Message, stateHandler: ((SendMessageState) -> Void)?) {
    }
}
