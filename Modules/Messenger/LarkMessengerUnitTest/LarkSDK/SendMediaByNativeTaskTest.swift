//
//  SendMediaProcessTest.swift
//  LarkSDK-Unit-Tests
//
//  Created by JackZhao on 2022/3/2.
//

import UIKit
import Foundation
import XCTest
import RxSwift
import LarkModel
@testable import LarkSDK
@testable import LarkRustClient
@testable import LarkSDKInterface

class SendMediaMsgOnScreenTaskTest: XCTestCase {
    private var task: SendMediaMsgOnScreenTask<SendMediaMsgOnScreenTaskTest>!
    private var input: SendMessageProcessInput<SendMediaModel>!
    var client: SDKRustService = {
        MockRustClient()
    }()
    var queue: DispatchQueue = DispatchQueue(label: "RustSendMessageAPI", qos: .utility)
    var currentChatter: Chatter = {
        SendMessageTestModel.mockChatter()
    }()

    override func setUp() {
        super.setUp()

        let params = SendMediaParams(
            exportPath: "info.exportPath",
            compressPath: "info.compressPath",
            name: "info.name",
            image: UIImage(),
            duration: Int32(3 * 1000),
            chatID: SendMessageTestModel.chatId,
            threadID: nil,
            parentMessage: nil
        )
        var content = QuasiContent()
        content.path = params.exportPath
        content.name = params.name
        content.width = Int32(params.image.size.width)
        content.height = Int32(params.image.size.height)
        content.duration = params.duration
        content.mediaSource = .lark
        content.compressPath = params.compressPath

        input = SendMessageProcessInput<SendMediaModel>(context: APIContext(contextID: "123"),
                                                        model: SendMediaModel(params: params,
                                                                              cid: SendMessageTestModel.mockCid,
                                                                              content: content,
                                                                              handler: { (_, task) in
            task(200)
        }))

        task = SendMediaMsgOnScreenTask(context: self)
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
        wait(for: [expectation], timeout: 3)
    }

}

extension SendMediaMsgOnScreenTaskTest: SendMediaMsgOnScreenTaskContext {
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in (letters.randomElement() ?? "a") })
    }

    func adjustLocalStatus(message: LarkModel.Message, stateHandler: ((SendMessageState) -> Void)?) {
    }
}
