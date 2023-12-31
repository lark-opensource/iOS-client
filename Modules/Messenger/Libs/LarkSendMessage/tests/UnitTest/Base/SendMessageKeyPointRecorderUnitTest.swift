//
//  SendMessageKeyPointRecorderUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/31.
//

import XCTest
import Foundation
import LarkModel // Message
import LarkContainer
@testable import LarkSendMessage

/// SendMessageKeyPointRecorder新增单测
final class SendMessageKeyPointRecorderUnitTest: CanSkipTestCase {
    /// 测试Success情况
    func testStateListenerSuccess() {
        let trackerInfo = ChatKeyPointTrackerInfo(id: "-", isCrypto: false, chat: nil)
        let recorder = SendMessageKeyPointRecorder(userResolver: Container.shared.getCurrentUserResolver(), stateListeners: [MySendMessageStateListener1(), MySendMessageStateListener2()])
        // beforeCreateQuasi
        recorder.startSendMessage(indentify: "-", chatInfo: trackerInfo)
        // createQuasiSuccess
        recorder.finishCallQuasiMessageAPI(indentify: "-", contextId: "-", message: Message.transform(pb: Message.PBModel()))
        // messageOnScreen
        _ = recorder.messageOnScreen(cid: "-", messageid: "-", page: "", renderCost: nil)
        // sendMessageSuccess
        _ = recorder.sendMessageFinish(cid: "-", messageId: "-", success: true, page: "", isCheckExitChat: false)
    }

    /// 测试Error情况
    func testStateListenerError() {
        let trackerInfo = ChatKeyPointTrackerInfo(id: "-", isCrypto: false, chat: nil)
        let recorder = SendMessageKeyPointRecorder(userResolver: Container.shared.getCurrentUserResolver(), stateListeners: [MySendMessageStateListener1(), MySendMessageStateListener2()])
        // beforeCreateQuasi
        recorder.startSendMessage(indentify: "-", chatInfo: trackerInfo)
        // createQuasiSuccess
        recorder.finishCallQuasiMessageAPI(indentify: "-", contextId: "-", message: Message.transform(pb: Message.PBModel()))
        // messageOnScreen
        _ = recorder.messageOnScreen(cid: "-", messageid: "-", page: "", renderCost: nil)
        // error
        recorder.finishWithError(indentify: "-", error: .otherError(), page: "")
    }

    /// 有很多埋点直接读取属性进行参数拼接，逻辑很简单就不加单测了
}

final class MySendMessageStateListener1: SendMessageStateListener {
    override func stateChange(_ state: SendMessageFlowState) {
        switch state {
        case .beforeCreateQuasi(let info):
            XCTAssertEqual(info.multiNumber, 1); info.multiNumber += 1
        case .createQuasiSuccess(let info):
            XCTAssertEqual(info.multiNumber, 3); info.multiNumber += 1
        case .messageOnScreen(let info):
            XCTAssertEqual(info.multiNumber, 5); info.multiNumber += 1
        case .sendMessageSuccess(let info):
            XCTAssertEqual(info.multiNumber, 7); info.multiNumber += 1
        case .error(let info, let error):
            XCTAssertEqual(info.multiNumber, 7); XCTAssertNil(error); info.multiNumber += 1
        }
    }
}
final class MySendMessageStateListener2: SendMessageStateListener {
    override func stateChange(_ state: SendMessageFlowState) {
        switch state {
        case .beforeCreateQuasi(let info):
            XCTAssertEqual(info.multiNumber, 2); info.multiNumber += 1
        case .createQuasiSuccess(let info):
            XCTAssertEqual(info.multiNumber, 4); info.multiNumber += 1
        case .messageOnScreen(let info):
            XCTAssertEqual(info.multiNumber, 6); info.multiNumber += 1
        case .sendMessageSuccess(let info):
            XCTAssertEqual(info.multiNumber, 8); info.multiNumber += 1
        case .error(let info, let error):
            XCTAssertEqual(info.multiNumber, 8); XCTAssertNil(error); info.multiNumber += 1
        }
    }
}
