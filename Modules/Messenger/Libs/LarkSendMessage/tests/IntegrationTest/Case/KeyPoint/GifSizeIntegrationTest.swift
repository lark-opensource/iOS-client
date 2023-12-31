//
//  GifSizeIntegrationTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2022/12/27.
//

import UIKit
import Foundation
import XCTest
import LarkContainer // InjectedSafeLazy
import LarkSDKInterface // SDKRustService
import LarkModel // ImageContent
import RustPB // Basic_V1_QuasiContent
import RxSwift // DisposeBag
import ByteWebImage // SendImageProcessor
@testable import LarkSendMessage

/// 发送Gif等图上屏，图片大小会变化：https://meego.feishu.cn/larksuite/issue/detail/6587956#comment
final class GifSizeIntegrationTest: CanSkipTestCase {
    @InjectedSafeLazy private var rustService: SDKRustService
    @InjectedSafeLazy private var imageProcessor: SendImageProcessor
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var chatAPI: ChatAPI
    private var cid: String = ""
    /// 图片渲染时的最大、小Size
    private static let imageMaxDisplaySize = CGSize(width: 680, height: 240)
    private static let imageMinDisplaySize = CGSize(width: 40, height: 40)

    override func setUp() {
        super.setUp()
        self.cid = RandomString.random(length: 10)
    }

    func testGifCase() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test gif size change")
        DispatchQueue.global().async {
            // 测试物料中该群已给userId设置了备注名为Test
            let chatId = "7170989253818646532"
            // 创建假消息，得到名称
            let context = APIContext(contextID: RandomString.random(length: 18))

            // 创建假消息
            let gifData = Resources.imageData(named: "300x400-GIF")
            let byteImage = try? ByteImage(gifData)
            guard let image = byteImage?.image else {
                expectation.fulfill()
                return
            }
            // Rust创建假消息时的大小
            XCTAssertEqual(image.size.scale(image.scale), CGSize(width: 300, height: 400))

            // 得到端上创建假消息时的上屏大小
            let nativeOnScreenSize = GifSizeIntegrationTest.nativeOnScreenSize(CGSize(width: 300, height: 400))
            // 渲染时，Rust创建假消息时的大小 应该等于 端上创建假消息时的上屏大小
            XCTAssertTrue(GifSizeIntegrationTest.showSizeEqual(left: nativeOnScreenSize, right: image.size.scale(image.scale)))

            var originContent = RustPB.Basic_V1_QuasiContent()
            originContent.isOriginSource = false
            originContent.image = gifData
            originContent.width = Int32(image.size.width * image.scale)
            originContent.height = Int32(image.size.height * image.scale)
            guard let msgResponse = try? RustSendMessageModule.createQuasiMessage(chatId: chatId,
                                                                                  type: .image,
                                                                                  content: originContent,
                                                                                  cid: self.cid,
                                                                                  client: self.rustService,
                                                                                  context: context) else {
                XCTExpectFailure("create quasi message fail, cid: \(self.cid)")
                expectation.fulfill()
                return
            }

            // 调用asyncSubscribeChatEvent进行订阅
            self.chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: true)
            RustSendMessageModule.sendMessage(cid: self.cid, client: self.rustService, context: context).subscribe(onNext: { _ in
                // Rust给服务端发送SEND_MESSAGE，如果push先于response返回Rust，则Rust给端上的response.messageId也会为空，所以不能用messageId是否为空判断是否发送成功
                /* if result.messageId.isEmpty { XCTExpectFailure("message id is empty") } */
            }).disposed(by: disposeBag)

            // 监听Push
            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
                // 只处理刚才创建的消息，成功的消息
                guard let `self` = self, pushMsg.message.cid == msgResponse.0.cid else { return }
                guard let imageContent = pushMsg.message.content as? ImageContent else {
                    XCTExpectFailure("image content not image content, cid: \(self.cid)")
                    expectation.fulfill()
                    return
                }
                // 图片的大小和Rust创建时保持一致
                XCTAssertEqual(imageContent.image.intactSize, image.size.scale(image.scale), "cid: \(self.cid)")

