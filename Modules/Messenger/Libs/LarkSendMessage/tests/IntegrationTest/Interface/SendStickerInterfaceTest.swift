//
//  SendStickerInterfaceTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2023/2/20.
//

import Foundation
import XCTest
import LarkSDKInterface // SendMessageAPI
import LarkContainer // InjectedSafeLazy
import RxSwift // DisposeBag
import LarkSDKInterface // SDKRustService
import RustPB // Im_V1_Sticker
import LarkModel // StickerContent
@testable import LarkSendMessage

// 测试sendSticker接口，校验接口调用是否成功
final class SendStickerInterfaceTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var chatAPI: ChatAPI
    /// 测试账号信息
    private let groupChatID = "7196963741224157187"

    // 测试发送表情信息，校验调用是否成功
    func testSendSticker() {
        // 设置异步等待
        // 1 等待发送接口
        let expectationSendMsg = LKTestExpectation(description: "@test send sticker msg")
        // 2 等待接收push
        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
        let disposeBag = DisposeBag()
        let context = APIContext(contextID: RandomString.random(length: 10))
        // 发送消息cid
        var msgCid: String = ""
        // 标记消息发送是否成功
        var inspecterSend = false
        var inspecterStickerKey = false
        // 输入数据
        var sticker = Im_V1_Sticker()
        var image = Basic_V1_ImageSet()
        image.origin.key = "v2_1ce6b578-e9ea-4bb6-a59f-d69a3e465c9g"
        image.thumbnail.key = "v2_77337b5f-7797-4dd8-ab29-93a15286482g"
        sticker.image = image

        // 调用asyncSubscribeChatEvent进行订阅
        self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)

        self.sendMessageAPI.sendSticker(context: context,
                                        sticker: sticker,
                                        parentMessage: nil,
                                        chatId: self.groupChatID,
                                        threadId: nil,
                                        sendMessageTracker: nil,
                                        stateHandler: { state in
            if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
            if case .finishSendMessage(_, _, _, _, _) = state {
                expectationSendMsg.fulfill()
            }
        })

        // 监听Push
        self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
            // 根据cid 判断是否为发送的消息
            guard let `self` = self, pushMsg.message.cid == msgCid, pushMsg.message.localStatus == .success else { return }
            if let currentContent = pushMsg.message.content as? StickerContent {
                inspecterSend = true
                inspecterStickerKey = currentContent.key.isEmpty
            }
            expectationReceivePushMsg.fulfill()
        }).disposed(by: disposeBag)
        expectationSendMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        expectationReceivePushMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectationSendMsg, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
        // 取消订阅
        _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: false)
        if expectationSendMsg.autoFulfill || expectationReceivePushMsg.autoFulfill { return }
        // 校验点1: 消息是否发送成功
        XCTAssertTrue(inspecterSend)
        XCTAssertFalse(inspecterStickerKey)
    }
}
