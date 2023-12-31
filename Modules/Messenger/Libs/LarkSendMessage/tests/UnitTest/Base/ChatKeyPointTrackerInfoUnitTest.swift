//
//  ChatKeyPointTrackerInfoUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/2.
//

import XCTest
import Foundation
import LarkModel // Chat
import LarkSendMessage

/// ChatKeyPointTrackerInfo新增单测
final class ChatKeyPointTrackerInfoUnitTest: CanSkipTestCase {
    /// p2p
    func testp2p() {
        let chat = Chat.transform(pb: Chat.PBModel()); chat.type = .p2P
        let trakcerInfo = ChatKeyPointTrackerInfo(id: "", isCrypto: false, inChatMessageDetail: false, chat: chat)
        XCTAssertEqual(trakcerInfo.chatTypeForReciableTrace, 1)
        XCTAssertEqual(trakcerInfo.log["chat_type"] ?? "", "single")
        XCTAssertEqual(trakcerInfo.log["crypto"] ?? "", "0")
    }

    /// messageDetail
    func testMessageDetail() {
        let chat = Chat.transform(pb: Chat.PBModel()); chat.type = .p2P
        let trakcerInfo = ChatKeyPointTrackerInfo(id: "", isCrypto: false, inChatMessageDetail: true, chat: chat)
        XCTAssertEqual(trakcerInfo.chatTypeForReciableTrace, 4)
        XCTAssertEqual(trakcerInfo.log["chat_type"] ?? "", "single")
        XCTAssertEqual(trakcerInfo.log["crypto"] ?? "", "0")
    }

    /// group
    func testGroup() {
        let chat = Chat.transform(pb: Chat.PBModel()); chat.type = .group
        let trakcerInfo = ChatKeyPointTrackerInfo(id: "", isCrypto: false, inChatMessageDetail: false, chat: chat)
        XCTAssertEqual(trakcerInfo.chatTypeForReciableTrace, 2)
        XCTAssertEqual(trakcerInfo.log["chat_type"] ?? "", "group")
        XCTAssertEqual(trakcerInfo.log["crypto"] ?? "", "0")
    }

    /// topicGroup
    func testTopicGroup() {
        let chat = Chat.transform(pb: Chat.PBModel()); chat.type = .topicGroup
        let trakcerInfo = ChatKeyPointTrackerInfo(id: "", isCrypto: false, inChatMessageDetail: false, chat: chat)
        XCTAssertEqual(trakcerInfo.chatTypeForReciableTrace, 0)
        XCTAssertEqual(trakcerInfo.log["chat_type"] ?? "", "topicGroup")
        XCTAssertEqual(trakcerInfo.log["crypto"] ?? "", "0")
    }

    /// crypto
    func testCrypto() {
        let chat = Chat.transform(pb: Chat.PBModel()); chat.type = .p2P
        let trakcerInfo = ChatKeyPointTrackerInfo(id: "", isCrypto: true, inChatMessageDetail: false, chat: chat)
        XCTAssertEqual(trakcerInfo.chatTypeForReciableTrace, 1)
        XCTAssertEqual(trakcerInfo.log["chat_type"] ?? "", "single")
        XCTAssertEqual(trakcerInfo.log["crypto"] ?? "", "1")
    }

    /// isMeeting
    func testIsMeeting() {
        let chat = Chat.transform(pb: Chat.PBModel()); chat.type = .p2P; chat.isMeeting = true
        let trakcerInfo = ChatKeyPointTrackerInfo(id: "", isCrypto: false, inChatMessageDetail: false, chat: chat)
        XCTAssertEqual(trakcerInfo.chatTypeForReciableTrace, 1)
        XCTAssertEqual(trakcerInfo.log["chat_type"] ?? "", "meeting")
        XCTAssertEqual(trakcerInfo.log["crypto"] ?? "", "0")
    }
}
