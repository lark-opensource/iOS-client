//
//  SendImageWrongOrderIntegrationTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2023/2/13.
//

import XCTest
import Foundation
import LarkModel // Message
import RxSwift // DisposeBag
import LarkContainer // InjectedSafeLazy
import LarkSDKInterface // SDKRustService
@testable import LarkSendMessage

/// 发送9张图片，实际到达服务端的顺序会错乱
/* final class SendImageWrongOrderIntegrationTest: CanSkipTestCase {
 @InjectedSafeLazy private var rustService: SDKRustService
 @InjectedSafeLazy private var chatAPI: ChatAPI
 @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
 private let chatId: String = "7180179231060557852"
 
 func testWrongOrder() {
 let disposeBag = DisposeBag()
 let expectation = LKTestExpectation(description: "@test wrong order")
 
 DispatchQueue.global().async { [weak self] in
 guard let `self` = self else { return }
 
 // 创建9条假消息，把cid存起来
 var messageCids: [(String, APIContext)] = []
 for _ in 0...8 {
 let apiContext = APIContext(contextID: RandomString.random(length: 8))
 var originContent = QuasiContent(); originContent.isOriginSource = true
 originContent.width = 1200; originContent.height = 1400
 originContent.image = Resources.imageData(named: "1200x1400-JPEG")
 guard let messasge = try? RustSendMessageModule.createQuasiMessage(chatId: self.chatId, type: .image, content: originContent, client: self.rustService, context: apiContext) else {
 XCTExpectFailure("quasi message create error")
 expectation.fulfill()
 return
 }
 messageCids.append((messasge.0.cid, apiContext))
 }
 
 XCTAssertEqual(messageCids.count, 9, "cids: \(messageCids.map({ $0.0 }))")
 
 // 调用asyncSubscribeChatEvent进行订阅，监听Push得到Message，主要是取position
 var messageMap: [String: Message] = [:]
 self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.chatId], subscribe: true)
 self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] pushMsg in
 guard let `self` = self, pushMsg.message.localStatus == .success, messageCids.contains(where: { $0.0 == pushMsg.message.cid }) else { return }
 
 messageMap[pushMsg.message.cid] = pushMsg.message
 
 // 如果messageMap已经有9个了，这时候就需要判断这个9个的position是否连续
 guard messageMap.count == 9 else { return }
 
 var lastMessagePosition: Int32 = 0
 messageCids.forEach { (cid, _) in
 guard let position = messageMap[cid]?.position else {
 XCTExpectFailure("push message error, cid: \(cid)")
 expectation.fulfill()
 return
 }
 if position > lastMessagePosition { lastMessagePosition = position; return }
 
 // 检测到某个position不连续，退出单测
 _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.chatId], subscribe: false)
 XCTExpectFailure("wrong order, cids: \(messageCids.map({ $0.0 }))")
 expectation.fulfill()
 }
 
 // position是连续的，退出单测
 _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.chatId], subscribe: false)
 expectation.fulfill()
 }).disposed(by: disposeBag)
 
 // 这9条消息依次调用SEND_MESSAGE
 for index in 0...8 {
 RustSendMessageModule.sendMessage(cid: messageCids[index].0, client: self.rustService, context: messageCids[index].1, multiSendSerialToken: 10_000).subscribe(onError: { _ in
 XCTExpectFailure("send message error, cid: \(messageCids[index].0)")
 expectation.fulfill()
 }).disposed(by: disposeBag)
 }
 }
 
 wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
 }
 } */
