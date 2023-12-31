//
//  SendThreadMediaUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by JackZhao on 2022/12/14.
//

import Foundation
import XCTest
@testable import LarkSendMessage

/// 从thread页面发送视频，视频不在thread页面展示，漏到了chat页面：https://meego.feishu.cn/larksuite/issue/detail/6060125
final class SendThreadMediaUnitTest: CanSkipTestCase {
    /// 测试rootId获取
    func testGetRootIdWhenReplyInThread() {
        let parentMessage = MockDataCenter.genMessage()
        parentMessage.rootId = "456"
        let rootId = RustSendMessageModule.getRootId(parentMessage: parentMessage, replyInThread: true)
        XCTAssert(rootId == parentMessage.id)
        XCTAssert(rootId != parentMessage.rootId)
    }

    /// 测试rootId获取当parentMessage有rootId
    func testGetRootIdWhenHasRootId() {
        let parentMessage = MockDataCenter.genMessage()
        parentMessage.rootId = "456"
        let rootId = RustSendMessageModule.getRootId(parentMessage: parentMessage, replyInThread: false)
        XCTAssert(rootId == parentMessage.rootId)
        XCTAssert(rootId != parentMessage.id)
    }

    /// 测试rootId获取当parentMessage没有rootId
    func testGetRootIdWhenNotHasRootId() {
        let parentMessage = MockDataCenter.genMessage()
        let rootId = RustSendMessageModule.getRootId(parentMessage: parentMessage, replyInThread: false)
        XCTAssert(rootId == parentMessage.id)
    }
}
