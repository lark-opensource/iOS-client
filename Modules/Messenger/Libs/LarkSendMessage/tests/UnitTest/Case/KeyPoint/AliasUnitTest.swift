//
//  AliasUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2022/12/6.
//

import Foundation
import XCTest
import RustPB // Basic_V1_QuasiContent
import RxSwift // DisposeBag
import LarkModel // TextContent
import LarkContainer // InjectedSafeLazy
import LarkSDKInterface // SDKRustService
@testable import LarkSendMessage

/// 备注名问题单测case：https://bytedance.feishu.cn/docx/ScGqdMeI4oaTwIxuTdsc6gwDn9b
final class AliasUnitTest: CanSkipTestCase {
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var rustService: SDKRustService
    @InjectedSafeLazy private var chatAPI: ChatAPI
    /// Rust创建假消息需要的内容
    private var quasiContent: Basic_V1_QuasiContent = Basic_V1_QuasiContent()

    override func setUp() {
        super.setUp()
        // 测试使用物料 具体可参考https://bytedance.feishu.cn/docx/VThDdraRioYcltxHCO7cFlxRnRd
        let userId = "7112332912338452481"
        // content随便设置一个不是原名&备注名的内容
        self.quasiContent = MockDataCenter.genQuasiContentData(withAtElement: true, userId: userId, content: "_")
    }

    /// 带AT的内容不使用端上创建假消息
    func testRustCreateQuasiMsgCondition() {
        let input = MockDataCenter.genSendTextMessageProcessInputData(withAtElement: true)
        XCTAssertEqual(RustSendMessageModule.genCreateQuasiMsgType(input), CreateQuasiMsgType.rust)
    }

    /// 不带AT的内容使用端上创建假消息
    func testNativeCreateQasiMsgCondition() {
        let input = MockDataCenter.genSendTextMessageProcessInputData(withAtElement: false)
        XCTAssertEqual(RustSendMessageModule.genCreateQuasiMsgType(input), CreateQuasiMsgType.native)
    }

    /// 向"备注名测试群"群发消息，展示设置的备注名
    func testRustCreateMessage1() {
        let expectation = LKTestExpectation(description: "@test rust create message")
        var resultContent: String?; let messageCid: String = RandomString.random(length: 10)
        DispatchQueue.global().async {
            // 得到Rust返回的名字
            let chatId = "7170989253818646532"
            do {
                let msgResponse = try RustSendMessageModule.createQuasiMessage(chatId: chatId,
                                                                                type: .text,
                                                                                content: self.quasiContent,
                                                                                cid: messageCid,
                                                                                client: self.rustService,
                                                                                context: nil)
                if let content = msgResponse.0.content as? LarkModel.TextContent {
                    for (_, value) in content.richText.elements where value.tag == .at {
                        resultContent = value.property.at.content
                    }
                }
            } catch {
                XCTExpectFailure("quasi message fail, err:\(error)")
            }
            expectation.fulfill()
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        // 应该和设置的备注名一样，测试物料中该群已给userId设置了备注名为Test
        XCTAssertEqual(resultContent, "Test", "cid: \(messageCid)")
    }

    /// 向"未设置备注名测试群"群发消息，展示原名
    func testRustCreateMessage2() {
        let expectation = LKTestExpectation(description: "@test rust create message")
        var resultContent: String?; let messageCid: String = RandomString.random(length: 10)
        DispatchQueue.global().async {
            // 得到Rust返回的名字
            let chatId = "7173491043940417540"
            do {
                let msgResponse = try RustSendMessageModule.createQuasiMessage(chatId: chatId,
                                                                                type: .text,
                                                                                content: self.quasiContent,
                                                                                cid: messageCid,
                                                                                client: self.rustService,
                                                                                context: nil)
                if let content = msgResponse.0.content as? LarkModel.TextContent {
                    for (_, value) in content.richText.elements where value.tag == .at {
                        resultContent = value.property.at.content
                    }
                }
            } catch {
                XCTExpectFailure("quasi message fail, err:\(error)")
            }
            expectation.fulfill()
        }
        // 应该和原名一样
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        XCTAssertEqual(resultContent, "xKshb1bEiU", "cid: \(messageCid)")
    }

    /// 测试SEND_MESSAGE，Rust、Server都不会修改内容
    func testSendMessagePush() {
        // 是否检测通过
        var inspecter: Bool = false; let disposeBag = DisposeBag()
        let messageCid: String = RandomString.random(length: 10)
        let expectation = LKTestExpectation(description: "@test send message push")
        DispatchQueue.global().async {
            // 测试物料中该群已给userId设置了备注名为Test
            let chatId = "7170989253818646532"
            // 需要传APIContext，否则SEND_MESSAGE会报错
            let apiContext = APIContext(contextID: RandomString.random(length: 18))
            // 先创建一个假消息
            guard let msgResponse = try? RustSendMessageModule.createQuasiMessage(chatId: chatId,
                                                                                  type: .text,
                                                                                  content: self.quasiContent,
                                                                                  cid: messageCid,
                                                                                  client: self.rustService,
                                                                                  context: apiContext) else {
                expectation.fulfill()
                return
            }
            guard let beforeContent = msgResponse.0.content as? LarkModel.TextContent,
                  let beforeAtElement = beforeContent.richText.elements.first(where: { $0.value.tag == .at }) else {
                XCTExpectFailure("not have at element, cid: \(messageCid)")
                expectation.fulfill()
                return
            }

            // 调用asyncSubscribeChatEvent进行订阅
            self.chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: true)
            // 订阅完成再调用SEND_MESSAGE
            RustSendMessageModule.sendMessage(cid: msgResponse.0.cid, client: self.rustService, context: apiContext, multiSendSerialToken: nil).subscribe(onNext: { _ in
                // Rust给服务端发送SEND_MESSAGE，如果push先于response返回Rust，则Rust给端上的response.messageId也会为空，所以不能用messageId是否为空判断是否发送成功
                /* if result.messageId.isEmpty { XCTExpectFailure("message id is empty") } */
            }).disposed(by: disposeBag)

            // 监听PushMessage
            self.sendMessageAPI.pushCenter.observable(for: PushChannelMessage.self).subscribe(onNext: { [weak self] pushMsg in
                // 只处理刚才创建的消息，成功的消息
                guard let `self` = self, pushMsg.message.cid == msgResponse.0.cid else { return }
                guard let currentContent = pushMsg.message.content as? LarkModel.TextContent,
                      let currentAtElement = currentContent.richText.elements.first(where: { $0.value.tag == .at }) else {
                    XCTExpectFailure("response not have at element, cid: \(messageCid)")
                    expectation.fulfill()
                    return
                }

                inspecter = (currentAtElement.value.property.at.content == beforeAtElement.value.property.at.content)

                _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: false)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        XCTAssertTrue(inspecter, "cid: \(messageCid)")
    }
}
