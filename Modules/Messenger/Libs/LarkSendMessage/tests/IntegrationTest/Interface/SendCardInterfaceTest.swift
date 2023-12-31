//
//  SendCardInterfaceTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2023/2/28.
//

import Foundation
import XCTest
import LarkSDKInterface // SendMessageAPI
import LarkContainer // InjectedSafeLazy
import LarkModel // CardContent
import RxSwift // DisposeBag
import LarkSDKInterface // SDKRustService
import RustPB // Basic_V1_RichTextElement
@testable import LarkSendMessage

// 测试sendCard接口
final class SendCardInterfaceTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var chatAPI: ChatAPI
    /// 测试账号信息
    private let groupChatID = "7196963741224157187"
    /// 设置备注名 uid (备注Test)
    private let userIDWithRemarkName = "7094941236301135876"
    /// 备注名：Test
    private let groupChatIDWithRemarkName = "7170989253818646532"
    /// 原名：xKshb1bEiU
    private let userId = "7112332912338452481"

    // 测试发送消息卡片文本，校验接口调用是否成功；文本输入与接收到的Push一致
    func testSendCardText() {
        // 设置异步等待
        // 1 等待发送接口
        let expectationSendMsg = LKTestExpectation(description: "@test send card msg")
        // 2 等待接收push
        let expectationReceivePushMsg = LKTestExpectation(description: "@test receive push msg")
        let disposeBag = DisposeBag()
        let context = APIContext(contextID: RandomString.random(length: 10))
        // 发送消息cid
        var msgCid: String = ""
        // 标记Push校验是否成功
        var inspecterPushText: String = ""
        var inspecterPushFormatText: String = ""
        var inspecterPushEmotion: String = ""
        var inspecterPushATRemarkName: String = ""
        var inspecterPushATOriginalName: String = ""
        // 标记消息发送是否成功
        var inspecterSend = false
        // 输入数据构造
        let contentBuilder = RichTextBuilder()
        let textContent = RandomString.random(length: 16)
        // 生成普通文本 - 只校验文本内容
        let textElementKey = "1"
        contentBuilder.updateRichTextWithFormatElement(key: textElementKey,
                                                       content: textContent)
        // 生成格式化文本 - 校验文本内容和文本格式
        let formatTextElementKey = "2"
        contentBuilder.updateRichTextWithFormatElement(key: formatTextElementKey,
                                                       content: textContent,
                                                       Bold: true)
        // 生成表情 - 校验表情的key
        let emotionElementKey = "3"
        contentBuilder.updateRichTextWithEmotionElement(key: emotionElementKey, emotionKey: "Done")
        // 生成AT（原名）- 校验at不含备注名的Key
        let atOriginalNameKey = "4"
        contentBuilder.updateRichTextWithAtElement(key: atOriginalNameKey, userID: self.userId, content: "")
        // 生成AT（备注名）- 校验at备注名的Key
        let atRemarkNameKey = "5"
        contentBuilder.updateRichTextWithAtElement(key: atRemarkNameKey, userID: self.userIDWithRemarkName, content: "")
        var basicCardContent = Basic_V1_CardContent()
        var cardHeader = RustPB.Basic_V1_CardContent.CardHeader()
        basicCardContent.type = .text
        basicCardContent.richtext = contentBuilder.richText
        cardHeader.title = "Test"
        basicCardContent.cardHeader = cardHeader
        let cardContent = CardContent.transform(cardContent: basicCardContent)
        // 调用asyncSubscribeChatEvent进行订阅
        self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)
        self.sendMessageAPI.sendCard(context: context,
                                     content: cardContent,
                                     chatId: self.groupChatID,
                                     threadId: nil,
                                     parentMessage: nil,
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
            if let currentContent = pushMsg.message.content as? CardContent {
                let elements = currentContent.richText.elements as [String: RustPB.Basic_V1_RichTextElement]
                inspecterPushText = elements[textElementKey]!.property.text.content
                inspecterPushFormatText = elements[formatTextElementKey]!.style["fontWeight"] ?? ""
                inspecterPushEmotion = elements[emotionElementKey]!.property.emotion.key
                inspecterPushATOriginalName = elements[atOriginalNameKey]!.property.at.content
                inspecterPushATRemarkName = elements[atRemarkNameKey]!.property.at.content
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
        XCTAssertEqual(inspecterPushText, textContent)
        XCTAssertEqual(inspecterPushFormatText, "bold")
        XCTAssertEqual(inspecterPushEmotion, "Done")
        XCTAssertEqual(inspecterPushATOriginalName, "xKshb1bEiU")
        XCTAssertEqual(inspecterPushATRemarkName, "Test")
    }
}