                _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: false)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    func testHeicForOriginCase() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test hiec size change")
        DispatchQueue.global().async {
            // 测试物料中该群已给userId设置了备注名为Test
            let chatId = "7170989253818646532"
            // 创建假消息，得到名称
            let context = APIContext(contextID: RandomString.random(length: 18))

            // 创建假消息
            let heicData = Resources.imageData(named: "1200x1400-HEIC")
            guard let heicResult = self.imageProcessor.process(source: .imageData(heicData), option: [.useOrigin], scene: .Chat) else {
                XCTExpectFailure("heic data process with origin, fail")
                return
            }
            // Rust创建假消息时的大小
            XCTAssertEqual(heicResult.image.size.scale(heicResult.image.scale), CGSize(width: 1200, height: 1400))

            // 得到端上创建假消息时的上屏大小
            let nativeOnScreenSize = GifSizeIntegrationTest.nativeOnScreenSize(CGSize(width: 1200, height: 1400))
            // 渲染时，Rust创建假消息时的大小 应该等于 端上创建假消息时的上屏大小
            XCTAssertTrue(GifSizeIntegrationTest.showSizeEqual(left: nativeOnScreenSize, right: heicResult.image.size.scale(heicResult.image.scale)))

            var originContent = RustPB.Basic_V1_QuasiContent()
            originContent.isOriginSource = true
            originContent.image = heicResult.imageData
            originContent.width = Int32(heicResult.image.size.width * heicResult.image.scale)
            originContent.height = Int32(heicResult.image.size.height * heicResult.image.scale)
            guard let msgResponse = try? RustSendMessageModule.createQuasiMessage(chatId: chatId,
                                                                                  type: .image,
                                                                                  content: originContent,
                                                                                  cid: self.cid,
                                                                                  client: self.rustService,
                                                                                  context: context) else {
                XCTExpectFailure("create quasi message fail, cid: \(self.cid)")
                expectation.fulfill()
                return
            }

            // 调用asyncSubscribeChatEvent进行订阅
            self.chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: true)
            RustSendMessageModule.sendMessage(cid: self.cid, client: self.rustService, context: context).subscribe(onNext: { _ in
                // Rust给服务端发送SEND_MESSAGE，如果push先于response返回Rust，则Rust给端上的response.messageId也会为空，所以不能用messageId是否为空判断是否发送成功
                /* if result.messageId.isEmpty { XCTExpectFailure("message id is empty") } */
            }).disposed(by: disposeBag)

            // 监听Push
            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
                // 只处理刚才创建的消息，成功的消息
                guard let `self` = self, pushMsg.message.cid == msgResponse.0.cid else { return }
                guard let imageContent = pushMsg.message.content as? ImageContent else {
                    XCTExpectFailure("content is not image content, cid: \(self.cid)")
                    expectation.fulfill()
                    return
                }
                // 图片的大小和Rust创建时保持一致
                XCTAssertEqual(imageContent.image.intactSize, heicResult.image.size.scale(heicResult.image.scale), "cid: \(self.cid)")

                _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: false)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    func testHeicForWebPCase() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test heic size change")
        DispatchQueue.global().async {
            // 测试物料中该群已给userId设置了备注名为Test
            let chatId = "7170989253818646532"
            // 创建假消息，得到名称
            let context = APIContext(contextID: RandomString.random(length: 18))

            // 创建假消息，scaleImageSize需要比self.imageMaxDisplaySize大，不然做不到渲染一致
            let scaleImageSize = CGSize(width: 600, height: 700)
            let heicData = Resources.imageData(named: "1200x1400-HEIC")
            guard let heicResult = self.imageProcessor.process(
                source: .imageData(heicData),
                options: [.needConvertToWebp],
                destPixel: Int(scaleImageSize.width),
                compressRate: 0.9, scene: .Chat)
            else {
                XCTExpectFailure("heic data process with origin, fail")
                return
            }
            // Rust创建假消息时的大小
            XCTAssertEqual(heicResult.image.size.scale(heicResult.image.scale), scaleImageSize)

            // 得到端上创建假消息时的上屏大小
            let nativeOnScreenSize = GifSizeIntegrationTest.nativeOnScreenSize(CGSize(width: 1200, height: 1400))
            // 渲染时，Rust创建假消息时的大小 应该等于 端上创建假消息时的上屏大小
            XCTAssertTrue(GifSizeIntegrationTest.showSizeEqual(left: nativeOnScreenSize, right: heicResult.image.size.scale(heicResult.image.scale)))

            var originContent = RustPB.Basic_V1_QuasiContent()
            originContent.isOriginSource = true
            originContent.image = heicResult.imageData
            originContent.width = Int32(heicResult.image.size.width * heicResult.image.scale)
            originContent.height = Int32(heicResult.image.size.height * heicResult.image.scale)
            guard let msgResponse = try? RustSendMessageModule.createQuasiMessage(chatId: chatId,
                                                                                  type: .image,
                                                                                  content: originContent,
                                                                                  cid: self.cid,
                                                                                  client: self.rustService,
                                                                                  context: context) else {
                XCTExpectFailure("create quasi message fail, cid: \(self.cid)")
                expectation.fulfill()
                return
            }

            // 调用asyncSubscribeChatEvent进行订阅
            self.chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: true)
            RustSendMessageModule.sendMessage(cid: self.cid, client: self.rustService, context: context).subscribe(onNext: { _ in
                // Rust给服务端发送SEND_MESSAGE，如果push先于response返回Rust，则Rust给端上的response.messageId也会为空，所以不能用messageId是否为空判断是否发送成功
                /* if result.messageId.isEmpty { XCTExpectFailure("message id is empty") } */
            }).disposed(by: disposeBag)

            // 监听Push
            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
                // 只处理刚才创建的消息，成功的消息
                guard let `self` = self, pushMsg.message.cid == msgResponse.0.cid else { return }
                guard let imageContent = pushMsg.message.content as? ImageContent else {
                    XCTExpectFailure("content is not image content, cid: \(self.cid)")
                    expectation.fulfill()
                    return
                }
                // 图片的大小和Rust创建时保持一致
                XCTAssertEqual(imageContent.image.intactSize, heicResult.image.size.scale(heicResult.image.scale), "cid: \(self.cid)")

                _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: false)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    func testHeicForJpegCase() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test heic size change")
        DispatchQueue.global().async {
            // 测试物料中该群已给userId设置了备注名为Test
            let chatId = "7170989253818646532"
            // 创建假消息，得到名称
            let context = APIContext(contextID: RandomString.random(length: 18))

            // 创建假消息，scaleImageSize需要比self.imageMaxDisplaySize大，不然做不到渲染一致
            let scaleImageSize = CGSize(width: 600, height: 700)
            let heicData = Resources.imageData(named: "1200x1400-HEIC")
            guard let heicResult = self.imageProcessor.process(source: .imageData(heicData), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) else {
                XCTExpectFailure("heic data process with origin, fail")
                return
            }
            // Rust创建假消息时的大小
            XCTAssertEqual(heicResult.image.size.scale(heicResult.image.scale), scaleImageSize)

            // 得到端上创建假消息时的上屏大小
            let nativeOnScreenSize = GifSizeIntegrationTest.nativeOnScreenSize(CGSize(width: 1200, height: 1400))
            // 渲染时，Rust创建假消息时的大小 应该等于 端上创建假消息时的上屏大小
            XCTAssertTrue(GifSizeIntegrationTest.showSizeEqual(left: nativeOnScreenSize, right: heicResult.image.size.scale(heicResult.image.scale)))

            var originContent = RustPB.Basic_V1_QuasiContent()
            originContent.isOriginSource = true
            originContent.image = heicResult.imageData
            originContent.width = Int32(heicResult.image.size.width * heicResult.image.scale)
            originContent.height = Int32(heicResult.image.size.height * heicResult.image.scale)
            guard let msgResponse = try? RustSendMessageModule.createQuasiMessage(chatId: chatId,
                                                                                  type: .image,
                                                                                  content: originContent,
                                                                                  cid: self.cid,
                                                                                  client: self.rustService,
                                                                                  context: context) else {
                XCTExpectFailure("create quasi message fail, cid: \(self.cid)")
                expectation.fulfill()
                return
            }

            // 调用asyncSubscribeChatEvent进行订阅
            self.chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: true)
            RustSendMessageModule.sendMessage(cid: self.cid, client: self.rustService, context: context).subscribe(onNext: { _ in
                // Rust给服务端发送SEND_MESSAGE，如果push先于response返回Rust，则Rust给端上的response.messageId也会为空，所以不能用messageId是否为空判断是否发送成功
                /* if result.messageId.isEmpty { XCTExpectFailure("message id is empty") } */
            }).disposed(by: disposeBag)

            // 监听Push
            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
                // 只处理刚才创建的消息，成功的消息
                guard let `self` = self, pushMsg.message.cid == msgResponse.0.cid else { return }
                guard let imageContent = pushMsg.message.content as? ImageContent else {
                    XCTExpectFailure("content is not image content, cid: \(self.cid)")
                    expectation.fulfill()
                    return
                }
                // 图片的大小和Rust创建时保持一致
                XCTAssertEqual(imageContent.image.intactSize, heicResult.image.size.scale(heicResult.image.scale), "cid: \(self.cid)")

                _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: false)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
    }

    // MARK: - 工具方法
    /// 得到端上创建假消息时的上屏大小，copy from PhotoScrollPicker-layout collectionViewLayout
    private static func nativeOnScreenSize(_ size: CGSize) -> CGSize {
        var nativeOnScreenSize = size.scale(1 / UIScreen.main.scale)
        // 192是选择视图的高度，得到宽高缩放比例
        let ratio = 192 / nativeOnScreenSize.height
        var realWidth = nativeOnScreenSize.width * ratio
        realWidth = max(80, realWidth)
        realWidth = min(400, realWidth)
        // 192 * UIScreen.main.scale需要比self.imageMaxDisplaySize大
        nativeOnScreenSize = CGSize(width: realWidth, height: 192)
        // PHCachingImageManager.requestImage传入的实际大小，比图片本身大会返回图片本身的大小
        nativeOnScreenSize = nativeOnScreenSize.scale(UIScreen.main.scale)
        return nativeOnScreenSize
    }

    /// 在屏幕上渲染时，两个size是否会渲染出一样的大小
    private static func showSizeEqual(left: CGSize, right: CGSize) -> Bool {
        let leftSize = self.calculateSize(originSize: left, maxSize: self.imageMaxDisplaySize, minSize: self.imageMinDisplaySize)
        let rightSize = self.calculateSize(originSize: right, maxSize: self.imageMaxDisplaySize, minSize: self.imageMinDisplaySize)

        return abs(leftSize.width - rightSize.width) <= 1 && abs(leftSize.height - rightSize.height) <= 1
    }

    /// copy from ChatImageViewWrapper.calculateSize
    private static func calculateSize(originSize: CGSize, maxSize: CGSize, minSize: CGSize) -> CGSize {
        let imageSize = self.calculateSizeAndContentMode(originSize: originSize, maxSize: maxSize, minSize: minSize).0
        return CGSize(width: max(imageSize.width, minSize.width), height: max(imageSize.height, minSize.height))
    }
    private static func calculateSizeAndContentMode(originSize size: CGSize, maxSize: CGSize, minSize: CGSize) -> (CGSize, UIView.ContentMode) {
        let fitSize = self.calcSize(size: size, maxSize: maxSize)
        let newWidth = fitSize.width
        let newHeight = fitSize.height
        return (CGSize(width: newWidth, height: newHeight), .scaleAspectFill)
    }
    private static func calcSize(size: CGSize, maxSize: CGSize) -> CGSize {
        if size.width <= maxSize.width && size.height <= maxSize.height { return size }

        let widthScaleRatio: CGFloat = min(1, maxSize.width / size.width)
        let heightScaleRatio: CGFloat = min(1, maxSize.height / size.height)
        let scaleRatio = min(widthScaleRatio, heightScaleRatio)
        return CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)
    }
}
