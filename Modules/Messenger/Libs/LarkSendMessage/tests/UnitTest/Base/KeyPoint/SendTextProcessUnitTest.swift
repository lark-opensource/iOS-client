//
//  SendTextProcessUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/1/31.
//

import XCTest
import Foundation
import RustPB // Basic_V1_RichText
import LarkContainer // InjectedLazy
import LarkModel // Message
@testable import LarkSendMessage

/// 发文本消息新增单测
final class SendTextProcessUnitTest: CanSkipTestCase {
    static var testNumber: Int = 0
    @InjectedLazy var sendMessageAPI: SendMessageAPI

    /// 测试内容裁剪
    func testTrimCharacters() {
        var text1 = Basic_V1_RichTextElement(); text1.tag = .text; text1.property.text.content = "  hello  "
        var p2 = Basic_V1_RichTextElement(); p2.tag = .p; p2.childIds = ["1"]
        var text3 = Basic_V1_RichTextElement(); text3.tag = .text; text3.property.text.content = "  hello  "
        var text4 = Basic_V1_RichTextElement(); text4.tag = .text; text4.property.text.content = "  hello  "
        var richText = Basic_V1_RichText(); richText.elementIds = ["2", "3", "4"]
        richText.elements["1"] = text1; richText.elements["2"] = p2; richText.elements["3"] = text3; richText.elements["4"] = text4

        // lead，第一个是p，p不是text，所以会继续遍历p的子元素，直到找到text为止
        var result = richText.trimCharacters(in: .whitespacesAndNewlines, postion: .lead)
        guard let text1 = result.elements["1"], text1.tag == .text else {
            XCTExpectFailure("trim characters error")
            return
        }
        XCTAssertEqual(text1.property.text.content, "hello  ")

        // tail，最后一个是text，直接使用即可
        result = richText.trimCharacters(in: .whitespacesAndNewlines, postion: .tail)
        guard let text4 = result.elements["4"], text4.tag == .text else {
            XCTExpectFailure("trim characters error")
            return
        }
        XCTAssertEqual(text4.property.text.content, "  hello")

        // both
        result = richText.trimCharacters(in: .whitespacesAndNewlines, postion: .both)
        guard let text1 = result.elements["1"], text1.tag == .text, let text4 = result.elements["4"], text4.tag == .text else {
            XCTExpectFailure("trim characters error")
            return
        }
        XCTAssertEqual(text1.property.text.content, "hello  ")
        XCTAssertEqual(text4.property.text.content, "  hello")
    }

    /// 测试定时消息发送，预期不会上屏等，测试账号没有权限发送定时消息
    /* func testScheduleTime() {
     let expectation = LKTestExpectation(description: "@test text call back")
     // 关闭端上创建假消息优化，让SendMessageTrackerProtocol回调逻辑好些一些
     let context = APIContext(contextID: RandomString.random(length: 10)); context.quasiMsgCreateByNative = false
     var element = Basic_V1_RichTextElement(); element.tag = .text; element.property.text.content = "test schedule time"
     var richText = Basic_V1_RichText(); richText.elementIds = ["1"]; richText.elements["1"] = element
     self.sendMessageAPI.sendText(context: context, content: richText, parentMessage: nil, chatId: "7170989253818646532", threadId: nil, createScene: nil,
     scheduleTime: 0, sendMessageTracker: TextSendMessageTracker()) { state in
     if case .finishSendMessage(_, _, _, _, _) = state { sleep(2); expectation.fulfill() }
     }
     wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
     } */
}

/* final class TextSendMessageTracker: SendMessageTrackerProtocol {
 func beforeCreateQuasiMessage(context: LarkSendMessage.APIContext?, processCost: TimeInterval?) {
 XCTAssertEqual(SendTextProcessUnitTest.testNumber, 0)
 SendTextProcessUnitTest.testNumber += 1
 }
 func getQuasiMessage(msg: Message, context: APIContext?, contextId: String, size: Int64?, rustCreateForSend: Bool?, rustCreateCost: TimeInterval?, useNativeCreate: Bool) {
 XCTAssertEqual(SendTextProcessUnitTest.testNumber, 1)
 SendTextProcessUnitTest.testNumber += 1
 }
 func showLoading(cid: String) {
 // showLoading不一定会触发，如果触发了也不能判断equal，因为网络不稳定；我们判断 > 0即可
 XCTAssertTrue(SendTextProcessUnitTest.testNumber > 0)
 }
 func beforeSendMessage(context: LarkSendMessage.APIContext?, msg: LarkModel.Message, processCost: TimeInterval?) {
 XCTAssertEqual(SendTextProcessUnitTest.testNumber, 2)
 SendTextProcessUnitTest.testNumber += 1
 }
 func finishSendMessageAPI(context: LarkSendMessage.APIContext?, msg: LarkModel.Message, contextId: String, messageId: String?, netCost: UInt64, trace: RustPB.Basic_V1_Trace?) {
 XCTAssertEqual(SendTextProcessUnitTest.testNumber, 3)
 SendTextProcessUnitTest.testNumber += 1
 }
 
 func beforeTransCode() {
 XCTExpectFailure("beforeTransCode")
 }
 func afterTransCode(cid: String, info: LarkSendMessage.VideoTrackInfo) {
 XCTExpectFailure("afterTransCode")
 }
 func sendMessageFinish(cid: String, messageId: String, success: Bool, page: String, isCheckExitChat: Bool, renderCost: TimeInterval?) {
 XCTExpectFailure("sendMessageFinish")
 }
 func beforeGetResource() {
 XCTExpectFailure("beforeGetResource")
 }
 func afterGetResource() {
 XCTExpectFailure("afterGetResource")
 }
 func cacheImageExtraInfo(cid: String, imageInfo: ImageMessageInfo, useOrigin: Bool) {
 XCTExpectFailure("cacheImageExtraInfo")
 }
 func cacheImageFallbackToFileExtraInfo(cid: String, imageFileSize: Int64?, useOrigin: Bool) {
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
 } */
