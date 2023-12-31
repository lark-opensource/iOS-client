//
//  HeicProgressUnitTest.swift
//  LarkSendMessage-LarkSendMessageUnitTest
//
//  Created by JackZhao on 2022/12/23.
//

import Foundation
import XCTest
import RustPB // Basic_V1_QuasiContent
import RxSwift // DisposeBag
import LarkModel // ImageContent
import ByteWebImage // ImageFileFormat
import LarkContainer // InjectedSafeLazy
import LarkSDKInterface // SDKRustService
@testable import LarkSendMessage

/// 以下问题的case集合：
/// 1.无法发送 HEIC 原图，https://meego.feishu.cn/larksuite/issue/detail/4755697
/// 2.发送图片的百分比不更新，直接发送成功，https://meego.feishu.cn/larksuite/issue/detail/4993733
/// 3.图片/视频发不出去，https://meego.feishu.cn/larksuite/issue/detail/7817199
final class HeicProgressUnitTest: CanSkipTestCase {
    @InjectedSafeLazy private var chatAPI: ChatAPI
    @InjectedSafeLazy private var rustService: SDKRustService
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    /* @InjectedSafeLazy private var progressService: ProgressService */

    /// 测试HEIC格式图片假消息是否创建成功
    func testCreateHeicOriginImageProcess() {
        let expectation = LKTestExpectation(description: "@test create heic origin image process")
        let chatId = "7173491043940417540"
        DispatchQueue.global().async {
            let context = APIContext(contextID: RandomString.random(length: 18))
            let msg = self.generateImageQuasiMsg(chatId: chatId, imgaeType: .heic, context: context)
            XCTAssert(msg != nil && (msg?.content as? LarkModel.ImageContent != nil))
            expectation.fulfill()
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    /// 测试：1.发送图片的百分比不更新，直接发送成功;  2.图片/视频发不出去
    func testSendImageProgressChange() {
        let disposeBag = DisposeBag()
        let testSendImageProgressChange = LKTestExpectation(description: "@test send image progress change")
        let chatId = "7173491043940417540"
        let cid = RandomString.random(length: 10)
        /* var progressCount: Int64?
         var isCompleted: Bool = false */

        // 1. 先登录
        DispatchQueue.global().async {
            // 2. 创建假消息
            let context = APIContext(contextID: RandomString.random(length: 18))
            guard let msg = self.generateImageQuasiMsg(cid: cid,
                                                       chatId: chatId,
                                                       imageName: "1170x2532-PNG",
                                                       imgaeType: .png,
                                                       isIgnoreQuickUpload: true,
                                                       context: context)/*,
                                                                         let currentContent = msg.content as? LarkModel.ImageContent*/ else {
                XCTExpectFailure("create quasi message error, cid: \(cid)")
                return
            }
            /* // 3. 监听进度的变化，这部分ProgressServiceUnitTest已经有了
             self.progressService.value(key: currentContent.image.origin.key)
             .subscribe(onNext: { progress in
             // 进度100直接返回
             if progress.completedUnitCount == 100 {
             isCompleted = true
             testSendImageProgressChange.fulfill()
             } else if progress.completedUnitCount != 0 {
             // 有非0和非100进度则记录下来
             progressCount = progress.completedUnitCount
             }
             }).disposed(by: disposeBag) */

            // 4. 发送图片，之前那个bug是SDK上传无法成功
            RustSendMessageModule.sendMessage(cid: msg.cid, client: self.rustService, context: context, multiSendSerialToken: nil).subscribe(onNext: { _ in
                // Rust给服务端发送SEND_MESSAGE，如果push先于response返回Rust，则Rust给端上的response.messageId也会为空，所以不能用messageId是否为空判断是否发送成功
                /* if result.messageId.isEmpty { XCTExpectFailure("message id is empty") } */
                testSendImageProgressChange.fulfill()
            }).disposed(by: disposeBag)
        }
        // 5. 等待图片发送
        testSendImageProgressChange.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [testSendImageProgressChange], timeout: WaitTimeout.defaultTimeout)
        if testSendImageProgressChange.autoFulfill { return }

        // 6. 检查结果
        /* XCTAssertNotNil(progressCount)
         XCTAssertTrue(isCompleted) */
    }

    // 创建图片假消息
    private func generateImageQuasiMsg(cid: String = RandomString.random(length: 10),
                                       chatId: String,
                                       imageName: String? = nil,
                                       imgaeType: ImageFileFormat,
                                       isIgnoreQuickUpload: Bool = false,
                                       context: APIContext) -> Message? {
        guard let sendImageModel = MockDataCenter.genSendImageModel(imageName: imageName, isIgnoreQuickUpload: isIgnoreQuickUpload, imageType: imgaeType) else { return nil }
        // 构造heic原图content
        let originImageResult = sendImageModel.imageMessageInfo.sendImageSource.originImage
        var originContent = RustPB.Basic_V1_QuasiContent()
        originContent.isOriginSource = true
        originContent.image = originImageResult.data ?? Data()
        originContent.width = Int32(originImageResult.image?.size.width ?? 0)
        originContent.height = Int32(originImageResult.image?.size.height ?? 0)

        // 创建假消息
        let res = try? RustSendMessageModule.createQuasiMessage(chatId: chatId,
                                                                type: .image,
                                                                content: originContent,
                                                                cid: cid,
                                                                client: self.rustService,
                                                                context: context)

        return res?.0
    }
}
