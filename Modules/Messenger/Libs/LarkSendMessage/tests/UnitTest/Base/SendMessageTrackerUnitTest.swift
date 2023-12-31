//
//  SendMessageTrackerUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/5.
//

import UIKit
import XCTest
import Foundation
import LarkModel // Message
import LarkContainer // InjectedSafeLazy
import RustPB // Basic_V1_RichText
import LarkStorage // IsoPath
@testable import LarkSendMessage

/// SendMessageTracker新增单测
final class SendMessageTrackerUnitTest: CanSkipTestCase {
    static var testNumber: Int = 0
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var videoSendService: VideoMessageSendService

    /// 测试SendMessageTracker的回调顺序，这里就测试Video类型就可以了
    func testVideoCallBack() {
        let expectation = LKTestExpectation(description: "@test text call back")
        // 自己搞一个临时路径
        let tempFileDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "test" + "upload"
        try? tempFileDir.createDirectoryIfNeeded()
        let tempFilePath = tempFileDir + "temp.mp4"
        try? tempFilePath.removeItem()
        do {
            let testMediaData = Resources.mediaData(named: "10-540x960-mp4")
            try testMediaData.write(to: tempFilePath)
        } catch {
            XCTExpectFailure("data move to path error")
            expectation.fulfill()
        }
        // 关闭端上创建假消息优化，让SendMessageTrackerProtocol回调逻辑好些一些
        let context = APIContext(contextID: RandomString.random(length: 10)); context.quasiMsgCreateByNative = false
        let sendVideoParams = SendVideoParams(content: .fileURL(tempFilePath.url), isCrypto: false, isOriginal: false, forceFile: false, chatId: "7170989253818646532", threadId: nil,
                                              parentMessage: nil, from: UIViewController())
        self.videoSendService.sendVideo(with: sendVideoParams, extraParam: nil, context: context, sendMessageTracker: MySendMessageTracker()) { state in
            if case .finishSendMessage(_, _, _, _, _) = state { sleep(2); expectation.fulfill() }
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }
}

final class MySendMessageTracker: SendMessageTrackerProtocol {
    func beforeGetResource() {
        XCTAssertEqual(SendMessageTrackerUnitTest.testNumber, 0)
        SendMessageTrackerUnitTest.testNumber += 1
    }
    func afterGetResource() {
        XCTAssertEqual(SendMessageTrackerUnitTest.testNumber, 1)
        SendMessageTrackerUnitTest.testNumber += 1
    }
    func beforeCreateQuasiMessage(context: LarkSendMessage.APIContext?, processCost: TimeInterval?) {
        XCTAssertEqual(SendMessageTrackerUnitTest.testNumber, 2)
        SendMessageTrackerUnitTest.testNumber += 1
    }
    func getQuasiMessage(msg: Message, context: APIContext?, contextId: String, size: Int64?, rustCreateForSend: Bool?, rustCreateCost: TimeInterval?, useNativeCreate: Bool) {
        XCTAssertEqual(SendMessageTrackerUnitTest.testNumber, 3)
        SendMessageTrackerUnitTest.testNumber += 1
    }
    func beforeTransCode() {
        XCTAssertEqual(SendMessageTrackerUnitTest.testNumber, 4)
        SendMessageTrackerUnitTest.testNumber += 1
    }
    func showLoading(cid: String) {
        // showLoading不一定会触发，如果触发了也不能判断equal，因为网络不稳定；我们判断 > 0即可
        XCTAssertTrue(SendMessageTrackerUnitTest.testNumber > 0)
    }
    func afterTransCode(cid: String, info: LarkSendMessage.VideoTrackInfo) {
        XCTAssertEqual(SendMessageTrackerUnitTest.testNumber, 5)
        SendMessageTrackerUnitTest.testNumber += 1
    }
    func beforeSendMessage(context: LarkSendMessage.APIContext?, msg: LarkModel.Message, processCost: TimeInterval?) {
        XCTAssertEqual(SendMessageTrackerUnitTest.testNumber, 6)
        SendMessageTrackerUnitTest.testNumber += 1
    }
    func finishSendMessageAPI(context: LarkSendMessage.APIContext?, msg: LarkModel.Message, contextId: String, messageId: String?, netCost: UInt64, trace: RustPB.Basic_V1_Trace?) {
        XCTAssertEqual(SendMessageTrackerUnitTest.testNumber, 7)
        SendMessageTrackerUnitTest.testNumber += 1
    }
    func sendMessageFinish(cid: String, messageId: String, success: Bool, page: String, isCheckExitChat: Bool, renderCost: TimeInterval?) {
        XCTAssertEqual(SendMessageTrackerUnitTest.testNumber, 8)
        SendMessageTrackerUnitTest.testNumber += 1
    }

    func cacheImageExtraInfo(cid: String, imageInfo: ImageMessageInfo, useOrigin: Bool) {
        XCTExpectFailure("cacheImageExtraInfo")
    }
    func cacheImageFallbackToFileExtraInfo(cid: String, imageFileSize: Int64?, useOrigin: Bool) {
        XCTExpectFailure("cacheImageFallbackToFileExtraInfo")
    }
    func cacheImageFallbackToFileExtraInfo(cid: String, imageInfo: ImageMessageInfo, useOrigin: Bool) {
        XCTExpectFailure("cacheImageFallbackToFileExtraInfo")
    }
    func errorQuasiMessage(context: LarkSendMessage.APIContext?) {
        XCTExpectFailure("errorQuasiMessage")
    }
    func otherError(context: LarkSendMessage.APIContext?) {
        XCTExpectFailure("otherError")
    }
    func transcodeFailed(context: LarkSendMessage.APIContext?, code: Int, errorMsg: String, cid: String?, info: LarkSendMessage.VideoTrackInfo?) {
        XCTExpectFailure("transcodeFailed")
    }
    func errorSendMessage(context: LarkSendMessage.APIContext?, cid: String, error: Error) {
        XCTExpectFailure("errorSendMessage")
    }
}
