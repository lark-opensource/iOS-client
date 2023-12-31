//
//  SendImageCreateQuasiMsgTaskTest.swift
//  LarkSDK-Unit-Tests
//
//  Created by JackZhao on 2022/3/2.
//

import Foundation
import XCTest
import RustPB
import RxSwift
import LarkModel
import ByteWebImage
@testable import LarkSDK
@testable import LarkRustClient
@testable import LarkSDKInterface

class SendImageCreateQuasiMsgTest: XCTestCase {
    var client: SDKRustService = {
        MockRustClient()
    }()
    var queue: DispatchQueue = DispatchQueue(label: "RustSendMessageAPI", qos: .utility)

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_createMsg_result() {
        var originContent = RustPB.Basic_V1_QuasiContent()
        originContent.image = Data()
        originContent.isOriginSource = true
        let res = try? RustSendMessageModule.createQuasiMessage(
            chatId: SendMessageTestModel.chatId,
            threadId: "",
            rootId: "rootId",
            parentId: "input.parentId",
            type: .image,
            content: originContent,
            imageCompressedSize: 0,
            cid: SendMessageTestModel.mockCid,
            position: 0,
            client: client,
            context: APIContext(contextID: "123"))
        XCTAssert(res?.0 != nil)
    }
}
