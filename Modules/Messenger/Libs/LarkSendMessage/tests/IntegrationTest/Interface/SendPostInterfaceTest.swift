//
//  SendPostInterfaceTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2023/2/14.
//

import Foundation
import XCTest
import LarkSDKInterface // SendMessageAPI
import LarkContainer // InjectedSafeLazy
import LarkModel // PostContent
import RxSwift // DisposeBag
import LarkSDKInterface // SDKRustService
import RustPB // Basic_V1_RichTextElement
import LarkStorage // IsoPath
@testable import LarkSendMessage

final class SendPostInterfaceTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var sendThreadAPI: SendThreadAPI
    @InjectedSafeLazy private var postSendSrvice: PostSendService
    @InjectedSafeLazy private var chatAPI: ChatAPI
    /// 测试账号信息
    private let groupChatID = "7196963741224157187"
    /// 设置备注名 uid (备注Test)
    private let userIDWithRemarkName = "7094941236301135876"
    /// 备注名：Test
    private let groupChatIDWithRemarkName = "7170989253818646532"
    /// 原名：xKshb1bEiU
    private let userId = "7112332912338452481"
    private let groupChatIDWithnotRmarkName = "7173491043940417540"

    // 测试普通群发送Post消息(不含视频)，校验接口调用是否成功；文本、格式文本、表情、AT等内容输入与接收到的Push一致
    func testSendPostFromChat() {
        // 设置异步等待
        // 1 等待发送接口
        let expectationSendMsg = LKTestExpectation(description: "@test send text msg")
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
        var inspecterPushTitle: String = ""
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
        // 调用asyncSubscribeChatEvent进行订阅
        self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)
        self.postSendSrvice.sendMessage(context: context,
                                        title: "Test",
                                        content: contentBuilder.richText,
                                        lingoInfo: nil,
                                        parentMessage: nil,
                                        chatId: self.groupChatID,
                                        threadId: nil,
                                        isGroupAnnouncement: false,
                                        isAnonymous: false,
                                        isReplyInThread: false,
                                        transmitToChat: false,
                                        scheduleTime: nil,
                                        sendMessageTracker: nil,
                                        stateHandler: { state in
            if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
            if case .finishSendMessage(_, _, _, _, _) = state {
                    inspecterSend = true
                    expectationSendMsg.fulfill()
                }
            })
        // 监听Push
        self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
            // 根据cid 判断是否为发送的消息
            guard let `self` = self, pushMsg.message.cid == msgCid, pushMsg.message.localStatus == .success else { return }
            if let currentContent = pushMsg.message.content as? PostContent {
                let elements = currentContent.richText.elements as [String: RustPB.Basic_V1_RichTextElement]
                inspecterPushText = elements[textElementKey]!.property.text.content
                inspecterPushFormatText = elements[formatTextElementKey]!.style["fontWeight"] ?? ""
                inspecterPushEmotion = elements[emotionElementKey]!.property.emotion.key
                inspecterPushATOriginalName = elements[atOriginalNameKey]!.property.at.content
                inspecterPushATRemarkName = elements[atRemarkNameKey]!.property.at.content
                inspecterPushTitle = currentContent.title
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
        // 校验点2: 接收push内容是否一致
        XCTAssertEqual(inspecterPushText, textContent)
        XCTAssertEqual(inspecterPushFormatText, "bold")
        XCTAssertEqual(inspecterPushEmotion, "Done")
        XCTAssertEqual(inspecterPushATOriginalName, "xKshb1bEiU")
        XCTAssertEqual(inspecterPushATRemarkName, "Test")
        XCTAssertEqual(inspecterPushTitle, "Test")
    }

    // 测试普通群发送Post消息(含视频)，校验接口调用是否成功；文本、格式文本、表情、AT等内容输入与接收到的Push一致
    func testSendPostFromChatWithMedia() {
        // 设置异步等待
        // 1 等待发送接口
        let expectationSendMsg = LKTestExpectation(description: "@test send text msg")
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
        var inspecterPushTitle: String = ""
        // 标记发送视频文件大小
        var inspecterSize: Int64?
        var originMediaSize: Int64?
        // 标记消息发送是否成功
        var inspecterSend = false
        // 标记视频消息key
        var inspecterMediaKey = false
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
        // 生成视频消息 - 校验视频的key
        let mediaElementKey = "6"
        // 人为造一个临时路径
        let tempMediaDir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "chatPostInterface" + "sendPost"
        do {
            try tempMediaDir.createDirectoryIfNeeded()
        } catch {
            XCTExpectFailure("create media dir error")
        }
        let tempMediaPath = tempMediaDir + "sendPost.mp4"
        try? tempMediaPath.removeItem()
        do {
            let mediaData = Resources.mediaData(named: "10-540x960-mp4")
            originMediaSize = Int64(mediaData.count)
            try mediaData.write(to: tempMediaPath)
        } catch {
            XCTExpectFailure("data move to path error")
            expectationSendMsg.fulfill()
        }
        contentBuilder.updateRichTextWithMediaElement(key: mediaElementKey, originPath: tempMediaPath.absoluteString, imageData: Resources.imageData(named: "1200x1400-JPEG"))
        AutoLoginHandler().autoLogin {
            // 调用asyncSubscribeChatEvent进行订阅
            self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: true)
            self.postSendSrvice.sendMessage(context: context,
                                            title: "Test With Media",
                                            content: contentBuilder.richText,
                                            lingoInfo: nil,
                                            parentMessage: nil,
                                            chatId: self.groupChatID,
                                            threadId: nil,
                                            isGroupAnnouncement: false,
                                            isAnonymous: false,
                                            isReplyInThread: false,
                                            transmitToChat: false,
                                            scheduleTime: nil,
                                            sendMessageTracker: nil,
                                            stateHandler: { state in
                if case let .getQuasiMessage(msg, _, _, _, _) = state { msgCid = msg.cid }
                if case .finishSendMessage(_, _, _, _, _) = state {
                        inspecterSend = true
                        expectationSendMsg.fulfill()
                    }
                })
            // 监听Push
            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
                // 根据cid 判断是否为发送的消息
                guard let `self` = self, pushMsg.message.cid == msgCid, pushMsg.message.localStatus == .success else { return }
                if let currentContent = pushMsg.message.content as? PostContent {
                    let elements = currentContent.richText.elements as [String: RustPB.Basic_V1_RichTextElement]
                    inspecterPushText = elements[textElementKey]!.property.text.content
                    inspecterPushFormatText = elements[formatTextElementKey]!.style["fontWeight"] ?? ""
                    inspecterPushEmotion = elements[emotionElementKey]!.property.emotion.key
                    inspecterPushATOriginalName = elements[atOriginalNameKey]!.property.at.content
                    inspecterPushATRemarkName = elements[atRemarkNameKey]!.property.at.content
                    inspecterSize = elements[mediaElementKey]!.property.media.size
                    inspecterPushTitle = currentContent.title
                    inspecterMediaKey = elements[mediaElementKey]!.property.media.key.isEmpty
                }
                expectationReceivePushMsg.fulfill()
            }).disposed(by: disposeBag)
        }
        expectationSendMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        expectationReceivePushMsg.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectationSendMsg, expectationReceivePushMsg], timeout: WaitTimeout.defaultTimeout)
        // 取消订阅
        _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [self.groupChatID], subscribe: false)
        if expectationSendMsg.autoFulfill || expectationReceivePushMsg.autoFulfill { return }
        // 校验点1: 消息是否发送成功
        XCTAssertTrue(inspecterSend)
        // 校验点2: 接收push内容是否一致
        XCTAssertEqual(inspecterPushText, textContent)
        XCTAssertEqual(inspecterPushFormatText, "bold")
        XCTAssertEqual(inspecterPushEmotion, "Done")
        XCTAssertEqual(inspecterPushATOriginalName, "xKshb1bEiU")
        XCTAssertEqual(inspecterPushATRemarkName, "Test")
        XCTAssertEqual(inspecterPushTitle, "Test With Media")
        XCTAssertEqual(inspecterSize, originMediaSize)
        XCTAssertFalse(inspecterMediaKey)
    }
}
