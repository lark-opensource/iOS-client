//
//  SendMessageTrackerInfoUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/31.
//

import XCTest
import Foundation
import RustPB
import LarkModel // Message
@testable import LarkSendMessage
import LarkContainer

/// SendMessageKeyPointRecorder、SendMessageTrackerInfo新增单测
final class SendMessageTrackerInfoUnitTest: CanSkipTestCase {
    private let recorder = SendMessageKeyPointRecorder(userResolver: Container.shared.getCurrentUserResolver(), stateListeners: [])
    /// 测试发消息信息是否记录正确
    func testTrackerInfo() {
        let indentify = RandomString.random(length: 10)
        let trackerInfo = ChatKeyPointTrackerInfo(id: indentify, isCrypto: false, chat: nil)
        // startSendMessage
        recorder.startSendMessage(indentify: indentify, chatInfo: trackerInfo, params: ["multiNumber": 2, "ChooseAssetSource": "image"])
        XCTAssertNotNil(self.getTrackInfo(key: indentify).pointCost[.start])
        XCTAssertEqual(self.getTrackInfo(key: indentify).multiNumber, 2)
        XCTAssertEqual(self.getTrackInfo(key: indentify).chooseAssetSource, "image")
        XCTAssertNotNil(self.getTrackInfo(key: indentify).chatInfo)

        // enterBackGroud
        XCTAssertFalse(self.getTrackInfo(key: indentify).enterBackGroud(nil))
        XCTAssertFalse(self.getTrackInfo(key: indentify).enterBackGroud(0))
        XCTAssertTrue(self.getTrackInfo(key: indentify).enterBackGroud((self.getTrackInfo(key: indentify).pointCost[.start] ?? 0) + 1))

        // startCallQuasiMessageAPI
        recorder.startCallQuasiMessageAPI(indentify: indentify, processCost: 100)
        XCTAssertNotNil(self.getTrackInfo(key: indentify).pointCost[.callQuasiMessageAPI])
        XCTAssertEqual(self.getTrackInfo(key: indentify).pointCost[.procssForQuasiMessage], 100)

        // finishCallQuasiMessageAPI
        let message = Message.transform(pb: Message.PBModel()); message.cid = "-"; message.type = .file
        self.getTrackInfo(key: indentify).textContentLength = 100; self.getTrackInfo(key: indentify).resourceLength = 100
        recorder.finishCallQuasiMessageAPI(indentify: indentify, contextId: "callQuasiMessageAPI", message: message)
        XCTAssertEqual(self.getTrackInfo(key: "-").contextIds[.callQuasiMessageAPI], "callQuasiMessageAPI")
        XCTAssertEqual(self.getTrackInfo(key: "-").messageType, .file)
        XCTAssertEqual(self.getTrackInfo(key: "-").cid, "-")
        XCTAssertNotNil(self.getTrackInfo(key: "-").pointCost[.callQuasiMessageAPI])
        // file只会改resourceLength，textContentLength不受影响
        XCTAssertEqual(self.getTrackInfo(key: "-").textContentLength, 100)
        XCTAssertEqual(self.getTrackInfo(key: "-").resourceLength, 0)

        // finishCallQuasiMessageAPI
        self.getTrackInfo(key: "-").textContentLength = 200; self.getTrackInfo(key: "-").resourceLength = 200
        recorder.finishCallQuasiMessageAPI(cid: "-", rustCreateCost: 100, message: message)
        // file只会改resourceLength，textContentLength不受影响
        XCTAssertEqual(self.getTrackInfo(key: "-").textContentLength, 200)
        XCTAssertEqual(self.getTrackInfo(key: "-").resourceLength, 0)
        XCTAssertEqual(self.getTrackInfo(key: "-").pointCost[.callQuasiMessageAPI], 100)

        // cacheExtraInfo
        recorder.cacheExtraInfo(cid: "-", extralInfo: ["c1": "c1", "c2": "c2"])
        XCTAssertEqual(self.getTrackInfo(key: "-").extralInfo["c1"] as? String, "c1")
        XCTAssertEqual(self.getTrackInfo(key: "-").extralInfo["c2"] as? String, "c2")

        // saveTrackVideoInfo
        XCTAssertNil(self.getTrackInfo(key: "-").videoTrackInfo)
        recorder.saveTrackVideoInfo(cid: "-", info: VideoTrackInfo())
        XCTAssertNotNil(self.getTrackInfo(key: "-").videoTrackInfo)

        // saveTrackVideoError
        XCTAssertNil(self.getTrackInfo(key: "-").videoTranscodeErrorCode)
        XCTAssertNil(self.getTrackInfo(key: "-").videoTranscodeErrorMsg)
        recorder.saveTrackVideoError(indentify: "-", cid: "-", code: 100, errorMsg: "errorMsg")
        XCTAssertEqual(self.getTrackInfo(key: "-").videoTranscodeErrorCode, 100)
        XCTAssertEqual(self.getTrackInfo(key: "-").videoTranscodeErrorMsg, "errorMsg")

        // startCallSendMessageAPI
        XCTAssertNil(self.getTrackInfo(key: "-").pointCost[.callSendMessageAPI])
        XCTAssertNil(self.getTrackInfo(key: "-").pointCost[.procssForSendMessage])
        self.getTrackInfo(key: "-").resourceLength = 0
        recorder.startCallSendMessageAPI(cid: "-", processCost: 100, extralInfo: ["c3": "c3", "resource_content_length": Int64(100)])
        XCTAssertNotNil(self.getTrackInfo(key: "-").pointCost[.callSendMessageAPI])
        XCTAssertNotNil(self.getTrackInfo(key: "-").pointCost[.procssForSendMessage])
        XCTAssertEqual(self.getTrackInfo(key: "-").resourceLength, Int64(100))
        XCTAssertEqual(self.getTrackInfo(key: "-").extralInfo["c3"] as? String, "c3")

        // finishSendMessageAPI
        XCTAssertTrue(self.getTrackInfo(key: "-").traceSpans.isEmpty)
        var span = Basic_V1_Trace.Span(); span.name = "span"; span.durationMillis = 1000; span.attributes = ["a1": "a1"]
        var trace = Basic_V1_Trace(); trace.spans = [span]
        recorder.finishSendMessageAPI(cid: "-", contextId: "finishSendMessageAPI", netCost: 100, trace: trace)
        XCTAssertNotNil(self.getTrackInfo(key: "-").pointCost[.callSendMessageAPI])
        XCTAssertEqual(self.getTrackInfo(key: "-").pointCost[.callSendMessageAPINetCost], 100)
        XCTAssertEqual(self.getTrackInfo(key: "-").contextIds[.callSendMessageAPI], "finishSendMessageAPI")
        XCTAssertEqual(self.getTrackInfo(key: "-").traceSpans["span"] as? UInt64, UInt64(1000))
        XCTAssertEqual(self.getTrackInfo(key: "-").traceSpans["a1"] as? String, "a1")

        // beforePublishOnScreenSignal
        XCTAssertNil(self.getTrackInfo(key: "-").pointCost[.publishOnScreenSignal])
        recorder.beforePublishOnScreenSignal(cid: "-", messageId: "-")
        XCTAssertNotNil(self.getTrackInfo(key: "-").pointCost[.publishOnScreenSignal])

        // afterPublishOnScreenSignal
        recorder.afterPublishOnScreenSignal(cid: "-", messageId: "-")
        XCTAssertNotNil(self.getTrackInfo(key: "-").pointCost[.publishOnScreenSignal])

        // beforePublishFinishSignal
        XCTAssertNil(self.getTrackInfo(key: "-").pointCost[.publishFinishSignal])
        recorder.beforePublishFinishSignal(cid: "-", messageId: "-")
        XCTAssertNotNil(self.getTrackInfo(key: "-").pointCost[.publishFinishSignal])

        // afterPublishFinishSignal
        recorder.afterPublishFinishSignal(cid: "-", messageId: "-")
        XCTAssertNotNil(self.getTrackInfo(key: "-").pointCost[.publishFinishSignal])

        // messageOnScreen
        XCTAssertNil(self.getTrackInfo(key: "-").pointCost[.messageOnScreen])
        _ = recorder.messageOnScreen(cid: "-", messageid: "-", page: "", renderCost: nil)
        XCTAssertNotNil(self.getTrackInfo(key: "-").pointCost[.messageOnScreen])

        // messageSendShowLoading
        XCTAssertFalse(self.getTrackInfo(key: "-").showLoading)
        recorder.messageSendShowLoading(cid: "-")
        XCTAssertTrue(self.getTrackInfo(key: "-").showLoading)

        // leaveChat
        recorder.leaveChat { info in
            XCTAssertNotNil(self.getTrackInfo(key: "-").pointCost[.leave])
            XCTAssertTrue(info.isExitChat)
        }

        // sendMessageFinish success
        XCTAssertNil(self.getTrackInfo(key: "-").pointCost[.success])
        guard let info = recorder.sendMessageFinish(cid: "-", messageId: "-", success: true, page: "", isCheckExitChat: false) else {
            XCTExpectFailure("send message finish success error")
            return
        }
        XCTAssertNotNil(info.pointCost[.success])

        // sendMessageFinish fail
        recorder.sendTrackInfoMap["-"] = info
        XCTAssertNil(self.getTrackInfo(key: "-").pointCost[.fail])
        guard let info = recorder.sendMessageFinish(cid: "-", messageId: "-", success: false, page: "", isCheckExitChat: false) else {
            XCTExpectFailure("send message finish fail error")
            return
        }
        XCTAssertNotNil(info.pointCost[.fail])

        // finishWithError
        recorder.sendTrackInfoMap["-"] = info
        recorder.finishWithError(indentify: "-", error: .otherError(), page: "")
        XCTAssertNil(recorder.sendTrackInfoMap["-"])
    }

    /// metricLog、category、extraLog、tracingTags直接读取属性进行参数拼接，逻辑很简单就不加单测了
    private func getTrackInfo(key: String) -> SendMessageTrackerInfo {
        guard let info = recorder.sendTrackInfoMap[key] else {
            XCTExpectFailure("get track info empty")
            return SendMessageTrackerInfo(indentify: "-")
        }
        return info
    }
}
