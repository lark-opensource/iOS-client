//
//  SendImageInterfaceTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2023/2/6.
//

import UIKit
import Foundation
import XCTest
import LarkContainer // InjectedSafeLazy
import LarkSDKInterface // ChatAPI
import ByteWebImage // ImageSourceResult
import LarkModel // ImageContent
import RxSwift // DisposeBag
@testable import LarkSendMessage

// 测试sendImage接口，测试接口可用性，发送与接收push的一致性
final class SendImageInterfaceTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var chatAPI: ChatAPI
    /// 测试账号信息
    private let groupChatID = "7196963741224157187"

    // 测试发送非原图，校验接口调用是否成功；图片尺寸输入与接收到的Push一致
    func testSendImage() {
        let expectationSend = LKTestExpectation(description: "@test send image msg")
        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
        let disposeBag = DisposeBag()
        // 发送图片消息是否成功
        var inspecterSendImage = false
        // 接收到的Push图片的尺寸
        var inspecterReceiveSize = CGSize(width: 0.0, height: 0.0)
        // 是否原图消息
        var inspecterOrigin = true
        // 图片消息的key
        var inspecterImageKey = false
        // 发送消息cid
        var msgCid: String = ""
        // 测试图片准备
        let image = Resources.image(named: "1200x1400-PNG")
        // 上屏图片
        let coverImage = Resources.image(named: "1170x2532-PNG")
        let apiContext = APIContext(contextID: RandomString.random(length: 10))
        let imageSourceFuncCover: ImageSourceFunc = {
            return ImageSourceResult(sourceType: .png, data: coverImage.pngData(), image: coverImage, compressRatio: 0.8)
        }
        let imageSourceFuncOrigin: ImageSourceFunc = {
            return ImageSourceResult(sourceType: .png, data: image.pngData(), image: image)
        }
        let imageMessageInfo = ImageMessageInfo(originalImageSize: image.size,
                                                sendImageSource: SendImageSource(cover: imageSourceFuncCover,
                                                                                  origin: imageSourceFuncOrigin))
        // 调用asyncSubscribeChatEvent进行订阅
        self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)
        // 调用sendImage
        self.sendMessageAPI.sendImage(context: apiContext,
                                      parentMessage: nil,
                                      useOriginal: false,
                                      imageMessageInfo: imageMessageInfo,
                                      chatId: self.groupChatID,
                                      threadId: nil,
                                      sendMessageTracker: nil) { state in
            if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
            if case .finishSendMessage(_, _, _, _, _) = state {
                inspecterSendImage = true
                expectationSend.fulfill()
            }
        }
        // 监听Push
        self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
            guard let `self` = self, pushMsg.message.cid == msgCid, pushMsg.message.localStatus == .success else { return }
            guard let imageContent = pushMsg.message.content as? ImageContent else { return }
            inspecterReceiveSize = imageContent.image.intactSize
            inspecterOrigin = imageContent.isOriginSource
            inspecterImageKey = imageContent.image.key.isEmpty
            expectationReceivePushMsg.fulfill()
        }).disposed(by: disposeBag)
        expectationSend.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        expectationReceivePushMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectationSend, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
        _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: false)
        if expectationSend.autoFulfill || expectationReceivePushMsg.autoFulfill { return }
        // 校验点1 消息发送是否成功
        XCTAssertTrue(inspecterSendImage)
        // 校验点2 输入-push图片大小是否一致
        XCTAssertEqual(inspecterReceiveSize, CGSize(width: 1200.0, height: 1400.0))
        XCTAssertFalse(inspecterOrigin)
        XCTAssertFalse(inspecterImageKey)
    }

    // 测试发送原图，校验接口调用是否成功；图片尺寸输入与接收到的Push一致
    func testSendOriginImage() {
        let expectationSend = LKTestExpectation(description: "@test send image msg")
        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
        let disposeBag = DisposeBag()
        // 发送图片消息是否成功
        var inspecterSendImage = false
        // 接收到的Push图片的尺寸
        var inspecterReceiveSize = CGSize(width: 0.0, height: 0.0)
        // 是否原图消息
        var inspecterOrigin = false
        // 图片消息的key
        var inspecterImageKey = false
        // 发送消息cid
        var msgCid: String = ""
        // 测试数据准备
        // 上屏图片
        let coverImage = Resources.image(named: "1170x2532-PNG")
        let image = Resources.image(named: "1200x1400-PNG")
        let apiContext = APIContext(contextID: RandomString.random(length: 10))
        let imageSourceFuncCover: ImageSourceFunc = {
            return ImageSourceResult(sourceType: .png, data: coverImage.pngData(), image: coverImage)
        }
        let imageSourceFuncOrigin: ImageSourceFunc = {
            return ImageSourceResult(sourceType: .png, data: image.pngData(), image: image)
        }
        let imageMessageInfo = ImageMessageInfo(originalImageSize: image.size,
                                                sendImageSource: SendImageSource(cover: imageSourceFuncCover,
                                                                                  origin: imageSourceFuncOrigin))
        // 调用asyncSubscribeChatEvent进行订阅
        self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)
        // 调用sendImage
        self.sendMessageAPI.sendImage(context: apiContext,
                                      parentMessage: nil,
                                      useOriginal: true,
                                      imageMessageInfo: imageMessageInfo,
                                      chatId: self.groupChatID,
                                      threadId: nil,
                                      sendMessageTracker: nil) { state in
            if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
            if case .finishSendMessage(_, _, _, _, _) = state {
                inspecterSendImage = true
                expectationSend.fulfill()
            }
        }
        // 监听Push
        self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
            guard let `self` = self, pushMsg.message.cid == msgCid, pushMsg.message.localStatus == .success else { return }
            guard let imageContent = pushMsg.message.content as? ImageContent else { return }
            inspecterReceiveSize = imageContent.image.intactSize
            inspecterOrigin = imageContent.isOriginSource
            inspecterImageKey = imageContent.image.key.isEmpty
            expectationReceivePushMsg.fulfill()
        }).disposed(by: disposeBag)
        expectationSend.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        expectationReceivePushMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectationSend, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
        _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: false)
        if expectationSend.autoFulfill || expectationReceivePushMsg.autoFulfill { return }
        // 校验点1 消息发送是否成功
        XCTAssertTrue(inspecterSendImage)
        // 校验点2 输入-push图片大小是否一致
        XCTAssertEqual(inspecterReceiveSize, CGSize(width: 1200.0, height: 1400.0))
        XCTAssertTrue(inspecterOrigin)
        XCTAssertFalse(inspecterImageKey)
    }

