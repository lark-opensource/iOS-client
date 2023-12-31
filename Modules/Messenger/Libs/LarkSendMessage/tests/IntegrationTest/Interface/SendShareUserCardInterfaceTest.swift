//
//  SendShareUserCardInterfaceTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2023/2/28.
//

import Foundation
import XCTest
import LarkSDKInterface // SendMessageAPI
import LarkContainer // InjectedSafeLazy
import LarkModel // ShareUserCardContent
import RxSwift // DisposeBag
import LarkSDKInterface // SDKRustService
@testable import LarkSendMessage

// 测试sendShareUserCardMessage接口
final class SendShareUserCardInterfaceTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var chatAPI: ChatAPI
    /// 测试账号信息
    private let groupChatID = "7196963741224157187"
    /// user名AutoTest
    private let userID = "7094941236301135876"

    // 测试发送个人名片，校验接口调用是否成功；个人卡片姓名、头像输入与接收到的Push一致
    func testSendShareUserCard() {
        // 设置异步等待
        // 1 等待发送接口
        let expectationSendMsg = LKTestExpectation(description: "@test send user card msg")
        // 2 等待接收push
        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
        let disposeBag = DisposeBag()
        let context = APIContext(contextID: RandomString.random(length: 10))
        // 发送消息cid
        var msgCid: String = ""
        // 标记消息发送是否成功
        var inspecterSend = false
        // 校验点
        var inspecterCardName: String?
        var inspecterCardAvatarKey: String?
        // 调用asyncSubscribeChatEvent进行订阅
        self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)
        self.sendMessageAPI.sendShareUserCardMessage(context: context,
                                                     shareChatterId: self.userID,
                                                     sendChannelType: .chat(id: self.groupChatID),
                                                     sendMessageTracker: nil,
                                                     stateHandler: { state in
            if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
            if case .finishSendMessage(_, _, _, _, _) = state {
                inspecterSend = true
                expectationSendMsg.fulfill()
            }})
        // 监听Push
        self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
            // 根据cid 判断是否为发送的消息
            guard let `self` = self, pushMsg.message.cid == msgCid, pushMsg.message.localStatus == .success else { return }
            if let currentContent = pushMsg.message.content as? ShareUserCardContent {
                inspecterCardName = currentContent.chatter?.nameWithAnotherName
                inspecterCardAvatarKey = currentContent.chatter?.avatarKey
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
        // 校验点2: 卡片名字、头像
        XCTAssertEqual(inspecterCardName, "AutoTest")
        XCTAssertFalse(inspecterCardAvatarKey.isEmpty)
    }
}
