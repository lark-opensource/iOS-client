//
//  AbnormalCallOriginImageIntegrationTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2022/12/29.
//

import Foundation
import XCTest
import LarkContainer // InjectedSafeLazy
import ByteWebImage // ImageSourceResult
@testable import LarkSendMessage

enum OriginCalledStatus {
    case normal
    case abnormal
}

/// 上屏前不能进行原图编码
final class AbnormalCallOriginImageIntegrationTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI

    func testAbnormalCallOriginImage() {
        /// 标识ImageMessageInfo中是否调用了原图编码
        var isCalledOrigin = false
        /// 用于判断在消息发送流程中是否存在原图编码调用异常（增加此变量是由于使用单一变量存在多线程问题）
        var originCalledStatus: OriginCalledStatus = .normal
        let expectation = LKTestExpectation(description: "@test abnormal call origin image")
        /// 测试数据准备
        let image = Resources.image(named: "1200x1400-PNG")
        let chatId = "7180179231060557852"
        let apiContext = APIContext(contextID: RandomString.random(length: 10))
        apiContext.quasiMsgCreateByNative = true
        let imageSourceFuncCover: ImageSourceFunc = {
            return ImageSourceResult(sourceType: .png, data: image.pngData(), image: image)
        }
        /// 原图编码被调用 则isCalledOrigin置为true
        let imageSourceFuncOrigin: ImageSourceFunc = {
            isCalledOrigin = true
            return ImageSourceResult(sourceType: .png, data: image.pngData(), image: image)
        }
        let imageMessageInfo = ImageMessageInfo(originalImageSize: image.size,
                                                sendImageSource: SendImageSource(cover: imageSourceFuncCover,
                                                                                 origin: imageSourceFuncOrigin))
        /// 设置校验逻辑，此逻辑在SendImageCreateQuasiMsgTask中执行
        RustSendMessageAPI.beforeCreateQuasiMsgHandler = {
            if isCalledOrigin {
                originCalledStatus = .abnormal
            }
        }
        self.sendMessageAPI.sendImage(context: apiContext,
                                      parentMessage: nil,
                                      useOriginal: true,
                                      imageMessageInfo: imageMessageInfo,
                                      chatId: chatId,
                                      threadId: nil,
                                      sendMessageTracker: nil) { state in
            // 让消息发送完成，否则下次启动时会重发该消息，可能会影响case运行
            if case .finishSendMessage(_, _, _, _, _) = state { sleep(2); expectation.fulfill() }
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        // 这里不设置为nil，当赋值时之前的block就会被释放
        // RustSendMessageAPI.beforeCreateQuasiMsgHandler = nil
        XCTAssertEqual(originCalledStatus, OriginCalledStatus.normal)
    }
}