//    func testSendImages() {
//        let expectationSend = LKTestExpectation(description: "@test send image msg")
//        expectationSend.expectedFulfillmentCount = 2
//        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
//        let disposeBag = DisposeBag()
//        // 发送消息cid
//        var msgCid: String = ""
//        /// 测试数据准备
//        let image_01 = Resources.image(named: "1200x1400-PNG")
//        let image_02 = Resources.image(named: "1170x2532-PNG")
//        let apiContext_01 = APIContext(contextID: RandomString.random(length: 10))
//        let apiContext_02 = APIContext(contextID: RandomString.random(length: 10))
//        let imageSourceFuncCover_01: ImageSourceFunc = {
//            return ImageSourceResult(sourceType: .png, data: image_01.pngData(), image: image_01)
//        }
//        let imageSourceFuncOrigin_01: ImageSourceFunc = {
//            return ImageSourceResult(sourceType: .png, data: image_01.pngData(), image: image_01)
//        }
//        let imageMessageInfo_01 = ImageMessageInfo(originalImageSize: image_01.size,
//                                                sendImageSource: SendImageSource(cover: imageSourceFuncCover_01,
//                                                                                  origin: imageSourceFuncOrigin_01))
//        let imageSourceFuncCover_02: ImageSourceFunc = {
//            return ImageSourceResult(sourceType: .png, data: image_02.pngData(), image: image_02)
//        }
//        let imageSourceFuncOrigin_02: ImageSourceFunc = {
//            return ImageSourceResult(sourceType: .png, data: image_02.pngData(), image: image_02)
//        }
//        let imageMessageInfo_02 = ImageMessageInfo(originalImageSize: image_02.size,
//                                                sendImageSource: SendImageSource(cover: imageSourceFuncCover_02,
//                                                                                  origin: imageSourceFuncOrigin_02))
//        AutoLoginHandler().autoLogin {
//            // 调用sendImage
//            // 多图发送发9张图
//            self.sendMessageAPI.sendImages(contexts: [apiContext_01, apiContext_02],
//                                           parentMessage: nil,
//                                           useOriginal: true,
//                                           imageMessageInfos: [imageMessageInfo_01, imageMessageInfo_02],
//                                           chatId: self.groupChatID,
//                                           threadId: nil) { _, state in
//                if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
//                if case .finishSendMessage(_, _, _, _, _) = state { expectationSend.fulfill() }
//            }
//            // 监听Push
//            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessages.self).subscribe(onNext: { pushMsg in
//                for msg in pushMsg.messages {
//                    print("TestMsg send \(msgCid) receive \(msg.cid)")
//                }
////                guard let `self` = self, pushMsg.message.cid == msgCid else {
////                    sleep(2)
////                    return
////                }
////                guard let imageContent = pushMsg.message.content as? ImageContent else { return }
////                print("TestMsg image key \(imageContent.image.intactSize)")
//                expectationReceivePushMsg.fulfill()
//            }).disposed(by: disposeBag)
//        }
//        wait(for: [expectationSend], timeout: WaitTimeout.longTimeout)
//        wait(for: [expectationReceivePushMsg], timeout: WaitTimeout.longTimeout)
//    }
}
