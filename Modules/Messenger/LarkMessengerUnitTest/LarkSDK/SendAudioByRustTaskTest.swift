//
//  SendMediaCreateQuasiMsgTaskTest.swift
//  LarkSDK-Unit-Tests
//
//  Created by JackZhao on 2022/3/2.
//

import Foundation
import XCTest
import RxSwift
import LarkModel
import LarkContainer
@testable import LarkSDK
@testable import LarkRustClient
@testable import LarkSDKInterface

class SendAudioCreateQuasiMsgTaskTest: XCTestCase {
    private var task: SendAudioCreateQuasiMsgTask<SendAudioCreateQuasiMsgTaskTest>!
    private var input: SendMessageProcessInput<SendAudioModel>!
    var client: SDKRustService = {
        MockRustClient()
    }()
    var queue: DispatchQueue = DispatchQueue(label: "RustSendMessageAPI", qos: .utility)
    var currentChatter: Chatter = {
        SendMessageTestModel.mockChatter()
    }()

    override func setUp() {
        super.setUp()

        let data = Data()
        let audioDataInfo = NewAudioDataInfo(dateType: .data(data),
                                             length: 100,
                                             type: .opus,
                                             text: "audio.text")
        var content = QuasiContent()
        content.audio = data
        content.duration = Int32(1 * 1000)
        content.text = "text"

        self.input = SendMessageProcessInput(context: APIContext(contextID: "123"),
                                             model: SendAudioModel(info: audioDataInfo,
                                                                   chatId: SendMessageTestModel.chatId,
                                                                   threadId: nil,
                                                                   content: content))

        task = SendAudioCreateQuasiMsgTask(context: self)
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

extension SendAudioCreateQuasiMsgTaskTest: SendAudioMsgOnScreenTaskContext {
    var userResolver: UserResolver {  Container.shared.getCurrentUserResolver() }
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in (letters.randomElement() ?? "a") })
    }

    func adjustLocalStatus(message: LarkModel.Message, stateHandler: ((SendMessageState) -> Void)?) {
    }
}
