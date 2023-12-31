//
//  AliasIntegrationTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李瑞 on 2022/12/6.
//

import Foundation
import XCTest
import LarkContainer // InjectedSafeLazy
import LarkModel // TextContent
import RustPB // Basic_V1_QuasiContent
import LarkSDKInterface // SDKRustService
import RxSwift // DisposeBag
@testable import LarkSendMessage

/// 备注名问题集成case：https://bytedance.feishu.cn/docx/ScGqdMeI4oaTwIxuTdsc6gwDn9b
final class AliasIntegrationTest: CanSkipTestCase {
    @InjectedSafeLazy private var rustService: SDKRustService
    @InjectedSafeLazy private var sendMessageAPI: SendMessageAPI
    @InjectedSafeLazy private var chatAPI: ChatAPI
    private var cid: String = ""
    private var content: Basic_V1_QuasiContent = Basic_V1_QuasiContent()

    override func setUp() {
        super.setUp()
        // 测试使用物料 具体可参考https://bytedance.feishu.cn/docx/VThDdraRioYcltxHCO7cFlxRnRd
        let userId = "7112332912338452481"
        self.cid = RandomString.random(length: 10)
        // content随便设置一个不是原名&备注名的内容
        self.content = MockDataCenter.genQuasiContentData(withAtElement: true, userId: userId, content: "_")
    }

    func testAliasCase() {
        let disposeBag = DisposeBag()
        let expectation = LKTestExpectation(description: "@test alias")
        // 是否检测通过
        var inspecter: Bool = false
        DispatchQueue.global().async {
            // 测试物料中该群已给userId设置了备注名为Test
            let chatId = "7170989253818646532"
            // 创建假消息，得到名称
            let context = APIContext(contextID: RandomString.random(length: 18))
            guard let msgResponse = try? RustSendMessageModule.createQuasiMessage(chatId: chatId,
                                                                                  type: .text,
                                                                                  content: self.content,
                                                                                  cid: self.cid,
                                                                                  client: self.rustService,
                                                                                  context: context)/*,
                                                                                                    let beforeContent = msgResponse.0.content as? LarkModel.TextContent,
                                                                                                    let atElement = beforeContent.richText.elements.first(where: { $0.value.tag == .at })*/ else {
                XCTExpectFailure("quasi message is nil, cid:\(self.cid)")
                expectation.fulfill()
                return
            }
            // 预期用设置的备注名，如果是首次安装，第一次创建假消息备注名还没从网络拉取，此时是原名
            /* if atElement.value.property.at.content != "Test" {
             expectation.fulfill()
             return
             } */

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

                if let currentContent = pushMsg.message.content as? LarkModel.TextContent {
                    for (_, value) in currentContent.richText.elements where value.tag == .at {
                        // 预期用设置的备注名，和Rust创建的假消息内容一致
                        inspecter = (value.property.at.content == "Test")
                    }
                }

                _ = self.chatAPI.asyncSubscribeChatEvent(chatIds: [chatId], subscribe: false)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        }
        expectation.setupAutoFulfill(after: WaitTimeout.defaultTimeout)
        wait(for: [expectation], timeout: WaitTimeout.defaultTimeout)
        if expectation.autoFulfill { return }
        XCTAssertTrue(inspecter, "cid: \(self.cid)")
    }
}
